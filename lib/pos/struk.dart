import 'package:flutter/material.dart';
import 'package:hayami_app/pos/customer_model.dart';
import 'package:hayami_app/pos/product_order_dialog.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> showStrukDialog(
  BuildContext context,
  List<OrderItem> cartItems,
  Customer? _,
  double grandTotal,
  Map<String, dynamic>? selectedPaymentAccount,
  String? __,
) async {
  final now = DateTime.now();
  final formatterDate = DateFormat('dd MMM yyyy');
  final formatterTime = DateFormat('HH:mm');
  final prefs = await SharedPreferences.getInstance();
  final collectedBy = prefs.getString('nm_user') ?? '-';

  // Format metode pembayaran
  String paymentMethod = '-';
  if (selectedPaymentAccount != null) {
    final tipe = selectedPaymentAccount['tipe']?.toString().toUpperCase().trim() ?? '';
    final bank = selectedPaymentAccount['bank']?.toString().toUpperCase().trim() ?? '';
    paymentMethod = ['TRANSFER', 'DEBET', 'EDC'].contains(tipe) ? '$tipe - $bank' : tipe;
  }

  showDialog(
    context: context,
    barrierDismissible: true, // <-- Bisa ditutup dengan klik luar (tombol X)
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.zero, // sudut kotak tanpa lengkung
    ),
  contentPadding: const EdgeInsets.all(10),
  insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
  content: SingleChildScrollView(
    child: Column(
      mainAxisSize: MainAxisSize.min, // <- Ini penting agar tidak tinggi berlebihan
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
              Text('Hayami Indonesia', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Pasar Mester Jatinegara Lt.1 Blok AKS No:144-145.', style: TextStyle(fontSize: 12)),
              Text('NPWP: 86.783.673.6-033.000', style: TextStyle(fontSize: 12)),
              Text('Jakarta Timur, DKI Jakarta, 13310', style: TextStyle(fontSize: 12)),
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

        const Divider(thickness: 1),

        // Header Produk
        // Header Produk
Row(
  children: const [
    Expanded(flex: 5, child: Text('Nama Barang', style: TextStyle(fontWeight: FontWeight.bold))),
    Expanded(flex: 2, child: Text('Ukuran', style: TextStyle(fontWeight: FontWeight.bold))),
    Expanded(flex: 2, child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
    Expanded(flex: 3, child: Text('Harga', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
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
    final lastSpace = name.substring(0, maxNameLength).lastIndexOf(' ');
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
            Expanded(flex: 2, child: Text(item.size)),
            Expanded(
  flex: 2,
  child: Align(
    alignment: Alignment.centerRight,
    child: Padding(
      padding: EdgeInsets.only(left: 6), // tambah jarak dari kiri
      child: Text(qtyDus.toStringAsFixed(2)),
    ),
  ),
),
            Expanded(flex: 3, child: Text('Rp${hargaDus.toStringAsFixed(0)}', textAlign: TextAlign.right)),
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
        Row(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Expanded(
      flex: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Notes :',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2),
          Text(
            'Barang yang sudah di beli tidak dapat dikembalikan',
            style: TextStyle(fontSize: 10),
          ),
          SizedBox(height: 8), // <-- ruang tambahan di sini
        ],
      ),
    ),
    Expanded(
      flex: 3,
      child: Text(
        'Total: Rp${grandTotal.toStringAsFixed(0)}',
        textAlign: TextAlign.right,
        style: const TextStyle(fontWeight: FontWeight.bold),
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

