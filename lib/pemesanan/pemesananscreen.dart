import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hayami_app/Penjualan/penjualanscreen.dart';
import 'package:hayami_app/pemesanan/dikirimsebagian.dart';
import 'package:hayami_app/pemesanan/jatuhtemposcreen.dart';
import 'package:hayami_app/pemesanan/openscreen.dart';
import 'package:hayami_app/pemesanan/selesaiscreen.dart';
import 'package:hayami_app/pemesanan/tambahpesanan.dart';
import 'package:hayami_app/pemesanan/transaksiberulangscreen.dart';
import 'package:http/http.dart' as http;

// Import halaman-halaman

class PemesananPage extends StatefulWidget {
  const PemesananPage({super.key});

  @override
  State<PemesananPage> createState() => _PemesananPageState();
}

class _PemesananPageState extends State<PemesananPage> {
  Map<String, int> pemesananCounts = {
    "Open": 0,
    "Dikirim Sebagian": 0,
    "Selesai": 0,
    "Jatuh Tempo": 0,
    "Transaksi Berulang": 0,
  };

  bool isLoading = true;

  final Map<String, Color> statusColors = {
    "Open": Colors.pink,
    "Dikirim Sebagian": Colors.amber,
    "Selesai": Colors.green,
    "Jatuh Tempo": Colors.black,
    "Transaksi Berulang": Colors.blue,
  };

  final Map<String, String> nilaiData = {
    // "Selesai": 'https://gmp-system.com/api-hayami/daftar_tagihan.php?sts=1',
  };

  @override
  void initState() {
    super.initState();
    fetchpemesananCounts();
  }

  Future<void> fetchpemesananCounts() async {
    setState(() {
      isLoading = true;
    });

    Map<String, int> newCounts = {
      for (var key in pemesananCounts.keys) key: 0,
    };

    try {
      for (var entry in nilaiData.entries) {
        final response = await http.get(Uri.parse(entry.value));
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          newCounts[entry.key] = data.length;
        }
      }

      setState(() {
        pemesananCounts = newCounts;
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget? getTargetPage(String label) {
    switch (label) {
      case "Open":
        return const Open();
      case "Dikirim Sebagian":
        return const DikirimSebagian();
      case "Selesai":
        return const SelesaiPemesanan();
      case "Jatuh Tempo":
        return const JatuhTempoPemesanan();
      case "Transaksi Berulang":
        return TransaksiBerulangPemesanan();
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusList = pemesananCounts.keys.toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text("Pemesanan", style: TextStyle(color: Colors.blue)),
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
                      final count = pemesananCounts[label]!;
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
                            trailing: Text("$count"),
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
      floatingActionButton: FloatingActionButton(
  backgroundColor: Colors.blue,
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Tambahpesanan()),
    );
  },
  child: const Icon(Icons.add),
),
    );
  }
}
