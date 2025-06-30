import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PerubahanModalPage extends StatefulWidget {
  @override
  _PerubahanModalPageState createState() => _PerubahanModalPageState();
}

class _PerubahanModalPageState extends State<PerubahanModalPage> {
  List<Map<String, dynamic>> data = [];
  bool isLoading = true;

  Future<void> fetchData() async {
    final response = await http.get(Uri.parse('http://192.168.1.9/hiyami/perubahanmodal.php'));

    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);

      setState(() {
        data = responseData.map((item) => item as Map<String, dynamic>).toList();
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  Map<String, int> hitungTotal() {
    Map<String, int> total = {
      "Awal": 0,
      "Debit": 0,
      "Kredit": 0,
      "Akhir": 0,
    };

    for (var item in data) {
      total["Awal"] = total["Awal"]! + _toInt(item["awal"]);
      total["Debit"] = total["Debit"]! + _toInt(item["debit"]);
      total["Kredit"] = total["Kredit"]! + _toInt(item["kredit"]);
      total["Akhir"] = total["Akhir"]! + _toInt(item["akhir"]);
    }

    return total;
  }

  int hitungPerubahanBersih() {
    int perubahanBersih = 0;
    for (var item in data) {
      perubahanBersih += _toInt(item['awal']);
      perubahanBersih += _toInt(item['debit']);
      perubahanBersih += _toInt(item['kredit']);
      perubahanBersih += _toInt(item['akhir']);
    }
    return perubahanBersih;
  }

  Widget _buildInfoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value.toString()),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final total = hitungTotal();
    final perubahanBersih = hitungPerubahanBersih();

    return Scaffold(
      appBar: AppBar(
        title: const Center(
          child: Text(
            "Perubahan Modal",
            style: TextStyle(fontWeight: FontWeight.bold,),
          ),
        ),
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 80.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: data.length,
                      itemBuilder: (context, index) {
                        final item = data[index];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              color: Colors.grey[300],
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                              child: Text(
                                item['section'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Column(
                                children: [
                                  _buildInfoRow("Awal", item['awal']),
                                  const Divider(),
                                  _buildInfoRow("Debit", item['debit']),
                                  const Divider(),
                                  _buildInfoRow("Kredit", item['kredit']),
                                  const Divider(),
                                  _buildInfoRow("Akhir", item['akhir']),
                                ],
                              ),
                            ),
                            const Divider(thickness: 1.5),
                          ],
                        );
                      },
                    ),
                    // Bagian Total
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            color: Colors.grey[300],
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                            child: const Text(
                              "Total",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Column(
                              children: [
                                _buildInfoRow("Total Awal", total['Awal']),
                                const Divider(),
                                _buildInfoRow("Total Debit", total['Debit']),
                                const Divider(),
                                _buildInfoRow("Total Kredit", total['Kredit']),
                                const Divider(),
                                _buildInfoRow("Total Akhir", total['Akhir']),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Bagian Perubahan Bersih
                          Container(
                            width: double.infinity,
                            color: Colors.grey[300],
                            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                            child: const Text(
                              "Perubahan Bersih",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Column(
                              children: [
                                _buildInfoRow("Perubahan Bersih", perubahanBersih),
                                const Divider(),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'share',
            mini: true,
            onPressed: () {},
            child: const Icon(Icons.share),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'download',
            onPressed: () {},
            child: const Icon(Icons.download),
          ),
        ],
      ),
    );
  }
}
