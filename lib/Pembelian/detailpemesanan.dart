import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class DetailPemesananPage extends StatefulWidget {
  final Map<String, dynamic> invoice;

  const DetailPemesananPage({super.key, required this.invoice});

  @override
  State<DetailPemesananPage> createState() => _DetailPemesananPageState();
}

class _DetailPemesananPageState extends State<DetailPemesananPage> {
  List<dynamic> barang = [];
  bool isLoading = false;
  String alamat = '-';

  @override
  void initState() {
  super.initState();
  final List<dynamic> data = widget.invoice['items'] ?? [];
  final List<Map<String, dynamic>> parsedProduk = data.map<Map<String, dynamic>>((item) {
    final qty = double.tryParse(item['pcs']?.toString() ?? '0') ?? 0;
    final total = double.tryParse(item['ttlcost']?.toString() ?? '0') ?? 0;

    return {
      'nama_barang': item['sku'] ?? 'Tidak Diketahui',
      'size': (item['size'] != null && item['size'].toString().isNotEmpty)
          ? item['size'].toString()
          : 'All Size',
      'jumlah': qty.toStringAsFixed(0),
      'harga': qty == 0 ? '0' : (total / qty).toStringAsFixed(0),
      'total': total.toStringAsFixed(0),
    };
  }).toList();

  setState(() {
    barang = parsedProduk;
    isLoading = false;
  });
}

  double getTotalSemuaBarang() {
    double total = 0;
    for (var item in barang) {
      final harga = double.tryParse(item['total']?.toString() ?? '0') ?? 0;
      total += harga;
    }
    return total;
  }

  String formatRupiah(double number) {
    final formatter = NumberFormat("#,###", "id_ID");
    return formatter.format(number);
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pemesanan':
        return Colors.blue;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    final memo = widget.invoice['invoice']?.toString() ?? '-';
    final idCust = invoice['name'] ?? 'Tidak diketahui';
    final instansi = invoice['instansi'] ?? '-';
    final date = invoice['date'] ?? '-';
    final sudahDibayar = invoice['dibayar'] ?? '-';
    final status = invoice['status'] ?? 'Pemesanan';
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
          _buildHeader(memo, idCust, instansi, alamat, date, status,
              statusColor),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Barang Dibeli",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : barang.isEmpty
                    ? const Center(
                        child: Text("Tidak ada barang untuk invoice ini."))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: barang.length,
                        itemBuilder: (context, index) {
                          final item = barang[index];
                          return Card(
                            child: ListTile(
                              title: Text(
                                  item['nama_barang'] ?? 'Tidak Diketahui'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item['size'] != null &&
                                      item['size'].isNotEmpty)
                                    Text("Ukuran: ${item['size']}"),
                                  Text(
                                    "${item['jumlah']} pcs",
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  "Rp ${formatRupiah(double.tryParse(item['total']?.toString() ?? '0') ?? 0)}",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
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
                      const Text("Total Semua",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text("Rp ${formatRupiah(getTotalSemuaBarang())}",
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (status.toLowerCase() == 'dibayar sebagian')
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Sudah Dibayar",
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500)),
                            Text(
                                "Rp ${formatRupiah(double.tryParse(sudahDibayar.toString()) ?? 0)}",
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Sisa Tagihan",
                                style: TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w500)),
                            Text(
                              "Rp ${formatRupiah(getTotalSemuaBarang() - (double.tryParse(sudahDibayar.toString()) ?? 0))}",
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w600),
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
      String address,
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
          Text(memo,
              style: const TextStyle(fontSize: 16, color: Colors.white70)),
          const SizedBox(height: 16),
          Text(contactName,
              style: const TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.bold)),
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
                Text(status,
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(date, style: const TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}