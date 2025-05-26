import 'package:flutter/material.dart';
import 'package:hayami_app/kas%20&%20bank/detailkas.dart';
import 'package:hayami_app/kas%20&%20bank/editbankscreen.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

class Rekeningbank extends StatefulWidget {
  const Rekeningbank({super.key});

  @override
  State<Rekeningbank> createState() => _RekeningbankState();
}

class _RekeningbankState extends State<Rekeningbank> {
  List<dynamic> transaksiHayami = [];
  List<dynamic> transaksiBank = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

Future<void> fetchData() async {
  final urlHayami = Uri.parse('http://hayami.id/apps/erp/api-android/api/transaksi.php');
  final urlBank = Uri.parse('http://hayami.id/apps/erp/api-android/api/transaksi_bank.php');

  try {
    final responseHayami = await http.get(urlHayami);
    final responseBank = await http.get(urlBank);

    if (responseHayami.statusCode == 200 && responseBank.statusCode == 200) {
      final dataHayami = jsonDecode(responseHayami.body);
      final dataBank = jsonDecode(responseBank.body);

      setState(() {
        transaksiHayami = dataHayami['hayami'];
        transaksiBank = dataBank['bank'];      
      });
    } else {
      print('Error status code: Hayami ${responseHayami.statusCode}, Bank ${responseBank.statusCode}');
    }
  } catch (e) {
    print('Terjadi error: $e');
  }
}


  String formatRupiah(dynamic amount) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    try {
      if (amount == null || amount.toString().isEmpty) return 'Rp 0';
      double value = double.tryParse(amount.toString()) ?? 0;
      return formatter.format(value);
    } catch (e) {
      return 'Rp 0';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Kas'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildInfoCard(
                        'Saldo', 'Rp 62,677,047', '+66,2%', Colors.green),
                    const SizedBox(width: 8),
                    _buildInfoCard(
                        'Masuk', 'Rp 25,000,000', '+45%', Colors.blue),
                    const SizedBox(width: 8),
                    _buildInfoCard(
                        'Keluar', 'Rp 10,000,000', '-12%', Colors.red),
                    const SizedBox(width: 8),
                    _buildInfoCard(
                        'Net', 'Rp 15,000,000', '-14%', Colors.black),
                  ],
                ),
              ),
            ),
            _buildSectionTitle("Transaksi di Hayami", () {}),
            ...transaksiHayami
                .map((item) => _buildHayamiTransactionItem(item))
                .toList(),
            _buildSectionTitle("Transaksi di Bank", () {}),
            ...transaksiBank.map((item) => _buildBankTransactionItem(
                  title: item["title"] ?? "-",
                  subtitle: item["subtitle"] ?? "-",
                  date: item["date"] ?? "-",
                  amount: item["amount"] ?? "0",
                  isKirim:
                      (item["subtitle"]?.toLowerCase() ?? "") == "kirim dana",
                  reconciled: item["status"] == "Reconciled",
                )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInfoCard(
      String title, String value, String change, Color color) {
    bool isNegative = change.startsWith('-');
    return SizedBox(
      width: 220,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[100],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (change.isNotEmpty)
                  Row(
                    children: [
                      Icon(
                        isNegative ? Icons.trending_down : Icons.trending_up,
                        size: 16,
                        color: color,
                      ),
                      const SizedBox(width: 4),
                      Text(change,
                          style: TextStyle(color: color, fontSize: 13)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          GestureDetector(
            onTap: onTap,
            child:
                const Text("Lihat Semua", style: TextStyle(color: Colors.blue)),
          )
        ],
      ),
    );
  }

  Widget _buildHayamiTransactionItem(Map<String, dynamic> item) {
    final title = item["title"] ?? "Judul tidak ada";
    final subtitle = item["subtitle"] ?? "Tidak ada nama";
    final date = item["date"] ?? "-";
    final amount = item["amount"] ?? "0";
    final status = item["status"] ?? "Unreconciled";

    final kasData = {
      'id': item['id'],
      'nama': "Terima pembayaran tagihan: $title",
      'tanggal': date,
      'status': status,
      'instansi': item['instansi'],
      'total': item['amount'],
    };

    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Detailkas(kasData: kasData),
          ),
        );
      },
      title: Text(
        "Terima pembayaran tagihan: $title",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: const TextStyle(fontSize: 12)),
          Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status.toLowerCase() == 'reconciled'
                      ? Colors.green[100]
                      : Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formatRupiah(amount),
                  style: TextStyle(
                    color: status.toLowerCase() == 'reconciled'
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                status,
                style: TextStyle(
                  color: status.toLowerCase() == 'reconciled'
                      ? Colors.green
                      : Colors.red,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildBankTransactionItem({
    required String title,
    required String subtitle,
    required String date,
    required String amount,
    required bool isKirim,
    required bool reconciled,
  }) {
    Color amountColor = isKirim ? Colors.red : Colors.green;
    Color statusColor = reconciled ? Colors.green : Colors.red;
    String statusText = reconciled ? "Reconciled" : "Unreconciled";

    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EditBankScreen(
              bankData: {
                "title": title,
                "subtitle": subtitle,
                "date": date,
                "amount": amount,
                "statusText": statusText,
              },
            ),
          ),
        );
      },
      leading: CircleAvatar(
        backgroundColor: subtitle.toLowerCase() == "kirim dana"
            ? Colors.red[50]
            : Colors.green[50],
        child: Icon(
          subtitle.toLowerCase() == "kirim dana"
              ? Icons.trending_down
              : Icons.trending_up,
          color: subtitle.toLowerCase() == "kirim dana"
              ? Colors.red
              : Colors.green,
        ),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: const TextStyle(fontSize: 12)),
          Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: amountColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(formatRupiah(amount),
                    style: TextStyle(color: amountColor)),
              ),
              const SizedBox(height: 4),
              Text(statusText,
                  style: TextStyle(color: statusColor, fontSize: 12)),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
        ],
      ),
    );
  }
}
