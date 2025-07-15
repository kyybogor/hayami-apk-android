import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Returbarang extends StatefulWidget {
  const Returbarang({super.key});

  @override
  State<Returbarang> createState() => _ReturbarangState();
}

class _ReturbarangState extends State<Returbarang> {
  final TextEditingController _searchController = TextEditingController();
  List<Item> items = [];
  bool isLoading = false;

  // Fungsi untuk mengambil data dari API
  Future<void> fetchItems(String idTransaksi) async {
    setState(() {
      isLoading = true;
    });

    final url = 'http://192.168.1.2/pos/detail_keluar.php?id_transaksi=$idTransaksi';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            items = (data['data'][0]['items'] as List)
                .map((itemData) => Item.fromJson(itemData))
                .toList();
          });
        } else {
          setState(() {
            items = [];
          });
        }
      } else {
        setState(() {
          items = [];
        });
      }
    } catch (e) {
      setState(() {
        items = [];
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fungsi untuk memformat angka menjadi Rupiah
  String formatRupiah(String amount) {
    final formatter = NumberFormat('#,###', 'id_ID');
    return 'Rp ${formatter.format(int.tryParse(amount) ?? 0)}';
  }

  // Fungsi untuk menampilkan popup dengan detail item
void _showItemDetails(Item item) {
  int qty = int.parse(item.qty); // Inisialisasi qty
  final TextEditingController qtyController = TextEditingController(text: qty.toString());

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        insetPadding: const EdgeInsets.all(16), // Memperlebar jarak dari tepi
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title (idBahan dengan teks biru dan tombol X merah)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.idBahan,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Teks idBahan menjadi biru
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red), // Tombol X menjadi merah
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Model, Ukuran, Harga, Total
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Model',
                        border: OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      ),
                      controller: TextEditingController(text: item.model),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Ukuran',
                        border: OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      ),
                      controller: TextEditingController(text: item.ukuran),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Harga',
                        border: OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      ),
                      controller: TextEditingController(text: item.harga.toString()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Qty Control
              Row(
                children: [
                  // Kotak "Qty" di kiri
                  SizedBox(
                    width: 100,
                    height: 40,
                    child: TextField(
                      readOnly: true,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        labelText: 'Qty',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Tombol minus
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      color: Colors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                      ),
                      onPressed: () {
                        if (qty > 1) {
                          setState(() {
                            qty--;
                            qtyController.text = qty.toString();
                          });
                        }
                      },
                    ),
                  ),

                  // Text qty
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 100,
                    height: 40,
                    child: TextField(
                      controller: qtyController,
                      textAlign: TextAlign.center,
                      readOnly: true,
                      style: const TextStyle(fontSize: 14),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),

                  // Tombol plus
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      color: Colors.white,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(),
                      ),
                      onPressed: () {
                        if (qty < int.parse(item.qty)) {
                          setState(() {
                            qty++;
                            qtyController.text = qty.toString();
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Tombol Cancel dan Save
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Tombol Cancel
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Menutup dialog
                    },
                    child: const Text('Cancel'),
                  ),

                  // Tombol Save
                  ElevatedButton(
                    onPressed: () {
                      // Simpan perubahan qty jika diperlukan
                      Navigator.of(context).pop(); // Menutup dialog
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Retur Barang',
          style: TextStyle(color: Colors.blue),
        ),
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kolom pencarian ID Transaksi
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Cari Berdasarkan ID Transaksi',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    if (_searchController.text.isNotEmpty) {
                      fetchItems(_searchController.text);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Indikator loading
            if (isLoading)
              const Center(child: CircularProgressIndicator()),

            // Menampilkan daftar produk
            if (!isLoading && items.isNotEmpty) ...[
              const SizedBox(height: 20),
              const Text(
                'Daftar Barang:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, index) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 4,
                      child: ListTile(
                        title: Text(items[index].idBahan),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Model: ${items[index].model}'),
                            Text('Ukuran: ${items[index].ukuran}'),
                            Text('Qty: ${items[index].qty}'),
                          ],
                        ),
                        trailing: Text(
                          formatRupiah(items[index].total),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          _showItemDetails(items[index]); // Menampilkan popup saat item diklik
                        },
                      ),
                    );
                  },
                ),
              ),
            ] else if (!isLoading && items.isEmpty) ...[
              const Center(child: Text('Tidak ada barang ditemukan untuk ID Transaksi ini')),
            ],
          ],
        ),
      ),
    );
  }
}

class Item {
  final String idBahan;
  final String model;
  final String ukuran;
  final String qty;
  final String harga;
  final String total;

  Item({
    required this.idBahan,
    required this.model,
    required this.ukuran,
    required this.qty,
    required this.harga,
    required this.total,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      idBahan: json['id_bahan'],
      model: json['model'],
      ukuran: json['ukuran'],
      qty: json['qty'],
      harga: json['harga'],
      total: json['total'],
    );
  }
}
