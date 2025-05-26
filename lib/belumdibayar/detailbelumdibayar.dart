import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hayami_app/produk/produkdetail.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class Detailbelumdibayar extends StatefulWidget {
  final Map<String, dynamic> invoice;

  const Detailbelumdibayar({super.key, required this.invoice});

  @override
  State<Detailbelumdibayar> createState() => _DetailbelumdibayarState();
}

class _DetailbelumdibayarState extends State<Detailbelumdibayar> {
  List<dynamic> barang = [];
  List<dynamic> allProduk = [];

  @override
  void initState() {
    super.initState();
    fetchProduct();
  }

  Future<void> fetchProduct() async {
    final invoiceId = widget.invoice['id']?.toString() ?? '';
    final url = Uri.parse("http://192.168.1.8/hiyami/produk.php");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        allProduk = data['data'];

        final filtered = (data['data'] as List).expand((product) {
          return (product['kontaks'] as List).where((kontak) {
            return kontak['kontak_id'].toString() == invoiceId;
          }).map((kontak) {
            final barang = kontak['barang_kontak'] ?? {};
            final jumlah = double.tryParse(barang['jumlah']?.toString() ?? '0') ?? 0;
            final harga = double.tryParse(barang['harga']?.toString() ?? '0') ?? 0;
            final total = jumlah * harga;

            return {
              'nama_barang': barang['nama_barang'] ?? 'Tidak Diketahui',
              'size': barang['size'] ?? 'Tidak Diketahui',
              'jumlah': jumlah.toString(),
              'harga': harga.toString(),
              'total': total.toString(),
              'barang_id': barang['barang_id'],
            };
          }).toList();
        }).toList();

        setState(() {
          barang = filtered;
        });
      } else {
        print('Gagal mengambil data barang. Status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error saat mengambil data barang: $e");
    }
  }

  double getTotalSemuaBarang() {
    double total = 0;
    for (var item in barang) {
      final harga = double.tryParse(item['total']?.toString() ?? '0') ?? 0;
      total += harga;
    }
    return total;
  }

  String formatRupiah(double number) {
    final formatter = NumberFormat("#,###", "id_ID");
    return formatter.format(number);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'belum dibayar':
        return Colors.red;
      case 'dibayar sebagian':
        return Colors.orange;
      case 'lunas':
        return Colors.green;
      case 'void':
        return Colors.grey;
      case 'jatuh tempo':
        return Colors.black;
      case 'retur':
        return Colors.deepOrange;
      case 'transaksi berulang':
        return Colors.blue;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    final contactName = invoice['name'] ?? 'Tidak diketahui';
    final instansi = invoice['instansi']?? '-';
    final invoiceNumber = invoice['invoice'] ?? '-';
    final date = invoice['date'] ?? '-';
    final dueDate = invoice['due'] ?? '-';
    final address = invoice['alamat'] ?? '-';
    final status = invoice['status'] ?? 'Belum Dibayar';
    final statusColor = _getStatusColor(status);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: const Text('Tagihan', style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(invoiceNumber, contactName, instansi, address, date, dueDate, status, statusColor),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Barang Dibeli",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: barang.isEmpty
                      ? const Center(child: Text("Tidak ada barang untuk invoice ini."))
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
                                    if (item['size'] != null && item['size'].isNotEmpty)
                                      Text("Ukuran: ${item['size']}"),
                                    Text(
                                      "${item['jumlah']} x Rp ${formatRupiah(double.tryParse(item['harga']?.toString() ?? '0') ?? 0)}",
                                    ),
                                  ],
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "Rp ${formatRupiah(double.tryParse(item['total']?.toString() ?? '0') ?? 0)}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  final barangId = item['barang_id']?.toString() ?? '';
                                  Map<String, dynamic>? productDetail;

                                  for (var produk in allProduk) {
                                    final kontaks = produk['kontaks'] as List;
                                    for (var kontak in kontaks) {
                                      final barangKontak = kontak['barang_kontak'];
                                      if (barangKontak != null &&
                                          barangKontak['barang_id']?.toString() == barangId) {
                                        productDetail = produk;
                                        break;
                                      }
                                    }
                                    if (productDetail != null) break;
                                  }

                                  if (productDetail != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailPage(product: productDetail!),
                                      ),
                                    );
                                  } else {
                                    print("Produk detail tidak ditemukan");
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
                if (barang.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    color: Colors.grey.shade200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Total Semua",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text("Rp ${formatRupiah(getTotalSemuaBarang())}",
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String invoiceNumber, String contactName, String instansi, String address,
      String date, String dueDate, String status, Color statusColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(invoiceNumber, style: const TextStyle(fontSize: 16, color: Colors.white70)),
          const SizedBox(height: 16),
          Text(contactName,
              style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(instansi, style: const TextStyle(fontSize: 13, color: Colors.white)),
          const SizedBox(height: 2),
          Text(address, style: const TextStyle(fontSize: 13, color: Colors.white)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(status, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(date, style: const TextStyle(color: Colors.white)),
                ],
              ),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(dueDate, style: const TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
