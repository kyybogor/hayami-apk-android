import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class PenjualanPerPeriodePage extends StatefulWidget {
  const PenjualanPerPeriodePage({Key? key}) : super(key: key);

  @override
  State<PenjualanPerPeriodePage> createState() =>
      _PenjualanPerPeriodePageState();
}

class _PenjualanPerPeriodePageState extends State<PenjualanPerPeriodePage> {
  List<Map<String, dynamic>> salesData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      fetchSalesData();
    });
  }

  Future<void> fetchSalesData() async {
    try {
      final response =
          await http.get(Uri.parse('http://192.168.1.9/Hiyami/jurnal.php'));

      if (response.statusCode == 200) {
        List data = jsonDecode(response.body);
        Map<String, Map<String, dynamic>> groupedData = {};

        for (var item in data) {
          List barangKontak = item['barang_kontak'] ?? [];
          String date = item['date'];

          DateTime parsedDate = DateTime.parse(date);
          String month = DateFormat('MMM yyyy', 'id_ID')
              .format(parsedDate); // e.g. "Apr 2025"

          for (var barang in barangKontak) {
            int qty = int.tryParse(barang['jumlah'] ?? '0') ?? 0;
            double amount = double.tryParse(barang['total'] ?? '0') ?? 0.0;

            if (!groupedData.containsKey(month)) {
              groupedData[month] = {'month': month, 'qty': 0, 'amount': 0.0};
            }

            groupedData[month]!['qty'] += qty;
            groupedData[month]!['amount'] += amount;
          }
        }

        setState(() {
          salesData = groupedData.values.toList();
          isLoading = false;
        });
      } else {
        throw Exception('Gagal mengambil data');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  String formatNumber(num number) {
    return NumberFormat.decimalPattern('id_ID').format(number);
  }

  @override
  Widget build(BuildContext context) {
    final totalQty =
        salesData.fold(0, (sum, item) => sum + (item['qty'] as int? ?? 0));
    final totalAmount = salesData.fold(
        0.0, (sum, item) => sum + (item['amount'] as double? ?? 0.0));

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.blueAccent,
        title: const Text('Penjualan per Periode', style: TextStyle(color: Colors.blueAccent, fontSize: 20),),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 10),
                ...salesData.map((item) {
                  return Column(
                    children: [
                      ListTile(
                        title: Text('${item['month']} (${item['qty']})'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber[600],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            formatNumber(item['amount']),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const Divider(
                        height: 5,
                      ),
                    ],
                  );
                }).toList(),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Kuantitas',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('$totalQty'),
                        ],
                      ),
                      const Divider(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            formatNumber(totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'share',
            backgroundColor: Colors.blue[300],
            child: const Icon(Icons.share),
            onPressed: () {
            },
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'download',
            backgroundColor: Colors.blue,
            child: const Icon(Icons.download),
            onPressed: () {
              // Tambahkan logika download jika diperlukan
            },
          ),
        ],
      ),
    );
  }
}
