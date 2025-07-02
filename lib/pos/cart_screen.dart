import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hayami_app/pos/cart_db_helper.dart';
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
    required this.diskonLusin,
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

  double parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

Future<void> fetchCartData() async {
  setState(() => isLoading = true);

  final connectivityResult = await Connectivity().checkConnectivity();

  if (connectivityResult != ConnectivityResult.none) {
    try {
      final response =
          await http.get(Uri.parse('http://192.168.1.9/hayami/cart.php'));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          await CartDBHelper.instance.clearCart();
          final List<dynamic> data = jsonResponse['data'];

          for (var item in data) {
            item['diskon_lusin'] = item.containsKey('diskon_lusin') ? item['diskon_lusin'] : 0.0;
            item['disc'] = parseDouble(item['disc']);
            item['disc_nilai'] = parseDouble(item['disc_nilai']);
            item['disc_invoice'] = parseDouble(item['disc_invoice']);
            item['diskon_lusin'] = parseDouble(item['diskon_lusin']);
            item['total_invoice'] = parseDouble(item['total_invoice']);

            await CartDBHelper.instance.insertOrUpdateCartItem(item);
          }
        }
      }
    } catch (e) {
      debugPrint('Error syncing from API: $e');
    }
  }

  final localData = await CartDBHelper.instance.getAllCartData();

  // Kelompokkan data berdasarkan id_transaksi
  final Map<String, List<Map<String, dynamic>>> groupedData = {};

  for (var item in localData) {
    final idTransaksi = item['id_transaksi'] ?? 'unknown';
    groupedData.putIfAbsent(idTransaksi, () => []).add(item);
  }

  final entries = groupedData.entries.map((entry) {
    final idTransaksi = entry.key;
    final items = entry.value;

    // Ambil customerName dari salah satu item
    final customerName = items[0]['id_customer'] ?? 'Unknown';

    // Ambil total_invoice dari salah satu item jika valid
    double totalInvoice = parseDouble(items[0]['total_invoice']);

    // Jika total_invoice tidak valid atau 0, hitung manual jumlah total item
    if (totalInvoice == 0) {
      totalInvoice = items.fold(0.0, (sum, item) => sum + parseDouble(item['total']));
    }

    // Ambil diskon dan lainnya dari satu item, bisa sesuaikan jika beda-beda
    final disc = parseDouble(items[0]['disc']);
    final discPersen = parseDouble(items[0]['disc_nilai']);
    final discBaru = parseDouble(items[0]['disc_invoice']);
    final diskonLusin = parseDouble(items[0]['diskon_lusin']);

    return CartEntry(
      customerName: customerName,
      grandTotal: totalInvoice,
      idTransaksi: idTransaksi,
      disc: disc,
      discPersen: discPersen,
      discBaru: discBaru,
      diskonLusin: diskonLusin,
    );
  }).toList();

  setState(() {
    cartSummaryList.clear();
    cartSummaryList.addAll(entries);
    isLoading = false;
  });
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

                                        try {
                                          // Ambil data detail dari SQLite
                                          final List<Map<String, dynamic>>
                                              localCartDetails =
                                              await CartDBHelper.instance
                                                  .getCartDetailsById(
                                                      idTransaksi);

                                          // Ubah hasil query menjadi List<OrderItem>
                                          final List<OrderItem> items =
                                              localCartDetails.map((item) {
                                            return OrderItem(
                                              productName: item['model'] ?? '',
                                              size: item['ukuran'] ?? '',
                                              quantity: double.tryParse(
                                                      item['qty'].toString()) ??
                                                  0,
                                              unitPrice: (double.tryParse(
                                                          item['harga']
                                                              .toString()) ??
                                                      0) *
                                                  12,
                                              idTipe: item['id_bahan'] ?? '',
                                            );
                                          }).toList();

                                          widget.onSelect(entry);
                                          Navigator.pop(context, {
                                            'entry': entry,
                                            'items': items,
                                            'disc': entry.disc,
                                            'discPersen': entry.discPersen,
                                            'discBaru': entry.discBaru,
                                            'idTransaksi': entry.idTransaksi,
                                            'diskonLusin': entry.diskonLusin,
                                          });
                                        } catch (e) {
                                          debugPrint('SQLite Error: $e');
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Gagal mengambil item dari lokal database'),
                                            ),
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
                                        print(
                                            "Attempting to delete cart with idTransaksi: $idTransaksi");

                                        final connectivity =
                                            await Connectivity()
                                                .checkConnectivity();
                                        bool deleteSuccess = false;

                                        if (connectivity !=
                                            ConnectivityResult.none) {
                                          // Online: delete ke API + update SQLite
                                          try {
                                            final response = await http.post(
                                              Uri.parse(
                                                  'http://192.168.1.9/hayami/delete_cart.php'),
                                              headers: {
                                                'Content-Type':
                                                    'application/json'
                                              },
                                              body: json.encode({
                                                'id_transaksi': idTransaksi
                                              }),
                                            );

                                            final responseBody =
                                                json.decode(response.body);

                                            if (response.statusCode == 200 &&
                                                responseBody['status'] ==
                                                    'success') {
                                              await CartDBHelper.instance
                                                  .markCartAsDeleted(
                                                      idTransaksi,
                                                      isSynced: true);
                                              deleteSuccess = true;
                                            } else {
                                              throw Exception(
                                                  responseBody['message'] ??
                                                      'Gagal menghapus data');
                                            }
                                          } catch (e) {
                                            debugPrint(
                                                'Delete Error (Online): $e');
                                            // fallback ke offline delete nanti di bawah
                                          }
                                        }

                                        if (!deleteSuccess) {
                                          // Offline or gagal koneksi → soft delete offline
                                          await CartDBHelper.instance
                                              .markCartAsDeleted(idTransaksi,
                                                  isSynced: false);
                                          final debugResult = await CartDBHelper
                                              .instance
                                              .getCartDetailsById(idTransaksi);
                                          print(
                                              "DEBUG - Data ditemukan untuk id_transaksi '$idTransaksi': ${debugResult.length} row(s)");
                                        }

                                        setState(() {
                                          cartSummaryList.removeAt(index);
                                        });
                                        widget.onDelete(entry);

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(deleteSuccess
                                                  ? "Data berhasil dihapus."
                                                  : "Cart ditandai untuk dihapus (offline).")),
                                        );
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
