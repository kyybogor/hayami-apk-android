import 'dart:io';
import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;

void main() => runApp(const MaterialApp(home: Stockdetail()));

class Stockdetail extends StatefulWidget {
  const Stockdetail({super.key});

  @override
  State<Stockdetail> createState() => _StockdetailState();
}

class _StockdetailState extends State<Stockdetail> {
  final ScrollController _scrollController = ScrollController();
  int itemsPerPage = 10;
  int currentPage = 1;
  String? selectedBahan;
  String? selectedModel;
  String? selectedUkuran;
  List<dynamic> bahanList = [];
  Map<String, dynamic>? stockDetail;
  List<dynamic> filteredStock = [];
  bool isLoading = false; // Status loading
  List<dynamic> get displayedStock =>
      filteredStock.take(currentPage * itemsPerPage).toList();

  @override
  void initState() {
    super.initState();
    fetchBahanModel();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (filteredStock.length > displayedStock.length) {
          setState(() {
            currentPage++;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchBahanModel() async {
    final url = 'http://192.168.1.11/pos/stock.php';
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
    final allBahan =
        bahanList.map((e) => e['id_bahan'].toString()).toSet().toList();
    return allBahan
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  List<String> getModelOptions(String query) {
    if (selectedBahan == null) return [];
    final models = bahanList
        .where((item) => item['id_bahan'] == selectedBahan)
        .map((item) => item['model'].toString())
        .toSet()
        .toList();
    return models
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  List<String> getUkuranOptions(String query) {
    if (selectedBahan == null || selectedModel == null) return [];
    final ukuran = bahanList
        .where((item) =>
            item['id_bahan'] == selectedBahan && item['model'] == selectedModel)
        .map((item) => item['ukuran'].toString())
        .toSet()
        .toList();
    return ukuran
        .where((item) => item.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  Future<void> generateExcel() async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'StockDetail';

    // Baris 1: Header atas
    sheet.getRangeByIndex(1, 1).setText('Nama Barang');
    sheet.getRangeByIndex(1, 3).setText('Total Stock');

    // Baris 2: Value atas
    sheet.getRangeByIndex(2, 1).setText('${stockDetail!['id_bahan']}');
    sheet.getRangeByIndex(2, 3).setText('${stockDetail!['total_stock']}');

    // Style baris atas: bold dan border
    final atas = [
      sheet.getRangeByIndex(1, 1),
      sheet.getRangeByIndex(1, 3),
      sheet.getRangeByIndex(2, 1),
      sheet.getRangeByIndex(2, 3),
    ];
    for (var cell in atas) {
      cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    }

    sheet.getRangeByIndex(1, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(1, 3).cellStyle.bold = true;

    // Header tabel di baris ke-3
    final headers = [
      'Tanggal Masuk',
      'No. Transaksi',
      'Model',
      'Ukuran',
      'Qty',
      'Harga'
    ];
    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(3, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle.bold = true;
      cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    }

    // Data isi tabel mulai baris ke-4
    for (int i = 0; i < filteredStock.length; i++) {
      final row = i + 4;
      final item = filteredStock[i];

      sheet.getRangeByIndex(row, 1).setText(item['tgl_masuk']);
      sheet.getRangeByIndex(row, 2).setText(item['id_transaksi']);
      sheet.getRangeByIndex(row, 3).setText(item['model']);
      sheet.getRangeByIndex(row, 4).setText(item['ukuran'].toString());
      sheet
          .getRangeByIndex(row, 5)
          .setNumber(double.tryParse(item['stock'].toString()) ?? 0);
      sheet
          .getRangeByIndex(row, 6)
          .setNumber(double.tryParse(item['harga'].toString()) ?? 0);

      for (int col = 1; col <= 6; col++) {
        sheet.getRangeByIndex(row, col).cellStyle.borders.all.lineStyle =
            xlsio.LineStyle.thin;
      }
    }

    // Auto-fit setiap kolom
    for (int col = 1; col <= 6; col++) {
      sheet.autoFitColumn(col);
    }

    // Simpan file
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    final directory = await getExternalStorageDirectory();
    final path =
        '${directory!.path}/StockDetail_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Excel berhasil disimpan di: $path')),
    );
  }

  Future<void> fetchDetailStock() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('http://192.168.1.11/pos/detail_stock.php'
        '?id_bahan=${Uri.encodeComponent(selectedBahan!)}');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final allStock = data['stok_detail'] as List;

        // Simpan total stock dari seluruh ID Bahan (tanpa filter)
        final totalStock = data['total_stock'];

        // Lalu filter jika model dan ukuran dipilih
        List<dynamic> result = allStock.where((item) {
          final matchModel =
              selectedModel == null || item['model'] == selectedModel;
          final matchUkuran =
              selectedUkuran == null || item['ukuran'] == selectedUkuran;
          return matchModel && matchUkuran;
        }).toList();

        setState(() {
          stockDetail = {
            'id_bahan': data['id_bahan'],
            'total_stock': totalStock,
          };
          filteredStock = result;
          currentPage = 1; // Reset halaman
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching detail stock: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Stock Detail', style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.blue),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Autocomplete<String>(
                      optionsBuilder: (textEditingValue) =>
                          getBahanOptions(textEditingValue.text),
                      onSelected: (selection) {
                        setState(() {
                          selectedBahan = selection;
                          selectedModel = null;
                          selectedUkuran = null;
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, _) =>
                          TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                            labelText: 'ID Bahan',
                            border: OutlineInputBorder()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Autocomplete<String>(
                      optionsBuilder: (textEditingValue) =>
                          getModelOptions(textEditingValue.text),
                      onSelected: (selection) {
                        setState(() {
                          selectedModel = selection;
                          selectedUkuran =
                              null; // Reset ukuran ketika model dipilih
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, _) =>
                          TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onChanged: (text) {
                          if (text.isEmpty) {
                            setState(() {
                              selectedModel = null; // Reset model ketika kosong
                              selectedUkuran =
                                  null; // Reset ukuran ketika model kosong
                            });
                          }
                        },
                        decoration: const InputDecoration(
                            labelText: 'Model', border: OutlineInputBorder()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Autocomplete<String>(
                      optionsBuilder: (textEditingValue) =>
                          getUkuranOptions(textEditingValue.text),
                      onSelected: (selection) {
                        setState(() {
                          selectedUkuran = selection;
                        });
                      },
                      fieldViewBuilder: (context, controller, focusNode, _) =>
                          TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onChanged: (text) {
                          if (text.isEmpty) {
                            setState(() {
                              selectedUkuran =
                                  null; // Reset ukuran ketika kosong
                            });
                          }
                        },
                        decoration: const InputDecoration(
                            labelText: 'Ukuran', border: OutlineInputBorder()),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: selectedBahan != null ? fetchDetailStock : null,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white),
                    child: const Text('Cari'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: generateExcel,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo.shade200,
                        foregroundColor: Colors.white),
                    child: const Row(
                      children: [
                        Icon(Icons.print, color: Colors.white),
                        SizedBox(width: 8),
                        Text('Print Excel')
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                ),
              if (!isLoading && stockDetail != null) ...[
                // Table for Barang Name and Stock
                Table(
                  border: TableBorder.all(color: Colors.black26),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Colors.indigo),
                      children: const [
                        Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Nama Barang',
                                style: TextStyle(color: Colors.white))),
                        Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Stock',
                                style: TextStyle(color: Colors.white))),
                      ],
                    ),
                    TableRow(
                      children: [
                        Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(stockDetail!['id_bahan'])),
                        Padding(
                            padding: const EdgeInsets.all(8),
                            child:
                                Text(stockDetail!['total_stock'].toString())),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Table for detailed Stock
                Table(
                  border: TableBorder.all(color: Colors.black26),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(color: Colors.indigo),
                      children: const [
                        Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Tanggal Masuk',
                                style: TextStyle(color: Colors.white))),
                        Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('No. Transaksi',
                                style: TextStyle(color: Colors.white))),
                        Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Model',
                                style: TextStyle(color: Colors.white))),
                        Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Ukuran',
                                style: TextStyle(color: Colors.white))),
                        Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Qty',
                                style: TextStyle(color: Colors.white))),
                        Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Harga',
                                style: TextStyle(color: Colors.white))),
                        Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Action',
                                style: TextStyle(color: Colors.white))),
                      ],
                    ),
                    for (final item in displayedStock)
                      TableRow(
                        children: [
                          Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(item['tgl_masuk'])),
                          Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(item['id_transaksi'])),
                          Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(item['model'])),
                          Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(item['ukuran'])),
                          Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(item['stock'].toString())),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              NumberFormat.currency(
                                      locale: 'id_ID',
                                      symbol: 'Rp ',
                                      decimalDigits: 0)
                                  .format(double.tryParse(
                                          item['harga'].toString()) ??
                                      0),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final qtyInput = await showDialog<String>(
                                  context: context,
                                  builder: (context) {
                                    final qtyController =
                                        TextEditingController();
                                    return AlertDialog(
                                      title: const Text('Input Qty (PCS)'),
                                      content: TextField(
                                        controller: qtyController,
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                            hintText: 'Misal: 03'),
                                      ),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancel')),
                                        ElevatedButton(
                                          onPressed: () => Navigator.pop(
                                              context, qtyController.text),
                                          child: const Text('Print'),
                                        ),
                                      ],
                                    );
                                  },
                                );

                                if (qtyInput == null || qtyInput.isEmpty)
                                  return;

                                final perQty = int.tryParse(qtyInput) ?? 1;
                                final totalStock =
                                    int.tryParse(item['stock'].toString()) ?? 0;
                                final totalPages = (totalStock / perQty).ceil();

                                final pdf = pw.Document();
                                final font = await PdfGoogleFonts.nunitoBold();
                                final barcode = Barcode.code128();

                                for (int i = 0; i < totalPages; i++) {
                                  final isLast = i == totalPages - 1;
                                  final qtyThisPage =
                                      isLast && (totalStock % perQty != 0)
                                          ? (totalStock % perQty)
                                          : perQty;
                                  final qtyFormatted =
                                      qtyThisPage.toString().padLeft(2, '0');
                                  final kodeBarcode =
                                      item['barcode'].toString() + qtyFormatted;
                                  final svg = barcode.toSvg(kodeBarcode,
                                      width: 200, height: 80);

                                  pdf.addPage(
                                    pw.Page(
                                      build: (context) {
                                        return pw.Center(
                                          // <--- memastikan semua di tengah halaman
                                          child: pw.Column(
                                            mainAxisSize: pw.MainAxisSize.min,
                                            children: [
                                              pw.Text(
                                                  '${stockDetail?['id_bahan'] ?? '-'}  x$qtyFormatted',
                                                  style: pw.TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          pw.FontWeight.bold)),
                                              pw.Text(
                                                  '${item['model']} ${item['ukuran']}',
                                                  style: pw.TextStyle(
                                                      fontSize: 10)),
                                              pw.SizedBox(height: 8),
                                              pw.SvgImage(svg: svg),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }

                                await Printing.layoutPdf(
                                  onLayout: (format) async => pdf.save(),
                                );
                              },
                              icon: const Icon(Icons.print, size: 16),
                              label: const Text('Print Barcode'),
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo.shade200,
                                  foregroundColor: Colors.white),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }
}
