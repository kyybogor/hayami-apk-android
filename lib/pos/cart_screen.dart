import 'package:flutter/material.dart';
import 'package:hayami_app/pos/product_order_dialog.dart';
import 'package:hayami_app/pos/customer_model.dart';
import 'package:hayami_app/pos/posscreen.dart';


class CartScreen extends StatefulWidget {
  final Customer selectedCustomer;
  final List<OrderItem> cartItems;
  final List<Map<String, dynamic>> diskonCustList;

  const CartScreen({
    super.key,
    required this.selectedCustomer,
    required this.cartItems,
    required this.diskonCustList,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool isConfirmMode = false;
  bool showDiscountInput = false;

  final TextEditingController percentController = TextEditingController();
  final TextEditingController nominalController = TextEditingController();

  String selectedPayment = 'cash';
  int selectedTopDuration = 0;

  void updateDiscountFromPercent(double percent, double subtotal) {
    final value = (subtotal * percent / 100).roundToDouble();
    nominalController.text = value.toStringAsFixed(0);
  }

  void updateDiscountFromNominal(double nominal, double subtotal) {
    final percent = (subtotal > 0) ? (nominal / subtotal * 100) : 0;
    percentController.text = percent.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    double subTotal = widget.cartItems.fold(0, (sum, item) => sum + item.total);
    double totalQty = widget.cartItems.fold(0, (sum, item) => sum + item.quantity);

    double calculateAutoDiskon() {
      double autoDiskon = 0;
      final customerId = widget.selectedCustomer.id;

      for (var item in widget.cartItems) {
        final diskonEntry = widget.diskonCustList.firstWhere(
          (d) => d['id_cust'] == customerId && d['id_tipe'] == item.idTipe,
          orElse: () => {},
        );

        final diskonPerLusin = double.tryParse(diskonEntry['discp'] ?? '0') ?? 0;
        autoDiskon += diskonPerLusin * item.quantity;
      }

      return autoDiskon;
    }

    double totalDiskon = calculateAutoDiskon();
    double manualDiskonNominal = double.tryParse(nominalController.text) ?? 0;
    double manualDiskonPercent = double.tryParse(percentController.text) != null
        ? (subTotal * (double.tryParse(percentController.text)! / 100))
        : 0;
    double newDiscount = manualDiskonNominal > 0 ? manualDiskonNominal : manualDiskonPercent;
    double grandTotal = subTotal - totalDiskon - newDiscount;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cart"),
        backgroundColor: Colors.indigo,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Current Customer ID: ${widget.selectedCustomer.id}",
                style: const TextStyle(fontWeight: FontWeight.bold)),

            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ...widget.cartItems.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;

                      return Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.productName} - ${item.size}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Text('Rp ${item.total.toStringAsFixed(0)}'),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setState(() {
                                    widget.cartItems.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${item.quantity} @ Rp ${item.unitPrice.toStringAsFixed(0)}'),
                              Text('Total: Rp ${item.total.toStringAsFixed(0)}'),
                            ],
                          ),
                          const Divider(),
                        ],
                      );
                    }),

                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isConfirmMode ? Colors.red : Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          if (isConfirmMode) {
                            widget.cartItems.clear();
                            isConfirmMode = false;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cart cleared')),
                            );
                          } else {
                            isConfirmMode = true;
                          }
                        });
                      },
                      child: Text(
                        isConfirmMode ? 'Confirm' : 'Clear Items',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              showDiscountInput = !showDiscountInput;
                              percentController.clear();
                              nominalController.clear();
                            });
                          },
                          child: const Text('New Discount'),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Sub-Total:'),
                            Text('Rp ${subTotal.toStringAsFixed(0)}'),
                            const Text('Auto Discount:'),
                            Text('Rp ${totalDiskon.toStringAsFixed(0)}'),
                            const Text('New Discount:'),
                            Text('Rp ${newDiscount.toStringAsFixed(0)}'),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),
                    if (showDiscountInput)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: percentController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Disc (%)',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                updateDiscountFromPercent(
                                    double.tryParse(value) ?? 0, subTotal);
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: nominalController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Disc (Rp)',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                updateDiscountFromNominal(
                                    double.tryParse(value) ?? 0, subTotal);
                                setState(() {});
                              },
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: 'Payment',
                              border: OutlineInputBorder(),
                            ),
                            value: selectedPayment,
                            items: const [
                              DropdownMenuItem(value: 'cash', child: Text('Cash')),
                              DropdownMenuItem(value: 'credit', child: Text('Credit')),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedPayment = value!;
                                selectedTopDuration = (value == 'credit') ? 30 : 0;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: selectedPayment == 'credit'
                              ? DropdownButtonFormField<int>(
                                  decoration: const InputDecoration(
                                    labelText: 'Top Duration',
                                    border: OutlineInputBorder(),
                                  ),
                                  value: selectedTopDuration,
                                  items: const [
                                    DropdownMenuItem(value: 30, child: Text('30 Hari')),
                                    DropdownMenuItem(value: 60, child: Text('60 Hari')),
                                    DropdownMenuItem(value: 90, child: Text('90 Hari')),
                                    DropdownMenuItem(value: 120, child: Text('120 Hari')),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      selectedTopDuration = value!;
                                    });
                                  },
                                )
                              : TextField(
                                  enabled: false,
                                  controller: TextEditingController(text: '0'),
                                  decoration: const InputDecoration(
                                    labelText: 'Top Duration',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
              onPressed: () {},
              child: Text(
                'GRAND TOTAL: Rp ${grandTotal.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
