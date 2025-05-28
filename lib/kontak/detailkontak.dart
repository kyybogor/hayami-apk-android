import 'package:flutter/material.dart';

class DetailKontakScreen extends StatelessWidget {
  final Map<String, dynamic> data;

  const DetailKontakScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final statusAktif = data['status_aktif'] == 'Y';
    final nama = data['nm_customer'] ?? '-';
    final name = data['name'] ?? '-';
    final email =
        (data['email'] != null && (data['email'] as String).trim().isNotEmpty)
            ? data['email']
            : '-';

    final telepon = ((data['telp'] != null &&
            (data['telp'] as String).trim().isNotEmpty)
        ? data['telp']
        : (data['telp2'] != null && (data['telp2'] as String).trim().isNotEmpty)
            ? data['telp2']
            : '-');

    // Cek alamat jika kosong tampilkan '-'
    final alamat = (data['address'] != null &&
            (data['address'] as String).trim().isNotEmpty)
        ? data['address']
        : '-';

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.blue,
        title: const Text("Kontak"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _squareStatusTab("Aktif", statusAktif),
                  const SizedBox(width: 16),
                  _squareStatusTab("Tidak Aktif", !statusAktif),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: Colors.grey[200],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey,
                        child: Text(
                          "N...",
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 5,),
                      ListTile(
                        leading: const Icon(Icons.email),
                        title: Text(email),
                      ),
                      const Divider(
                        height: 5,
                      ),
                      ListTile(
                        leading: const Icon(Icons.phone),
                        title: Text(telepon),
                      ),
                      const Divider(
                        height: 5,
                      ),
                      ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(alamat),
                      ),
                      const Divider(height: 5,),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _squareStatusTab(String label, bool selected) {
    return Container(
      width: 90,
      height: 70,
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        boxShadow: selected
            ? [const BoxShadow(color: Colors.black12, blurRadius: 4)]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            label == "Aktif" ? Icons.check_circle : Icons.cancel,
            color: selected ? Colors.green : Colors.grey,
            size: 20,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12, // kecilkan ukuran font
              color: selected ? Colors.black : Colors.grey,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
