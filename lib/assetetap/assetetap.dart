import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:hayami_app/assetetap/detailasset.dart';
import 'package:hayami_app/Dashboard/dashboardscreen.dart' show KledoDrawer;

class AssetPage extends StatefulWidget {
  const AssetPage({super.key});

  @override
  State<AssetPage> createState() => _AssetPageState();
}

class _AssetPageState extends State<AssetPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<Map<String, dynamic>> draftAssets = [];
  final List<Map<String, dynamic>> registeredAssets = [];
  final List<Map<String, dynamic>> soldAssets = [];

  List<Map<String, dynamic>> allAssets = [];
  List<Map<String, dynamic>> filteredAssets = [];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchAssets();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      draftAssets.retainWhere((a) => a['name'].toLowerCase().contains(query));
      registeredAssets.retainWhere((a) => a['name'].toLowerCase().contains(query));
      soldAssets.retainWhere((a) => a['name'].toLowerCase().contains(query));
    });
  }

  String formatRupiah(dynamic amount) {
    try {
      final value = double.tryParse(amount.toString()) ?? 0;
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
          .format(value);
    } catch (e) {
      return 'Rp 0';
    }
  }

  Future<void> fetchAssets() async {
    final url = Uri.parse('http://192.168.1.9/Hiyami/asset.php'); // Ganti dengan URL kamu

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        draftAssets.clear();
        registeredAssets.clear();
        soldAssets.clear();

        for (var asset in data) {
          final assetMap = {
            'name': asset['name'],
            'code': asset['code'],
            'date': asset['date'],
            'amount': asset['amount'],
            'akun': asset['akun'],
            'akun_akumulasi': asset['akun_akumulasi'],
            'akun_penyusutan': asset['akun_penyusutan'],
            'metode': asset['metode'],
            'masa_manfaat': asset['masa_manfaat'],
            'tanggal_pelepasan': asset['tanggal_pelepasan'],
            'batas_biaya': asset['batas_biaya'],
          };

          switch (asset['status']) {
            case 'draft':
              draftAssets.add(assetMap);
              break;
            case 'registered':
              registeredAssets.add(assetMap);
              break;
            case 'sold':
              soldAssets.add(assetMap);
              break;
          }
        }
        setState(() {});
      } else {
        print('Failed to load assets: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Widget buildAssetList(List<Map<String, dynamic>> assets) {
    if (assets.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_late_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("Data tidak ditemukan", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: assets.length,
      itemBuilder: (context, index) {
        final asset = assets[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Text(asset['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(asset['code']),
                Text(asset['date']),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                formatRupiah(asset['amount']),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AssetDetailPage(asset: asset),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const KledoDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text('Aset Tetap'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.black,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black,
          tabs: const [
            Tab(text: 'DRAFT'),
            Tab(text: 'TERDAFTAR'),
            Tab(child: Column(children: [Text('TERJUAL/'), Text('DILEPASKAN')])),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                buildAssetList(draftAssets),
                buildAssetList(registeredAssets),
                buildAssetList(soldAssets),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.amber,
        onPressed: () {
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}