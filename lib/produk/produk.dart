import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:hayami_app/Dashboard/dashboardscreen.dart';
import 'package:hayami_app/produk/produkdetail.dart';

// Fungsi untuk memperbaiki path gambar agar URL valid
// Ubah fungsi cleanImageUrl agar benar-benar valid URL
String cleanImageUrl(String path) {
  if (path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  // Perbaikan path: buang backslash dan tambah https://
  return 'https://hayami.id/apps/erp/api-android/${path.replaceAll('\\', '/')}';
}

class ProdukPage extends StatefulWidget {
  const ProdukPage({super.key});

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  bool _showChart = true;
  List<List<Map<String, dynamic>>> _produkGroupedList = [];
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
    final url = Uri.parse(
        'https://hayami.id/apps/erp/api-android/api/master_produk.php');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse.containsKey('all_product')) {
          final List<dynamic> data = jsonResponse['all_product'];

          setState(() {
            _produkGroupedList = [];
            for (int i = 0; i < data.length; i += 4) {
              final group = data.skip(i).take(4).map((e) {
                print('Image path raw: ${e['img']}');
                print('Image URL cleaned: ${cleanImageUrl(e['img'] ?? '')}');
                return Map<String, dynamic>.from(e);
              }).toList();
              _produkGroupedList.add(group);
            }

            _calculateProduk(data);
          });
        } else {
          print('Key "all_product" tidak ditemukan');
        }
      } else {
        print('Gagal load produk: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  void _calculateProduk(List<dynamic> data) {
    int total = 0;
    int hampirHabis = 0;
    int habis = 0;

    for (var produk in data) {
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
        onPressed: () {},
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
            child: Row(
              children: [
                _buildStatusCard(
                    'Produk Tersedia',
                    (totalProduk - produkHampirHabis - produkHabis).toString(),
                    Colors.green),
                _buildStatusCard('Produk Hampir Habis',
                    produkHampirHabis.toString(), Colors.orange),
                _buildStatusCard(
                    'Produk Habis', produkHabis.toString(), Colors.red),
                _buildStatusCard(
                    'Total Produk', totalProduk.toString(), Colors.blue),
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
                  style: const TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold),
                ),
                Icon(_showChart ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (_showChart)
            ..._produkGroupedList.map((groupProduk) {
              final ScrollController _scrollController = ScrollController();
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  height: 180,
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    thickness: 6,
                    radius: const Radius.circular(10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _scrollController,
                      child: Row(
                        children: groupProduk.map((produk) {
                          return _buildChartPlaceholder(
                            produk['sku'] ?? '',
                            screenWidth,
                            produk['img'] ?? '',
                            produk['harga'] ?? '0',
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
        ],
      ),
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
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartPlaceholder(
      String title, double screenWidth, String imagePath, String harga) {
    final imgUrl = cleanImageUrl(imagePath);
    print('Final Image URL: $imgUrl');

    return Container(
      width: screenWidth * 0.35,
      height: 150,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(8),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imgUrl.isEmpty
                  ? Container(
                      color: Colors.grey.shade300,
                      width: double.infinity,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : Image.network(
                      imgUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade300,
                        width: double.infinity,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            formatRupiah(harga),
            style: const TextStyle(color: Colors.green),
          ),
        ],
      ),
    );
  }
}
