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
    fetchInvoices();
  }

  Future<void> fetchInvoices() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final rawIdCabang = prefs.getString('id_cabang') ?? 'TKB-HAYAMI OFFICIAL-JAKARTA PUSAT';
    final cleanIdCabang = rawIdCabang.replaceAll('\u00A0', ' ').trim();
    print("🛠 ID Cabang (raw): '$rawIdCabang'");
    print("🛠 ID Cabang (clean): '$cleanIdCabang'");

    if (cleanIdCabang.isEmpty) {
      print("❌ id_cabang belum disimpan di SharedPreferences");
      setState(() {
        isLoading = false;
      });
      return;
    }

    final url = Uri.https(
      'hayami.id',
      '/pos/masuk.php',
      {'id_cabang': cleanIdCabang},
    );
    print("🛠 Request URL: $url");

    try {
      final response = await http.get(url);
      print("📦 Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> invoicesData = data['data'];

        // Filter hanya status "s"
        invoices = invoicesData.where((item) {
          return item['status'] == 's';
        }).map<Map<String, dynamic>>((item) {
          return {
            "id": item["id_transaksi"] ?? '-',
            "name": item["id_supplier"] ?? '-',
            "date": item["tgl_transaksi"] ?? '-',
            "total": item["total"] ?? '0',
            "keterangan": item["keterangan"] ?? '-',
            "qty": item["qty"] ?? '0',
            "uom": item["uom"] ?? '-',
          };
        }).toList();

        // Urutkan berdasarkan tanggal
        invoices.sort((a, b) {
          try {
            final dateA = DateFormat('yyyy-MM-dd').parse(a['date']);
            final dateB = DateFormat('yyyy-MM-dd').parse(b['date']);
            return dateA.compareTo(dateB);
          } catch (_) {
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
        return invoice["id"].toString().toLowerCase().contains(keyword);
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
          title: const Text(
            "Laporan Barang Masuk",
            style: TextStyle(color: Colors.blue),
          ),
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
                                  Text(invoice["id"] ?? '-'),
                                  Text(
                                    invoice["name"] ?? '-',
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                  Text(
                                    invoice["keterangan"] ?? '-',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "Qty: ${invoice["qty"]} ${invoice["uom"]}",
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.black54),
                                  ),
                                ],
                              ),
                              subtitle: Text(invoice["date"] ?? '-'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Card(
                                    color: Colors.green.shade100,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 6),
                                      child: Text(
                                        "${NumberFormat.currency(symbol: "Rp ").format(double.parse(invoice["total"]))}",
                                        style: TextStyle(
                                          color: Colors.green[800],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_ios,
                                      size: 16, color: Colors.grey),
                                ],
                              ),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        Detaillaporanpembelian(invoice: invoice),
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