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

  IconData getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'tipe':
        return Icons.category;
      case 'id tipe':
        return Icons.confirmation_num;
      case 'ukuran':
        return Icons.straighten;
      case 'qty':
        return Icons.inventory_2;
      case 'qty reserved':
        return Icons.assignment_turned_in;
      case 'harga':
        return Icons.attach_money;
      default:
        return Icons.info_outline;
    }
  }

  Widget buildInfoTile(String label, String value,
      {bool isHarga = false, IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon ?? getIconForLabel(label),
            size: 20,
            color: Colors.blueAccent,
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          const Text(
            ": ",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: isHarga ? Colors.blue[700] : Colors.grey[800],
                fontWeight: isHarga ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 3,
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

    final int qtyClear = int.tryParse(produk['qtyclear'].toString()) ?? 0;
    final int qtyClearDO = int.tryParse(produk['qtycleardo'].toString()) ?? 0;
    final int qtyReserved = qtyClear + qtyClearDO;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.blue),
        title: const Text(
          'Detail Produk',
          style: TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Gambar proporsional, bisa dizoom, tidak kepotong
            InteractiveViewer(
              panEnabled: true,
              minScale: 1,
              maxScale: 4,
              child: AspectRatio(
                aspectRatio: 1, // Gunakan 4/3 jika gambar cenderung horizontal
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image,
                            size: 60, color: Colors.grey),
                      ),
                    ),
                    loadingBuilder: (_, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Kartu Info Produk
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produk['sku'] ?? '',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const Divider(height: 16),
                    const SizedBox(height: 16),
                    if (produk['tipe'] != null)
                      buildInfoTile('Tipe', produk['tipe'].toString()),
                    if (produk['id_tipe'] != null)
                      buildInfoTile('ID Tipe', produk['id_tipe'].toString()),
                    if (produk['size'] != null)
                      buildInfoTile('Ukuran', produk['size'].toString()),
                    if (produk['qty'] != null)
                      buildInfoTile('Qty', produk['qty'].toString()),
                    buildInfoTile('Qty Reserved', qtyReserved.toString()),
                    buildInfoTile('Harga', formatRupiah(produk['harga']),
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
