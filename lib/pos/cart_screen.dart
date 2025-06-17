import 'package:flutter/material.dart';
import 'package:hayami_app/pos/product_order_dialog.dart';

class CartEntry {
  final String customerName;
  final double grandTotal;

  CartEntry({required this.customerName, required this.grandTotal});
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

  void addToCart() {
    final entry = CartEntry(
      customerName: widget.customerId,
      grandTotal: widget.grandTotal,
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              "Current Customer ID: ${widget.customerId}",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),

            // Tombol Add To Cart ukuran kecil
            Center(
  child: SizedBox(
    width: 170,
    height: 40,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.cyan,
        padding: const EdgeInsets.symmetric(horizontal: 8),
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
            const SizedBox(height: 8),
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
                          subtitle: Text("Rp ${entry.grandTotal.toStringAsFixed(0)}"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                onPressed: () {
                                  widget.onSelect(entry);
                                  Navigator.pop(context);
                                },
                                child: const Text("Select", style: TextStyle(fontSize: 12)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                ),
                                onPressed: () {
                                  setState(() {
                                    cartSummaryList.removeAt(index);
                                  });
                                  widget.onDelete(entry);
                                },
                                child: const Text("Delete", style: TextStyle(fontSize: 12)),
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
