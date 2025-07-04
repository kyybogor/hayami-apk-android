import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DetailPengirimanPage extends StatefulWidget {
  final Map<String, dynamic> invoice;
  final List<Map<String, dynamic>> barang;
  final String alamat;
  final String resi;

  const DetailPengirimanPage({
    super.key,
    required this.invoice,
    this.barang = const [],
    this.alamat = '-',
    this.resi = '-',
  });

  @override
  State<DetailPengirimanPage> createState() => _DetailPengirimanPageState();
}

class _DetailPengirimanPageState extends State<DetailPengirimanPage> {
  List<Map<String, dynamic>> get barang => widget.barang;
  String get alamat => widget.alamat;
  String get resi => widget.resi;

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
      case 'dispatched':
        return Colors.pinkAccent;
      case 'delivered':
        return Colors.greenAccent;
      default:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    final invoiceNumber = invoice['invoice'] ?? '-';
    final idCust = invoice['name'] ?? 'Tidak diketahui';
    final instansi = invoice['instansi'] ?? '-';
    final date = invoice['date'] ?? '-';
    final dueDate = invoice['due'] ?? '-';
    final status = invoice['status']?.toString().toLowerCase() ?? 'belum dibayar';
    final statusColor = _getStatusColor(status);
    
    // Ambil path file gambar dari invoice
    final filePath = invoice['file'] ?? '';

    // Base URL untuk gambar
    final baseUrl = 'https://hayami.id/apps/erp/';

    // Buat URL lengkap gambar
    final imageUrl = filePath.trim().isEmpty ? null : baseUrl + filePath;

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
            title: const Text('Detail', style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(invoiceNumber, idCust, instansi, alamat, date, dueDate, status, statusColor),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Nomor Resi: $resi",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tampilkan gambar jika ada
            if (imageUrl != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return SizedBox(
                        height: 150,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 150,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Kamu bisa tambahkan detail lainnya disini
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    String invoiceNumber,
    String contactName,
    String instansi,
    String address,
    String date,
    String dueDate,
    String status,
    Color statusColor,
  ) {
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
          Text(invoiceNumber, style: const TextStyle(fontSize: 16, color: Colors.white70)),
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
                Text(status[0].toUpperCase() + status.substring(1),
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Colors.white),
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
