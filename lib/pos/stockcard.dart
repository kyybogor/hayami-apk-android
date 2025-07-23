import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'dart:convert';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

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

  @override
  void initState() {
    super.initState();
    fetchBahanModel();
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
  border: pw.TableBorder.symmetric(inside: pw.BorderSide(color: PdfColors.black, width: 0.3)),
  columnWidths: const {
    0: pw.FlexColumnWidth(2),
    1: pw.FlexColumnWidth(1.5),
    2: pw.FlexColumnWidth(1.5),
    3: pw.FlexColumnWidth(1.5),
    4: pw.FlexColumnWidth(1.5),
  },
  children: [
    // Baris judul
    pw.TableRow(
  decoration: pw.BoxDecoration(color: indigo),
  children: [
    pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text('Ukuran',
        style: pw.TextStyle(color: PdfColors.white)),
    ),
    pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text('Awal',
        style: pw.TextStyle(color: PdfColors.white)),
    ),
    pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text('Masuk',
        style: pw.TextStyle(color: PdfColors.white)),
    ),
    pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text('Keluar',
        style: pw.TextStyle(color: PdfColors.white)),
    ),
    pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text('Sisa',
        style: pw.TextStyle(color: PdfColors.white)),
    ),
  ],
),
    // Baris data
    pw.TableRow(
      decoration: pw.BoxDecoration(color: indigo),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text('${item['ukuran']}', style: const pw.TextStyle(color: PdfColors.white)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text('${summary['stock_awal']}', style: const pw.TextStyle(color: PdfColors.white)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text('${summary['masuk']}', style: const pw.TextStyle(color: PdfColors.white)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text('${summary['keluar']}', style: const pw.TextStyle(color: PdfColors.white)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(6),
          child: pw.Text('${summary['sisa']}', style: const pw.TextStyle(color: PdfColors.white)),
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
  required String idBahan,
  required String model,
  required String ukuran,
  required String qty, // input dari user, misal "03"
}) async {
  final url = 'http://192.168.1.25/pos/stock.php';

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

      final int fullBarcodeCount = stock ~/ qtyPerBarcode;
      final int remainingQty = stock % qtyPerBarcode;

      final pdf = pw.Document();

      // Cetak barcode @qty penuh
      for (int i = 0; i < fullBarcodeCount; i++) {
        final full = '$baseBarcode${qty.padLeft(2, '0')}';
        pdf.addPage(buildBarcodePage(item, full, qty.padLeft(2, '0')));
      }

      // Jika ada sisa
      if (remainingQty > 0) {
        final sisa = remainingQty.toString().padLeft(2, '0');
        final full = '$baseBarcode$sisa';
        pdf.addPage(buildBarcodePage(item, full, sisa));
      }

      await Printing.layoutPdf(onLayout: (format) async => pdf.save());
    }
  } catch (e) {
    debugPrint('Error saat print barcode: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Terjadi kesalahan saat print')),
    );
  }
}

pw.Page buildBarcodePage(dynamic item, String fullBarcode, String qtyLabel) {
  return pw.Page(
    build: (pw.Context context) {
      return pw.Center(
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            // Nama barang + Qty
            pw.Text(
              '${item['id_bahan']}  x$qtyLabel',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 2),
            // Model + Ukuran
            pw.Text(
              '${item['model']} ${item['ukuran']}',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 8),
            // Barcode 128
            pw.BarcodeWidget(
              barcode: pw.Barcode.code128(),
              data: fullBarcode,
              width: 150,
              height: 50,
              drawText: false,
            ),
            pw.SizedBox(height: 4),
            // Text barcode
            pw.Text(
              fullBarcode,
              style: pw.TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    },
  );
}

  Future<void> fetchBahanModel() async {
    final url = 'http://192.168.1.25/pos/stock.php';
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
    if (selectedBahan == null || selectedModel == null) return;

    final from = DateFormat('yyyy-MM-dd').format(fromDate);
    final to = DateFormat('yyyy-MM-dd').format(toDate);

    final url =
        'http://192.168.1.25/pos/stock_card.php?tanggal_from=$from&tanggal_to=$to&id_bahan=${Uri.encodeComponent(selectedBahan!)}&model=${Uri.encodeComponent(selectedModel!)}';

    setState(() => isLoading = true);

    try {
      final response = await http.get(Uri.parse(url));
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
                          selectedModel = null;
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
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
                        setState(() => selectedModel = selection);
                      },
                      fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
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
const SizedBox(width: 16),
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