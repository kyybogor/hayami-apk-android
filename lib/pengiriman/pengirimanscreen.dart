import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hayami_app/Penjualan/penjualanscreen.dart';
import 'package:hayami_app/open/openscreen.dart';
import 'package:hayami_app/selesai/selesaiscreen.dart';

class PengirimanPage extends StatefulWidget {
  const PengirimanPage({super.key});

  @override
  State<PengirimanPage> createState() => _PengirimanPageState();
}

class _PengirimanPageState extends State<PengirimanPage> {
  Map<String, int> pengirimanCounts = {
    "Dispatched": 0,
    "Delivered": 0,
  };

  bool isLoading = true;

  final Map<String, Color> statusColors = {
    "Dispatched": Colors.pink,
    "Delivered": Colors.green,
  };

  @override
  void initState() {
    super.initState();
    fetchPengirimanData();
  }

  Future<void> fetchPengirimanData() async {
  setState(() {
    isLoading = true;
  });

  try {
    final response = await http.get(
      Uri.parse('https://hayami.id/apps/erp/api-android/api/daftar_delivery.php'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      int dispatchedCount = 0;
      int deliveredCount = 0;

      // Ambil bulan dan tahun sekarang
      final DateTime now = DateTime.now();
      final int currentMonth = now.month;
      final int currentYear = now.year;

      for (var item in data) {
        final String? tanggalStr = item["date"]; // ← GUNAKAN "date"
        if (tanggalStr == null || tanggalStr.isEmpty) continue;

        DateTime tanggal;
        try {
          tanggal = DateTime.parse(tanggalStr); // Format sudah cocok
        } catch (e) {
          continue; // Skip jika parsing gagal
        }

        // Filter hanya data bulan dan tahun yang sedang berjalan
        if (tanggal.month == currentMonth && tanggal.year == currentYear) {
          final resi = item["resi"]?.toString().trim();
          if (resi == null || resi.isEmpty) {
            dispatchedCount++;
          } else {
            deliveredCount++;
          }
        }
      }

      setState(() {
        pengirimanCounts = {
          "Dispatched": dispatchedCount,
          "Delivered": deliveredCount,
        };
        isLoading = false;
      });
    } else {
      throw Exception('Gagal mengambil data');
    }
  } catch (e) {
    print("Error: $e");
    setState(() {
      isLoading = false;
    });
  }
}


  @override
  Widget build(BuildContext context) {
    final statusList = pengirimanCounts.keys.toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.blue),
        title: const Text("Pengiriman", style: TextStyle(color: Colors.blue)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const Penjualanscreen()),
              (Route<dynamic> route) => false,
            );
          },
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Cari",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.all(10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: statusList.length,
                    itemBuilder: (context, index) {
                      final label = statusList[index];
                      final count = pengirimanCounts[label]!;
                      final color = statusColors[label] ?? Colors.grey;

                      return Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: color,
                              radius: 10,
                            ),
                            title: Text(label),
                            subtitle: Text("$count"),
                            trailing: const Icon(Icons.arrow_forward_ios,
                                size: 16, color: Colors.grey),
                            onTap: () {
                              if (label == "Dispatched") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const OpenPage()),
                                );
                              } else if (label == "Delivered") {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const SelesaiPage()),
                                );
                              }
                            },
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
