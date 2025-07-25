import 'package:flutter/material.dart';
import 'package:hayami_app/pos/customer_model.dart' show Customer;
import 'package:intl/intl.dart';

class OrderItem {
  final String idTipe;
  final String productName;
  final String size;
  final double quantity;
  final double unitPrice;
  final double discount; // ✅ Tambahkan diskon per item

  OrderItem({
    required this.idTipe,
    required this.productName,
    required this.size,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0, // ✅ Default ke 0 jika tidak ada diskon
  });

  double get subtotal => quantity * unitPrice;
  double get total => subtotal - discount;
}

class ProductOrderDialogContent extends StatefulWidget {
  final Customer? selectedCustomer;
  final Map<String, dynamic> representative;
  final List<dynamic> allSizes;
  final void Function(List<OrderItem>) onAddToOrder;
  final List<OrderItem> currentCart;


  ProductOrderDialogContent({
    required this.representative,
    required this.allSizes,
    required this.onAddToOrder,
    required this.selectedCustomer,
    required this.currentCart,
    super.key,
  });

  @override
  State<ProductOrderDialogContent> createState() => _ProductOrderDialogContentState();
}

class _ProductOrderDialogContentState extends State<ProductOrderDialogContent> {
  final Map<String, TextEditingController> qtyControllers = {};
  final formatCurrency = NumberFormat('#,###', 'id_ID');

  @override
  void initState() {
    super.initState();
    for (var size in widget.allSizes) {
      qtyControllers[size['ukuran']] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    for (var controller in qtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double calculatePrice(double pcsQty, double pricePerLusin) {
    return (pcsQty / 12) * pricePerLusin;
  }

  double calculateFinalUnitPrice({
    required double basePrice,
    required double quantity,
    required double diskonLusin,
  }) {
    final lusinQty = quantity / 12;
    return basePrice;
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.representative['image'] ?? widget.representative['image'];
    final imgUrl = (imagePath != null && imagePath.toString().isNotEmpty)
        ? 'https://hayami.id/apps/erp/$imagePath'
        : 'https://via.placeholder.com/150';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(imgUrl, height: 200, fit: BoxFit.contain),
            const SizedBox(height: 8),
            Text(
              'Type: ${widget.representative['id_bahan']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text('Model: ${widget.representative['model']}'),
            const Divider(height: 24),
            Row(
              children: const [
                Expanded(flex: 3, child: Text('Size', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Stok', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Center(child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(flex: 3, child: Center(child: Text('Harga', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(flex: 3, child: Center(child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)))),
              ],
            ),
            const SizedBox(height: 8),
            ...widget.allSizes.map((item) {
              final stock = double.tryParse(item['stock'].toString()) ?? 0.0;
              final size = item['ukuran'].toString();
              final price = double.tryParse(item['harga'].toString()) ?? 0.0;

              final qtyText = qtyControllers[size]?.text ?? '0';
              final orderQty = double.tryParse(qtyText) ?? 0;
              final totalPrice = calculatePrice(orderQty, price);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(size)),
                    Expanded(flex: 2, child: Text('${stock.toInt()} pcs')),
                    FittedBox(
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(
        icon: const Icon(Icons.remove, size: 16),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: () {
          setState(() {
            final currentQty = double.tryParse(qtyControllers[size]?.text ?? '0') ?? 0;
            final newQty = (currentQty - 3).clamp(0, stock);
            qtyControllers[size]?.text = newQty.toStringAsFixed(0);
          });
        },
      ),
      SizedBox(
        width: 40,
        child: Center(
          child: Builder(
            builder: (_) {
              final qty = double.tryParse(qtyControllers[size]?.text ?? '0') ?? 0;
              if (qty < 12) {
                return Text('${qty.toInt()} pcs', style: const TextStyle(fontSize: 11));
              } else {
                final lusinDecimal = (qty / 12).toStringAsFixed(2);
                return Text('$lusinDecimal ls', style: const TextStyle(fontSize: 11));
              }
            },
          ),
        ),
      ),
      IconButton(
        icon: const Icon(Icons.add, size: 16),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: () {
          setState(() {
            final currentQty = double.tryParse(qtyControllers[size]?.text ?? '0') ?? 0;
            final newQty = (currentQty + 3).clamp(0, stock);
            qtyControllers[size]?.text = newQty.toStringAsFixed(0);
          });
        },
      ),
    ],
  ),
),
                    Expanded(flex: 3, child: Center(child: Text(formatCurrency.format(price)))),
                    Expanded(flex: 3, child: Center(child: Text(formatCurrency.format(totalPrice)))),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
  final List<OrderItem> updatedCart = List.from(widget.currentCart);

  for (var item in widget.allSizes) {
    final size = item['ukuran'].toString();
    final qtyText = qtyControllers[size]?.text ?? '0';
    final qty = double.tryParse(qtyText) ?? 0.0;

    if (qty > 0) {
      final basePrice = double.tryParse(item['harga'].toString()) ?? 0.0;
      final idTipe = widget.representative['id_bahan'].toString();
      final stock = double.tryParse(item['stock'].toString()) ?? 0.0;

      double finalPrice = basePrice;

      if (widget.selectedCustomer != null) {
        finalPrice = calculateFinalUnitPrice(
          basePrice: basePrice,
          quantity: qty,
          diskonLusin: widget.selectedCustomer!.diskonLusin,
        );
      }

      final existingItemIndex = updatedCart.indexWhere(
        (e) => e.idTipe == idTipe && e.size == size,
      );

      double currentQtyInCart = 0.0;
      if (existingItemIndex != -1) {
        currentQtyInCart = updatedCart[existingItemIndex].quantity;
      }

      if ((currentQtyInCart + qty) > stock) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Stok tidak mencukupi'),
            content: Text(
              'Stok tersedia hanya ${stock - currentQtyInCart} untuk ukuran $size.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return; // Stop proses jika tidak cukup stok
      }

      if (existingItemIndex != -1) {
        updatedCart[existingItemIndex] = OrderItem(
          idTipe: idTipe,
          productName: '${widget.representative['model']}',
          size: size,
          quantity: currentQtyInCart + qty,
          unitPrice: finalPrice,
        );
      } else {
        updatedCart.add(OrderItem(
          idTipe: idTipe,
          productName: '${widget.representative['model']}',
          size: size,
          quantity: qty,
          unitPrice: finalPrice,
        ));
      }
    }
  }

  widget.onAddToOrder(updatedCart);
  Navigator.pop(context);
},
style: ElevatedButton.styleFrom(
    backgroundColor: Colors.indigo, // Warna latar belakang biru
    foregroundColor: Colors.white, // Warna teks putih
  ),

                  child: const Text('Add to Order'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}