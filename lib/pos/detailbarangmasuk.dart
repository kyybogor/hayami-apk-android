import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hayami_app/pos/barangmasuk.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart'; 
import 'package:pdf/widgets.dart' as pw; 
import 'package:printing/printing.dart'; 
import 'package:excel/excel.dart' hide Border; 
import 'package:path_provider/path_provider.dart'; 
import 'package:permission_handler/permission_handler.dart'; 
import 'dart:io'; 
import 'dart:typed_data'; 
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio; 

class Detailbarangmasuk extends StatefulWidget {
  final Map<String, dynamic> invoice;

  const Detailbarangmasuk({super.key, required this.invoice});

  @override
  State<Detailbarangmasuk> createState() => _DetailbarangmasukState();
}

class _DetailbarangmasukState extends State<Detailbarangmasuk> {
  List<dynamic> barang = [];
  bool isLoading = false;
  Map<int, TextEditingController> stockControllers = {};
  final Map<int, TextEditingController> lusinControllers = {};
  final Map<int, TextEditingController> pcsControllers = {};
  bool isApproving = false;

  @override
  void initState() {
    super.initState();
    fetchProduct();
  }

  void showPrintBarcodeDialog() {
    final selectedItems = <Map<String, dynamic>>[]; // Barang yang dipilih
    final TextEditingController qtyController = TextEditingController();
    bool isSelectAll = false; // Untuk menentukan apakah semua barang dipilih

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Print Barcode"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: "Qty per Barcode (PCS)",
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text("Pilih Barang:"),
                    // Pilihan untuk memilih semua barang
                    CheckboxListTile(
                      title: const Text("Pilih Semua Barang"),
                      value: isSelectAll,
                      onChanged: (bool? value) {
                        setState(() {
                          isSelectAll = value ?? false;
                          if (isSelectAll) {
                            selectedItems
                                .addAll(barang.cast<Map<String, dynamic>>());
                          } else {
                            selectedItems.clear();
                          }
                        });
                      },
                    ),
                    // Menampilkan daftar barang dengan stok
                    ...barang.map((item) {
                      final isSelected = selectedItems.contains(item);
                      return CheckboxListTile(
                        title: Text(item['nama_barang']),
                        subtitle: Text(
                            "Model: ${item['model']} | Stok: ${item['jumlah']} ${item['uom']}"),
                        value: isSelected,
                        onChanged: (bool? val) {
                          setState(() {
                            if (val == true) {
                              selectedItems.add(item);
                            } else {
                              selectedItems.remove(item);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Batal"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final qty = int.tryParse(qtyController.text);
                    if (qty == null || qty <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Qty tidak valid")),
                      );
                      return;
                    }
                    Navigator.pop(context);
                    generateAndPrintBarcodePdf(selectedItems, qty);
                  },
                  child: const Text("Cetak Barcode"),
                ),
              ],
            );
          },
        );
      },
    );
  }

Future<void> generateExcelReport(
  BuildContext context,
  String idTransaksi,
) async {
  final prefs = await SharedPreferences.getInstance();
  final idCabang = prefs.getString('id_cabang') ?? '';
  final url = 'https://hayami.id/pos/detail_masuk.php?id_cabang=$idCabang'; 
  final response = await http.get(Uri.parse(url));

  if (response.statusCode != 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Gagal mengambil data dari server.")),
    );
    return;
  }

  final data = json.decode(response.body);
  final transaksiList = data['data'];

  final transaksi = transaksiList.firstWhere(
    (t) => t['id_transaksi'] == idTransaksi,
    orElse: () => null,
  );

  if (transaksi == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Transaksi dengan ID $idTransaksi tidak ditemukan.")),
    );
    return;
  }

  final workbook = xlsio.Workbook();
  final sheet = workbook.worksheets[0];
  sheet.name = 'Laporan Barang Masuk';

  // Buat style untuk header
  final headerStyle = workbook.styles.add('headerStyle');
  headerStyle.bold = true;
  headerStyle.hAlign = xlsio.HAlignType.center;
  headerStyle.vAlign = xlsio.VAlignType.center;
  headerStyle.backColor = '#D9E1F2';
  headerStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

  // Style untuk info transaksi
  final infoStyle = workbook.styles.add('infoStyle');
  infoStyle.bold = true;
  infoStyle.hAlign = xlsio.HAlignType.left;
  infoStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

  // Style untuk cell biasa
  final cellStyle = workbook.styles.add('cellStyle');
  cellStyle.hAlign = xlsio.HAlignType.center;
  cellStyle.vAlign = xlsio.VAlignType.center;
  cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

  int rowIndex = 1;

  // Tulis info transaksi (3 baris)
  final transaksiData = [
    ['ID Transaksi', transaksi['id_transaksi'] ?? ''],
    ['Tanggal Transaksi', transaksi['tgl_transaksi'] ?? ''],
    ['Keterangan', transaksi['keterangan'] ?? ''],
  ];

  for (var row in transaksiData) {
    sheet.getRangeByIndex(rowIndex, 1).setText(row[0]);
    sheet.getRangeByIndex(rowIndex, 2).setText(row[1]);

    sheet.getRangeByIndex(rowIndex, 1).cellStyle = infoStyle;
    sheet.getRangeByIndex(rowIndex, 2).cellStyle = infoStyle;

    rowIndex++;
  }

  rowIndex++; // kosongkan satu baris

  // Header tabel barang
  final headers = [
    'No',
    'ID Bahan',
    'Model',
    'Ukuran',
    'Qty',
    'Harga',
    'Total',
  ];

  for (int col = 0; col < headers.length; col++) {
    final cell = sheet.getRangeByIndex(rowIndex, col + 1);
    cell.setText(headers[col]);
    cell.cellStyle = headerStyle;
  }

  rowIndex++;

  // Data barang
  int no = 1;
  for (var item in transaksi['items']) {
    sheet.getRangeByIndex(rowIndex, 1).setNumber(no.toDouble());
    sheet.getRangeByIndex(rowIndex, 2).setText(item['id_bahan']?.toString() ?? '');
    sheet.getRangeByIndex(rowIndex, 3).setText(item['model']?.toString() ?? '');
    sheet.getRangeByIndex(rowIndex, 4).setText(item['ukuran']?.toString() ?? '');

    // Qty, Harga, Total as number if possible
    final qty = item['qty'];
    final harga = item['harga'];
    final total = item['total'];

    if (qty != null && qty.toString().isNotEmpty) {
      sheet.getRangeByIndex(rowIndex, 5).setNumber(double.tryParse(qty.toString()) ?? 0);
    } else {
      sheet.getRangeByIndex(rowIndex, 5).setText('');
    }
    if (harga != null && harga.toString().isNotEmpty) {
      sheet.getRangeByIndex(rowIndex, 6).setNumber(double.tryParse(harga.toString()) ?? 0);
    } else {
      sheet.getRangeByIndex(rowIndex, 6).setText('');
    }
    if (total != null && total.toString().isNotEmpty) {
      sheet.getRangeByIndex(rowIndex, 7).setNumber(double.tryParse(total.toString()) ?? 0);
    } else {
      sheet.getRangeByIndex(rowIndex, 7).setText('');
    }

    // Set style dan border
    for (int col = 1; col <= headers.length; col++) {
      sheet.getRangeByIndex(rowIndex, col).cellStyle = cellStyle;
    }

    no++;
    rowIndex++;
  }

  // Autofit kolom
  for (int col = 1; col <= headers.length; col++) {
    sheet.autoFitColumn(col);
  }

  // Simpan file
  try {
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final directory = await getExternalStorageDirectory();
    final filePath = '${directory!.path}/StockDetail_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Excel berhasil disimpan di: $filePath")),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Gagal menyimpan file: $e")),
    );
  }
}

Future<void> generateAndPrintBarcodePdf(
    List<Map<String, dynamic>> items, int qtyPerBarcode) async {
  final pdf = pw.Document();
  int totalPages = 0;

  const int maxColumns = 3;
  const double spacing = 10;

  for (var item in items) {
final rawBarcode = item['barcode'] ?? '';
if (rawBarcode.isEmpty) continue;
if (rawBarcode.startsWith('0')) continue;

final barcodeBase = rawBarcode;

    print('Cetak barcode: $barcodeBase (Qty: $qtyPerBarcode)');

    final stockLusin = double.tryParse(item['jumlah'] ?? '0') ?? 0;
    final stockPcs = (stockLusin).toInt();

    int remaining = stockPcs;
    int barcodeCount = (remaining / qtyPerBarcode).ceil();

    final List<pw.Widget> barcodeWidgets = [];

    for (int i = 0; i < barcodeCount; i++) {
      final qty = remaining >= qtyPerBarcode ? qtyPerBarcode : remaining;
      final qtyString = qty.toString().padLeft(2, '0');
      final fullBarcode = '$barcodeBase$qtyString';

      remaining -= qty;

      barcodeWidgets.add(
        pw.Container(
          width: (PdfPageFormat.a4.availableWidth - spacing * (maxColumns - 1)) / maxColumns,
          padding: const pw.EdgeInsets.all(4),
          child: pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                '${item['nama_barang'] ?? ''} x$qty',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '${item['model'] ?? ''} ${item['ukuran'] ?? ''}',
                style: pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 8),
              pw.BarcodeWidget(
                barcode: pw.Barcode.code128(),
                data: fullBarcode,
                width: 150,
                height: 50,
                drawText: false,
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                fullBarcode,
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    // Bagi ke dalam halaman jika terlalu banyak
    const int itemsPerPage = 21; // 7 baris * 3 kolom per halaman
    for (int i = 0; i < barcodeWidgets.length; i += itemsPerPage) {
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: barcodeWidgets.sublist(
                i,
                (i + itemsPerPage > barcodeWidgets.length)
                    ? barcodeWidgets.length
                    : i + itemsPerPage,
              ),
            );
          },
        ),
      );
      totalPages++;
    }
  }

  if (totalPages == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tidak ada barcode valid untuk dicetak.")),
    );
    return;
  }

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}


  Future<void> fetchProduct() async {
    setState(() {
      isLoading = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final idCabang = prefs.getString('id_cabang') ?? '';


    final idTransaksi = widget.invoice['id']?.toString() ?? '';
    final url = Uri.parse(
        "https://hayami.id/pos/masuk_detail.php?id_transaksi=$idTransaksi&id_cabang=$idCabang");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          final List<dynamic> produkList = jsonData['data'];

          final prefs = await SharedPreferences.getInstance();
final String idCabang = prefs.getString('id_cabang') ?? '1';


          // Mengambil data stock
          final stockResponse =
              await http.get(Uri.parse('https://hayami.id/pos/stock.php?id_cabang=$idCabang'));
          final List<dynamic> stockList =
              json.decode(stockResponse.body)['data'];

          // Menyamakan data produk dengan stock
          final List<Map<String, dynamic>> parsedProduk =
              produkList.map<Map<String, dynamic>>((item) {
            final matchingStock = stockList.firstWhere(
              (stockItem) =>
                  stockItem['id_bahan'] == item['id_product'] && 
                  stockItem['model'] == item['model'] && 
                  stockItem['ukuran'] == item['ukuran'], 
              orElse: () => null,
            );

            final barcode =
                matchingStock != null ? matchingStock['barcode'] : '';

            final qty = double.tryParse(item['qty']?.toString() ?? '0') ?? 0;
            final harga =
                double.tryParse(item['harga']?.toString() ?? '0') ?? 0;
            final total =
                double.tryParse(item['total']?.toString() ?? '0') ?? 0;

            return {
              'nama_barang': item['id_product'] ?? 'Tidak Diketahui',
              'uom': item['uom'] ?? 'Pcs',
              'model': item['model'] ?? '',
              'ukuran': item['ukuran'] ?? 'All Size',
              'jumlah': qty.toString(),
              'harga': harga.toString(),
              'total': total.toString(),
              'barcode': barcode,
            };
          }).toList();

          setState(() {
            barang = parsedProduk;
          });
        }
      }
    } catch (e) {
      print("Error saat mengambil data: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  double getTotalSemuaBarang() {
    return barang.fold(0, (sum, item) {
      final harga = double.tryParse(item['total']?.toString() ?? '0') ?? 0;
      return sum + harga;
    });
  }

  String formatRupiah(double number) {
    final formatter = NumberFormat("#,###", "id_ID");
    return formatter.format(number);
  }

Future<void> handleApprove() async {
  setState(() {
    isApproving = true; // Menandakan proses dimulai dan tombol dinonaktifkan
  });

  final idTransaksi = widget.invoice['id']?.toString() ?? '';
  final prefs = await SharedPreferences.getInstance();
  final idCabang = prefs.getString('id_cabang') ?? '';

  // Konfirmasi user
  final shouldApprove = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Konfirmasi"),
      content: const Text("Apakah Anda yakin ingin approve transaksi ini?"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("Tidak"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text("Ya"),
        ),
      ],
    ),
  );

  if (shouldApprove != true) {
    setState(() {
      isApproving = false; // Kembalikan tombol setelah cancel
    });
    return;  // Jika user memilih 'Tidak', batalkan proses
  }

  // Siapkan data barang yang dikirim ke backend
  final List<Map<String, dynamic>> barangDikirim = barang.map((item) {
    final lusin = item['stock_asli_converted_lusin'] ?? 0;
    final pcs = item['stock_asli_converted_pcs'] ?? 0;
    return {
      'id_product': item['nama_barang'],
      'model': item['model'],
      'ukuran': item['ukuran'],
      'harga': item['harga'],
      'stock': (double.tryParse(item['jumlah']?.toString() ?? '0') ?? 0) * 12, // Menghitung qty otomatis
      'image': item['image'] ?? '',
    };
  }).toList();

  final url = Uri.parse('https://hayami.id/pos/inbond.php');
  final body = json.encode({
    'id_transaksi': idTransaksi,
    'id_cabang': idCabang,
    'barang': barangDikirim,
  });

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            widget.invoice['status'] = 's'; // Update status invoice
            isApproving = false;  // Tombol diaktifkan kembali setelah berhasil
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => Barangmasuk()),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Barang berhasil di-approve")),
          );
        } else {
          setState(() {
            isApproving = false; // Tombol diaktifkan kembali jika gagal
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal: ${data['message']}")),
          );
        }
      } catch (e) {
        debugPrint("Response bukan JSON: ${response.body}");
        setState(() {
          isApproving = false; // Tombol diaktifkan kembali setelah error
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Format JSON tidak valid: $e")),
        );
      }
    } else {
      setState(() {
        isApproving = false; // Tombol diaktifkan kembali setelah gagal
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Gagal terhubung ke server.")),
      );
    }
  } catch (e) {
    setState(() {
      isApproving = false; // Tombol diaktifkan kembali jika terjadi error
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Terjadi error: $e")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Detail Barang Masuk",
            style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : barang.isEmpty
                    ? const Center(child: Text("Tidak ada barang."))
                    : // Pastikan kamu mendeklarasikan controller di luar itemBuilder agar tetap persisten

ListView.builder(
  padding: const EdgeInsets.all(16),
  itemCount: barang.length,
  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag, // ⬅ ini penting
  itemBuilder: (context, index) {
    final item = barang[index];

    // Pastikan controller sudah disiapkan sebelumnya
    lusinControllers.putIfAbsent(index, () => TextEditingController());
    pcsControllers.putIfAbsent(index, () => TextEditingController());

    return Card(
      child: ListTile(
        title: Text(item['nama_barang'] ?? 'Tidak Diketahui'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item['model'] != null && item['model'].toString().isNotEmpty)
              Text("Model: ${item['model']}"),
            Text("Ukuran: ${item['ukuran']}"),
            Text("${item['jumlah']} ${item['uom']}"),
          ],
        ),
        trailing: Text(
          "Rp ${formatRupiah(double.tryParse(item['total'] ?? '0') ?? 0)}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  },
),
          ),
          if (widget.invoice['status']?.toString() == 'd')
            Padding(
  padding: const EdgeInsets.all(16.0),
  child: SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: isApproving ? null : handleApprove,  // Nonaktifkan tombol saat proses
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.indigo, // Warna latar belakang biru
        foregroundColor: Colors.white, // Warna teks putih
        padding: const EdgeInsets.symmetric(vertical: 16), // Padding vertikal
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8), // Sudut tombol melengkung
        ),
      ),
      child: isApproving  // Tampilkan loading saat proses
          ? const CircularProgressIndicator(
              color: Colors.white, // Indikator loading putih
            )
          : const Text(
              'Approve',
              style: TextStyle(fontSize: 16), // Ukuran font tetap 16
            ),
    ),
  ),
),
          if (widget.invoice['status']?.toString() == 's')
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Tombol Print Barcode
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          showPrintBarcodeDialog, // Menampilkan dialog print barcode
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Print Barcode',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),

                  const SizedBox(
                      height:
                          16), // Spasi antara tombol Print Barcode dan Print Excel

                  // Tombol Print Excel
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final idTransaksi =
                            widget.invoice['id']?.toString() ?? '';
                        generateExcelReport(context, idTransaksi);
                      },

                      // Tidak ada aksi untuk sementara
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Print Excel',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}