import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProdukDetailPage extends StatelessWidget {
  final Map<String, dynamic> produk;

  const ProdukDetailPage({super.key, required this.produk});

  String formatRupiah(dynamic amount) {
    final value = double.tryParse(amount.toString()) ?? 0;
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  }

  Widget buildInfoRow(String label, String value, {bool isHarga = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const Text(': ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: isHarga ? Colors.blue : Colors.black,
                fontWeight: isHarga ? FontWeight.w600 : FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String imageUrl = produk['img'].toString().startsWith('http')
        ? produk['img']
        : 'https://hayami.id/apps/erp/${produk['img'].toString().replaceAll('\\', '/')}';

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title:
            const Text('Detail Produk', style: TextStyle(color: Colors.blue)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Produk
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  height: 250,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.broken_image,
                    size: 100,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Informasi Produk
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produk['sku'] ?? '',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (produk['tipe'] != null)
                      buildInfoRow('Tipe', produk['tipe'].toString()),
                    if (produk['id_tipe'] != null)
                      buildInfoRow('ID Tipe', produk['id_tipe'].toString()),
                    if (produk['gambar'] != null)
                      buildInfoRow('Gambar', produk['gambar'].toString()),
                    if (produk['size'] != null)
                      buildInfoRow('Ukuran', produk['size'].toString()),
                    if (produk['qty'] != null)
                      buildInfoRow('Qty', produk['qty'].toString()),
                    if (produk['qtyclear'] != null)
                      buildInfoRow('Qty Clear', produk['qtyclear'].toString()),
                    if (produk['qtycleardo'] != null)
                      buildInfoRow(
                          'Qty Clear DO', produk['qtycleardo'].toString()),
                    const SizedBox(height: 8),
                    buildInfoRow('Harga', formatRupiah(produk['harga']),
                        isHarga: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
