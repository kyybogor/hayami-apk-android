import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Import intl for formatting

class DetailBarangMasuk extends StatefulWidget {
  final Map<String, dynamic> invoice;
  const DetailBarangMasuk({super.key, required this.invoice});

  @override
  State<DetailBarangMasuk> createState() => _DetailBarangMasukState();
}

class _DetailBarangMasukState extends State<DetailBarangMasuk> {
  bool isLoading = true;
  Map<String, dynamic> invoiceDetail = {};

  @override
  void initState() {
    super.initState();
    fetchInvoiceDetail();
  }

  Future<void> fetchInvoiceDetail() async {
    final idTransaksi = widget.invoice['id_transaksi'];
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.14/pos/barang_keluar.php?id_transaksi=$idTransaksi'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            invoiceDetail = data['data'][0]; // Ambil data pertama sesuai id_transaksi
            isLoading = false;
          });
        } else {
          throw Exception('Data tidak ditemukan');
        }
      } else {
        throw Exception('Gagal mengambil data');
      }
    } catch (e) {
      print("Error: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to format number into Indonesian currency with thousands separators
  String formatRupiah(double number) {
    final formatter = NumberFormat("#,###", "id_ID");
    return formatter.format(number);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(' ${widget.invoice['id_transaksi']}'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID Transaksi: ${invoiceDetail["id_transaksi"] ?? '-'}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    SizedBox(height: 10),
                    Text('Tanggal: ${invoiceDetail["tgl_transaksi"] ?? '-'}'),
                    SizedBox(height: 10),
                    Text('Total: Rp ${formatRupiah(double.tryParse(invoiceDetail["total_invoice"] ?? '0') ?? 0)}'),
                    SizedBox(height: 20),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: invoiceDetail["items"]?.length ?? 0,
                      itemBuilder: (context, index) {
                        final item = invoiceDetail["items"][index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12.0,  // Reduce horizontal padding
                              vertical: 8.0,    // Reduce vertical padding
                            ),
                            title: Row(
                              children: [
                                // Left side with item info
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item["id_bahan"] ?? '-'}',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14), // Make id_bahan bold
                                      ),
                                      SizedBox(height: 4),
                                      Text('Model: ${item["model"] ?? '-'}', style: TextStyle(fontSize: 12)),
                                      SizedBox(height: 4),
                                      Text('Ukuran: ${item["ukuran"] ?? '-'}', style: TextStyle(fontSize: 12)),
                                      SizedBox(height: 4),
                                      Text('Qty: ${item["qty"] ?? '-'}', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                // Right side with total price
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Rp ${formatRupiah(double.tryParse(item["total"] ?? '0') ?? 0)}',
                                        style: TextStyle(
                                          fontSize: 12, // Smaller font size for total
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Implement aksi retur di sini (tapi tidak perlu fungsi)
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Retur',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
