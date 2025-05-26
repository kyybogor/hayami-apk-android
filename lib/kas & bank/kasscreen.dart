import 'package:flutter/material.dart';
import 'package:hayami_app/kas%20&%20bank/detailkas.dart';
import 'package:hayami_app/kas%20&%20bank/editbankscreen.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

class Kasscreen extends StatefulWidget {
  final String? judul;

  const Kasscreen({super.key, this.judul});

  @override
  State<Kasscreen> createState() => _KasscreenState();
}

class _KasscreenState extends State<Kasscreen> {
  List<dynamic> transaksiHayami = [];
  List<dynamic> transaksiBank = [];
  bool isLoading = true;

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
          transaksiHayami = (dataHayami['hayami'] ?? []) as List;
          transaksiBank = (dataBank['bank'] ?? []) as List;
          isLoading = false;
        });
      } else {
        debugPrint('HTTP Error: ${responseHayami.statusCode} / ${responseBank.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Fetch error: $e');
      setState(() => isLoading = false);
    }
  }

  String formatRupiah(dynamic amount) {
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    try {
      double value = amount is num
          ? amount.toDouble()
          : double.tryParse(amount.toString()) ?? 0;
      return formatter.format(value);
    } catch (_) {
      return 'Rp 0';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(widget.judul ?? 'Kas'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildInfoSection(),
                _buildSectionTitle("Transaksi di Hayami", () {}),
                ...transaksiHayami.map((item) => _buildHayamiTransactionItem(item)),
                _buildSectionTitle("Transaksi di Bank", () {}),
                ...transaksiBank.map((item) => _buildBankTransactionItem(item)).toList(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildInfoSection() {
    return SizedBox(
      height: 120,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _buildInfoCard('Saldo', 'Rp 62,677,047', '+66,2%', Colors.green),
          const SizedBox(width: 8),
          _buildInfoCard('Masuk', 'Rp 25,000,000', '+45%', Colors.blue),
          const SizedBox(width: 8),
          _buildInfoCard('Keluar', 'Rp 10,000,000', '-12%', Colors.red),
          const SizedBox(width: 8),
          _buildInfoCard('Net', 'Rp 15,000,000', '-14%', Colors.black),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, String change, Color color) {
    bool isNegative = change.startsWith('-');
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey[100],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Icon(
                    isNegative ? Icons.trending_down : Icons.trending_up,
                    size: 16,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(change, style: TextStyle(color: color, fontSize: 13)),
                ],
              ),
            ],
          ),
        ],
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
            child: const Text("Lihat Semua", style: TextStyle(color: Colors.blue)),
          ),
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
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Detailkas(kasData: kasData)),
      ),
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
      trailing: Column(
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
    );
  }

  Widget _buildBankTransactionItem(Map<String, dynamic> item) {
    final title = item["title"] ?? "-";
    final subtitle = item["subtitle"] ?? "-";
    final date = item["date"] ?? "-";
    final amount = item["amount"] ?? "0";
    final isKirim = subtitle.toLowerCase() == "kirim dana";
    final reconciled = item["status"] == "Reconciled";

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
                "statusText": reconciled ? "Reconciled" : "Unreconciled",
              },
            ),
          ),
        );
      },
      leading: CircleAvatar(
        backgroundColor: isKirim ? Colors.red[50] : Colors.green[50],
        child: Icon(
          isKirim ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
          color: isKirim ? Colors.red : Colors.green,
        ),
      ),
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: const TextStyle(fontSize: 12)),
          Text(date, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(formatRupiah(amount), style: TextStyle(color: isKirim ? Colors.red : Colors.green)),
          const SizedBox(height: 4),
          Text(
            reconciled ? "Reconciled" : "Unreconciled",
            style: TextStyle(color: reconciled ? Colors.green : Colors.red, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
