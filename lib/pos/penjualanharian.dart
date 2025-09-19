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
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  DateTime? startDate;
  DateTime? endDate;

  List<Map<String, dynamic>> invoices = [];
  List<Map<String, dynamic>> filteredInvoices = [];
  Map<String, dynamic> totalPerAkun = {};
  bool isLoading = true;
  bool dataChanged = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    fetchInvoices();
  }

  Future<void> fetchInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final idCabang = prefs.getString('id_cabang') ?? '';

    try {
      final response = await http.get(
        Uri.parse(
            'https://hayami.id/pos/barang_keluar.php?id_cabang=$idCabang'),
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
              "sisa_bayar": item["sisa_bayar"] ?? '0',
            };
          }).toList();

          totalPerAkun = akunData;
          isLoading = false;
        });

        filterByDateRange();
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
    filterByDateRange();
  }

  void filterByDateRange() {
    setState(() {
      filteredInvoices = invoices.where((invoice) {
        try {
          final dateStr = invoice["tgl_transaksi"];
          if (dateStr == null || dateStr.isEmpty || dateStr == '-')
            return false;

          final invoiceDate = _dateFormat.parse(dateStr);
          final matchStart = startDate == null ||
              invoiceDate.isAfter(startDate!.subtract(const Duration(days: 1)));
          final matchEnd = endDate == null ||
              invoiceDate.isBefore(endDate!.add(const Duration(days: 1)));

          final matchKeyword = invoice["id_transaksi"]
              .toString()
              .toLowerCase()
              .contains(_searchController.text.toLowerCase());

          return matchStart && matchEnd && matchKeyword;
        } catch (e) {
          return false;
        }
      }).toList();

      filteredInvoices.sort((a, b) {
        try {
          final dateA = _dateFormat.parse(a['tgl_transaksi']);
          final dateB = _dateFormat.parse(b['tgl_transaksi']);
          return dateB.compareTo(dateA);
        } catch (e) {
          return 0;
        }
      });
    });
  }

  Future<void> _pickDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          isStartDate ? startDate ?? DateTime.now() : endDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
      filterByDateRange();
    }
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
                  // TextField cari transaksi
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

                  // Pilih tanggal awal dan akhir (dua dropdown)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDate(context, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: Colors.blue.shade100),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Icon(Icons.date_range,
                                        color: Colors.blue),
                                    Text(
                                      startDate != null
                                          ? _dateFormat.format(startDate!)
                                          : "Dari Tanggal",
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () => _pickDate(context, false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border:
                                      Border.all(color: Colors.blue.shade100),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Icon(Icons.date_range,
                                        color: Colors.blue),
                                    Text(
                                      endDate != null
                                          ? _dateFormat.format(endDate!)
                                          : "Sampai Tanggal",
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverToBoxAdapter(child: const SizedBox(height: 12)),

                  // Total per akun
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
                                            decimalDigits: 0)
                                        .format(total),
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

                  // List data transaksi
                  filteredInvoices.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                              child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Text("Tidak ada data ditemukan"),
                          )),
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
                                    Text(invoice["akun"] ?? '-',
                                        style: const TextStyle(fontSize: 10)),
                                    Text(invoice["tgl_transaksi"] ?? '-',
                                        style: const TextStyle(fontSize: 10)),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isOutstanding
                                            ? Colors.red.shade100
                                            : Colors.green.shade100,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        formatRupiah(
                                            invoice["total_invoice"] ?? '0'),
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
