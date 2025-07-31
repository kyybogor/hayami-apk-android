import 'package:flutter/material.dart';
import 'package:hayami_app/pos/customer_model.dart' show Customer;
import 'package:intl/intl.dart';

class OrderItem {
  final String idTipe;
  final String productName;
  final String size;
  final double quantity;
  final double unitPrice;
  final double discount;

  OrderItem({
    required this.idTipe,
    required this.productName,
    required this.size,
    required this.quantity,
    required this.unitPrice,
    this.discount = 0.0,
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
  State<ProductOrderDialogContent> createState() =>
      _ProductOrderDialogContentState();
}

class _ProductOrderDialogContentState extends State<ProductOrderDialogContent> {
  final Map<String, TextEditingController> qtyControllers = {};
  final Map<String, TextEditingController> lusinControllers = {};
  final Map<String, TextEditingController> pcsControllers = {};
  final formatCurrency = NumberFormat('#,###', 'id_ID');
  final Map<String, TextEditingController> customPriceControllers = {};
  final NumberFormat currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: '',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    for (var size in widget.allSizes) {
      final ukuran = size['ukuran'].toString();
      qtyControllers[ukuran] = TextEditingController(text: '0');
      lusinControllers[ukuran] = TextEditingController(text: '0');
      pcsControllers[ukuran] = TextEditingController(text: '0');
      customPriceControllers[ukuran] = TextEditingController(text: '0');
    }
  }

  @override
  void dispose() {
    for (var controller in qtyControllers.values) {
      controller.dispose();
    }
    for (var controller in lusinControllers.values) {
      controller.dispose();
    }
    for (var controller in pcsControllers.values) {
      controller.dispose();
    }
    for (var controller in customPriceControllers.values) {
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
    return basePrice;
  }

  String formatLusinPcs(double qty) {
    final lusin = qty ~/ 12;
    final pcs = qty % 12;
    if (lusin > 0 && pcs > 0) return '${lusin}ls ${pcs.toInt()}pcs';
    if (lusin > 0) return '${lusin}ls';
    return '${pcs.toInt()}pcs';
  }

  void updateQty(String size) {
    final ls = int.tryParse(lusinControllers[size]?.text ?? '0') ?? 0;
    final pcs = int.tryParse(pcsControllers[size]?.text ?? '0') ?? 0;
    final total = (ls * 12) + pcs;
    qtyControllers[size]?.text = total.toString();
    setState(() {});
  }

  void syncQtyToLusinPcs(String size, int totalQty) {
    final lusin = totalQty ~/ 12;
    final pcs = totalQty % 12;
    lusinControllers[size]?.text = lusin.toString();
    pcsControllers[size]?.text = pcs.toString();
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.representative['image'];
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
            Text('Type: ${widget.representative['id_bahan']}',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('Model: ${widget.representative['model']}'),
            const Divider(height: 24),
            Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Size',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Stok',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                // Expanded(
                //   flex: 3,
                //   child: Align(
                //     alignment: Alignment.center,
                //     child: Text(
                //       'Qty',
                //       style: TextStyle(fontWeight: FontWeight.bold),
                //     ),
                //   ),
                // ),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      'Lusin',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: Text(
                      'Pcs',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Center(
                    child: Text(
                      'Harga',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...widget.allSizes.map((item) {
              final stock = double.tryParse(item['stock'].toString()) ?? 0.0;
              final size = item['ukuran'].toString();
              final price = double.tryParse(item['harga'].toString()) ?? 0.0;

              final qtyText = qtyControllers[size]?.text ?? '0';
              final orderQty = double.tryParse(qtyText) ?? 0;

              final lsQty =
                  int.tryParse(lusinControllers[size]?.text ?? '0') ?? 0;
              final pcsQty =
                  int.tryParse(pcsControllers[size]?.text ?? '0') ?? 0;

              final useQty =
                  (orderQty > 0) ? orderQty : (lsQty * 12 + pcsQty).toDouble();

              final totalPrice = calculatePrice(useQty, price);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(flex: 3, child: Text(size)),
                    Expanded(flex: 2, child: Text(formatLusinPcs(stock))),
                    // Expanded(
                    //   flex: 3,
                    //   child: Row(
                    //     children: [
                    //       IconButton(
                    //         icon: const Icon(Icons.remove, size: 16),
                    //         padding: EdgeInsets.zero,
                    //         constraints: const BoxConstraints(),
                    //         onPressed: (lsQty > 0 || pcsQty > 0)
                    //             ? null
                    //             : () {
                    //                 setState(() {
                    //                   final currentQty = double.tryParse(
                    //                           qtyControllers[size]?.text ??
                    //                               '0') ??
                    //                       0;
                    //                   final newQty =
                    //                       (currentQty - 1).clamp(0, stock);
                    //                   qtyControllers[size]?.text =
                    //                       newQty.toStringAsFixed(0);
                    //                   if (newQty > 0) {
                    //                     lusinControllers[size]?.text = '0';
                    //                     pcsControllers[size]?.text = '0';
                    //                   }
                    //                 });
                    //               },
                    //       ),
                    //       SizedBox(
                    //         width: 28,
                    //         child: TextField(
                    //           controller: qtyControllers[size],
                    //           keyboardType: TextInputType.number,
                    //           readOnly: true,
                    //           textAlign: TextAlign.center,
                    //           decoration: const InputDecoration(isDense: true),
                    //           enabled: lsQty == 0 && pcsQty == 0,
                    //         ),
                    //       ),
                    //       IconButton(
                    //         icon: const Icon(Icons.add, size: 16),
                    //         padding: EdgeInsets.zero,
                    //         constraints: const BoxConstraints(),
                    //         onPressed: (lsQty > 0 || pcsQty > 0)
                    //             ? null
                    //             : () {
                    //                 setState(() {
                    //                   final currentQty = double.tryParse(
                    //                           qtyControllers[size]?.text ??
                    //                               '0') ??
                    //                       0;
                    //                   final newQty =
                    //                       (currentQty + 1).clamp(0, stock);
                    //                   qtyControllers[size]?.text =
                    //                       newQty.toStringAsFixed(0);
                    //                   if (newQty > 0) {
                    //                     lusinControllers[size]?.text = '0';
                    //                     pcsControllers[size]?.text = '0';
                    //                   }
                    //                 });
                    //               },
                    //       ),
                    //     ],
                    //   ),
                    // ),
Expanded(
  flex: 3,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(
        icon: const Icon(Icons.remove, size: 16),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: (double.tryParse(qtyControllers[size]?.text ?? '0') ?? 0) > 0
            ? null
            : () {
                int current = int.tryParse(lusinControllers[size]?.text ?? '0') ?? 0;
                if (current > 0) {
                  current--;
                  lusinControllers[size]?.text = current.toString();
                  qtyControllers[size]?.text = '0';
                  setState(() {});
                }
              },
      ),
      Text(
        lusinControllers[size]?.text ?? '0',
        style: const TextStyle(fontSize: 14),
      ),
      IconButton(
        icon: const Icon(Icons.add, size: 16),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: (double.tryParse(qtyControllers[size]?.text ?? '0') ?? 0) > 0
            ? null
            : () {
                int lusin = int.tryParse(lusinControllers[size]?.text ?? '0') ?? 0;
                int pcs = int.tryParse(pcsControllers[size]?.text ?? '0') ?? 0;
                final total = (lusin + 1) * 12 + pcs;
                if (total <= stock) {
                  lusin++;
                  lusinControllers[size]?.text = lusin.toString();
                  qtyControllers[size]?.text = '0';
                  setState(() {});
                }
              },
      ),
    ],
  ),
),
Expanded(
  flex: 3,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(
        icon: const Icon(Icons.remove, size: 16),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: (double.tryParse(qtyControllers[size]?.text ?? '0') ?? 0) > 0
            ? null
            : () {
                int current = int.tryParse(pcsControllers[size]?.text ?? '0') ?? 0;
                if (current > 0) {
                  current--;
                  pcsControllers[size]?.text = current.toString();
                  qtyControllers[size]?.text = '0';
                  setState(() {});
                }
              },
      ),
      Text(
        pcsControllers[size]?.text ?? '0',
        style: const TextStyle(fontSize: 14),
      ),
      IconButton(
        icon: const Icon(Icons.add, size: 16),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        onPressed: (double.tryParse(qtyControllers[size]?.text ?? '0') ?? 0) > 0
            ? null
            : () {
                int lusin = int.tryParse(lusinControllers[size]?.text ?? '0') ?? 0;
                int pcs = int.tryParse(pcsControllers[size]?.text ?? '0') ?? 0;

                if (pcs < 11) {
                  final total = lusin * 12 + pcs + 1;
                  if (total <= stock) {
                    pcs++;
                    pcsControllers[size]?.text = pcs.toString();
                    qtyControllers[size]?.text = '0';
                    setState(() {});
                  }
                }
              },
      ),
    ],
  ),
),
                    Expanded(
                        flex: 2,
                        child: Center(
                            child: Text(formatCurrency.format(totalPrice)))),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        width: 100,
                        child: TextField(
                          controller: customPriceControllers[size],
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '0',
                            isDense: true,
                          ),
                          textAlign: TextAlign.right,
                          onChanged: (value) {
                            String digits =
                                value.replaceAll(RegExp(r'[^\d]'), '');

                            int number = int.tryParse(digits) ?? 0;

                            String formatted = currencyFormatter.format(number);

                            customPriceControllers[size]!.value =
                                TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(
                                  offset: formatted.length),
                            );
                          },
                        ),
                      ),
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
                    final List<OrderItem> updatedCart =
                        List.from(widget.currentCart);

                    for (var item in widget.allSizes) {
                      final size = item['ukuran'].toString();
                      final qtyText = qtyControllers[size]?.text ?? '0';
                      final qtyLusin =
                          int.tryParse(lusinControllers[size]?.text ?? '0') ??
                              0;
                      final qtyPcs =
                          int.tryParse(pcsControllers[size]?.text ?? '0') ?? 0;

                      final qty = (double.tryParse(qtyText) ?? 0) > 0
                          ? double.tryParse(qtyText) ?? 0
                          : (qtyLusin * 12 + qtyPcs).toDouble();

                      if (qty > 0) {
                        final basePrice =
                            double.tryParse(item['harga'].toString()) ?? 0.0;
                        final idTipe =
                            widget.representative['id_bahan'].toString();
                        final stock =
                            double.tryParse(item['stock'].toString()) ?? 0.0;

                        final inputText = customPriceControllers[size]
                                ?.text
                                .replaceAll('.', '') ??
                            '0';
                        final inputCustomTotal =
                            double.tryParse(inputText) ?? 0.0;

                        final unitPrice = (inputCustomTotal > 0 && qty > 0)
                            ? (inputCustomTotal * 12) / qty
                            : basePrice;

                        double finalPrice = unitPrice;
                        if (widget.selectedCustomer != null) {
                          finalPrice = calculateFinalUnitPrice(
                            basePrice: unitPrice,
                            quantity: qty,
                            diskonLusin: widget.selectedCustomer!.diskonLusin,
                          );
                        }

                        final existingItemIndex = updatedCart.indexWhere(
                          (e) => e.idTipe == idTipe && e.size == size,
                        );

                        double currentQtyInCart = 0.0;
                        if (existingItemIndex != -1) {
                          currentQtyInCart =
                              updatedCart[existingItemIndex].quantity;
                        }

                        if ((currentQtyInCart + qty) > stock) {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Stok tidak mencukupi'),
                              content: Text(
                                  'Stok tersedia hanya ${stock - currentQtyInCart} untuk ukuran $size.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                          return;
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
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
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
