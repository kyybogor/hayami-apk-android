import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:intl/intl.dart';

class DetilAsetTetapPage extends StatefulWidget {
  const DetilAsetTetapPage({super.key});

  @override
  State<DetilAsetTetapPage> createState() => _DetilAsetTetapPageState();
}

class _DetilAsetTetapPageState extends State<DetilAsetTetapPage> {
  List<Aset> daftarAset = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  String formatRupiah(String nominal) {
    // Menghapus semua karakter yang bukan angka, kecuali titik (.)
    String cleaned = nominal.replaceAll(RegExp(r'[^0-9.]'), '');

    // Jika ada lebih dari satu titik, ambil hanya bagian sebelum titik pertama
    if (cleaned.contains('.')) {
      final parts = cleaned.split('.');
      cleaned = parts[0]; // Ambil bagian sebelum titik
    }

    // Format menjadi mata uang Rupiah tanpa desimal
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    // Menggunakan tryParse untuk memastikan konversi ke integer
    return formatter.format(int.tryParse(cleaned) ?? 0);
  }

  Future<void> fetchData() async {
    final url = Uri.parse('http://192.168.1.9/hiyami/asset.php');
    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          daftarAset = jsonData.map((data) => Aset.fromJson(data)).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        debugPrint('Gagal memuat data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Detil Aset Tetap', style: TextStyle(color: Colors.blueAccent, fontSize: 20),),
        foregroundColor: Colors.blueAccent,
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.filter_alt_outlined),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 8),
                ...daftarAset.map(_buildAsetItem).toList(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Aksi tombol
        },
        child: const Icon(Icons.download),
      ),
    );
  }

  Widget _buildAsetItem(Aset aset) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.grey[300],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            '${aset.name} - ${aset.code}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(formatRupiah(aset.amount)),
            ],
          ),
        ),
      ],
    );
  }
}

class Aset {
  final String asetId;
  final String name;
  final String code;
  final String date;
  final String amount;
  final String status;
  final String? akunAkumulasi;
  final String? akunPenyusutan;
  final String? metode;
  final String? masaManfaat;
  final String? tanggalPelepasan;
  final String? batasBiaya;

  Aset({
    required this.asetId,
    required this.name,
    required this.code,
    required this.date,
    required this.amount,
    required this.status,
    this.akunAkumulasi,
    this.akunPenyusutan,
    this.metode,
    this.masaManfaat,
    this.tanggalPelepasan,
    this.batasBiaya,
  });

  factory Aset.fromJson(Map<String, dynamic> json) {
    return Aset(
      asetId: json['aset_id'],
      name: json['name'],
      code: json['code'],
      date: json['date'],
      amount: json['amount'],
      status: json['status'],
      akunAkumulasi: json['akun_akumulasi'],
      akunPenyusutan: json['akun_penyusutan'],
      metode: json['metode'],
      masaManfaat: json['masa_manfaat'],
      tanggalPelepasan: json['tanggal_pelepasan'],
      batasBiaya: json['batas_biaya'],
    );
  }
}
