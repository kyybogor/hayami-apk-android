import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hayami_app/produk/produkdetail.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() => runApp(const MaterialApp(home: LabaRugiPage()));

// Fungsi global untuk format Rupiah
String formatRupiah(double nominal, {int decimalDigits = 0}) {
  final formatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: decimalDigits,
  );
  return formatter.format(nominal);
}

// Helper untuk convert String ke double aman
double parseToDouble(String value) {
  // Hapus titik atau koma yang biasanya pemisah ribuan, lalu parse
  final cleaned = value.replaceAll('.', '').replaceAll(',', '.');
  return double.tryParse(cleaned) ?? 0.0;
}

class LabaRugiPage extends StatefulWidget {
  const LabaRugiPage({super.key});

  @override
  _LabaRugiPageState createState() => _LabaRugiPageState();
}

class _LabaRugiPageState extends State<LabaRugiPage> {
  List<LabaRugiItem> items = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response =
        await http.get(Uri.parse('http://192.168.1.8/hiyami/labarugi.php'));

    if (response.statusCode == 200) {
      List jsonData = jsonDecode(response.body);
      setState(() {
        items = jsonData.map((e) => LabaRugiItem.fromJson(e)).toList();
        isLoading = false;
      });
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil data dari server')),
      );
    }
  }

  Widget? getPageByKode(String kode, LabaRugiItem item) {
    switch (kode) {
      default:
        return DetailLabaRugiPage(item: item);
    }
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle labelStyle = TextStyle(fontSize: 16);
    const TextStyle valueStyle = TextStyle(fontSize: 16, color: Colors.blue);
    const TextStyle boldStyle =
        TextStyle(fontSize: 16, fontWeight: FontWeight.bold);

    Widget buildItem(String label, String value,
        {bool isBold = false, LabaRugiItem? item}) {
      final textWidget = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: isBold ? boldStyle : labelStyle),
          ),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Text(
                  value,
                  style: isBold ? boldStyle : valueStyle,
                  textAlign: TextAlign.end,
                ),
              ),
            ),
          ),
        ],
      );

      return InkWell(
        onTap: (item != null && item.kode.isNotEmpty)
            ? () {
                final page = getPageByKode(item.kode, item);
                if (page != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => page),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Halaman belum tersedia')),
                  );
                }
              }
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),
          child: textWidget,
        ),
      );
    }

    Map<String, List<LabaRugiItem>> groupedItems = {};
    for (var item in items) {
      groupedItems.putIfAbsent(item.kategori, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.blueAccent,
        title: const Text(
          "Laba Rugi",
          style: TextStyle(color: Colors.blueAccent, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: groupedItems.entries.expand((entry) {
                final isLabaBersih =
                    entry.key.trim().toLowerCase() == 'laba bersih';

                return [
                  if (!isLabaBersih)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      color: Colors.grey[200],
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ...entry.value.map((item) => buildItem(
                        "${item.kode.isNotEmpty ? "(${item.kode}) " : ""}${item.deskripsi}",
                        formatRupiah(parseToDouble(item.nilai)),
                        isBold: item.kode.isEmpty,
                        item: item,
                      )),
                ];
              }).toList(),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "share",
            onPressed: () {},
            backgroundColor: Colors.blueAccent,
            child: const Icon(Icons.share),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "download",
            onPressed: () {},
            backgroundColor: Colors.blue,
            child: const Icon(Icons.download),
          ),
        ],
      ),
    );
  }
}

// === Model Data ===

class LabaRugiItem {
  final String kategori;
  final String kode;
  final String deskripsi;
  final String nilai;
  final String date;
  final List<LabaRugiDetail> detail;

  LabaRugiItem({
    required this.kategori,
    required this.kode,
    required this.deskripsi,
    required this.nilai,
    required this.detail,
    required this.date,
  });

  factory LabaRugiItem.fromJson(Map<String, dynamic> json) {
    var detailList = <LabaRugiDetail>[];
    if (json['detail'] != null && json['detail'] is List) {
      detailList =
          (json['detail'] as List).map((d) => LabaRugiDetail.fromJson(d)).toList();
    }

    return LabaRugiItem(
      kategori: json['kategori'] ?? '',
      kode: json['kode'] ?? '',
      deskripsi: json['deskripsi'] ?? '',
      nilai: json['nilai'] ?? '0',
      date: json['date'] ?? '',
      detail: detailList,
    );
  }
}

class LabaRugiDetail {
  final String idLaba;
  final String id;
  final String nama;
  final String tanggal;
  final String nominal;

  LabaRugiDetail({
    required this.idLaba,
    required this.id,
    required this.nama,
    required this.tanggal,
    required this.nominal,
  });

  factory LabaRugiDetail.fromJson(Map<String, dynamic> json) {
    return LabaRugiDetail(
      idLaba: json['id_laba'] ?? '',
      id: json['id'] ?? '',
      nama: json['nama'] ?? '',
      tanggal: json['tanggal'] ?? '',
      nominal: json['nominal'] ?? '0',
    );
  }
}

class DetailLabaRugiPage extends StatelessWidget {
  final LabaRugiItem item;

  const DetailLabaRugiPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final String namaAkun = "${item.deskripsi} (${item.kode})";

    double totalNominal = 0.0;
    for (var detail in item.detail) {
      totalNominal += parseToDouble(detail.nominal);
    }

    if (item.detail.isEmpty) {
      totalNominal = parseToDouble(item.nilai);
    }

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Transaksi ${item.deskripsi}",
                style: const TextStyle(fontSize: 16)),
            Text(item.kode, style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        children: [
          Container(
            width: double.infinity,
            color: Colors.grey[300],
            padding: const EdgeInsets.all(12),
            child: Text(
              namaAkun,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Saldo Awal',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('0'),
              ],
            ),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Transaksi Terkait',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          ..._buildDetailList(item),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Saldo Akhir',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(formatRupiah(totalNominal),
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDetailList(LabaRugiItem item) {
    if (item.detail.isEmpty) {
      return [
        ListTile(
          title: Text(item.deskripsi),
          subtitle: Text(item.date),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.pink[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(formatRupiah(parseToDouble(item.nilai)),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ];
    }

    return item.detail.map((detail) {
      return ListTile(
        title: Text(detail.nama),
        subtitle: Text(detail.tanggal),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.pink[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(formatRupiah(parseToDouble(detail.nominal)),
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      );
    }).toList();
  }
}
