import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class DetailPemesananPage extends StatefulWidget {
  final Map<String, dynamic> invoice;

  const DetailPemesananPage({super.key, required this.invoice});

  @override
  State<DetailPemesananPage> createState() => _DetailPemesananPageState();
}

class _DetailPemesananPageState extends State<DetailPemesananPage> {
  List<Map<String, dynamic>> barang = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _parseItems();
  }

void _parseItems() async {
  final idPo1 = widget.invoice['id_po1'];
  final url = Uri.parse('http://hayami.id/apps/erp/api-android/api/po2.php?id_po1=$idPo1');

  try {
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      if (jsonResponse['status'] == 'success' && jsonResponse['data'] != null) {
        final List<dynamic> items = jsonResponse['data'];
        final List<Map<String, dynamic>> parsed = [];

        for (var item in items) {
  final qty = double.tryParse(item['qty']?.toString() ?? '0') ?? 0;
  final qtyClear = double.tryParse(item['qtyclear']?.toString() ?? '0') ?? 0;
  final harga = double.tryParse(item['harga']?.toString() ?? '0') ?? 0;
  final total = double.tryParse(item['ttl_harga']?.toString() ?? '0') ?? 0;

  String statusProses;
  if (qtyClear == 0) {
    statusProses = 'Belum diproses';
  } else if (qtyClear < qty) {
    statusProses = 'Diproses sebagian';
  } else if (qtyClear == qty) {
    statusProses = 'Sedang diproses';
  } else {
    statusProses = 'Tidak diketahui';
  }

  parsed.add({
    'nama_barang': item['sku'] ?? 'Tidak diketahui',
    'size': item['size']?.toString().isNotEmpty == true ? item['size'] : 'All Size',
    'jumlah': (qty * 12).toStringAsFixed(0),
    'harga': harga.toStringAsFixed(0),
    'total': total.toStringAsFixed(0),
    'status_proses': statusProses,
  });
}


        setState(() {
          barang = parsed;
          isLoading = false;
        });
      } else {
        setState(() {
          barang = [];
          isLoading = false;
        });
      }
    } else {
      print("Gagal load data detail barang: ${response.statusCode}");
      setState(() => isLoading = false);
    }
  } catch (e) {
    print("Terjadi error saat mengambil data: $e");
    setState(() => isLoading = false);
  }
}

  double getTotalSemuaBarang() {
    return barang.fold(0, (sum, item) => sum + (double.tryParse(item['total'] ?? '0') ?? 0));
  }

  String formatRupiah(dynamic number) {
    final doubleValue = double.tryParse(number.toString()) ?? 0;
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(doubleValue);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pemesanan':
        return Colors.blue;
      case 'dibayar sebagian':
        return Colors.orange;
      case 'lunas':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    final memo = invoice['id_po1']?.toString() ?? '-';
    final idCust = invoice['id_cust'] ?? 'Tidak diketahui';
    final instansi = invoice['instansi'] ?? '-';
    final date = invoice['dibuat_tgl'] ?? '-';
    final rawFlag = invoice['flag']?.toString() ?? '';
String status;

if (rawFlag.toLowerCase() == 'so partially created') {
  status = 'Partially Created';
} else if (rawFlag.isNotEmpty) {
  status = rawFlag; // tampilkan apa adanya kalau bukan yang di atas
} else {
  status = 'Pemesanan'; // default kalau flag kosong
}

    final sudahDibayar = invoice['dibayar'] ?? '0';
    final statusColor = _getStatusColor(status);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: AppBar(
            title: const Text('Detail Pemesanan',
                style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildHeader(memo, idCust, instansi, date, status, statusColor),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Barang Dibeli",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : barang.isEmpty
                    ? const Center(child: Text("Tidak ada barang untuk invoice ini."))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: barang.length,
                        itemBuilder: (context, index) {
                          final item = barang[index];
                          return Card(
                            child: ListTile(
                              title: Text(item['nama_barang'] ?? 'Tidak diketahui'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Ukuran: ${item['size']}"),
                                  Text("${item['jumlah']} pcs"),
                                ],
                              ),
                              trailing: Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        formatRupiah(item['total']),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: statusColor,
        ),
      ),
    ),
    const SizedBox(height: 4),
    Text(
      "Status: ${item['status_proses']}",
      style: const TextStyle(
        fontSize: 12,
        color: Colors.black87,
      ),
    ),
  ],
),

                            ),
                          );
                        },
                      ),
          ),
          if (!isLoading && barang.isNotEmpty)
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  width: double.infinity,
                  color: Colors.grey.shade200,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total Semua", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(formatRupiah(getTotalSemuaBarang()),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (status.toLowerCase() == 'dibayar sebagian')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Sudah Dibayar", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            Text(formatRupiah(double.tryParse(sudahDibayar.toString()) ?? 0),
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Sisa Tagihan", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            Text(
                              formatRupiah(getTotalSemuaBarang() - (double.tryParse(sudahDibayar.toString()) ?? 0)),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      String memo,
      String contactName,
      String instansi,
      String date,
      String status,
      Color statusColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          Text(memo, style: const TextStyle(fontSize: 16, color: Colors.white70)),
          const SizedBox(height: 16),
          Text(contactName,
              style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(status, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(date, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }
}
