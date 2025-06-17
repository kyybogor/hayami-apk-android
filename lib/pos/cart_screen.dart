import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hayami_app/pos/product_order_dialog.dart';
import 'package:http/http.dart' as http;

class CartEntry {
  final String customerName;
  final double grandTotal;
  final String idPo1;

  CartEntry({
    required this.customerName,
    required this.grandTotal,
    required this.idPo1,
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
      final response =
          await http.get(Uri.parse('http://192.168.1.8/hayami/gpo1.php'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        final List<CartEntry> entries = data.map((item) {
          final String customerName = item['id_cust'] ?? 'Unknown';
          final double grandTotal =
              double.tryParse(item['ttlhrg'] ?? '0') ?? 0.0;
          final String idPo1 = item['id_po1'] ?? '';

          return CartEntry(
            customerName: customerName,
            grandTotal: grandTotal,
            idPo1: idPo1,
          );
        }).toList();

        setState(() {
          cartSummaryList.clear();
          cartSummaryList.addAll(entries);
        });
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
      idPo1: '',
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
                  Text(
                    "Current Customer ID: ${widget.customerId}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: SizedBox(
                      width: 170,
                      height: 40,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                        ),
                        onPressed: addToCart,
                        child: const Text(
                          "Add To Cart",
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
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
                                    "Rp ${entry.grandTotal.toStringAsFixed(0)}"),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                      ),
                                      onPressed: () async {
                                        final idPo1 = entry.idPo1;
                                        final encodedIdPo1 =
                                            Uri.encodeComponent(
                                                idPo1); // encode dulu

                                        try {
                                          final response = await http.get(
                                            Uri.parse(
                                                'http://192.168.1.8/hayami/gpo2.php?id_po1=$encodedIdPo1'),
                                          );

                                          print(
                                              'Response body: ${response.body}');

                                          if (response.statusCode == 200) {
                                            final List<dynamic> allItems =
                                                json.decode(response.body);

                                            final filteredItems = allItems
                                                .where((item) =>
                                                    item['id_po1'] == idPo1)
                                                .toList();

                                            final List<OrderItem> items =
                                                filteredItems.map((item) {
                                              return OrderItem(
                                                productName: item['tipe'] ?? '',
                                                size: item['size'] ?? '',
                                                quantity: double.tryParse(
                                                        item['qty'] ?? '0') ??
                                                    0,
                                                unitPrice: double.tryParse(
                                                        item['harga'] ?? '0') ??
                                                    0,
                                                idTipe: item['sku'] ?? '',
                                              );
                                            }).toList();

                                            widget.onSelect(entry);
                                            Navigator.pop(context, items);
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
                                      onPressed: () {
                                        setState(() {
                                          cartSummaryList.removeAt(index);
                                        });
                                        widget.onDelete(entry);
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
