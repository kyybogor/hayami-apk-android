import 'package:flutter/material.dart';
import 'package:hayami_app/produk/produkdetail.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class InventorySummaryPage extends StatefulWidget {
  const InventorySummaryPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _InventorySummaryPageState createState() => _InventorySummaryPageState();
}

class _InventorySummaryPageState extends State<InventorySummaryPage> {
  late Future<List<Map<String, dynamic>>> futureItems;

  @override
  void initState() {
    super.initState();
    futureItems = fetchProduct();
  }

  Future<List<Map<String, dynamic>>> fetchProduct() async {
    final response =
        await http.get(Uri.parse('http://192.168.1.9/hiyami/produk.php'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        final List<dynamic> itemsData = data['data'];
        
        return itemsData.map<Map<String, dynamic>>((item) => {
              'id': item['produk_id'],
              'name': item['produk_name'],
              'code': item['produk_code'],
              'stok': int.tryParse(item['stok']) ?? 0,
              'nominal_stok': double.tryParse(item['nominal_stok']) ?? 0.0,
              'hpp': item['hpp'],
              'hpp_value': item['hpp_value'],
              'harga_jual': item['harga_jual'],
              'penjualan': item['penjualan'],
              'nominal_penjualan': item['nominal_penjualan'],
              'gudang_utama': item['gudang']['gudang_utama'],
              'gudang_elektronik': item['gudang']['gudang_elektronik'],
              'total_gudang': item['gudang']['total'],
            }).toList();
      } else {
        throw Exception('Data tidak berhasil dimuat');
      }
    } else {
      throw Exception('Gagal memuat data inventori');
    }
  }

  int calculateTotalStok(List<Map<String, dynamic>> items) {
    return items.fold(
        0, (sum, item) => sum + ((item['stok'] ?? 0) as num).toInt());
  }

  double calculateTotalNominal(List<Map<String, dynamic>> items) {
    return items.fold(0.0,
        (sum, item) => sum + ((item['nominal_stok'] ?? 0.0) as num).toDouble());
  }

  String formatRupiah(dynamic number) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    double value = 0;
    if (number is int) {
      value = number.toDouble();
    } else if (number is double) {
      value = number;
    } else if (number is String) {
      value = double.tryParse(number) ?? 0;
    }
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ringkasan Inventori', style: TextStyle(color: Colors.blueAccent, fontSize: 20),),
        foregroundColor: Colors.blueAccent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>( 
              future: futureItems,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                      child: Text('Terjadi kesalahan: ${snapshot.error}'));
                }

                final items = snapshot.data ?? [];
                final totalStok = calculateTotalStok(items);
                final totalNominal = calculateTotalNominal(items);

                return ListView.separated(
                  itemCount: items.length + 1,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index == items.length) {
                      // Bottom Summary
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            Row(
                              children: [
                                const Text('Total Stok',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Text('$totalStok'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('Total Nilai Stok',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                                const Spacer(),
                                Text(formatRupiah(totalNominal)),
                              ],
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      );
                    }

                    var item = items[index];
                    return ListTile(
                      title: Text(item['name'] ?? '-'),
                      subtitle: Text(item['code'] ?? '-'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber[600],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item['stok'].toString(),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InventoriDetail(
                              item: item,
                              formatRupiah: formatRupiah,
                            ),
                          ),
                        );
                      },
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
        child: const Icon(Icons.download),
      ),
    );
  }
}

class InventoriDetail extends StatelessWidget {
  final Map<String, dynamic> item;
  final String Function(dynamic) formatRupiah;

  const InventoriDetail({
    super.key,
    required this.item,
    required this.formatRupiah,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item['name']),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            infoRow('Kode', item['code']),
            infoRow('Stok', item['stok'].toString()),
            infoRow('Nominal Stok', formatRupiah(item['nominal_stok'])),
            infoRow('Harga Pokok Produksi', formatRupiah(item['hpp'])),
            infoRow('Harga Jual', formatRupiah(item['harga_jual'])),
            const SizedBox(height: 24),
            InkWell(
              onTap: () {
              },
              child: buttonRow('Lihat Detail'),
            ),
            const SizedBox(height: 12),
            buttonRow('Buka Ringkasan', withIcon: true),
          ],
        ),
      ),
    );
  }
  

  Widget infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget buttonRow(String text, {bool withIcon = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(text),
          const Spacer(),
          Icon(withIcon ? Icons.expand_less : Icons.chevron_right),
        ],
      ),
    );
  }
}
