import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PenjualanPerKategoriPage extends StatefulWidget {
  const PenjualanPerKategoriPage({super.key});

  @override
  _PenjualanPerKategoriPageState createState() =>
      _PenjualanPerKategoriPageState();
}

class _PenjualanPerKategoriPageState extends State<PenjualanPerKategoriPage> {
  late Future<List<Map<String, dynamic>>> _kategoriData;

  @override
  void initState() {
    super.initState();
    _kategoriData = fetchKategoriData();
  }

  Future<List<Map<String, dynamic>>> fetchKategoriData() async {
    final response = await http.get(Uri.parse('http://192.168.1.8/Hiyami/produk.php'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      final List<dynamic> produkList = jsonData['data'];

      Map<String, Map<String, dynamic>> kategoriMap = {};

      for (var item in produkList) {
        final kategori = item['kategori'];
        final jumlah = double.tryParse(item['nominal_penjualan'])?.toInt() ?? 0;
        final kuantitas = int.tryParse(item['penjualan']) ?? 0;

        if (kategoriMap.containsKey(kategori)) {
          kategoriMap[kategori]!['jumlah'] += jumlah;
          kategoriMap[kategori]!['kuantitas'] += kuantitas;
        } else {
          kategoriMap[kategori] = {
            'nama': kategori,
            'jumlah': jumlah,
            'kuantitas': kuantitas,
          };
        }
      }

      return kategoriMap.values.toList();
    } else {
      throw Exception('Gagal mengambil data dari API');
    }
  }

  String formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Penjualan per Kategori Produk', style: TextStyle(color: Colors.blueAccent, fontSize: 20),),
        foregroundColor: Colors.blueAccent,
        centerTitle: true,
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          )
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _kategoriData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
          }

          final dataKategori = snapshot.data!;
          final total = dataKategori.fold(0, (sum, item) => sum + item['jumlah'] as int);
          final jumlahTerjual = dataKategori.fold(0, (sum, item) => sum + item['kuantitas'] as int);
          final rataRata = jumlahTerjual == 0 ? 0 : total ~/ jumlahTerjual;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    ...dataKategori.map((item) => Column(
                      children: [
                        ListTile(
                          title: Text(item['nama']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.amber[200],
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(formatRupiah(item['jumlah'])),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailPage(
                                  kategori: item['nama'],
                                  jumlah: item['jumlah'],
                                  kuantitas: item['kuantitas'],
                                ),
                              ),
                            );
                          },
                        ),
                        const Divider(),
                      ],
                    )).toList(),
                    const SizedBox(height: 10,),
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[100],
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Jumlah Terjual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(jumlahTerjual.toString(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 5,),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(formatRupiah(total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 5,),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Rata-rata', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Text(formatRupiah(rataRata), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 5,),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80), 
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'share',
            backgroundColor: Colors.lightBlue,
            onPressed: () {},
            child: const Icon(Icons.share),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'download',
            child: const Icon(Icons.download),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class DetailPage extends StatelessWidget {
  final String kategori;
  final int jumlah;
  final int kuantitas;

  const DetailPage({
    super.key,
    required this.kategori,
    required this.jumlah,
    required this.kuantitas,
  });

  String formatRupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    final rataRata = kuantitas == 0 ? 0 : jumlah / kuantitas;

    return Scaffold(
      appBar: AppBar(
        title: Text(kategori),
        centerTitle: true,
      ),
      body: Column(
        children: [
          ListTile(
            title: const Text('Kuantitas'),
            trailing: Text(kuantitas.toString()),
          ),
          const Divider(height: 5),
          ListTile(
            title: const Text('Jumlah', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text(
              formatRupiah(jumlah),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 5),
          ListTile(
            title: const Text('Rata-rata'),
            trailing: Text(rataRata.toStringAsFixed(2).replaceAll('.', ',')),
          ),
          const Divider(height: 5),
        ],
      ),
    );
  }
}
