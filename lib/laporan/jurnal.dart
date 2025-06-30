import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class JurnalItem {
  final String nama;
  final String invoice;
  final double amount;
  final String date;
  final List<BarangKontak> barangKontak;
  final String? akunPiutang;
  final String? instansi;
  final String statusTransaksi; // Tambahan

  JurnalItem({
    required this.nama,
    required this.invoice,
    required this.amount,
    required this.date,
    required this.barangKontak,
    this.akunPiutang,
    this.instansi,
    required this.statusTransaksi, // Tambahan
  });

  factory JurnalItem.fromJson(Map<String, dynamic> json) {
    var barangList = (json['barang_kontak'] as List)
        .map((e) => BarangKontak.fromJson(e))
        .toList();
    return JurnalItem(
      nama: json['nama'],
      invoice: json['invoice'],
      amount: double.tryParse(json['amount']) ?? 0,
      date: json['date'],
      barangKontak: barangList,
      akunPiutang: json['akun_piutang'],
      instansi: json['instansi'],
      statusTransaksi: json['status_transaksi'], // Tambahan
    );
  }
}


class BarangKontak {
  final String? namaBarang;
  final String size; 
  final String total;

  BarangKontak({
    this.namaBarang,
    required this.size,
    required this.total,
  });

  factory BarangKontak.fromJson(Map<String, dynamic> json) {
    return BarangKontak(
      namaBarang: json['produk']?['name'],
      size: json['size'] ?? 'N/A',
      total: json['total'],
    );
  }
}

class JurnalListPage extends StatefulWidget {
  const JurnalListPage({super.key});

  @override
  _JurnalListPageState createState() => _JurnalListPageState();
}

class _JurnalListPageState extends State<JurnalListPage> {
  late Future<List<JurnalItem>> futureJurnal;

  @override
  void initState() {
    super.initState();
    futureJurnal = fetchJurnalItems();
  }

  Future<List<JurnalItem>> fetchJurnalItems() async {
    final response = await http.get(Uri.parse(
        'http://192.168.1.9/Hiyami/jurnal.php')); // Ganti dengan URL-mu

    if (response.statusCode == 200) {
      final List jsonData = jsonDecode(response.body);
      return jsonData.map((e) => JurnalItem.fromJson(e)).toList();
    } else {
      throw Exception('Gagal memuat data jurnal');
    }
  }

  String formatCurrency(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.blueAccent,
        title: const Text('Jurnal', style: TextStyle(color: Colors.blueAccent, fontSize: 20),),
        centerTitle: true,
        leading: const BackButton(),
      ),
      body: FutureBuilder<List<JurnalItem>>(
        future: futureJurnal,
        builder: (context, snapshot) {   
          if (snapshot.hasData) {
            final data = snapshot.data!;
            return ListView.separated(
              itemCount: data.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final item = data[index];
                return ListTile(
                  title: Text(item.nama),
                  subtitle: Text(item.invoice),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber[400],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          formatCurrency(item.amount),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => JurnalDetailPage(item: item)),
                    );
                  },
                );
              },
            );
          } else if (snapshot.hasError) {
            return const Center(child: Text('Gagal memuat data'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

class JurnalDetailPage extends StatelessWidget {
  final JurnalItem item;

  const JurnalDetailPage({super.key, required this.item});

  String formatCurrency(String value) {
    final number = double.tryParse(value) ?? 0;
    return number
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'lunas':
        return Colors.green[100]!;
      case 'dibayar sebagian':
        return Colors.orange[100]!;
      case 'belum dibayar':
        return Colors.red[100]!;
      default:
        return Colors.grey[300]!;
    }
  }

  Color getTextColor(String status) {
    switch (status.toLowerCase()) {
      case 'lunas':
        return Colors.green[800]!;
      case 'dibayar sebagian':
        return Colors.orange[800]!;
      case 'belum dibayar':
        return Colors.red[800]!;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = item.statusTransaksi;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jurnal'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: Colors.grey[300],
            padding: const EdgeInsets.all(12),
            child: Text(
              item.nama,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Tanggal:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Text(item.date),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Invoice:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Text(item.invoice),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 10),

                // List Barang
                ...item.barangKontak.map((barang) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item.akunPiutang ?? "Belum Ada Akun Piutang"}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                    '${item.instansi ?? "Tidak Diketahui"} ${item.nama}'),
                                Text(
                                    '${barang.namaBarang ?? 'Barang Tidak Diketahui'} Ukuran ${barang.size}'),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: getStatusColor(status),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              formatCurrency(barang.total),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: getTextColor(status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(thickness: 1),
                    ],
                  );
                }).toList(),

                // TOTAL
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        formatCurrency(item.amount.toString()),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
