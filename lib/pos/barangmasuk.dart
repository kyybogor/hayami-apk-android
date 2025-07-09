import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hayami_app/pos/detailbarangmasuk.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Barangmasuk extends StatefulWidget {
  const Barangmasuk({super.key});
  @override
  State<Barangmasuk> createState() => _BarangmasukState();
}

class _BarangmasukState extends State<Barangmasuk> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> invoices = [];
  List<Map<String, dynamic>> filteredInvoices = [];
  bool isLoading = true;
  bool dataChanged = false;

  String selectedMonth = DateFormat('MM').format(DateTime.now());
  String selectedYear = DateFormat('yyyy').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    selectedMonth = DateFormat('MM').format(DateTime.now());
    selectedYear = DateFormat('yyyy').format(DateTime.now());
    fetchInvoices();
  }

  Future<void> fetchInvoices() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.5/pos/masuk.php'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> invoicesData = data['data'];

        final openInvoices = invoicesData
            .where((item) =>
                item["status_lunas"] != null &&
                item["status_lunas"].toString() == '0')
            .toList();

        invoices = openInvoices.map<Map<String, dynamic>>((item) {
          String? dibuatTgl = item["tgl_transaksi"];
          return {
            "id": item["id_transaksi"] ?? '-',
            "name": (item["keterangan"] ?? '').toString().trim().isEmpty
                ? '-'
                : item["keterangan"],
            "instansi": (item["id_supplier"] ?? '').toString().trim().isEmpty
                ? '-'
                : item["id_supplier"],
            "date":
                dibuatTgl?.toString().trim().isEmpty ?? true ? null : dibuatTgl,
            "due": (item["tgl_lunas"] ?? '').toString().trim().isEmpty
                ? '-'
                : item["tgl_lunas"],
            "alamat": (item["id_cabang"] ?? '').toString().trim().isEmpty
                ? '-'
                : item["id_cabang"],
            "amount": (item["total"] ?? '').toString().trim().isEmpty
                ? '-'
                : item["total"],
            "disc": (item["disc"] ?? '0.00').toString(),
            "ppn": (item["ppn"] ?? '0.00').toString(),
            "tax": (item["cn"] ?? '0.00').toString(),
            "status": 'Belum Dibayar',
          };
        }).toList();

        // Urutkan dari tanggal terlama ke terbaru
        invoices.sort((a, b) {
          try {
            final dateA = DateFormat('yyyy-MM-dd').parse(a['date']);
            final dateB = DateFormat('yyyy-MM-dd').parse(b['date']);
            return dateA.compareTo(dateB);
          } catch (e) {
            return 0;
          }
        });

        setState(() {
          filteredInvoices = invoices;
          isLoading = false;
        });
      } else {
        throw Exception('Gagal mengambil data');
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void filterByMonthYear() {
    setState(() {
      filteredInvoices = invoices.where((invoice) {
        try {
          final dateStr = invoice["date"];
          if (dateStr == null || dateStr.isEmpty || dateStr == '-')
            return false;

          final invoiceDate = DateFormat('yyyy-MM-dd').parse(dateStr);
          final matchMonth = selectedMonth == 'Semua' ||
              invoiceDate.month.toString().padLeft(2, '0') == selectedMonth;
          final matchYear = selectedYear == 'Semua' ||
              invoiceDate.year.toString() == selectedYear;

          return matchMonth && matchYear;
        } catch (e) {
          return false;
        }
      }).toList();

      // Sort tanggal dari terlama
      filteredInvoices.sort((a, b) {
        try {
          final dateA = DateFormat('yyyy-MM-dd').parse(a['date']);
          final dateB = DateFormat('yyyy-MM-dd').parse(b['date']);
          return dateA.compareTo(dateB);
        } catch (e) {
          return 0;
        }
      });
    });
  }

void _onSearchChanged() {
  String keyword = _searchController.text.toLowerCase();

  // Set untuk menyimpan id_transaksi yang sudah diproses
  Set<String> processedIds = {};
  
  setState(() {
    filteredInvoices = invoices.where((invoice) {
      final idMatch =
          invoice["id"].toString().toLowerCase().contains(keyword); // Pencarian berdasarkan id_transaksi

      try {
        final dateStr = invoice["date"];
        if (dateStr == null || dateStr.isEmpty || dateStr == '-')
          return false;

        final invoiceDate = DateFormat('yyyy-MM-dd').parse(dateStr);
        final matchMonth = selectedMonth == 'Semua' ||
            invoiceDate.month.toString().padLeft(2, '0') == selectedMonth;
        final matchYear = selectedYear == 'Semua' ||
            invoiceDate.year.toString() == selectedYear;

        if (idMatch && matchMonth && matchYear) {
          // Cek apakah id_transaksi sudah diproses
          if (!processedIds.contains(invoice["id"])) {
            processedIds.add(invoice["id"]); // Tambahkan id yang sudah diproses
            return true; // Tampilkan hanya entri pertama dengan id_transaksi yang sama
          }
        }

        return false; // Jangan tampilkan jika id sudah diproses
      } catch (e) {
        return false;
      }
    }).toList();

    // Sort tanggal dari terlama
    filteredInvoices.sort((a, b) {
      try {
        final dateA = DateFormat('yyyy-MM-dd').parse(a['date']);
        final dateB = DateFormat('yyyy-MM-dd').parse(b['date']);
        return dateA.compareTo(dateB);
      } catch (e) {
        return 0;
      }
    });
  });
}

  String formatRupiah(String amount) {
    try {
      final double value = double.parse(amount);
      return NumberFormat.currency(
              locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
          .format(value);
    } catch (e) {
      return amount;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, dataChanged);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title:
              const Text("Belum Dibayar", style: TextStyle(color: Colors.blue)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.blue),
            onPressed: () {
              Navigator.pop(context, dataChanged);
            },
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Cari",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredInvoices.isEmpty
                      ? const Center(child: Text("Tidak ada data ditemukan"))
                      : ListView.builder(
                          itemCount: filteredInvoices.length,
                          itemBuilder: (context, index) {
                            final invoice = filteredInvoices[index];
                            return ListTile(
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(invoice["id"] ?? '-'), // id_transaksi
                                  Text(
        invoice["name"] ?? '-',
        style: TextStyle(fontSize: 10), // Mengatur ukuran font menjadi lebih kecil
      ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Dihilangkan `no_id` sesuai permintaan
                                  Text(invoice["date"] ?? '-'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.pink.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      formatRupiah(invoice["amount"] ?? '0'),
                                      style: const TextStyle(
                                        color: Colors.pink,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios,
                                      size: 16, color: Colors.grey),
                                ],
                              ),
                              onTap: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        Detailbarangmasuk(invoice: invoice),
                                  ),
                                );
                                if (result == true) {
                                  fetchInvoices();
                                  dataChanged = true;
                                }
                              },
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
