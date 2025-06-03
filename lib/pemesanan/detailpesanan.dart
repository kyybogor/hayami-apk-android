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
    fetchProduct();
  }

Future<void> fetchProduct() async {
  setState(() => isLoading = true);
  final idPo1 = widget.invoice['id_po1']?.toString() ?? '';
  final url = Uri.parse("http://192.168.1.11/connect/JSON/gpo2.php");

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      final List<Map<String, dynamic>> parsedProduk = data
          .where((item) => item['id_po1']?.toString() == idPo1)
          .map<Map<String, dynamic>>((item) {
        final qty = int.tryParse(item['qty']?.toString() ?? '0') ?? 0;
        final harga = int.tryParse(item['harga']?.toString() ?? '0') ?? 0;
        final total = int.tryParse(item['ttl_harga']?.toString() ?? '0') ?? (qty * harga);

        return {
          'nama_barang': item['sku'] ?? 'Tidak Diketahui',
          'size': item['size']?.toString() ?? 'All Size',
          'jumlah': qty.toString(),
          'harga': harga.toString(),
          'total': total.toString(),
        };
      }).toList();

      setState(() {
        barang = parsedProduk;
      });
    } else {
      setState(() {
        barang = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data. Status: ${response.statusCode}')),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Terjadi kesalahan: $e')),
    );
  } finally {
    setState(() => isLoading = false);
  }
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
      case 'belum dibayar':
        return Colors.red;
      case 'dibayar sebagian':
        return Colors.orange;
      case 'lunas':
        return Colors.green;
      case 'void':
        return Colors.grey;
      case 'jatuh tempo':
        return Colors.black;
      case 'retur':
        return Colors.deepOrange;
      case 'transaksi berulang':
        return Colors.blue;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    final memo = widget.invoice['memo']?.toString() ?? '-';
    final idCust = invoice['name'] ?? 'Tidak diketahui';
    final instansi = invoice['instansi'] ?? '-';
    final date = invoice['date'] ?? '-';
    final dueDate = invoice['due'] ?? '-';
    final sudahDibayar = invoice['dibayar'] ?? '-';
    final status = invoice['status'] ?? 'Belum Dibayar';
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
            title: const Text('Detail Tagihan',
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
          _buildHeader(widget.invoice),
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
                                    "${item['jumlah']} x Rp ${formatRupiah(double.tryParse(item['harga']?.toString() ?? '0') ?? 0)}",
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
  Map<String, dynamic> invoice,
) {
  final idPo1 = invoice['id_po1'] ?? '-';
  final idCust = invoice['id_cust'] ?? '-';
  final dibuatTgl = invoice['dibuat_tgl'] ?? '-';
  final tgltop = invoice['tgltop'] ?? '-';

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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          idPo1,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          idCust,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,  // ini yang tebal
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Dibuat: $dibuatTgl',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
            Text(
              'Tgl TOP: $tgltop',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

}
