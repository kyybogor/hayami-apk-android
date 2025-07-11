  import 'dart:convert';
  import 'package:flutter/material.dart';
  import 'package:hayami_app/pos/barangmasuk.dart';
  import 'package:intl/intl.dart';
  import 'package:http/http.dart' as http;
  import 'package:shared_preferences/shared_preferences.dart';

  class Detailbarangmasuk extends StatefulWidget {
    final Map<String, dynamic> invoice;

    const Detailbarangmasuk({super.key, required this.invoice});

    @override
    State<Detailbarangmasuk> createState() => _DetailbarangmasukState();
  }

  class _DetailbarangmasukState extends State<Detailbarangmasuk> {
    List<dynamic> barang = [];
    bool isLoading = false;

    @override
    void initState() {
      super.initState();
      fetchProduct();
    }

    Future<void> fetchProduct() async {
      setState(() {
        isLoading = true;
      });

      final idTransaksi = widget.invoice['id']?.toString() ?? '';

      final url = Uri.parse(
          "http://192.168.1.14/pos/masuk_detail.php?id_transaksi=$idTransaksi");

      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final Map<String, dynamic> jsonData = json.decode(response.body);
          if (jsonData['status'] == 'success') {
            final List<dynamic> produkList = jsonData['data'];

            final List<Map<String, dynamic>> parsedProduk =
                produkList.map<Map<String, dynamic>>((item) {
              final qty = double.tryParse(item['qty']?.toString() ?? '0') ?? 0;
              final harga =
                  double.tryParse(item['harga']?.toString() ?? '0') ?? 0;
              final total =
                  double.tryParse(item['total']?.toString() ?? '0') ?? 0;

              return {
                'nama_barang': item['id_product'] ?? 'Tidak Diketahui',
                'uom': item['uom'] ?? 'Pcs',
                'model': item['model'] ?? '',
                'ukuran': item['ukuran'] ?? 'All Size',
                'jumlah': qty.toString(),
                'harga': harga.toString(),
                'total': total.toString(),
              };
            }).toList();

            setState(() {
              barang = parsedProduk;
            });
          } else {
            print("Status response bukan success.");
          }
        } else {
          print('Gagal mengambil data. Status: ${response.statusCode}');
        }
      } catch (e) {
        print("Error saat mengambil data: $e");
      } finally {
        setState(() {
          isLoading = false;
        });
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

    bool isConfirming = false;

Future<void> handleApprove() async {
  final idTransaksi = widget.invoice['id']?.toString() ?? '';
  final prefs = await SharedPreferences.getInstance();
  final idCabang = prefs.getString('id_cabang') ?? '';

  final url = Uri.parse('http://192.168.1.14/pos/inbond.php?id_transaksi=$idTransaksi&id_cabang=$idCabang');

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Konfirmasi"),
        content: const Text("Apakah Anda yakin ingin approve transaksi ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Tidak"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog first
              try {
                final response = await http.get(url);
                if (response.statusCode == 200) {
                  final data = json.decode(response.body);
                  if (data['status'] == 'success') {
                    // Mengubah status transaksi di widget sebelum melanjutkan
                    setState(() {
                      widget.invoice['status'] = 's'; // Update status menjadi 'approve'
                    });

                    // Kembali ke halaman Barangmasuk tanpa perlu klik tombol back
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => Barangmasuk(), // Pindah langsung ke Barangmasuk
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Barang berhasil di-approve")),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Gagal: ${data['message']}")),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error server: ${response.statusCode}")),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Error: $e")),
                );
              }
            },
            child: const Text("Ya"),
          ),
        ],
      );
    },
  );
}


    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text("Detail Barang Masuk",
              style: TextStyle(color: Colors.blue)),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.blue),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : barang.isEmpty
                      ? const Center(child: Text("Tidak ada barang."))
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
                                    if (item['model'] != null &&
                                        item['model'].toString().isNotEmpty)
                                      Text("Model: ${item['model']}"),
                                    Text("Ukuran: ${item['ukuran']}"),
                                    Text("${item['jumlah']} ${item['uom']}"),
                                  ],
                                ),
                                trailing: Text(
                                  "Rp ${formatRupiah(double.tryParse(item['total'] ?? '0') ?? 0)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
            if (widget.invoice['status']?.toString() == 'd')
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: handleApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Approve',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }
  }
