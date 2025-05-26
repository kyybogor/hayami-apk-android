import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// Model Produk Penjualan
class ProdukPenjualan {
  final String name;
  final String sku;
  final String harga;
  final int jumlahTerjual;
  final String total;
  final String rataRata;

  ProdukPenjualan({
    required this.name,
    required this.sku,
    required this.harga,
    required this.jumlahTerjual,
    required this.total,
    required this.rataRata,
  });

factory ProdukPenjualan.fromJson(Map<String, dynamic> json) {
  final hargaJual = double.tryParse(json['harga_jual'] ?? '0') ?? 0;
  final penjualan = int.tryParse(json['penjualan'] ?? '0') ?? 0;
  final nominalPenjualan = double.tryParse(json['nominal_penjualan'] ?? '0') ?? 0;
  final rata2 = penjualan != 0 ? (nominalPenjualan / penjualan) : 0;

  return ProdukPenjualan(
    name: json['produk_name'] ?? '',
    sku: json['produk_code'] ?? '',
    harga: hargaJual.toStringAsFixed(0),
    jumlahTerjual: penjualan,
    total: nominalPenjualan.toStringAsFixed(0),
    rataRata: rata2.toStringAsFixed(0),
  );
}

}

// Halaman Utama
class PenjualanPerProdukPage extends StatefulWidget {
  const PenjualanPerProdukPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PenjualanPerProdukPageState createState() => _PenjualanPerProdukPageState();
}

class _PenjualanPerProdukPageState extends State<PenjualanPerProdukPage> {
  List<ProdukPenjualan> dataPenjualan = [];
  bool isLoading = true;

  int get totalTerjual =>
      dataPenjualan.fold(0, (sum, item) => sum + item.jumlahTerjual);

  double get totalNominal => dataPenjualan.fold(
      0.0, (sum, item) => sum + double.tryParse(item.total)!.toDouble());

  double get rataRataGlobal =>
      totalTerjual == 0 ? 0 : totalNominal / totalTerjual;

  String formatRupiah(dynamic value) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return formatter.format(double.tryParse(value.toString()) ?? 0);
  }

  @override
  void initState() {
    super.initState();
    fetchProduk();
  }

  Future<void> fetchProduk() async {
    final response = await http.get(Uri.parse(
        'http://192.168.1.8/hiyami/produk.php')); // Ganti dengan URL API kamu

    if (response.statusCode == 200) {
      final response =
          await http.get(Uri.parse('http://192.168.1.8/hiyami/produk.php'));

      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(response.body);
        final List<dynamic> jsonData = jsonMap['data'] ?? [];

        setState(() {
          dataPenjualan =
              jsonData.map((item) => ProdukPenjualan.fromJson(item)).toList();
          isLoading = false;
        });
      }

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        foregroundColor: Colors.blueAccent,
        title: const Text("Penjualan per Produk", style: TextStyle(color: Colors.blueAccent, fontSize: 20),),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: TextField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Cari produk...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                  ),
                ),
                Expanded(
                    child: ListView.separated(
                  itemCount: dataPenjualan.length + 1,
                  separatorBuilder: (context, index) => const Divider(
                    height: 5,
                  ),
                  itemBuilder: (context, index) {
                    if (index < dataPenjualan.length) {
                      final item = dataPenjualan[index];
                      return ListTile(
                        title: Text(item.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber[700],
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                formatRupiah(item.total),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailProdukPage(produk: item),
                            ),
                          );
                        },
                      );
                    } else {
                      // Statistik di akhir list
                      return Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.grey[200],
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Statistik Penjualan',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            buildStatRow(
                                "Total Jumlah Terjual", "$totalTerjual"),
                            buildStatRow("Total Nominal Penjualan",
                                formatRupiah(totalNominal)),
                            buildStatRow("Rata-rata Penjualan",
                                formatRupiah(rataRataGlobal)),
                          ],
                        ),
                      );
                    }
                  },
                )),
              ],
            ),
    );
  }

  Widget buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

// Halaman Detail Produk
class DetailProdukPage extends StatelessWidget {
  final ProdukPenjualan produk;

  const DetailProdukPage({super.key, required this.produk});

  String formatRupiah(dynamic value) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return formatter.format(double.tryParse(value.toString()) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(produk.name),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.grey[300],
            padding: const EdgeInsets.all(12.0),
            child: const Text(
              'Penjualan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          buildRow('Kode/SKU', produk.sku),
          const Divider(
            height: 5,
          ),
          buildRow('Harga Jual', formatRupiah(produk.harga)),
          const Divider(
            height: 5,
          ),
          buildRow('Jumlah Terjual', '${produk.jumlahTerjual}'),
          const Divider(
            height: 5,
          ),
          buildRow('Total Penjualan', formatRupiah(produk.total), bold: true),
          const Divider(
            height: 5,
          ),
          buildRow('Rata-rata per Produk', formatRupiah(produk.rataRata)),
        ],
      ),
    );
  }

  Widget buildRow(String label, String value, {bool bold = false}) {
    return ListTile(
      title: Text(label),
      trailing: Text(
        value,
        style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
      ),
    );
  }
}
