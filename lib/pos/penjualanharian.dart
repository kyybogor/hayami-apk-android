import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hayami_app/pos/detailpenjualan.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Penjualanharian extends StatefulWidget {
  const Penjualanharian({super.key});

  @override
  State<Penjualanharian> createState() => _PenjualanharianState();
}

class _PenjualanharianState extends State<Penjualanharian> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> invoices = [];
  List<Map<String, dynamic>> filteredInvoices = [];
  Map<String, dynamic> totalPerAkun = {};
  bool isLoading = true;
  bool dataChanged = false;

  String selectedMonth =
      DateFormat('MM').format(DateTime.now()); // Default bulan ini
  String selectedYear =
      DateFormat('yyyy').format(DateTime.now()); // Default tahun ini

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    fetchInvoices();
    filterByMonthYear();
  }

  Future<void> fetchInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final idCabang = prefs.getString('id_cabang') ?? '';

    try {
      final response = await http.get(
        Uri.parse(
            'http://192.168.1.11/pos/barang_keluar.php?id_cabang=$idCabang'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> invoicesData = data['data'] ?? [];
        final Map<String, dynamic> akunData = data['total_per_akun'] ?? {};

        setState(() {
          invoices = invoicesData.map<Map<String, dynamic>>((item) {
            return {
              "id_transaksi": item["id_transaksi"] ?? '-',
              "tgl_transaksi": item["tgl_transaksi"] ?? '-',
              "total_invoice": item["total_invoice"] ?? '0',
              "akun": item["akun"] ?? '-',
              "sisa_bayar": item["sisa_bayar"] ?? '0', // Tambahan ini
            };
          }).toList();

          totalPerAkun = akunData;
          isLoading = false;
        });

        // Langsung filter ke bulan Juli
        filterByMonthYear();
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

  void _onSearchChanged() {
    String keyword = _searchController.text.toLowerCase();

    setState(() {
      filteredInvoices = invoices.where((invoice) {
        final idTransaksi = invoice["id_transaksi"].toString().toLowerCase();
        return idTransaksi.contains(keyword);
      }).toList();

      filteredInvoices.sort((a, b) {
        try {
          final dateA = DateFormat('yyyy-MM-dd').parse(a['tgl_transaksi']);
          final dateB = DateFormat('yyyy-MM-dd').parse(b['tgl_transaksi']);
          return dateB
              .compareTo(dateA); // Urutkan dari yang terbaru ke yang terlama
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

  void filterByMonthYear() {
    setState(() {
      filteredInvoices = invoices.where((invoice) {
        try {
          final dateStr = invoice["tgl_transaksi"];
          if (dateStr == null || dateStr.isEmpty || dateStr == '-') {
            return false;
          }

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

      filteredInvoices.sort((a, b) {
        try {
          final dateA = DateFormat('yyyy-MM-dd').parse(a['tgl_transaksi']);
          final dateB = DateFormat('yyyy-MM-dd').parse(b['tgl_transaksi']);
          return dateB.compareTo(dateA); // descending (baru ke lama)
        } catch (e) {
          return 0;
        }
      });
    });
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
          title: const Text("Penjualan Harian",
              style: TextStyle(color: Colors.blue)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.blue),
            onPressed: () {
              Navigator.pop(context, dataChanged);
            },
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
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
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12.0, vertical: 4),
                      child: Row(
                        children: [
                          Flexible(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              value: selectedMonth,
                              isExpanded: true,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.calendar_today),
                                labelText: "Bulan",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.blue.shade50,
                              ),
                              items: [
                                'Semua',
                                ...List.generate(
                                    12,
                                    (index) =>
                                        (index + 1).toString().padLeft(2, '0')),
                              ].map((month) {
                                return DropdownMenuItem(
                                  value: month,
                                  child: Text(month == 'Semua'
                                      ? 'Semua Bulan'
                                      : DateFormat('MMMM').format(
                                          DateTime(0, int.parse(month)))),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    selectedMonth = value;
                                  });
                                  filterByMonthYear();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            flex: 1,
                            child: DropdownButtonFormField<String>(
                              value: selectedYear,
                              isExpanded: true,
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.date_range),
                                labelText: "Tahun",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide.none,
                                ),
                                filled: true,
                                fillColor: Colors.blue.shade50,
                              ),
                              items:
                                  ['Semua', '2023', '2024', '2025'].map((year) {
                                return DropdownMenuItem(
                                  value: year,
                                  child: Text(
                                      year == 'Semua' ? 'Semua Tahun' : year),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    selectedYear = value;
                                  });
                                  filterByMonthYear();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: const SizedBox(height: 12)),
                  SliverToBoxAdapter(
                    child: Container(
                      height: 100,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: totalPerAkun.entries.map((entry) {
                            String akun = entry.key.trim().isEmpty
                                ? 'LAINNYA'
                                : entry.key.trim();
                            int total =
                                int.tryParse(entry.value.toString()) ?? 0;

                            return Container(
                              width: 220,
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade100),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.shade300,
                                    blurRadius: 4,
                                    offset: const Offset(2, 2),
                                  )
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    akun,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    NumberFormat.currency(
                                      locale: 'id_ID',
                                      symbol: 'Rp ',
                                      decimalDigits: 0,
                                    ).format(total),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: const SizedBox(height: 12)),
                  filteredInvoices.isEmpty
                      ? SliverToBoxAdapter(
                          child:
                              Center(child: Text("Tidak ada data ditemukan")),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final invoice = filteredInvoices[index];
                              final int sisaBayar =
                                  int.tryParse(invoice["sisa_bayar"] ?? '0') ??
                                      0;
                              final bool isOutstanding = sisaBayar > 0;

                              return ListTile(
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(invoice["id_transaksi"] ?? '-'),
                                    Text(
                                      invoice["akun"] ?? '-',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    Text(
                                      invoice["tgl_transaksi"] ?? '-',
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  ],
                                ),
                                trailing: Builder(
                                  builder: (context) {
                                    final int sisaBayar = int.tryParse(
                                            invoice["sisa_bayar"] ?? '0') ??
                                        0;
                                    final bool isOutstanding = sisaBayar > 0;

                                    return Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: isOutstanding
                                                ? Colors.red.shade100
                                                : Colors.green.shade100,
                                            borderRadius:
                                                BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            formatRupiah(
                                                invoice["total_invoice"] ??
                                                    '0'),
                                            style: TextStyle(
                                              color: isOutstanding
                                                  ? Colors.red
                                                  : Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.arrow_forward_ios,
                                            size: 16, color: Colors.grey),
                                      ],
                                    );
                                  },
                                ),
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          Detailpenjualan(invoice: invoice),
                                    ),
                                  );
                                  if (result == true) {
                                    fetchInvoices();
                                    dataChanged = true;
                                  }
                                },
                              );
                            },
                            childCount: filteredInvoices.length,
                          ),
                        ),
                ],
              ),
      ),
    );
  }
}
