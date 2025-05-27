import 'dart:convert';
import 'package:flutter/material.dart';
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
  bool isLoading = false; // indikator loading
  String alamat = '-';     // alamat dari API

  @override
  void initState() {
    super.initState();
    fetchProduct();
  }

  Future<void> fetchProduct() async {
    setState(() {
      isLoading = true; // mulai loading
    });

    final idDo1 = widget.invoice['id']?.toString() ?? '';
    final idCust = widget.invoice['name']?.toString() ?? '';

    final url = Uri.parse("https://hayami.id/apps/erp/api-android/api/produk.php?id_do1=$idDo1&id_cust=$idCust");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final rawBody = response.body;

        final splitIndex = rawBody.indexOf('}{') + 1;
        if (splitIndex > 0 && splitIndex < rawBody.length) {
          final json1 = rawBody.substring(0, splitIndex);
          final json2 = rawBody.substring(splitIndex);

          // Decode data barang
          final data1 = json.decode(json1);
          final List<dynamic> produkList = data1['data'];

          // Decode data customer
          final dataCust = json.decode(json2);
          final List<dynamic> dataCustomerList = dataCust['data_cust'];

          // Ambil alamat customer, gabungkan alamat, kota, provinsi jika ada
          String alamatCustomer = '-';
          if (dataCustomerList.isNotEmpty) {
            final cust = dataCustomerList[0];
            final parts = [
              cust['alamat'] ?? '',
              cust['kota'] ?? '',
              cust['provinsi'] ?? ''
            ].where((element) => element.trim().isNotEmpty).toList();

            alamatCustomer = parts.isNotEmpty ? parts.join(', ') : '-';
          }

          // Parsing produk ke list barang
          final List<Map<String, dynamic>> parsedProduk = produkList.map<Map<String, dynamic>>((item) {
            final qty = double.tryParse(item['qty']?.toString() ?? '0') ?? 0;
            final harga = double.tryParse(item['harga']?.toString() ?? '0') ?? 0;
            final total = qty * harga;

            return {
              'nama_barang': item['sku'] ?? 'Tidak Diketahui',
              'size': (item['size'] != null && item['size'].toString().isNotEmpty)
                  ? item['size'].toString()
                  : 'All Size',
              'jumlah': qty.toString(),
              'harga': harga.toString(),
              'total': total.toString(),
            };
          }).toList();

          setState(() {
            barang = parsedProduk;
            alamat = alamatCustomer;  // update alamat dari API
          });
        } else {
          print("Format JSON tidak valid atau tidak bisa dipisahkan.");
        }
      } else {
        print('Gagal mengambil data barang. Status: ${response.statusCode}');
      }
    } catch (e) {
      print("Error saat mengambil data barang: $e");
    } finally {
      setState(() {
        isLoading = false; // selesai loading
      });
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
    final invoiceNumber = invoice['invoice'] ?? '-';
    final idCust = invoice['name'] ?? 'Tidak diketahui';
    final instansi = invoice['instansi'] ?? '-';
    final date = invoice['date'] ?? '-';
    final dueDate = invoice['due'] ?? '-';
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
          _buildHeader(invoiceNumber, idCust, instansi, alamat, date, dueDate, status, statusColor),
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
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : barang.isEmpty
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
                            ),
                          );
                        },
                      ),
          ),
          if (!isLoading && barang.isNotEmpty)
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
