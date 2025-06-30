import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ProfitabilitasProdukPage extends StatefulWidget {
  const ProfitabilitasProdukPage({super.key});

  @override
  _ProfitabilitasProdukPageState createState() => _ProfitabilitasProdukPageState();
}

class _ProfitabilitasProdukPageState extends State<ProfitabilitasProdukPage> {
  List<Produk> produkList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProduk();
  }

  Future<void> fetchProduk() async {
    final response = await http.get(Uri.parse('http://192.168.1.9/hiyami/produk.php'));

    if (response.statusCode == 200) {
      final jsonMap = jsonDecode(response.body);
      final List<dynamic> jsonData = jsonMap['data'] ?? [];

      setState(() {
        produkList = jsonData.map((item) => Produk.fromJson(item)).toList();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil data dari server')),
      );
    }
  }

  String formatRupiah(dynamic value) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(double.tryParse(value.toString()) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final totalPenjualan = produkList.fold<double>(
      0.0,
      (sum, p) => sum + (double.tryParse(p.nominalPenjualan) ?? 0),
    );

    final totalTerjual = produkList.fold<int>(
      0,
      (sum, p) => sum + (int.tryParse(p.penjualan) ?? 0),
    );

    final rataRata = totalTerjual == 0 ? 0.0 : totalPenjualan / totalTerjual;

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.blueAccent,
        title: const Text("Profitabilitas Produk", style: TextStyle(color: Colors.blueAccent, fontSize: 20),),
        centerTitle: true,
        leading: const BackButton(),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.filter_list),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: produkList.length + 1,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index < produkList.length) {
                  final produk = produkList[index];
                  return ListTile(
                    title: Text(produk.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber[700],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${produk.profitMargin}%',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailProdukPage(produk: produk),
                        ),
                      );
                    },
                  );
                } else {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey[100],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Statistik Penjualan', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        buildStatRow("Jumlah Terjual", "$totalTerjual"),
                        const Divider(height: 5),
                        buildStatRow("Total Penjualan", formatRupiah(totalPenjualan)),
                        const Divider(height: 5),
                        buildStatRow("Rata-rata", formatRupiah(rataRata)),
                      ],
                    ),
                  );
                }
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.download),
      ),
    );
  }

  Widget buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

class Produk {
  final String id;
  final String name;
  final String hargaJual;
  final String nominalPenjualan;
  final String penjualan;
  final String hpp;
  final String profitMargin;

  Produk({
    required this.id,
    required this.name,
    required this.hpp,
    required this.hargaJual,
    required this.nominalPenjualan,
    required this.penjualan,
    required this.profitMargin,
  });

  factory Produk.fromJson(Map<String, dynamic> json) {
    final hargaJual = double.tryParse(json['harga_jual'] ?? '0') ?? 0;
    final hpp = double.tryParse(json['hpp'] ?? '0') ?? 0;
    final penjualan = int.tryParse(json['penjualan'] ?? '0') ?? 0;
    final nominalPenjualan = double.tryParse(json['nominal_penjualan'] ?? '0') ?? 0;
    final totalHPP = hpp * penjualan;
    final totalProfit = nominalPenjualan - totalHPP;
    final profitMargin = (nominalPenjualan == 0) ? 0 : (totalProfit / nominalPenjualan * 100);

    return Produk(
      id: json['produk_id'] ?? '',
      name: json['produk_name'] ?? '',
      hpp: hpp.toStringAsFixed(0),
      hargaJual: hargaJual.toStringAsFixed(0),
      nominalPenjualan: nominalPenjualan.toStringAsFixed(0),
      penjualan: penjualan.toString(),
      profitMargin: profitMargin.toStringAsFixed(2),
    );
  }
}

class DetailProdukPage extends StatelessWidget {
  final Produk produk;

  const DetailProdukPage({super.key, required this.produk});

  String formatRupiah(String value) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(double.tryParse(value) ?? 0);
  }

  @override
  Widget build(BuildContext context) {
    final totalHPP = double.parse(produk.hpp) * int.parse(produk.penjualan);
    final totalProfit = double.parse(produk.nominalPenjualan) - totalHPP;
    final rataHargaJual = int.parse(produk.penjualan) == 0
        ? 0
        : double.parse(produk.nominalPenjualan) / int.parse(produk.penjualan);
    final hppPerUnit = double.parse(produk.hpp);

    return Scaffold(
      appBar: AppBar(
        title: Text(produk.name),
        leading: const BackButton(),
      ),
      body: ListView(
        children: [
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.all(12),
            child: const Text('Penjualan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          buildDetailRow("Total Penjualan", formatRupiah(produk.nominalPenjualan)),
          const Divider(height: 5),
          buildDetailRow("Total HPP", formatRupiah(totalHPP.toString())),
          const Divider(height: 5),
          buildDetailRow("Total Profit", formatRupiah(totalProfit.toString())),
          const Divider(height: 5),
          buildDetailRow("Profit Margin", "${produk.profitMargin}%"),
          const Divider(height: 5),
          buildDetailRow("Harga Jual Rata-rata", formatRupiah(rataHargaJual.toString())),
          const Divider(height: 5),
          buildDetailRow("HPP Per Unit", formatRupiah(hppPerUnit.toString())),
          const Divider(height: 5),
        ],
      ),
    );
  }

  Widget buildDetailRow(String label, String value) {
    return ListTile(
      title: Text(label),
      trailing: Text(value),
    );
  }
}
