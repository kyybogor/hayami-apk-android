import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hayami_app/pos/detaillaporanpembelian.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Laporanpembelian extends StatefulWidget {
  const Laporanpembelian({super.key});

  @override
  State<Laporanpembelian> createState() => _LaporanpembelianState();
}

class _LaporanpembelianState extends State<Laporanpembelian> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> invoices = [];
  List<Map<String, dynamic>> filteredInvoices = [];
  bool isLoading = true;

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

  @override
  Future<void> fetchInvoices() async {
        final prefs = await SharedPreferences.getInstance();
    final idCabang = prefs.getString('id_cabang') ?? '';

  try {
    final response = await http.get(
      Uri.parse('http://192.168.1.11/pos/masuk.php?id_cabang=$idCabang'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> invoicesData = data['data'];

      // Filter data berdasarkan status "s"
      invoices = invoicesData.where((item) {
        return item['status'] == 's'; // Hanya ambil data dengan status "s"
      }).map<Map<String, dynamic>>((item) {
        return {
          "id": item["id_transaksi"] ?? '-',
          "name": item["id_supplier"] ?? '-',
          "date": item["tgl_transaksi"] ?? '-',
          "total": item["total"] ?? '0',  // Ambil total transaksi
        };
      }).toList();

      // Urutkan berdasarkan tanggal
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

  void _onSearchChanged() {
    String keyword = _searchController.text.toLowerCase();
    setState(() {
      filteredInvoices = invoices.where((invoice) {
        final idMatch =
            invoice["id"].toString().toLowerCase().contains(keyword); // Pencarian berdasarkan id_transaksi
        return idMatch;
      }).toList();
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
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Laporan Barang Masuk", style: TextStyle(color: Colors.blue)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.blue),
            onPressed: () {
              Navigator.pop(context);
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
                                    style: TextStyle(fontSize: 18), // Mengatur ukuran font menjadi lebih kecil
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
                                  // Kartu hijau yang menampilkan total transaksi
                                  Card(
                                    color: Colors.green.shade100,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      child: Text(
                                        "${NumberFormat.currency(symbol: "Rp ").format(double.parse(invoice["total"]))}",
                                        style: TextStyle(
                                          color: Colors.green[800], // Teks hijau
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                ],
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => Detaillaporanpembelian(invoice: invoice),
                                  ),
                                );
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
