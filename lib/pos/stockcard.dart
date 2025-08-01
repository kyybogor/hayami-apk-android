import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

void main() => runApp(const MaterialApp(home: StockCard()));

class StockCard extends StatefulWidget {
  const StockCard({super.key});

  @override
  State<StockCard> createState() => _StockCardState();
}

class _StockCardState extends State<StockCard> {
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();
  String? selectedBahan;
  String? selectedModel;
  List<dynamic> bahanList = [];
  List<dynamic> stockCardData = [];
  bool isLoading = false;
  bool isPrinting = false;
  TextEditingController barcodeController = TextEditingController();

@override
void initState() {
  super.initState();
  fetchBahanModel();

  barcodeController.addListener(() {
    setState(() {
      // ini hanya untuk trigger rebuild agar enable/disable field bahan/model
    });
  });
}
Future<void> printAllStockData({
  required List<dynamic> stockCardData,
  required String selectedBahan,
  required String selectedModel,
}) async {
  final pdf = pw.Document();

  final indigo = PdfColor.fromInt(0xFF3F51B5);       
  final indigo200 = PdfColor.fromInt(0xFF9FA8DA);     
  final white = PdfColor.fromInt(0xFFFFFFFF);

  pdf.addPage(
    pw.MultiPage(
      build: (context) => [
        pw.Text('Laporan Stock Card',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('ID Bahan: $selectedBahan'),
        pw.Text('Model   : $selectedModel'),
        pw.SizedBox(height: 12),

        ...stockCardData.map((item) {
          final detail = item['detail'] as List;
          final summary = item['summary'];

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header ukuran + ringkasan
              // Header ukuran + ringkasan dalam bentuk tabel 2 baris
pw.Table(
  border: pw.TableBorder.all(color: PdfColors.black, width: 0.5),
  columnWidths: const {
    0: pw.FlexColumnWidth(2),
    1: pw.FlexColumnWidth(1.5),
    2: pw.FlexColumnWidth(1.5),
    3: pw.FlexColumnWidth(1.5),
    4: pw.FlexColumnWidth(1.5),
  },
  children: [
    pw.TableRow(
      decoration: pw.BoxDecoration(color: indigo),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text('Ukuran', style: pw.TextStyle(color: PdfColors.white)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text('Awal', style: pw.TextStyle(color: PdfColors.white)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text('Masuk', style: pw.TextStyle(color: PdfColors.white)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text('Keluar', style: pw.TextStyle(color: PdfColors.white)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text('Sisa', style: pw.TextStyle(color: PdfColors.white)),
        ),
      ],
    ),
    pw.TableRow(
      decoration: pw.BoxDecoration(color: white),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text('${item['ukuran']}', style: pw.TextStyle(color: PdfColors.black)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text('${summary['stock_awal']}', style: pw.TextStyle(color: PdfColors.black)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text('${summary['masuk']}', style: pw.TextStyle(color: PdfColors.black)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text('${summary['keluar']}', style: pw.TextStyle(color: PdfColors.black)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text('${summary['sisa']}', style: pw.TextStyle(color: PdfColors.black)),
        ),
      ],
    ),
  ],
),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColor.fromInt(0xFF000000), width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(1),
                },
                children: [
                  // Header kolom tabel
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: indigo200),
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Tgl')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('No. Transaksi')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Masuk')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Keluar')),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Total')),
                    ],
                  ),

                  // Data isi tabel
                  ...detail.map<pw.TableRow>((trx) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(trx['tgl'])),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(trx['no_transaksi'])),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('${trx['masuk']}')),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('${trx['keluar']}')),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('${trx['total']}')),
                      ],
                    );
                  }).toList(),
                ],
              ),
              pw.SizedBox(height: 16),
            ],
          );
        }).toList(),
      ],
    ),
  );

  await Printing.layoutPdf(onLayout: (format) => pdf.save());
}

Future<void> handleBarcodePrint({
  required BuildContext context,
  required String idBahan,
  required String model,
  required String ukuran,
  required String qty, // input dari user, misal "03"
}) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
String? idCabang = prefs.getString('id_cabang');
  final url = 'http://192.168.1.25/pos/stock.php?id_cabang=$idCabang';

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['data'];

      final item = data.firstWhere(
        (item) =>
            item['id_bahan'] == idBahan &&
            item['model'] == model &&
            item['ukuran'] == ukuran,
        orElse: () => null,
      );

      if (item == null || item['barcode'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Barcode tidak ditemukan')),
        );
        return;
      }

      final String baseBarcode = item['barcode'];
      final int stock = int.tryParse(item['stock'].toString()) ?? 0;
      final int qtyPerBarcode = int.tryParse(qty) ?? 0;

      if (qtyPerBarcode <= 0 || stock <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Qty atau stok tidak valid')),
        );
        return;
      }

      final int totalQty = stock;
      int remaining = totalQty;
      int barcodeCount = (remaining / qtyPerBarcode).ceil();

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          build: (pw.Context context) {
            return pw.Column(
              children: [
                pw.Container(
                  alignment: pw.Alignment.center,
                  child: pw.Wrap(
                    direction: pw.Axis.horizontal,
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(barcodeCount, (index) {
                      final qtyThis = remaining >= qtyPerBarcode
                          ? qtyPerBarcode
                          : remaining;
                      final qtyStr = qtyThis.toString().padLeft(2, '0');
                      final fullBarcode = "$baseBarcode$qtyStr";

                      remaining -= qtyThis;

                      return pw.Column(
  crossAxisAlignment: pw.CrossAxisAlignment.center,
  children: [
    pw.Text(
      '${item['id_bahan']}  x$qtyThis',
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
    ),
    pw.SizedBox(height: 2),
    pw.Text(
      '${item['model']} ${item['ukuran']}',
      textAlign: pw.TextAlign.center,
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
      textAlign: pw.TextAlign.center,
      style: pw.TextStyle(fontSize: 12),
    ),
  ],
);
                    }),
                  ),
                ),
              ],
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    }
  } catch (e) {
    debugPrint('Error saat print barcode: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terjadi kesalahan saat print')),
    );
  }
}

// Fungsi membangun tampilan 1 barcode (tanpa Page, hanya Widget)
pw.Widget buildBarcodeWidget(dynamic item, String fullBarcode, String qtyLabel) {
  return pw.Container(
    width: 180, // Lebar box barcode
    padding: const pw.EdgeInsets.all(4),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(width: 0.5),
    ),
    child: pw.Column(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          '${item['id_bahan']}  x$qtyLabel',
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          '${item['model']} ${item['ukuran']}',
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
  );
}

Future<void> exportToExcelStyled(
    List<dynamic> data,
    String selectedBahan,
    String selectedModel,
    BuildContext context) async {
  
  final workbook = xlsio.Workbook();
  final sheet = workbook.worksheets[0];
  sheet.name = 'Stock Card';

  sheet.pageSetup.orientation = xlsio.ExcelPageOrientation.landscape;
  sheet.pageSetup.isCenterHorizontally = true;
  sheet.pageSetup.topMargin = 0.5;
  sheet.pageSetup.leftMargin = 0.5;

  final headerStyle = workbook.styles.add('HeaderStyle');
  headerStyle.backColor = '#3F51B5';
  headerStyle.fontColor = '#FFFFFF';
  headerStyle.bold = true;
  headerStyle.hAlign = xlsio.HAlignType.center;

  final summaryStyle = workbook.styles.add('SummaryStyle');
  summaryStyle.backColor = '#FFFFFF';
  summaryStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

  final detailHeaderStyle = workbook.styles.add('DetailHdr');
  detailHeaderStyle.backColor = '#9FA8DA';
  detailHeaderStyle.bold = true;
  detailHeaderStyle.hAlign = xlsio.HAlignType.center;
  detailHeaderStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

  final detailStyle = workbook.styles.add('DetailStyle');
  detailStyle.borders.all.lineStyle = xlsio.LineStyle.thin;

  void setTextWithStyle(xlsio.Worksheet s, int row, int col, String text, xlsio.Style style) {
    final cell = s.getRangeByIndex(row, col);
    cell.setText(text);
    cell.cellStyle = style;
  }

  void setNumberWithStyle(xlsio.Worksheet s, int row, int col, double num, xlsio.Style style) {
    final cell = s.getRangeByIndex(row, col);
    cell.setNumber(num);
    cell.cellStyle = style;
  }

  int row = 1;
  setTextWithStyle(sheet, row, 1, 'Laporan Stock Card', summaryStyle);
  row++;
  sheet.getRangeByIndex(row, 1).setText('ID Bahan: $selectedBahan');
  sheet.getRangeByIndex(row, 3).setText('Model: $selectedModel');
  row += 2;

  for (var item in data) {
    final summary = item['summary'];
    final detail = item['detail'] as List;

    // Header Ringkasan
    setTextWithStyle(sheet, row, 1, 'Ukuran', headerStyle);
    setTextWithStyle(sheet, row, 2, 'Awal', headerStyle);
    setTextWithStyle(sheet, row, 3, 'Masuk', headerStyle);
    setTextWithStyle(sheet, row, 4, 'Keluar', headerStyle);
    setTextWithStyle(sheet, row, 5, 'Sisa', headerStyle);
    row++;

    setTextWithStyle(sheet, row, 1, '${item['ukuran']}', summaryStyle);
    setNumberWithStyle(sheet, row, 2, double.tryParse('${summary['stock_awal']}') ?? 0, summaryStyle);
    setNumberWithStyle(sheet, row, 3, double.tryParse('${summary['masuk']}') ?? 0, summaryStyle);
    setNumberWithStyle(sheet, row, 4, double.tryParse('${summary['keluar']}') ?? 0, summaryStyle);
    setNumberWithStyle(sheet, row, 5, double.tryParse('${summary['sisa']}') ?? 0, summaryStyle);
    row ++;

    setTextWithStyle(sheet, row, 1, 'Tanggal', detailHeaderStyle);
    setTextWithStyle(sheet, row, 2, 'No. Transaksi', detailHeaderStyle);
    setTextWithStyle(sheet, row, 3, 'Masuk', detailHeaderStyle);
    setTextWithStyle(sheet, row, 4, 'Keluar', detailHeaderStyle);
    setTextWithStyle(sheet, row, 5, 'Total', detailHeaderStyle);
    row++;

    for (var trx in detail) {
      setTextWithStyle(sheet, row, 1, trx['tgl'], detailStyle);
      setTextWithStyle(sheet, row, 2, trx['no_transaksi'], detailStyle);
      setNumberWithStyle(sheet, row, 3, double.tryParse('${trx['masuk']}') ?? 0, detailStyle);
      setNumberWithStyle(sheet, row, 4, double.tryParse('${trx['keluar']}') ?? 0, detailStyle);
      setNumberWithStyle(sheet, row, 5, double.tryParse('${trx['total']}') ?? 0, detailStyle);
      row++;
    }

    row += 2;
  }

  for (int i = 1; i <= 5; i++) {
    sheet.autoFitColumn(i);
  }

  final bytes = workbook.saveAsStream();
  workbook.dispose();

final dir = await getExternalStorageDirectory();
if (dir != null) {
  final path = '${dir.path}/stock_card_${DateTime.now().millisecondsSinceEpoch}.xlsx';
  final file = File(path);
  await file.writeAsBytes(bytes, flush: true);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Excel disimpan: $path')),
  );
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Gagal mendapatkan direktori penyimpanan')),
  );
}

}


  Future<void> fetchBahanModel() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idCabang = prefs.getString('id_cabang');
    final url = 'http://192.168.1.25/pos/stock.php?id_cabang=$idCabang';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          setState(() {
            bahanList = jsonData['data'];
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching bahan/model: $e');
    }
  }

  List<String> getBahanOptions(String query) {
    final allBahan = bahanList.map((e) => e['id_bahan'].toString()).toSet().toList();
    return allBahan.where((item) => item.toLowerCase().contains(query.toLowerCase())).toList();
  }

  List<String> getModelOptions(String query) {
    if (selectedBahan == null) return [];
    final models = bahanList
        .where((item) => item['id_bahan'] == selectedBahan)
        .map((item) => item['model'].toString())
        .toSet()
        .toList();
    return models.where((item) => item.toLowerCase().contains(query.toLowerCase())).toList();
  }

  Future<void> fetchStockCard() async {
  final from = DateFormat('yyyy-MM-dd').format(fromDate);
  final to = DateFormat('yyyy-MM-dd').format(toDate);
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? idCabang = prefs.getString('id_cabang');

  // Validasi input
  if (barcodeController.text.isEmpty &&
      (selectedBahan == null || selectedModel == null)) return;

  final Uri url = Uri.parse(
    barcodeController.text.isNotEmpty
        ? 'http://192.168.1.25/pos/stock_card.php?tanggal_from=$from&tanggal_to=$to&barcode=${Uri.encodeComponent(barcodeController.text)}&id_cabang=$idCabang'
        : 'http://192.168.1.25/pos/stock_card.php?tanggal_from=$from&tanggal_to=$to&id_bahan=${Uri.encodeComponent(selectedBahan!)}&model=${Uri.encodeComponent(selectedModel!)}&id_cabang=$idCabang',
  );

  setState(() => isLoading = true);

  try {
    final response = await http.get(url);
    print('🔎 URL: $url');
print('📡 Status: ${response.statusCode}');
print('📦 Body: ${response.body}');
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      setState(() {
        stockCardData = jsonData;
      });
    } else {
      setState(() => stockCardData = []);
    }
  } catch (e) {
    setState(() => stockCardData = []);
  }

  setState(() => isLoading = false);
}

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
  title: const Text(
    'Stock Card Detail',
    style: TextStyle(color: Colors.blue),
  ),
  backgroundColor: Colors.white,
  iconTheme: const IconThemeData(color: Colors.blue),
),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dari Tanggal'),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: fromDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => fromDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(dateFormat.format(fromDate)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Sampai Tanggal'),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: toDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() => toDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(dateFormat.format(toDate)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
// BARCODE
Row(
  children: [
    Expanded(
      child: TextField(
        controller: barcodeController,
        decoration: const InputDecoration(
          labelText: 'Barcode',
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            setState(() {
              selectedBahan = null;
              selectedModel = null;
            });
          }
        },
      ),
    ),
  ],
),
const SizedBox(height: 8),

// ID BAHAN dan MODEL
Row(
  children: [
    Expanded(
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          return getBahanOptions(textEditingValue.text);
        },
        onSelected: (String selection) {
          setState(() {
            selectedBahan = selection;
            barcodeController.clear(); // Kosongkan barcode saat ID Bahan diisi
          });
        },
        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: barcodeController.text.isEmpty,
            decoration: const InputDecoration(
              labelText: 'ID Bahan',
              border: OutlineInputBorder(),
            ),
          );
        },
      ),
    ),
    const SizedBox(width: 8),
    Expanded(
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          return getModelOptions(textEditingValue.text);
        },
        onSelected: (String selection) {
          setState(() {
            selectedModel = selection;
            barcodeController.clear(); // Kosongkan barcode saat Model diisi
          });
        },
        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
          return TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: barcodeController.text.isEmpty,
            decoration: const InputDecoration(
              labelText: 'Model',
              border: OutlineInputBorder(),
            ),
          );
        },
      ),
    ),
  ],
),

              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
  onPressed: fetchStockCard,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.indigo,
    foregroundColor: Colors.white, // teks jadi putih
  ),
  child: const Text('Cari'),
),
const SizedBox(width: 10),
ElevatedButton(
  onPressed: stockCardData.isNotEmpty
    ? () => printAllStockData(
          stockCardData: stockCardData,
          selectedBahan: selectedBahan ?? '',
          selectedModel: selectedModel ?? '',
        )
    : null,

  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.indigo.shade200,
    foregroundColor: Colors.white, // teks jadi putih
  ),
  child: const Row(
    children: [
      Icon(Icons.print, color: Colors.white), // ikon jadi putih juga
      SizedBox(width: 8),
      Text('Print'),
    ],
  ),
),
const SizedBox(width: 10),
ElevatedButton(
  onPressed: stockCardData.isNotEmpty
      ? () => exportToExcelStyled(
            stockCardData,
            selectedBahan ?? '',
            selectedModel ?? '',
            context,  // jangan lupa kirim context juga
          )
      : null,
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    foregroundColor: Colors.white,
  ),
  child: const Row(
    children: [
      Icon(Icons.file_download, color: Colors.white),
      SizedBox(width: 8),
      Text('Print Excel'),
    ],
  ),
),

                ],
              ),
              const SizedBox(height: 24),
              
if (isPrinting)
  const Padding(
    padding: EdgeInsets.symmetric(vertical: 8),
    child: Center(child: CircularProgressIndicator()),
  ),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (stockCardData.isEmpty)
                const Text('Tidak ada data')
              else
                Column(
                  children: stockCardData.map((item) {
                    final summary = item['summary'];
                    final detail = item['detail'] as List;

                    return Column(
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    Card(
  margin: const EdgeInsets.only(bottom: 8),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Header Ukuran & Ringkasan
      // Header Ringkasan 2 Baris
Container(
  color: Colors.indigo,
  child: Table(
    columnWidths: const {
      0: FlexColumnWidth(2),
      1: FlexColumnWidth(2),
      2: FlexColumnWidth(2),
      3: FlexColumnWidth(2),
      4: FlexColumnWidth(2),
    },
    border: TableBorder.symmetric(
      inside: BorderSide(color: Colors.grey.shade300, width: 0.5),
    ),
    children: [
      // Baris Header
      const TableRow(
  decoration: BoxDecoration(color: Colors.indigo),
  children: [
    Padding(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text('Ukuran', style: TextStyle(color: Colors.white)),
      ),
    ),
    Padding(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text('Awal', style: TextStyle(color: Colors.white)),
      ),
    ),
    Padding(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text('Masuk', style: TextStyle(color: Colors.white)),
      ),
    ),
    Padding(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text('Keluar', style: TextStyle(color: Colors.white)),
      ),
    ),
    Padding(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text('Sisa', style: TextStyle(color: Colors.white)),
      ),
    ),
  ],
),

      // Baris Data
      TableRow(
  decoration: const BoxDecoration(color: Colors.white),
  children: [
    Padding(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text('${item['ukuran']}', style: const TextStyle(color: Colors.black)),
      ),
    ),
    Padding(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text('${summary['stock_awal']}', style: const TextStyle(color: Colors.black)),
      ),
    ),
    Padding(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text('${summary['masuk']}', style: const TextStyle(color: Colors.black)),
      ),
    ),
    Padding(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text('${summary['keluar']}', style: const TextStyle(color: Colors.black)),
      ),
    ),
    Padding(
      padding: const EdgeInsets.all(8),
      child: Center(
        child: Text('${summary['sisa']}', style: const TextStyle(color: Colors.black)),
      ),
    ),
  ],
),
    ],
  ),
),
      // Table Header
      Container(
        color: Colors.indigo.shade200,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(3),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1),
            4: FlexColumnWidth(1),
          },
          children: const [
            TableRow(
  children: [
    Padding(
      padding: const EdgeInsets.all(1),
      child: Center(
        child: Text('Tgl'),
      ),
    ),
    Padding(
      padding: const EdgeInsets.all(1),
      child: Center(
        child: Text('No. Transaksi'),
      ),
    ),
    Padding(
      padding: const EdgeInsets.all(1),
      child: Center(
        child: Text('Masuk'),
      ),
    ),
    Padding(
      padding: const EdgeInsets.all(1),
      child: Center(
        child: Text('Keluar'),
      ),
    ),
    Padding(
      padding: const EdgeInsets.all(1),
      child: Center(
        child: Text('Total'),
      ),
    ),
  ],
),
          ],
        ),
      ),

      // Table Rows
      Table(
        columnWidths: const {
          0: FlexColumnWidth(2),
          1: FlexColumnWidth(3),
          2: FlexColumnWidth(1),
          3: FlexColumnWidth(1),
          4: FlexColumnWidth(1),
        },
        border: TableBorder.all(color: Colors.grey.shade300),
        children: detail.map<TableRow>((trx) {
          return TableRow(
  children: [
    Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(trx['tgl']),
      ),
    ),
    Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text(trx['no_transaksi']),
      ),
    ),
    Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text('${trx['masuk']}'),
      ),
    ),
    Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text('${trx['keluar']}'),
      ),
    ),
    Padding(
      padding: const EdgeInsets.all(8.0),
      child: Center(
        child: Text('${trx['total']}'),
      ),
    ),
  ],
);
        }).toList(),
      ),
    ],
  ),
),

    // tombol print di luar card, kanan bawah
    Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: ElevatedButton.icon(
        onPressed: () async {
  final qty = await showDialog<String>(
    context: context,
    builder: (context) {
      final qtyController = TextEditingController();
      return AlertDialog(
        title: const Text('Input Qty (PCS)'),
        content: TextField(
          controller: qtyController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Misal: 03'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, qtyController.text),
            child: const Text('Print'),
          ),
        ],
      );
    },
  );

  if (qty != null && qty.isNotEmpty) {
    setState(() => isPrinting = true); // ⏳ Start loading

    await handleBarcodePrint(
  context: context, // Tambahkan ini
  idBahan: selectedBahan!,
  model: selectedModel!,
  ukuran: item['ukuran'],
  qty: qty,
);


    setState(() => isPrinting = false); // ✅ Done
  }
},

        icon: const Icon(Icons.print, color: Colors.white),
        label: const Text('Print Barcode'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.indigo.shade200,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ),
  ],
);

                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}