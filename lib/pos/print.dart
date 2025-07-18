import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'product_order_dialog.dart'; // pastikan ada class OrderItem di file ini

Future<void> generateAndPrintStrukPdf({
  required List<OrderItem> cartItems,
  required double grandTotal,
  double? totalDiskon,
  double? newDiscount,
  required double totalLusin,
  required dynamic selectedPaymentAccount,
  required List<Map<String, dynamic>> splitPayments,
  required String collectedBy,
    String? idTransaksi,
}) async {
  final double diskonCustomer = totalDiskon ?? 0;
  final double diskonTambahan = newDiscount ?? 0;
  final double totalDiskonFinal = diskonCustomer + diskonTambahan;

  print(
      'DEBUG >> Diskon Customer: $diskonCustomer | Diskon Tambahan: $diskonTambahan | Total: $totalDiskonFinal');

  final pdf = pw.Document();
  final now = DateTime.now();
  final dateFormatter = DateFormat('dd MMM yyyy');
  final timeFormatter = DateFormat('HH:mm');
  final currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  final ByteData logoBytes =
      await rootBundle.load('assets/image/hayamilogo.png');
  final Uint8List logoImage = logoBytes.buffer.asUint8List();

  final tipe =
      selectedPaymentAccount['tipe']?.toString().toUpperCase().trim() ?? '';
  final bank =
      selectedPaymentAccount['bank']?.toString().toUpperCase().trim() ?? '';
  final paymentMethod =
      ['TRANSFER', 'DEBET', 'EDC'].contains(tipe) ? '$tipe $bank' : tipe;

  final double computedLusin =
      cartItems.fold(0.0, (sum, item) => sum + (item.quantity / 12));

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(20),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Center(child: pw.Image(pw.MemoryImage(logoImage), height: 50)),
            pw.SizedBox(height: 6),
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text('Hayami Indonesia',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 12)),
                  pw.Text('Pasar Mester Jatinegara Lt.1 Blok AKS No:144-145.',
                      style: pw.TextStyle(fontSize: 15)),
                  pw.Text('NPWP: 86.783.673.6-033.000',
                      style: pw.TextStyle(fontSize: 15)),
                  pw.Text('Jakarta Timur, DKI Jakarta, 13310',
                      style: pw.TextStyle(fontSize: 15)),
                  pw.Text('087788155246', style: pw.TextStyle(fontSize: 15)),
                ],
              ),
            ),
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 0.5),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(dateFormatter.format(now),
                    style: pw.TextStyle(fontSize: 15)),
                pw.Text(timeFormatter.format(now),
                    style: pw.TextStyle(fontSize: 15)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Order ID', style: pw.TextStyle(fontSize: 15)),
                pw.Text(idTransaksi ?? 'SO/xxxx/yyyy', style: pw.TextStyle(fontSize: 15)),
              ],
            ),
            pw.SizedBox(height: 3),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Collected By', style: pw.TextStyle(fontSize: 15)),
                pw.Text(collectedBy, style: pw.TextStyle(fontSize: 15)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Metode Pembayaran', style: pw.TextStyle(fontSize: 15)),
                pw.Text(paymentMethod,
                    style: pw.TextStyle(
                        fontSize: 15, fontWeight: pw.FontWeight.bold)),
              ],
            ),
            if (splitPayments.isNotEmpty) ...[
              pw.SizedBox(height: 4),
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
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(metode, style: pw.TextStyle(fontSize: 15)),
                    pw.Text(currencyFormatter.format(nominal),
                        style: pw.TextStyle(fontSize: 15)),
                  ],
                );
              }),
            ],
            pw.SizedBox(height: 6),
            pw.Divider(thickness: 0.5),
            pw.Row(
              children: [
                pw.Expanded(
                    flex: 5,
                    child: pw.Text('Nama Barang',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 15))),
                pw.Expanded(
                    flex: 2,
                    child: pw.Text('Ukuran',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 15))),
                pw.Expanded(
                    flex: 2,
                    child: pw.Text('Qty',
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 15))),
                pw.Expanded(
                    flex: 3,
                    child: pw.Text('Harga',
                        textAlign: pw.TextAlign.right,
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 15))),
              ],
            ),
            pw.Divider(thickness: 0.3),
            ...cartItems.map((item) {
  final qtyDus = item.quantity / 12;
  final hargaDus = item.total / 12;
  final name = '${item.idTipe} - ${item.productName}';

  return pw.Column(
    children: [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            flex: 5,
            child: pw.Text(name,
                style: const pw.TextStyle(fontSize: 14)),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Padding(
              padding: const pw.EdgeInsets.only(left: 8),
              child: pw.Text(item.size,
                  style: const pw.TextStyle(fontSize: 14)),
            ),
          ),
          pw.Expanded(
            flex: 2,
            child: pw.Padding(
              padding: const pw.EdgeInsets.only(left: 6),
              child: pw.Text(qtyDus.toStringAsFixed(2),
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 14)),
            ),
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Padding(
              padding: const pw.EdgeInsets.only(left: 6),
              child: pw.Text(currencyFormatter.format(hargaDus),
                  textAlign: pw.TextAlign.right,
                  style: const pw.TextStyle(fontSize: 14)),
            ),
          ),
        ],
      ),
      pw.Divider(thickness: 0.3),
    ],
  );
}),

            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Lusin',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 12)),
                pw.Text(computedLusin.toStringAsFixed(2),
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 12)),
              ],
            ),
            if (totalDiskonFinal > 0)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total Diskon',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 15,
                          color: PdfColors.red)),
                  pw.Text(currencyFormatter.format(totalDiskonFinal),
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 15,
                          color: PdfColors.red)),
                ],
              ),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 15)),
                pw.Text(currencyFormatter.format(grandTotal),
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 15)),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Text('Notes:',
                style:
                    pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
            pw.Text('Barang yang sudah dibeli tidak dapat dikembalikan.',
                style: pw.TextStyle(fontSize: 15)),
            pw.SizedBox(height: 8),
            pw.Center(
              child: pw.Text('Terima kasih!',
                  style: pw.TextStyle(
                      fontSize: 15, fontStyle: pw.FontStyle.italic)),
            ),
          ],
        );
      },
    ),
  );

  await Printing.layoutPdf(onLayout: (format) => pdf.save());
}
