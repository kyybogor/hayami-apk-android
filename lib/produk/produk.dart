import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:hayami_app/Dashboard/dashboardscreen.dart';
import 'package:hayami_app/produk/produkdetail.dart';

class ProdukPage extends StatefulWidget {
  const ProdukPage({super.key});

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  bool _showChart = true;
  List<Map<String, dynamic>> _produkList = [];
  int totalProduk = 0;
  int produkHampirHabis = 0;
  int produkHabis = 0;

  @override
  void initState() {
    super.initState();
    _fetchProduk();
  }

  String formatRupiah(dynamic amount) {
    try {
      final value = double.tryParse(amount.toString()) ?? 0;
      return NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(value);
    } catch (e) {
      return 'Rp 0';
    }
  }

  Future<void> _fetchProduk() async {
    final url = Uri.parse('http://hayami.id/apps/erp/api-android/api/master_produk.php');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'];
          setState(() {
            _produkList = data.map((e) => Map<String, dynamic>.from(e)).toList();
            _calculateProduk();
          });
        } else {
          print('Status not success');
        }
      } else {
        print('Failed to load produk');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _calculateProduk() {
    int total = 0;
    int hampirHabis = 0;
    int habis = 0;

    for (var produk in _produkList) {
      int stok = int.tryParse(produk['stok'].toString()) ?? 0;
      total++;

      if (stok == 0) {
        habis++;
      } else if (stok < 10) {
        hampirHabis++;
      }
    }

    setState(() {
      totalProduk = total;
      produkHampirHabis = hampirHabis;
      produkHabis = habis;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      drawer: const KledoDrawer(),
      appBar: AppBar(
        title: const Text('Produk'),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Tambah Produk
        },
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Cari',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),

          // Status Cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildStatusCard('Produk Tersedia', (totalProduk - produkHampirHabis - produkHabis).toString(), Colors.green),
                _buildStatusCard('Produk Hampir Habis', produkHampirHabis.toString(), Colors.orange),
                _buildStatusCard('Produk Habis', produkHabis.toString(), Colors.red),
                _buildStatusCard('Total Produk', totalProduk.toString(), Colors.blue),
              ],
            ),
          ),
          const SizedBox(height: 16),

          InkWell(
            onTap: () {
              setState(() {
                _showChart = !_showChart;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _showChart ? 'Sembunyikan' : 'Lihat Selengkapnya',
                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
                Icon(_showChart ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (_showChart)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChartPlaceholder('Pergerakan Stok', screenWidth),
                  _buildChartPlaceholder('Jenis Produk', screenWidth),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // List Produk
          ..._produkList.map((produk) => _buildProductItem(produk)).toList(),
        ],
      ),
    );
  }

  Widget _buildProductItem(Map<String, dynamic> produk) {
    return ListTile(
      title: Text(produk['produk_name'] ?? ''),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${formatRupiah(produk['hpp'])} → ${formatRupiah(produk['harga_jual'])}'),
          Text('${produk['hpp_value']} (HPP)'),
          Text('${produk['produk_code']}', style: const TextStyle(fontSize: 12)),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: produk),
          ),
        );
      },
    );
  }

  Widget _buildStatusCard(String title, String count, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth * 0.65,
      height: 80,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  count,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartPlaceholder(String title, double width) {
    return Container(
      width: width - 90,
      height: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}