import 'package:flutter/material.dart';
import 'package:hayami_app/pos/customer_model.dart';
import 'package:hayami_app/pos/product_order_dialog.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hayami_app/pos/print.dart';

Future<void> showStrukDialog(
  BuildContext context,
  List<OrderItem> cartItems,
  Customer? _,
  double grandTotal,
  Map<String, dynamic>? selectedPaymentAccount,
  String? __,
  double totalDiskon, // tambah parameter ini
  double newDiscount, // tambah parameter ini
  double totalLusin,
  List<Map<String, dynamic>> splitPayments,
) async {
  final now = DateTime.now();
  final formatterDate = DateFormat('dd MMM yyyy');
  final formatterTime = DateFormat('HH:mm');
  final currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
  final prefs = await SharedPreferences.getInstance();
  final collectedBy = prefs.getString('nm_user') ?? '-';

  Future.microtask(() async {
    await generateAndPrintStrukPdf(
      cartItems: cartItems,
      grandTotal: grandTotal,
      totalDiskon: totalDiskon,
      newDiscount: newDiscount,
      totalLusin: totalLusin,
      selectedPaymentAccount: selectedPaymentAccount ?? {},
      splitPayments: splitPayments,
      collectedBy: collectedBy,
    );
  });

  // Format metode pembayaran
  String paymentMethod = '-';
  if (selectedPaymentAccount != null) {
    final tipe =
        selectedPaymentAccount['tipe']?.toString().toUpperCase().trim() ?? '';
    final bank =
        selectedPaymentAccount['bank']?.toString().toUpperCase().trim() ?? '';
    paymentMethod =
        ['TRANSFER', 'DEBET', 'EDC'].contains(tipe) ? '$tipe $bank' : tipe;
  }

  return await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // sudut kotak tanpa lengkung
      ),
      contentPadding: const EdgeInsets.all(10),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize:
              MainAxisSize.min, // <- Ini penting agar tidak tinggi berlebihan
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Logo dan header toko
            Center(
              child: Image.asset(
                'assets/image/hayamilogo.png',
                height: 80,
              ),
            ),
            const SizedBox(height: 8),
            const Center(
              child: Column(
                children: [
                  Text('Hayami Indonesia',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text('Pasar Mester Jatinegara Lt.1 Blok AKS No:144-145.',
                      style: TextStyle(fontSize: 12)),
                  Text('NPWP: 86.783.673.6-033.000',
                      style: TextStyle(fontSize: 12)),
                  Text('Jakarta Timur, DKI Jakarta, 13310',
                      style: TextStyle(fontSize: 12)),
                  Text('087788155246', style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            const Divider(thickness: 1),

            // Tanggal dan jam
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(formatterDate.format(now)),
                Text(formatterTime.format(now)),
              ],
            ),
            const SizedBox(height: 4),

            // Order info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Order ID'),
                Text('SO/xxxx/yyyy'),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Collected By'),
                Text(collectedBy),
              ],
            ),
            Row(
              children: [
                const Expanded(flex: 2, child: Text('Metode Pembayaran')),
                Expanded(
                  flex: 3,
                  child: Text(
                    paymentMethod,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 4),

            // Split Payments
            if (splitPayments.isNotEmpty) ...[
              const SizedBox(height: 4),
              ...splitPayments.map((item) {
                final metodeRaw = item['metode'] ?? '-';
                final metodeParts = metodeRaw.split(' - ');
                final metode = metodeParts.length >= 2
                    ? '${metodeParts[0]} ${metodeParts[1]}'
                    : metodeRaw;
                final nominal = double.tryParse(item['jumlah']!
                        .replaceAll('.', '')
                        .replaceAll(',', '')) ??
                    0;
                final formatted = currencyFormatter.format(nominal);
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(metode),
                    Text(formatted),
                  ],
                );
              }).toList(),
            ],

            const Divider(thickness: 1),

            // Header Produk
            // Header Produk
// Header Produk
            Row(
              children: const [
                Expanded(
                  flex: 5,
                  child: Text(
                    'Nama Barang',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding:
                        EdgeInsets.only(left: 29), // geser ke kanan 8 pixel
                    child: Text(
                      'Ukuran',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Qty',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Harga',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),

// List Produk
            ...List.generate(cartItems.length, (index) {
              final item = cartItems[index];
              final isLast = index == cartItems.length - 1;

              final qtyDus = item.quantity / 12;
              final hargaDus = item.total / 12;

              final name = item.productName;
              final maxNameLength = 28;
              String firstLine = name;
              String? secondLine;

              if (name.length > maxNameLength) {
                final lastSpace =
                    name.substring(0, maxNameLength).lastIndexOf(' ');
                if (lastSpace != -1) {
                  firstLine = name.substring(0, lastSpace);
                  secondLine = name.substring(lastSpace).trim();
                }
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(flex: 5, child: Text(firstLine)),
                        Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 29), // geser kanan juga
                            child: Text(item.size),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            qtyDus.toStringAsFixed(2),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            currencyFormatter.format(hargaDus),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    if (secondLine != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 0, top: 2),
                        child: Text(secondLine),
                      ),
                    if (!isLast) const Divider(thickness: 0.5),
                  ],
                ),
              );
            }),

            const Divider(thickness: 1),

// Menampilkan Total Lusin, Diskon, Total, dan Split Payment
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Lusin
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Lusin',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      totalLusin.toStringAsFixed(2),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),

                // Diskon (jika ada)
                if ((totalDiskon + newDiscount) > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Diskon',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        currencyFormatter.format(totalDiskon + newDiscount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 6),
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      currencyFormatter.format(grandTotal),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Notes
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notes :',
                        style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Barang yang sudah di beli tidak dapat dikembalikan',
                        style: TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
