import 'package:flutter/material.dart';
import 'package:hayami_app/assetetap/detailasset.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Aset {
  final String id;
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
  final String? akun;

  Aset({
    required this.id,
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
    this.akun,
  });

  factory Aset.fromJson(Map<String, dynamic> json) {
    return Aset(
      id: json['aset_id'],
      name: json['name'],
      code: json['code'],
      date: json['date'],
      amount: json['amount'],
      status: json['status'],
      akun: json['akun'],
      akunAkumulasi: json['akun_akumulasi'],
      akunPenyusutan: json['akun_penyusutan'],
      metode: json['metode'],
      masaManfaat: json['masa_manfaat'],
      tanggalPelepasan: json['tanggal_pelepasan'],
      batasBiaya: json['batas_biaya'],
    );
  }
}

class AsetRingkasanPage extends StatefulWidget {
  const AsetRingkasanPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AsetRingkasanPageState createState() => _AsetRingkasanPageState();
}

class _AsetRingkasanPageState extends State<AsetRingkasanPage> {
  List<Aset> asetList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAsetData();
  }

  Future<void> fetchAsetData() async {
    final url = Uri.parse('http://192.168.1.9/hiyami/asset.php');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          asetList = jsonData.map((e) => Aset.fromJson(e)).toList();
          isLoading = false;
        });
      } else {
        throw Exception("Gagal memuat data");
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error: $e");
    }
  }

  int calculateTotal() {
    return asetList.fold(
        0, (sum, item) => sum + double.parse(item.amount).toInt());
  }

  String formatCurrency(int value) {
    return value.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  }

  @override
  Widget build(BuildContext context) {
    int total = calculateTotal();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Ringkasan Aset Tetap", style: TextStyle(color: Colors.blueAccent, fontSize: 20),),
        foregroundColor: Colors.blueAccent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: const [Icon(Icons.filter_list)],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Aset Tetap",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: asetList.length + 1,
                    separatorBuilder: (context, index) =>
                        index < asetList.length - 1 ? const Divider() : const SizedBox(),
                    itemBuilder: (context, index) {
                      if (index < asetList.length) {
                        final item = asetList[index];
                        return ListTile(
                          title: Text(item.name),
                          subtitle: Text(item.code),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.yellow[700],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              formatCurrency(double.parse(item.amount).toInt()),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => DetailAsetPage(data: item),
                              ),
                            );
                          },
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Total",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text(
                                formatCurrency(total),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchAsetData,
        child: const Icon(Icons.download),
      ),
    );
  }
}

class DetailAsetPage extends StatelessWidget {
  final Aset data;

  const DetailAsetPage({super.key, required this.data});

  String formatNumber(num value) {
    return value.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );
  }

  @override
  Widget build(BuildContext context) {
    final double harga = double.tryParse(data.amount) ?? 0;
    final double penyusutan = double.tryParse(data.batasBiaya ?? '0') ?? 0;
    final double nilaiBuku = harga - penyusutan;

    return Scaffold(
      appBar: AppBar(
        title: Text(data.name),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            InfoRow(label: "Nomor", value: data.code),
            InfoRow(label: "Tanggal", value: data.date),
            InfoRow(label: "Harga", value: formatNumber(harga)),
            InfoRow(label: "Penyusutan", value: formatNumber(penyusutan)),
            const Divider(height: 32),
            InfoRow(
                label: "Nilai Buku",
                value: formatNumber(nilaiBuku),
                bold: true),
            const SizedBox(height: 20),
            ListTile(
              tileColor: Colors.grey[200],
              title: const Text("Lihat Detail"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AssetDetailPage(
                      asset: {
                        'name': data.name,
                        'code': data.code,
                        'date': data.date,
                        'amount': data.amount,
                        'akun': data.akun,
                        'akun_akumulasi': data.akunAkumulasi,
                        'akun_penyusutan': data.akunPenyusutan,
                        'metode': data.metode,
                        'masa_manfaat': data.masaManfaat,
                        'tanggal_pelepasan': data.tanggalPelepasan,
                        'batas_biaya': data.batasBiaya,
                      },
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const InfoRow({super.key, 
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null,
          ),
        ],
      ),
    );
  }
}
