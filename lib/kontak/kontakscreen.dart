import 'package:flutter/material.dart';
import 'package:hayami_app/kontak/detailkontak.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hayami_app/Dashboard/dashboardscreen.dart';

class KontakScreen extends StatefulWidget {
  const KontakScreen({super.key});

  @override
  State<KontakScreen> createState() => _KontakScreenState();
}

class _KontakScreenState extends State<KontakScreen> {
  List<dynamic> allContacts = [];
  String searchQuery = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchContacts();
  }

  Future<void> fetchContacts() async {
    try {
      final response = await http.get(
        Uri.parse("http://hayami.id/apps/erp/api-android/api/kontak.php"),
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> data = jsonData['customer_data'] ?? [];

        setState(() {
          allContacts = data;
          isLoading = false;
        });
      } else {
        debugPrint('Gagal mengambil kontak. Status: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Error: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filtered = allContacts
        .where((item) => item['nm_customer']
            .toLowerCase()
            .contains(searchQuery.toLowerCase()))
        .toList()
      ..sort((a, b) => a['nm_customer'].compareTo(b['nm_customer']));

    Map<String, List<dynamic>> grouped = {};
    for (var contact in filtered) {
      String huruf = contact['nm_customer'][0].toUpperCase();
      grouped.putIfAbsent(huruf, () => []).add(contact);
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Kontak"),
      ),
      drawer: const KledoDrawer(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Cari nama...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (value) =>
                  setState(() => searchQuery = value),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : grouped.isEmpty
                    ? const Center(child: Text("Tidak ada kontak ditemukan."))
                    : ListView(
                        children: grouped.entries.expand((entry) {
                          return [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              color: Colors.grey[300],
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            ...entry.value.map((item) {
                              final nama = item['nm_customer'] ?? '';
                              final id = item['id_customer'] ?? '';
                              final inisial = nama.isNotEmpty
                                  ? nama
                                      .substring(0, nama.length >= 2 ? 2 : 1)
                                      .toUpperCase()
                                  : '??';

                              return Column(
                                children: [
                                  ListTile(
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailKontakScreen(data: item),
      ),
    );
  },
  leading: CircleAvatar(
    backgroundColor:
        Colors.primaries[nama.codeUnitAt(0) % Colors.primaries.length],
    child: Text(inisial, style: const TextStyle(color: Colors.white)),
  ),
  title: Text(nama.isNotEmpty ? nama : 'Tanpa Nama'),
  subtitle: Text(id.isNotEmpty ? id : '-'),
  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
),
                                  const Divider(height: 1),
                                ],
                              );
                            }),
                          ];
                        }).toList(),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Tambahkan logika untuk tambah kontak jika diperlukan
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
