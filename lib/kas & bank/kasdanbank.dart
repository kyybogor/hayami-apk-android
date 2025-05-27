import 'package:flutter/material.dart';
import 'package:hayami_app/kas%20&%20bank/kasscreen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hayami_app/Dashboard/dashboardscreen.dart';

class KasDanBank extends StatefulWidget {
  const KasDanBank({super.key});

  @override
  State<KasDanBank> createState() => _KasDanBankState();
}

class _KasDanBankState extends State<KasDanBank> {
  List<dynamic> kasData = [];
  bool isLoading = true;

  final String apiUrl = "http://hayami.id/apps/erp/api-android/api/kasdanbank.php";

  @override
  void initState() {
    super.initState();
    fetchKasData();
  }

  Future<void> fetchKasData() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          kasData = data;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load data");
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Color getWarnaByNama(String nama) {
    final lowerNama = nama.toLowerCase();
    if (lowerNama.contains("kas")) {
      return Colors.red;
    } else if (lowerNama.contains("bca") ||
        lowerNama.contains("mandiri") ||
        lowerNama.contains("bri") ||
        lowerNama.contains("bank")) {
      return Colors.pink;
    } else if (lowerNama.contains("giro")) {
      return Colors.purple;
    } else {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const KledoDrawer(),
      appBar: AppBar(
        title: const Text('Kas & Bank'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: kasData.length,
                    itemBuilder: (context, index) {
                      final data = kasData[index];
                      final nama = data['nama'] ?? '';
                      final kode = data['kode'] ?? '';
                      final nominal =
                          double.tryParse(data['nominal'].toString()) ?? 0;
                      final warna = getWarnaByNama(nama);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: warna,
                        ),
                        title: Text(nama),
                        subtitle: Text(kode),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 6,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color: warna.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                nominal.toStringAsFixed(0).replaceAllMapped(
                                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                      (Match m) => '${m[1]}.',
                                    ),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
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
                              builder: (_) => Kasscreen(judul: nama),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
