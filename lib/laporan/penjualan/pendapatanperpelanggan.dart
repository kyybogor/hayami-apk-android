import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pendapatan Per Pelanggan',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PendapatanPerpelangganPage(),
    );
  }
}

class PendapatanPerpelangganPage extends StatefulWidget {
  const PendapatanPerpelangganPage({super.key});

  @override
  State<PendapatanPerpelangganPage> createState() =>
      _PendapatanPerpelangganPageState();
}

class _PendapatanPerpelangganPageState
    extends State<PendapatanPerpelangganPage> {
  List<dynamic> customers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDataFromApi();
  }

  // Mengambil data dari API
  Future<void> fetchDataFromApi() async {
    const url =
        'http://192.168.1.9/Hiyami/pendapatan.php'; // Ganti dengan URL API-mu

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          customers = jsonData;
          isLoading = false;
        });
      } else {
        throw Exception("Gagal memuat data (${response.statusCode})");
      }
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint("Error saat ambil data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          foregroundColor: Colors.blueAccent,
          title: const Text("Pendapatan per Orang", style: TextStyle(color: Colors.blueAccent, fontSize: 20),),
          centerTitle: true,
          leading: const BackButton(),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: customers.length,
                itemBuilder: (context, index) {
                  final item = customers[index];
                  return ListTile(
                    title: Text(item['nama']),
                    subtitle: Text(item['instansi']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item['amount'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                          builder: (_) => DetailPendapatanPage(data: item),
                        ),
                      );
                    },
                  );
                },
              ));
  }
}

class DetailPendapatanPage extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetailPendapatanPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> transactions = data['barang_kontak'];

    return Scaffold(
      appBar: AppBar(
        title: Text(data['nama']),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header tetap
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                infoRow('Perusahaan', data['instansi']),
                const Divider(
                  height: 5,
                ),
                infoRow('Total Transaksi', transactions.length.toString()),
                const Divider(
                  height: 5,
                ),
                infoRow('Pendapatan', data['amount']),
                const Divider(height: 5),
                const SizedBox(height: 16),
              ],
            ),
          ),
          // Bagian transaksi scrollable
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(
                      height: 5,
                    ),
                    infoRow('Nomor', data['invoice']),
                    const Divider(height: 5),
                    infoRow('Tanggal', data['date']),
                    const Divider(height: 5),
                    infoRow('Produk', tx['nama_barang'] ?? 'Tidak ada'),
                    const Divider(height: 5),
                    infoRow('Jumlah', tx['jumlah']),
                    const Divider(height: 5),
                    infoRow('Harga', tx['harga']),
                    const Divider(height: 5),
                    infoRow('Total', tx['total']),
                    const Divider(
                      height: 5,
                    ),
                    const SizedBox(height: 35),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
