import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hayami_app/pos/barangmasuk.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Detaillaporanpembelian extends StatefulWidget {
  final Map<String, dynamic> invoice;

  const Detaillaporanpembelian({super.key, required this.invoice});

  @override
  State<Detaillaporanpembelian> createState() => _DetaillaporanpembelianState();
}

class _DetaillaporanpembelianState extends State<Detaillaporanpembelian> {
  List<dynamic> barang = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchProduct();
  }

  Future<void> fetchProduct() async {
    setState(() {
      isLoading = true;
    });

    final idTransaksi = widget.invoice['id']?.toString() ?? '';
    final url = Uri.parse("https://hayami.id/pos/masuk_detail.php?id_transaksi=$idTransaksi");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          final List<dynamic> produkList = jsonData['data'];

          // Mengambil data stock
          final stockResponse = await http.get(Uri.parse('https://hayami.id/pos/stock1.php'));
          final List<dynamic> stockList = json.decode(stockResponse.body)['data'];

          // Menyamakan data produk dengan stock
          final List<Map<String, dynamic>> parsedProduk = produkList.map<Map<String, dynamic>>((item) {
            final matchingStock = stockList.firstWhere(
              (stockItem) => stockItem['id_bahan'] == item['id_product'] &&
                             stockItem['model'] == item['model'] &&
                             stockItem['ukuran'] == item['ukuran'],
              orElse: () => null,
            );

            final qty = double.tryParse(item['qty']?.toString() ?? '0') ?? 0;
            final harga = double.tryParse(item['harga']?.toString() ?? '0') ?? 0;
            final total = double.tryParse(item['total']?.toString() ?? '0') ?? 0;

            return {
              'nama_barang': item['id_product'] ?? 'Tidak Diketahui',
              'uom': item['uom'] ?? 'Pcs',
              'model': item['model'] ?? '',
              'ukuran': item['ukuran'] ?? 'All Size',
              'jumlah': qty.toString(),
              'harga': harga.toString(),
              'total': total.toString(),
            };
          }).toList();

          setState(() {
            barang = parsedProduk;
          });
        }
      }
    } catch (e) {
      print("Error saat mengambil data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  double getTotalSemuaBarang() {
    return barang.fold(0, (sum, item) {
      final harga = double.tryParse(item['total']?.toString() ?? '0') ?? 0;
      return sum + harga;
    });
  }

  String formatRupiah(double number) {
    final formatter = NumberFormat("#,###", "id_ID");
    return formatter.format(number);
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Detail Barang Masuk", style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : barang.isEmpty
                    ? const Center(child: Text("Tidak ada barang."))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: barang.length,
                        itemBuilder: (context, index) {
                          final item = barang[index];
                          return Card(
                            child: ListTile(
                              title: Text(item['nama_barang'] ?? 'Tidak Diketahui'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item['model'] != null && item['model'].toString().isNotEmpty)
                                    Text("Model: ${item['model']}"),
                                  Text("Ukuran: ${item['ukuran']}"),
                                  Text("${item['jumlah']} ${item['uom']}"),
                                ],
                              ),
                              trailing: Text(
                                "Rp ${formatRupiah(double.tryParse(item['total'] ?? '0') ?? 0)}",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          // Add total amount section
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Semua Barang',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Rp ${formatRupiah(getTotalSemuaBarang())}",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
 }
