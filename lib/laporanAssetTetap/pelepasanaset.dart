import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PelepasanAsetPage extends StatefulWidget {
  const PelepasanAsetPage({super.key});

  @override
  State<PelepasanAsetPage> createState() => _PelepasanAsetPageState();
}

class _PelepasanAsetPageState extends State<PelepasanAsetPage> {
  late Future<List<Map<String, dynamic>>> futureAssets;

  String formatRupiah(String nominal) {
    String cleaned = nominal.replaceAll(RegExp(r'[^0-9.]'), '');

    if (cleaned.contains('.')) {
      final parts = cleaned.split('.');
      cleaned = parts[0];
    }

    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return formatter.format(int.tryParse(cleaned) ?? 0);
  }

  Future<List<Map<String, dynamic>>> fetchSoldAssets() async {
    final response =
        await http.get(Uri.parse('http://192.168.1.9/hiyami/asset.php'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);

      // Filter hanya status "sold"
      return data
          .where((item) => item['status'] == 'sold')
          .map<Map<String, dynamic>>((item) => item as Map<String, dynamic>)
          .toList();
    } else {
      throw Exception('Gagal memuat data dari API');
    }
  }

  @override
  void initState() {
    super.initState();
    futureAssets = fetchSoldAssets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pelepasan Aset', style: TextStyle(color: Colors.blueAccent, fontSize: 20),),
        foregroundColor: Colors.blueAccent,
        centerTitle: true,
        leading: const BackButton(),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.filter_list),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: futureAssets,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text('Terjadi kesalahan: ${snapshot.error}'));
                } else if (snapshot.hasData && snapshot.data!.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.assignment, size: 80, color: Colors.grey),
                        SizedBox(height: 10),
                        Text('Data tidak ditemukan',
                            style: TextStyle(fontSize: 16)),
                      ],
                    ),
                  );
                } else {
                  final assets = snapshot.data!;
                  return ListView.builder(
                    itemCount: assets.length,
                    itemBuilder: (context, index) {
                      final asset = assets[index];
                      return ListTile(
                        title: Text('${asset['name']} - ${asset['code']}'),
                        subtitle:
                            Text('Tanggal: ${asset['tanggal_pelepasan']}'),
                        trailing: Text(
                          formatRupiah(asset['amount']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  );
                }
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.download),
      ),
    );
  }
}
