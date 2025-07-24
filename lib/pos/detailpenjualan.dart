import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class PaymentMethod {
  final String idAkun;
  final String tipe;
  final String bank;
  final String noAkun;

  PaymentMethod({
    required this.idAkun,
    required this.tipe,
    required this.bank,
    required this.noAkun,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      idAkun: json['id_akun'] ?? '',
      tipe: json['tipe'] ?? '',
      bank: json['bank'] ?? '',
      noAkun: json['no_akun'] ?? '',
    );
  }
}

class Detailpenjualan extends StatefulWidget {
  final Map<String, dynamic> invoice;
  const Detailpenjualan({super.key, required this.invoice});

  @override
  State<Detailpenjualan> createState() => _DetailpenjualanState();
}

class _DetailpenjualanState extends State<Detailpenjualan> {
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
        Uri.parse(
            'https://hayami.id/pos/detail_keluar.php?id_transaksi=$idTransaksi'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            invoiceDetail = data['data'][0];
            isLoading = false;
          });
          print("Data retrieved: ${invoiceDetail}");
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

  Future<List<PaymentMethod>> fetchPaymentMethods() async {
    final url = Uri.parse('https://hayami.id/pos/akun.php');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      if (jsonData['status'] == 'success') {
        List data = jsonData['data'];
        return data
            .map((e) => PaymentMethod.fromJson(e))
            .where((pm) =>
                pm.tipe.toUpperCase() != 'HUTANG' &&
                pm.tipe.toUpperCase() != 'SPLIT')
            .toList();
      } else {
        throw Exception('API gagal: status bukan success');
      }
    } else {
      throw Exception('Gagal load data dari server: ${response.statusCode}');
    }
  }

  Future<bool> submitPembayaran({
    required String idTransaksi,
    required String jumlahBayar,
    required String keterangan,
    required String idAkun,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String? idUser = prefs.getString('id_user') ?? 'system';
    String idCabang = prefs.getString('id_cabang') ?? 'default_cabang';

    final url = Uri.parse('https://hayami.id/pos/bayar.php');

    String jumlahBayarPlain = jumlahBayar.replaceAll('.', '');

    final body = jsonEncode({
      'id_transaksi': idTransaksi,
      'jumlah_bayar': jumlahBayarPlain,
      'keterangan': keterangan,
      'id_akun': idAkun,
      'dibuat_oleh': idUser,
      'id_cabang': idCabang,
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    print('Response status code: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final res = jsonDecode(response.body);
      if (res['status'] == 'success') {
        return true;
      } else {
        throw Exception(res['message']);
      }
    } else {
      throw Exception('Gagal menghubungi server: ${response.statusCode}');
    }
  }

  void showBayarHutangDialog(BuildContext context) {
    final TextEditingController jumlahBayarController = TextEditingController();
    final TextEditingController keteranganController = TextEditingController();
    String today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final selectedPaymentMethodNotifier = ValueNotifier<PaymentMethod?>(null);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Bayar Hutang',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: FutureBuilder<List<PaymentMethod>>(
          future: fetchPaymentMethods(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                  height: 100,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Text('Gagal memuat metode pembayaran');
            } else {
              final paymentMethods = snapshot.data!;
              if (selectedPaymentMethodNotifier.value == null &&
                  paymentMethods.isNotEmpty) {
                selectedPaymentMethodNotifier.value = paymentMethods[0];
              }

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'ID Transaksi',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      controller: TextEditingController(
                        text: invoiceDetail['id_transaksi'] ?? '-',
                      ),
                    ),
                    SizedBox(height: 12),
                    TextField(
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Tgl Bayar',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      controller: TextEditingController(text: today),
                    ),
                    SizedBox(height: 12),
                    ValueListenableBuilder<PaymentMethod?>(
                      valueListenable: selectedPaymentMethodNotifier,
                      builder: (context, selected, _) {
                        return DropdownButtonFormField<PaymentMethod>(
                          decoration: InputDecoration(
                            labelText: 'Metode Pembayaran',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          value: selected,
                          items: paymentMethods
                              .map(
                                (pm) => DropdownMenuItem(
                                  value: pm,
                                  child: Text(pm.noAkun.isNotEmpty
                                      ? '${pm.bank} - ${pm.noAkun}'
                                      : pm.bank),
                                ),
                              )
                              .toList(),
                          onChanged: (pm) {
                            if (pm != null) {
                              selectedPaymentMethodNotifier.value = pm;
                            }
                          },
                        );
                      },
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: jumlahBayarController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Jumlah Bayar',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onChanged: (value) {
                        String digitsOnly = value.replaceAll('.', '');

                        if (digitsOnly.isEmpty) {
                          jumlahBayarController.value = TextEditingValue(
                            text: '',
                            selection: TextSelection.collapsed(offset: 0),
                          );
                          return;
                        }

                        final buffer = StringBuffer();
                        int count = 0;
                        for (int i = digitsOnly.length - 1; i >= 0; i--) {
                          buffer.write(digitsOnly[i]);
                          count++;
                          if (count % 3 == 0 && i != 0) {
                            buffer.write('.');
                          }
                        }
                        String formatted =
                            buffer.toString().split('').reversed.join('');

                        jumlahBayarController.value = TextEditingValue(
                          text: formatted,
                          selection:
                              TextSelection.collapsed(offset: formatted.length),
                        );
                      },
                    ),
                    SizedBox(height: 12),
                    TextField(
                      controller: keteranganController,
                      decoration: InputDecoration(
                        labelText: 'Keterangan',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      maxLines: 2,
                    ),
                  ],
                ),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              String jumlahBayarStr = jumlahBayarController.text.trim();
              String keterangan = keteranganController.text.trim();
              final selected = selectedPaymentMethodNotifier.value;

              if (jumlahBayarStr.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Jumlah bayar tidak boleh kosong')),
                );
                return;
              }

              if (selected == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Pilih metode pembayaran')),
                );
                return;
              }

              // Parsing jumlah bayar ke double, hilangkan tanda titik ribuan dulu
              double jumlahBayar =
                  double.tryParse(jumlahBayarStr.replaceAll('.', '')) ?? 0;

              // Ambil sisa bayar dari invoiceDetail, parse juga ke double
              double sisaBayar = double.tryParse(
                      invoiceDetail['sisa_bayar']?.toString() ?? '0') ??
                  0;

              if (jumlahBayar > sisaBayar) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: Text('Nominal melebihi outstanding'),
                    content: Text(
                        'Nominal tidak boleh melebihi outstanding yang tersisa.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
                return;
              }

              try {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => Center(child: CircularProgressIndicator()),
                );

                bool success = await submitPembayaran(
                  idTransaksi: invoiceDetail['id_transaksi'] ?? '',
                  jumlahBayar: jumlahBayarStr,
                  keterangan: keterangan,
                  idAkun: selected.idAkun,
                );

                Navigator.pop(context); // tutup loading
                Navigator.pop(context); // tutup dialog bayar hutang
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Pembayaran berhasil disimpan:\nRp $jumlahBayarStr - ${selected.tipe} (${selected.bank} - ${selected.noAkun})',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  fetchInvoiceDetail();
                }
              } catch (e) {
                Navigator.pop(context); // tutup loading
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Gagal simpan pembayaran: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('Simpan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
    final tglTransaksi =
        invoiceDetail['tgl_transaksi'] ?? '0000-00-00 00:00:00';
    final dateTime = DateTime.tryParse(tglTransaksi);
    final dateFormatter = DateFormat('dd MMM yyyy');
    final timeFormatter = DateFormat('HH:mm');
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    final ByteData logoBytes =
        await rootBundle.load('assets/image/hayamilogo.png');
    final Uint8List logoImage = logoBytes.buffer.asUint8List();

    final akunPembayaran =
        invoiceDetail['akun']?.toString().toUpperCase().trim() ?? '';
    String paymentMethod = akunPembayaran;

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
                  pw.Text(idTransaksi ?? 'SO/xxxx/yyyy',
                      style: pw.TextStyle(fontSize: 15)),
                ],
              ),
              pw.SizedBox(height: 3),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Collected By', style: pw.TextStyle(fontSize: 15)),
                  pw.Text(invoiceDetail['dibuat_oleh'] ?? 'Unknown',
                      style: pw.TextStyle(fontSize: 15)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Metode Pembayaran',
                      style: pw.TextStyle(fontSize: 15)),
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
                      padding: const pw.EdgeInsets.only(left: 6),
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
              ...cartItems.map((item) {
                return pw.Column(
                  children: [
                    pw.Row(
                      children: [
                        pw.Expanded(
                            flex: 5,
                            child: pw.Text(
                                '${item.idTipe} - ${item.productName}',
                                style: pw.TextStyle(fontSize: 15))),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Padding(
                            padding: const pw.EdgeInsets.only(left: 12),
                            child: pw.Text(item.size,
                                style: pw.TextStyle(fontSize: 15)),
                          ),
                        ),
                        pw.Expanded(
                            flex: 2,
                            child: pw.Text(item.quantity.toStringAsFixed(2),
                                textAlign: pw.TextAlign.center,
                                style: pw.TextStyle(fontSize: 15))),
                        pw.Expanded(
                            flex: 3,
                            child: pw.Text(currencyFormatter.format(item.total),
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(fontSize: 15))),
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
                  style: pw.TextStyle(
                      fontSize: 15, fontWeight: pw.FontWeight.bold)),
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
            color: Colors.blue,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () {
            Navigator.pop(context);
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
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    SizedBox(height: 10),
                    Text('Tanggal: ${invoiceDetail["tgl_transaksi"] ?? '-'}'),
                    SizedBox(height: 10),
                    Text(
                        'Total: Rp ${formatRupiah(double.tryParse(invoiceDetail["total_invoice"] ?? '0') ?? 0)}'),
                    SizedBox(height: 10),
                    Text(
                        'Diskon: ${invoiceDetail["disc_invoice"] != null && invoiceDetail["disc_invoice"].isNotEmpty && invoiceDetail["disc"] != null && invoiceDetail["disc"].isNotEmpty ? formatRupiah((double.tryParse(invoiceDetail["disc_invoice"]) ?? 0.0) + (double.tryParse(invoiceDetail["disc"]) ?? 0.0)) : invoiceDetail["disc_invoice"] != null && invoiceDetail["disc_invoice"].isNotEmpty ? formatRupiah(double.tryParse(invoiceDetail["disc_invoice"]) ?? 0.0) : invoiceDetail["disc"] != null && invoiceDetail["disc"].isNotEmpty ? formatRupiah(double.tryParse(invoiceDetail["disc"]) ?? 0.0) : '-'}'),
                    SizedBox(height: 10),
                    if ((invoiceDetail['akun']?.toString().toUpperCase() ??
                            '') ==
                        'HUTANG')
                      Text(
                        'Outstanding: Rp ${formatRupiah(double.tryParse(invoiceDetail["sisa_bayar"] ?? '0') ?? 0)}',
                      ),
                    SizedBox(height: 20),
                    ...List.generate(invoiceDetail["items"]?.length ?? 0,
                        (index) {
                      final item = invoiceDetail["items"][index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 8.0,
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item["id_bahan"] ?? '-'}',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    SizedBox(height: 4),
                                    Text('Model: ${item["model"] ?? '-'}',
                                        style: TextStyle(fontSize: 12)),
                                    SizedBox(height: 4),
                                    Text('Ukuran: ${item["ukuran"] ?? '-'}',
                                        style: TextStyle(fontSize: 12)),
                                    SizedBox(height: 4),
                                    Text('Qty: ${item["qty"] ?? '-'} pcs',
                                        style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Rp ${formatRupiah(double.tryParse(item["total"] ?? '0') ?? 0)}',
                                      style: TextStyle(
                                        fontSize: 12,
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
                    }),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                List<OrderItem> cartItems =
                                    invoiceDetail["items"]
                                            ?.map<OrderItem>((item) {
                                          return OrderItem(
                                            idTipe: item["id_bahan"] ?? '-',
                                            productName: item["model"] ?? '-',
                                            size: item["ukuran"] ?? '-',
                                            quantity: double.tryParse(
                                                    item["qty"]?.toString() ??
                                                        '0') ??
                                                0,
                                            total: double.tryParse(
                                                    item["total"]?.toString() ??
                                                        '0') ??
                                                0,
                                          );
                                        }).toList() ??
                                        [];

                                double grandTotal = double.tryParse(
                                        invoiceDetail["total_invoice"] ??
                                            '0') ??
                                    0;
                                double totalDiskon = double.tryParse(
                                        invoiceDetail["disc_invoice"] ?? '0') ??
                                    0;
                                double newDiscount = double.tryParse(
                                        invoiceDetail["disc"] ?? '0') ??
                                    0;
                                await generateAndPrintStrukPdf(
                                  cartItems: cartItems,
                                  grandTotal: grandTotal,
                                  totalDiskon: totalDiskon,
                                  newDiscount: newDiscount,
                                  totalLusin: 0,
                                  selectedPaymentAccount: {},
                                  splitPayments: [],
                                  collectedBy: 'Admin',
                                  idTransaksi: invoiceDetail["id_transaksi"],
                                );

                                print("Print Button Pressed");
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Print',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white),
                              ),
                            ),
                          ),
                          if ((invoiceDetail['akun']
                                      ?.toString()
                                      .toUpperCase() ==
                                  'HUTANG') &&
                              (double.tryParse(
                                          invoiceDetail['sisa_bayar'] ?? '0') ??
                                      0) >
                                  0)
                            Padding(
                              padding: const EdgeInsets.only(top: 12.0),
                              child: SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Panggil fungsi dialog
                                    showBayarHutangDialog(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Bayar',
                                    style: TextStyle(
                                        fontSize: 16, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
