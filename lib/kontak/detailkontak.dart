import 'package:flutter/material.dart';

class DetailKontakScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetailKontakScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final statusAktif = data['status_aktif'] == 'Y';
    final nama = data['nm_customer'] ?? '-';
    final name = data['name'] ?? '-';
    final email = data['email'] ?? '-';
    final telepon = (data['telp']?.isNotEmpty == true)
        ? data['telp']
        : (data['telp2']?.isNotEmpty == true ? data['telp2'] : '-');
    final alamat = data['address'] ?? '-';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontak'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Tampilkan status Aktif / Tidak Aktif di sini
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSimpleStatusCard("Aktif", Icons.check_circle, statusAktif),
                _buildSimpleStatusCard("Tidak Aktif", Icons.cancel, !statusAktif),
              ],
            ),
            const SizedBox(height: 16),
            // Card Informasi Kontak
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nama, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(name, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.email, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(email)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.phone, size: 20),
                        const SizedBox(width: 8),
                        Text(telepon),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(alamat)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleStatusCard(String label, IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isActive ? Colors.green : Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: isActive ? Colors.white : Colors.grey[700]),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
