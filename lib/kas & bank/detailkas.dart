import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Detailkas extends StatefulWidget {
  final Map<String, dynamic> kasData;

  const Detailkas({Key? key, required this.kasData}) : super(key: key);

  @override
  State<Detailkas> createState() => _DetailkasState();
}

class _DetailkasState extends State<Detailkas> {
  List<dynamic> transaksi = [];

  @override
  void initState() {
    super.initState();
    fetchTransaksi();
  }

  Future<void> fetchTransaksi() async {
    final url = Uri.parse("http://hayami.id/apps/erp/api-android/api/transaksi.php");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<dynamic> semuaTransaksi = [];

        if (data is Map<String, dynamic>) {
          semuaTransaksi = [
            ...?data['hayami'],
            ...?data['bank'],
          ];

          final namaKas = widget.kasData['nama']?.toString().split(':').last.trim();
          final instansiKas = widget.kasData['instansi']?.toString();

          final filtered = semuaTransaksi.where((item) {
            final title = item['title']?.toString().trim();
            final instansi = item['instansi']?.toString().trim();
            return title == namaKas && instansi == instansiKas;
          }).toList();

          setState(() {
            transaksi = filtered;
          });
        }
      } else {
        debugPrint('Gagal mengambil data transaksi. Status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Error saat mengambil data transaksi: $e");
    }
  }

  String formatRupiah(double number) {
    final formatter = NumberFormat("#,###", "id_ID");
    return formatter.format(number);
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.kasData;
    final nama = (data['nama'] ?? '-').toString().split(':').last.trim();
    final instansi = data['instansi']?.toString() ?? '-';
    final tanggal = data['tanggal']?.toString() ?? '-';
    final status = data['status']?.toString() ?? 'Unreconciled';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Kas"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(nama,
                    style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                Text(instansi, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 6,
                        backgroundColor: Colors.black,
                      ),
                      const SizedBox(width: 8),
                      Text(status,
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          tanggal,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: transaksi.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text("Tidak ada transaksi untuk kas ini."),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: transaksi.length,
                    itemBuilder: (context, index) {
                      final item = transaksi[index];
                      final jumlah = double.tryParse(item['amount']?.toString() ?? '') ?? 0;

                      return Column(
                        children: [
                          const Divider(thickness: 1),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Total Transaksi:",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "Rp ${formatRupiah(jumlah)}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(thickness: 1),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
