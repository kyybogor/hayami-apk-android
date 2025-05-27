import 'package:flutter/material.dart';

class Detailkontak extends StatelessWidget {
  final dynamic data;

  const Detailkontak({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Cek jika data null atau bukan Map
    if (data == null || data is! Map) {
      return const Scaffold(
        body: Center(child: Text("Data tidak tersedia")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Kontak"),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _headerCard(data),
            ),
            _buildSectionTitle("Detail Profil"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _buildLineItem(Icons.layers, "Grup", data['grup']?.toString() ?? '-'),
                  _buildLineItem(Icons.assignment, "NPWP", data['npwp']?.toString() ?? '-'),
                ],
              ),
            ),
            _buildSectionTitle("Pemetaan Akun"),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  _buildLineItem(Icons.receipt_long, "Akun Hutang", data['ap_amount']?.toString() ?? '0.00'),
                  _buildLineItem(Icons.receipt_long, "Akun Piutang", data['ar_amount']?.toString() ?? '0.00'),
                  _buildLineItem(Icons.receipt, "Kena Pajak",
                      (data['cust_class']?.toString() == "1") ? "Ya" : "Tidak"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCard(Map data) {
    String nama = data['nm_customer']?.toString() ?? '-';
    String instansi = data['name']?.toString() ?? '-';
    String email = data['email']?.toString() ?? '-';

    String telepon = (data['telp']?.toString().isNotEmpty ?? false)
        ? data['telp'].toString()
        : data['telp2']?.toString() ?? '-';

    String alamat = data['address']?.toString() ?? '-';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nama,
              style: const TextStyle(fontSize: 20, color: Color(0xFF0D47A1)),
            ),
            const SizedBox(height: 4),
            Text(
              instansi,
              style: const TextStyle(color: Colors.black),
            ),
            const SizedBox(height: 16),
            Center(
              child: CircleAvatar(
                radius: 30,
                backgroundColor: Colors.grey.shade400,
                child: Text(
                  (nama.isNotEmpty) ? nama[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 24, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _infoRow(Icons.email, email),
            _infoRow(Icons.phone, telepon),
            _infoRow(Icons.location_on, alamat),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[700], size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade300,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLineItem(IconData icon, String label, String value) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 16)),
                  const Divider(thickness: 1),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
