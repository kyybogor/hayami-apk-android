import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProductOrderDialogContent extends StatefulWidget {
  final Map<String, dynamic> representative;
  final List<dynamic> allSizes;

  const ProductOrderDialogContent({
    required this.representative,
    required this.allSizes,
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
      qtyControllers[size['size']] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    for (var controller in qtyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double calculateStock(dynamic item) {
    double qty = double.tryParse(item['qty']) ?? 0.0;
    double clear = double.tryParse(item['qtyclear']) ?? 0.0;
    double doClear = double.tryParse(item['qtycleardo']) ?? 0.0;
    return qty - (clear + doClear);
  }

  double calculatePrice(double orderQty, double unitPrice) {
    return orderQty * unitPrice;
  }

  @override
  Widget build(BuildContext context) {
    final imgUrl = 'https://hayami.id/apps/erp/${widget.representative['img']}';

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              imgUrl,
              height: 200,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 8),
            Text('Type: ${widget.representative['tipe']}', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Model: ${widget.representative['gambar']}'),
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
              final stock = calculateStock(item);
              final size = item['size'];
              final price = double.tryParse(item['harga'] ?? '0') ?? 0;

              final qtyText = qtyControllers[size]?.text ?? '0';
              final orderQty = double.tryParse(qtyText) ?? 0;
              final totalPrice = calculatePrice(orderQty, price);

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
  children: [
    Expanded(flex: 3, child: Text(size)),
    Expanded(flex: 2, child: Text(stock.toStringAsFixed(1))),
    Expanded(
      flex: 2,
      child: Center(
        child: SizedBox(
          width: 60,
          child: TextField(
            controller: qtyControllers[size],
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.center,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            ),
            onChanged: (val) {
              final inputQty = double.tryParse(val) ?? 0.0;
              if (inputQty > stock) {
                qtyControllers[size]?.text = stock.toStringAsFixed(1);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Qty melebihi stok')),
                );
              }
              setState(() {});
            },
          ),
        ),
      ),
    ),
    Expanded(
      flex: 3,
      child: Center(child: Text(formatCurrency.format(price))),
    ),
    Expanded(
      flex: 3,
      child: Center(child: Text(formatCurrency.format(totalPrice))),
    ),
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
                    // TODO: Tambahkan ke keranjang
                    Navigator.pop(context);
                  },
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
