import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Import halaman-halaman tujuan
import 'package:hayami_app/biaya/belumdibayarbiaya.dart';
import 'package:hayami_app/biaya/dibayarsebagianbiaya.dart';
import 'package:hayami_app/biaya/jatuhtempobiaya.dart';
import 'package:hayami_app/biaya/lunasbiaya.dart';
import 'package:hayami_app/biaya/transaksiberulangbiaya.dart';
import 'package:hayami_app/Dashboard/dashboardscreen.dart';

class BiayaPage extends StatefulWidget {
  const BiayaPage({super.key});

  @override
  State<BiayaPage> createState() => _BiayaPageState();
}

class _BiayaPageState extends State<BiayaPage> {
  bool _showChart = true;
  bool isLoading = true;

  Map<String, dynamic> summaryData = {};

  Map<String, int> biayaCounts = {
    'Belum Dibayar': 0,
    'Dibayar Sebagian': 0,
    'Lunas': 0,
    'Jatuh Tempo': 0,
    'Transaksi Berulang': 0,
  };

  String _formatCurrency(num value) {
    return value.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  final Map<String, Color> kategoriColors = {
    'Belum Dibayar': Colors.pink,
    'Dibayar Sebagian': Colors.amber,
    'Lunas': Colors.green,
    'Jatuh Tempo': Colors.black,
    'Transaksi Berulang': Colors.blue,
  };

  final Map<String, String> statusEndpoints = {
    'Belum Dibayar':
        'https://gmp-system.com/api-hayami/daftar_tagihan.php?sts=1',
    'Dibayar Sebagian':
        'https://gmp-system.com/api-hayami/daftar_tagihan.php?sts=3',
    'Lunas': 'https://gmp-system.com/api-hayami/daftar_tagihan.php?sts=2',
    'Jatuh Tempo': 'https://gmp-system.com/api-hayami/daftar_tagihan.php?sts=4',
    'Transaksi Berulang':
        'https://gmp-system.com/api-hayami/daftar_tagihan.php?sts=5',
  };

  final Map<String, Widget> kategoriPages = {
    'Belum Dibayar': const BelumDibayarBiaya(),
    'Dibayar Sebagian': const DibayarSebagianBiaya(),
    'Lunas': const LunasBiaya(),
    'Jatuh Tempo': const JatuhTempoBiaya(),
    'Transaksi Berulang': const TransaksiBerulangBiaya(),
  };

  @override
  void initState() {
    super.initState();
    fetchBiayaCounts();
    fetchSummaryData();
  }

  Future<void> fetchSummaryData() async {
    final url = Uri.parse('http://192.168.1.9/Hiyami/infocard.php');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          summaryData = data;
        });
      } else {
        print("Gagal fetch summary data: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetchSummaryData: $e");
    }
  }

  Future<void> fetchBiayaCounts() async {
    setState(() {
      isLoading = true;
    });

    Map<String, int> newCounts = {
      for (var key in biayaCounts.keys) key: 0,
    };

    try {
      for (var entry in statusEndpoints.entries) {
        final response = await http.get(Uri.parse(entry.value));
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          newCounts[entry.key] = data.length;
        }
      }

      setState(() {
        biayaCounts = newCounts;
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      drawer: const KledoDrawer(),
      appBar: AppBar(
        title: const Text('Biaya'),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Action button pressed
        },
        child: const Icon(Icons.add),
      ),
      body: ListView(
        children: [
          // Search bar with padding
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Cari',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // Info cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildInfoCard(
                    'Bulan Ini',
                    _formatCurrency(
                        summaryData['total_bulan_ini']?['jumlah'] ?? 0),
                    Colors.amber,
                    '${summaryData['total_bulan_ini']?['jumlah_data'] ?? 0}',
                  ),
                  _buildInfoCard(
                    '30 Hari Lalu',
                    _formatCurrency(
                        summaryData['total_30_hari']?['jumlah'] ?? 0),
                    Colors.pink,
                    '${summaryData['total_30_hari']?['jumlah_data'] ?? 0}',
                  ),
                  _buildInfoCard(
                    'Belum Dibayar',
                    _formatCurrency(
                        summaryData['total_belum_dibayar']?['jumlah'] ?? 0),
                    Colors.orange,
                    '${summaryData['total_belum_dibayar']?['jumlah_data'] ?? 0}',
                  ),
                  _buildInfoCard(
                    'Jatuh Tempo',
                    _formatCurrency(
                        summaryData['total_dibayar_sebagian']?['jumlah'] ?? 0),
                    Colors.green,
                    '${summaryData['total_dibayar_sebagian']?['jumlah_data'] ?? 0}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Expand/Collapse Chart Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: InkWell(
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
          ),
          const SizedBox(height: 12),

          // Chart content
          if (_showChart)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(
                    2,
                    (index) => _buildChartCard(index + 1, screenWidth),
                  ),
                ),
              ),
            ),
          if (_showChart) const SizedBox(height: 16),

          // List kategori item + Divider full width
          ...List.generate(kategoriPages.keys.length, (index) {
            final label = kategoriPages.keys.elementAt(index);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildKategoriItem(
                  label,
                  kategoriColors[label] ?? Colors.grey,
                  '${biayaCounts[label]}',
                  kategoriPages[label],
                ),
                if (index < kategoriPages.keys.length - 1)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey,
                    indent: 0,
                    endIndent: 0,
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      String title, String amount, Color color, String count) {
    return Container(
      width: 220,
      height: 80,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
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
            width: 50,
            height: 50,
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                count,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(amount,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(int index, double width) {
    return Container(
      width: width - 100,
      height: 180,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          'Chart $index',
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }

  Widget _buildKategoriItem(
      String title, Color color, String count, Widget? page) {
    return InkWell(
      onTap: page != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => page),
              );
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color, radius: 8),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(count, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
