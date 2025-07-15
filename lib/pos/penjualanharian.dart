import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hayami_app/pos/detailpenjualan.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Penjualanharian extends StatefulWidget {
  const Penjualanharian({super.key});

  @override
  State<Penjualanharian> createState() => _PenjualanharianState();
}

class _PenjualanharianState extends State<Penjualanharian> {
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
        Uri.parse('http://192.168.1.2/pos/barang_keluar.php'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> invoicesData = data['data'];

        invoices = invoicesData.map<Map<String, dynamic>>((item) {
          return {
            "id_transaksi": item["id_transaksi"] ?? '-',
            "tgl_transaksi": item["tgl_transaksi"] ?? '-',
            "total_invoice": item["total_invoice"] ?? '0',
          };
        }).toList();

        invoices.sort((a, b) {
          try {
            final dateA = DateFormat('yyyy-MM-dd HH:mm:ss').parse(a['tgl_transaksi']);
            final dateB = DateFormat('yyyy-MM-dd HH:mm:ss').parse(b['tgl_transaksi']);
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
          title: const Text("Penjualan Harian", style: TextStyle(color: Colors.blue)),
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
                                  Text(invoice["id_transaksi"] ?? '-'),
                                  Text(
                                    invoice["tgl_transaksi"] ?? '-',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100, // Hijau Muda
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      formatRupiah(invoice["total_invoice"] ?? '0'),
                                      style: TextStyle(
                                        color: Colors.green.shade800, // Hijau Tua
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
      builder: (context) => DetailBarangMasuk(invoice: invoice),
    ),
  );
  if (result == true) {
    setState(() {
      int index = filteredInvoices.indexWhere((inv) => inv['id_transaksi'] == invoice['id_transaksi']);
      if (index != -1) {
        filteredInvoices[index]['status'] = 's';
      }
    });
    Navigator.of(context).pop(true);
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
