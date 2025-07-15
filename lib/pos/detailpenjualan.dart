import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // Import intl for formatting
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class OrderItem {
  final String idTipe;
  final String productName;
  final String size;
  final double quantity;
  final double total;

  OrderItem({
    required this.idTipe,
    required this.productName,
    required this.size,
    required this.quantity,
    required this.total,
  });
}

class DetailBarangMasuk extends StatefulWidget {
  final Map<String, dynamic> invoice;
  const DetailBarangMasuk({super.key, required this.invoice});

  @override
  State<DetailBarangMasuk> createState() => _DetailBarangMasukState();
}

class _DetailBarangMasukState extends State<DetailBarangMasuk> {
  bool isLoading = true;
  Map<String, dynamic> invoiceDetail = {};

  @override
  void initState() {
    super.initState();
    fetchInvoiceDetail();
  }

Future<void> fetchInvoiceDetail() async {
  final idTransaksi = widget.invoice['id_transaksi'];
  try {
    final response = await http.get(
      Uri.parse('http://192.168.1.4/pos/detail_keluar.php?id_transaksi=$idTransaksi'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data['status'] == 'success') {
        setState(() {
          invoiceDetail = data['data'][0];
          isLoading = false;
        });
        print("Data retrieved: ${invoiceDetail}");  // Debugging data
      } else {
        throw Exception('Data tidak ditemukan');
      }
    } else {
      throw Exception('Gagal mengambil data');
    }
  } catch (e) {
    print("Error: $e");
    setState(() {
      isLoading = false;
    });
  }
}

  // Function to format number into Indonesian currency with thousands separators
  String formatRupiah(double number) {
    final formatter = NumberFormat("#,###", "id_ID");
    return formatter.format(number);
  }

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

  final pdf = pw.Document();
  final tglTransaksi = invoiceDetail['tgl_transaksi'] ?? '0000-00-00 00:00:00';
final dateTime = DateTime.tryParse(tglTransaksi);
  final dateFormatter = DateFormat('dd MMM yyyy');
  final timeFormatter = DateFormat('HH:mm');
  final currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

  final ByteData logoBytes = await rootBundle.load('assets/image/hayamilogo.png');
  final Uint8List logoImage = logoBytes.buffer.asUint8List();

  // Get payment method from invoice detail
  final akunPembayaran = invoiceDetail['akun']?.toString().toUpperCase().trim() ?? '';
  String paymentMethod = akunPembayaran;

  // Handle the "SPLIT" payment method case
  if (akunPembayaran == "SPLIT" && splitPayments.isNotEmpty) {
    paymentMethod += ' (Split Payments)';
  }

  final double computedLusin =
      cartItems.fold(0.0, (sum, item) => sum + (item.quantity / 12));

  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
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
    pw.Text(dateFormatter.format(dateTime!),
        style: pw.TextStyle(fontSize: 15)),
    pw.Text(timeFormatter.format(dateTime!),
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
                pw.Text(invoiceDetail['dibuat_oleh'] ?? 'Unknown', style: pw.TextStyle(fontSize: 15)),
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
  child: pw.Padding(
    padding: const pw.EdgeInsets.only(left: 6), // sama dengan isi
    child: pw.Text('Ukuran',
        style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold, fontSize: 15)),
  ),
),

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
            // Menambahkan Divider untuk pemisah antara item barang
...cartItems.map((item) {
  return pw.Column(
    children: [
      pw.Row(
        children: [
          pw.Expanded(
            flex: 5,
            child: pw.Text('${item.idTipe} - ${item.productName}', style: pw.TextStyle(fontSize: 15))
          ),
          pw.Expanded(
  flex: 2,
  child: pw.Padding(
    padding: const pw.EdgeInsets.only(left: 12), // atau coba 8
    child: pw.Text(item.size, style: pw.TextStyle(fontSize: 15)),
  ),
),
          pw.Expanded(
            flex: 2,
            child: pw.Text(item.quantity.toStringAsFixed(2), textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 15))
          ),
          pw.Expanded(
            flex: 3,
            child: pw.Text(currencyFormatter.format(item.total), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 15))
          ),
        ],
      ),
      // Tambahkan Divider setelah tiap item
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
              pw.Row(
  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  children: [
    pw.Text('Grand Total',
        style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold, fontSize: 16)),
    pw.Text(currencyFormatter.format(grandTotal),
        style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold, fontSize: 16)),
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

  // Print PDF
  await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save());
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Detail Transaksi',
          style: TextStyle(
            color: Colors.blue, // Mengubah warna teks id_transaksi menjadi biru
          ),
        ),
        backgroundColor: Colors.white, // Background appbar berwarna putih
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.blue), // Mengubah warna ikon kembali menjadi biru
          onPressed: () {
            Navigator.pop(context);  // Menutup halaman saat tombol back ditekan
          },
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID Transaksi: ${invoiceDetail["id_transaksi"] ?? '-'}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    SizedBox(height: 10),
                    Text('Tanggal: ${invoiceDetail["tgl_transaksi"] ?? '-'}'),
                    SizedBox(height: 10),
                    Text('Total: Rp ${formatRupiah(double.tryParse(invoiceDetail["total_invoice"] ?? '0') ?? 0)}'),
                    SizedBox(height: 10),
                    Text(
                      'Diskon: ${invoiceDetail["disc_invoice"] != null && invoiceDetail["disc_invoice"].isNotEmpty && invoiceDetail["disc"] != null && invoiceDetail["disc"].isNotEmpty 
    ? formatRupiah((double.tryParse(invoiceDetail["disc_invoice"]) ?? 0.0) + (double.tryParse(invoiceDetail["disc"]) ?? 0.0)) 
    : invoiceDetail["disc_invoice"] != null && invoiceDetail["disc_invoice"].isNotEmpty 
      ? formatRupiah(double.tryParse(invoiceDetail["disc_invoice"]) ?? 0.0) 
      : invoiceDetail["disc"] != null && invoiceDetail["disc"].isNotEmpty 
        ? formatRupiah(double.tryParse(invoiceDetail["disc"]) ?? 0.0) 
        : '-'}'
),
                    SizedBox(height: 20),
                    ListView.builder(
                      shrinkWrap: true,
                      itemCount: invoiceDetail["items"]?.length ?? 0,
                      itemBuilder: (context, index) {
                        final item = invoiceDetail["items"][index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12.0,  // Reduce horizontal padding
                              vertical: 8.0,    // Reduce vertical padding
                            ),
                            title: Row(
                              children: [
                                // Left side with item info
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${item["id_bahan"] ?? '-'}',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14), // Make id_bahan bold
                                      ),
                                      SizedBox(height: 4),
                                      Text('Model: ${item["model"] ?? '-'}', style: TextStyle(fontSize: 12)),
                                      SizedBox(height: 4),
                                      Text('Ukuran: ${item["ukuran"] ?? '-'}', style: TextStyle(fontSize: 12)),
                                      SizedBox(height: 4),
                                      Text('Qty: ${item["qty"] ?? '-'} pcs', style: TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                                // Right side with total price
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Rp ${formatRupiah(double.tryParse(item["total"] ?? '0') ?? 0)}',
                                        style: TextStyle(
                                          fontSize: 12, // Smaller font size for total
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Implement aksi retur di sini (tapi tidak perlu fungsi)
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Retur',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    // Adding the Print button
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            // Siapkan data untuk dicetak
                            List<OrderItem> cartItems = invoiceDetail["items"]?.map<OrderItem>((item) {
  return OrderItem(
    idTipe: item["id_bahan"] ?? '-',
    productName: item["model"] ?? '-',
    size: item["ukuran"] ?? '-',
    quantity: double.tryParse(item["qty"]?.toString() ?? '0') ?? 0,
    total: double.tryParse(item["total"]?.toString() ?? '0') ?? 0,
  );
}).toList() ?? [];

                            double grandTotal = double.tryParse(invoiceDetail["total_invoice"] ?? '0') ?? 0;
                            double totalDiskon = double.tryParse(invoiceDetail["disc_invoice"] ?? '0') ?? 0;
                            double newDiscount = double.tryParse(invoiceDetail["disc"] ?? '0') ?? 0;

                            // Menghubungkan tombol print dengan fungsi pencetakan
                            await generateAndPrintStrukPdf(
                              cartItems: cartItems,
                              grandTotal: grandTotal,
                              totalDiskon: totalDiskon,
                              newDiscount: newDiscount,
                              totalLusin: 0, // Bisa disesuaikan
                              selectedPaymentAccount: {}, // Jika perlu
                              splitPayments: [], // Jika perlu
                              collectedBy: 'Admin', // Sesuaikan dengan siapa yang mengumpulkan
                              idTransaksi: invoiceDetail["id_transaksi"],
                            );

                            print("Print Button Pressed");
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent, // Different color for print button
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Print',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
