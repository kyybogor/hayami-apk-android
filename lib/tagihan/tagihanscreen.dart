import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Import halaman-halaman
import 'package:hayami_app/belumdibayar/belumdibayarscreen.dart';
import 'package:hayami_app/dibayarsebagian/dibayarsebagian.dart';
import 'package:hayami_app/lunas/lunas.dart';
import 'package:hayami_app/void/void.dart';
import 'package:hayami_app/penjualan/penjualanscreen.dart';

class TagihanPage extends StatefulWidget {
  const TagihanPage({super.key});

  @override
  State<TagihanPage> createState() => _TagihanPageState();
}

class _TagihanPageState extends State<TagihanPage> {
  Map<String, int> tagihanCounts = {
    "Belum Dibayar": 0,
    "Dibayar Sebagian": 0,
    "Lunas": 0,
    "Void": 0,
  };

  bool isLoading = true;

  final Map<String, Color> statusColors = {
    "Belum Dibayar": Colors.pink,
    "Dibayar Sebagian": Colors.amber,
    "Lunas": Colors.green,
    "Void": Colors.grey,
  };

  // Mapping status dari API ke kategori di app kamu
  final Map<String, String> statusMapping = {
    "Open": "Belum Dibayar",
    "Partial Paid": "Dibayar Sebagian",  
    "Paid": "Lunas",
    "Void": "Void",
  };

  @override
  void initState() {
    super.initState();
    fetchTagihanCounts();
  }

  Future<void> fetchTagihanCounts() async {
    setState(() {
      isLoading = true;
    });

    // Reset count
    Map<String, int> newCounts = {
      for (var key in tagihanCounts.keys) key: 0,
    };

    try {
      final response = await http.get(Uri.parse('https://hayami.id/apps/erp/api-android/api/gdo1.php'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        for (var item in data) {
          String statusApi = (item['status'] ?? '').toString();
          String stsVoid = (item['stsvoid'] ?? '0').toString();

          // Jika stsvoid = "1", anggap Void
          if (stsVoid == "1") {
            newCounts["Void"] = (newCounts["Void"] ?? 0) + 1;
            continue;
          }

          // Mapping status API ke status app
          if (statusMapping.containsKey(statusApi)) {
            String mappedStatus = statusMapping[statusApi]!;
            newCounts[mappedStatus] = (newCounts[mappedStatus] ?? 0) + 1;
          } else {
            // Jika status tidak dikenali, bisa diabaikan atau dimasukkan kategori lain
          }
        }

        setState(() {
          tagihanCounts = newCounts;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load data from API');
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget? getTargetPage(String label) {
    switch (label) {
      case "Belum Dibayar":
        return const BelumDibayar();
      case "Dibayar Sebagian":
        return const DibayarSebagian();
      case "Lunas":
        return const Lunas();
      case "Void":
        return const Void();
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusList = tagihanCounts.keys.toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Tagihan", style: TextStyle(color: Colors.blue)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Penjualanscreen()),
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
                      final count = tagihanCounts[label]!;
                      final color = statusColors[label] ?? Colors.grey;
                      final page = getTargetPage(label);

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
                            onTap: page != null
                                ? () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => page),
                                    );
                                  }
                                : null,
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
