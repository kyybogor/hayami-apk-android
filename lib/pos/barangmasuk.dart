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

        invoices = invoicesData.map<Map<String, dynamic>>((item) {
          return {
            "id": item["id_transaksi"] ?? '-',
            "name": item["keterangan"] ?? '-',
            "date": item["tgl_transaksi"] ?? '-',
            "status": item["status"] ?? 'Unknown', // Pastikan status ada
          };
        }).toList();

        // Hapus duplikat berdasarkan id_transaksi (opsional)
        final seen = <String>{};
        invoices = invoices.where((invoice) {
          final id = invoice["id"];
          if (seen.contains(id)) {
            return false;
          } else {
            seen.add(id);
            return true;
          }
        }).toList();

        // Urutkan tanggal
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

  String formatStatus(String status) {
    try {
      if (status == 'd') {
        return 'Draft'; // Status "d" menjadi "Draft"
      } else if (status == 's') {
        return 'Aprove'; // Status "s" menjadi "Aprove"
      } else {
        return status.isEmpty ? 'Unknown' : status; // Jika tidak cocok, tampilkan status asli atau "Unknown"
      }
    } catch (e) {
      return 'Unknown'; // Jika ada error, kembalikan "Unknown"
    }
  }

  Color getStatusColor(String status) {
    if (status == 'd') {
      return Colors.pink; // Teks merah untuk Draft
    } else if (status == 's') {
      return Colors.green[800]!; // Teks hijau tua untuk Aprove
    }
    return Colors.black; // Default warna hitam
  }

  Color getBackgroundColor(String status) {
    if (status == 'd') {
      return Colors.pink.shade50; // Background merah muda untuk Draft
    } else if (status == 's') {
      return Colors.green.shade100; // Background hijau muda untuk Aprove
    }
    return Colors.transparent; // Tidak ada background khusus
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
          title: const Text("Barang Masuk", style: TextStyle(color: Colors.blue)),
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
                                  Text(invoice["date"] ?? '-'),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: getBackgroundColor(invoice["status"] ?? ''),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      formatStatus(invoice["status"] ?? ''), // Panggil formatStatus untuk mendapatkan status
                                      style: TextStyle(
                                        color: getStatusColor(invoice["status"] ?? ''),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
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
