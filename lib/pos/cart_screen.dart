import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hayami_app/pos/product_order_dialog.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class CartEntry {
  final String customerName;
  final double grandTotal;
  final String idTransaksi;
  final double disc;
  final double discPersen;
  final double discBaru;
  final double diskonLusin; // <--- Tambahan

  CartEntry({
    required this.customerName,
    required this.grandTotal,
    required this.idTransaksi,
    required this.disc,
    required this.discPersen,
    required this.discBaru,
    required this.diskonLusin, // <--- Tambahan
  });
}

class CartScreen extends StatefulWidget {
  final String customerId;
  final double grandTotal;
  final List<OrderItem> cartItems;
  final Function(CartEntry) onSelect;
  final Function(CartEntry) onDelete;

  const CartScreen({
    super.key,
    required this.customerId,
    required this.grandTotal,
    required this.cartItems,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final List<CartEntry> cartSummaryList = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCartData();
  }

  Future<void> fetchCartData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.8/hayami/cart.php'),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'];

          // Simpan satu data per id_transaksi
          final Map<String, dynamic> uniqueEntries = {};

          for (var item in data) {
            final idTransaksi = item['id_transaksi'] ?? 'unknown';
            if (!uniqueEntries.containsKey(idTransaksi)) {
              uniqueEntries[idTransaksi] = item;
            }
          }

          final List<CartEntry> entries = [];

          uniqueEntries.forEach((idTransaksi, item) {
            final customerName = item['id_customer'] ?? 'Unknown';
            final grandTotal =
                double.tryParse(item['total_invoice'] ?? '0') ?? 0.0;
            final disc = double.tryParse(item['disc'] ?? '0') ?? 0.0;
            final discPersen =
                double.tryParse(item['disc_invoice'] ?? '0') ?? 0.0;
            final discBaru = double.tryParse(item['disc_nilai'] ?? '0') ?? 0.0;
            final diskonLusin = double.tryParse(item['diskon_lusin'] ?? '0') ?? 0.0;

            entries.add(CartEntry(
              customerName: customerName,
              grandTotal: grandTotal,
              idTransaksi: idTransaksi,
              disc: disc,
              discPersen: discPersen,
              discBaru: discBaru,
              diskonLusin: diskonLusin,
            ));
          });

          setState(() {
            cartSummaryList.clear();
            cartSummaryList.addAll(entries);
          });
        } else {
          throw Exception('Status not success');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      debugPrint('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal mengambil data dari API.")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void addToCart() {
    final entry = CartEntry(
      customerName: widget.customerId,
      grandTotal: widget.grandTotal,
      idTransaksi: '',
      disc: 0.0,
      discPersen: 0.0,
      discBaru: 0.0,
      diskonLusin: 0.0, 
    );

    setState(() {
      cartSummaryList.add(entry);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Cart ditambahkan.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cart", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 1,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  const Divider(),
                  const Text(
                    "Daftar Cart:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: cartSummaryList.isEmpty
                        ? const Center(child: Text("Belum ada cart."))
                        : ListView.builder(
                            itemCount: cartSummaryList.length,
                            itemBuilder: (context, index) {
                              final entry = cartSummaryList[index];
                              return ListTile(
                                title: Text(entry.customerName),
                                subtitle: Text(
                                    "Rp ${NumberFormat('#,##0', 'id_ID').format(entry.grandTotal)}"),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      onPressed: () async {
                                        final idTransaksi = entry.idTransaksi;
                                        final encodedIdTransaksi =
                                            Uri.encodeComponent(idTransaksi);

                                        try {
                                          final response = await http.get(
                                            Uri.parse(
                                                'http://192.168.1.8/hayami/cartdetail.php?id_transaksi=$encodedIdTransaksi'),
                                          );

                                          if (response.statusCode == 200) {
                                            final Map<String, dynamic>
                                                jsonResponse =
                                                json.decode(response.body);

                                            if (jsonResponse['status'] ==
                                                'success') {
                                              final List<dynamic> allItems =
                                                  jsonResponse['data'];

                                              final filteredItems = allItems
                                                  .where((item) =>
                                                      item['id_transaksi'] ==
                                                      idTransaksi)
                                                  .toList();

                                              final List<OrderItem> items =
                                                  filteredItems.map((item) {
                                                return OrderItem(
                                                  productName:
                                                      item['model'] ?? '',
                                                  size: item['ukuran'] ?? '',
                                                  quantity: double.tryParse(
                                                          item['qty'] ?? '0') ??
                                                      0,
                                                  unitPrice: (double.tryParse(
                                                              item['harga'] ??
                                                                  '0') ??
                                                          0) *
                                                      12,
                                                  idTipe:
                                                      item['id_bahan'] ?? '',
                                                );
                                              }).toList();

                                              widget.onSelect(entry);
                                              Navigator.pop(context, {
                                                'entry': entry,
                                                'items': items,
                                                'disc': entry.disc,
                                                'discPersen': entry.discPersen,
                                                'discBaru': entry.discBaru,
                                                'idTransaksi':
                                                    entry.idTransaksi,
                                                'diskonLusin': entry.diskonLusin,
                                              });
                                            } else {
                                              throw Exception(
                                                  'Response status not success');
                                            }
                                          } else {
                                            throw Exception(
                                                'Failed to load item data');
                                          }
                                        } catch (e) {
                                          debugPrint('Error: $e');
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Gagal mengambil item dari server')),
                                          );
                                        }
                                      },
                                      child: const Text(
                                        "Select",
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
onPressed: () async {
  final idTransaksi = entry.idTransaksi;
  try {
    final response = await http.post(
      Uri.parse('http://192.168.1.8/hayami/delete_cart.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'id_transaksi': idTransaksi}),
    );

    final responseBody = json.decode(response.body);

    if (response.statusCode == 200 && responseBody['status'] == 'success') {
      setState(() {
        cartSummaryList.removeAt(index);
      });
      widget.onDelete(entry);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Data berhasil dihapus."),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      throw Exception(responseBody['message'] ?? 'Gagal menghapus data');
    }
  } catch (e) {
    debugPrint('Delete Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Terjadi kesalahan saat menghapus."),
        duration: Duration(seconds: 1),
      ),
    );
  }
},
                                      child: const Text("Delete",
                                          style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
