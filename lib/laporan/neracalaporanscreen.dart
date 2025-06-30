import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Import intl untuk format tanggal

// ApiService untuk mengambil data dari API
class ApiService {
  final String apiUrl = "http://192.168.1.9/hiyami/neraca.php"; // URL API

  Future<List<Map<String, dynamic>>> fetchNeracaData() async {
    try {
      final response = await http.get(Uri.parse(apiUrl));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        throw Exception('Gagal mengambil data');
      }
    } catch (e) {
      throw Exception('Terjadi kesalahan: $e');
    }
  }
}

// Halaman Neraca untuk menampilkan data
class NeracaPage extends StatefulWidget {
  @override
  _NeracaPageState createState() => _NeracaPageState();
}

class _NeracaPageState extends State<NeracaPage> {
  final TextStyle labelStyle = const TextStyle(fontSize: 16);
  final TextStyle valueStyle = const TextStyle(fontSize: 16, color: Colors.blue);
  final TextStyle boldStyle = const TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

  late Future<List<Map<String, dynamic>>> _neracaData;

  @override
  void initState() {
    super.initState();
    _neracaData = ApiService().fetchNeracaData(); // Ambil data dari API
  }

  // Widget untuk menampilkan header setiap section
  Widget buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      color: Colors.grey[300],
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  Widget buildItem(String label, String value, {bool isBold = false}) {
    Color valueColor = (label == "Total Assets") ? Colors.black : Colors.blue;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: isBold ? boldStyle : labelStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            flex: 1,
            child: Text(
              value,
              style: isBold ? boldStyle : valueStyle.copyWith(color: valueColor), // Mengubah warna teks
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          ),
        ],
      ),
    );
  }

  String getFormattedDate() {
    final DateTime now = DateTime.now();
    final DateFormat formatter = DateFormat('dd MMMM yyyy');
    return formatter.format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.blueAccent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Neraca", style: TextStyle(color: Colors.blueAccent, fontSize: 20),),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(  // FutureBuilder to fetch data from API
        future: _neracaData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("Tidak ada data"));
          }

          var data = snapshot.data!;

          // Mengelompokkan data berdasarkan section
          Map<String, List<Map<String, dynamic>>> groupedData = {};
          for (var item in data) {
            if (!groupedData.containsKey(item['section'])) {
              groupedData[item['section']] = [];
            }
            groupedData[item['section']]!.add(item);
          }

          return ListView(
            children: groupedData.keys.map((section) {
              List<Map<String, dynamic>> sectionData = groupedData[section]!;

              // Jika section adalah "Total", hanya tampilkan Total Assets tanpa header
              if (section == "Total") {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: sectionData.map((item) {
                    // Menampilkan hanya Total Assets
                    return buildItem(item['label'], item['value']);
                  }).toList(),
                );
              }

              // Menambahkan tanggal di atas header Liabilitas Jangka Pendek dan Kas & Bank
              if (section == "Liabilitas Jangka Pendek" || section == "Kas & Bank") {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tanggal kecil di atas header
                    Container(
                      padding: const EdgeInsets.only(left: 12, bottom: 0, top: 12), // Mengatur jarak
                      child: Text(
                        getFormattedDate(),  // Menampilkan tanggal
                        style: TextStyle(fontSize: 12, color: Colors.black),  // Ukuran font lebih kecil
                      ),
                    ),
                    buildSectionHeader(section),  // Menampilkan header section
                    ...sectionData.map((item) {
                      return buildItem(item['label'], item['value']);
                    }).toList(),
                  ],
                );
              }

              // Menampilkan header untuk section lain selain "Total"
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionHeader(section),  // Menampilkan header section
                  ...sectionData.map((item) {
                    return buildItem(item['label'], item['value']);
                  }).toList(),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: NeracaPage(),
  ));
}
