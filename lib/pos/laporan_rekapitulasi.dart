import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';

void main() => runApp(const MaterialApp(home: RekapitulasiPage()));

class RekapitulasiPage extends StatefulWidget {
  const RekapitulasiPage({super.key});

  @override
  State<RekapitulasiPage> createState() => _RekapitulasiState();
}

class _RekapitulasiState extends State<RekapitulasiPage> {
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();
  String? selectedCustomer;
  List<Map<String, dynamic>> customerList = [];
  List<dynamic> rekapList = [];
  bool isLoading = false;

  double totalLusin = 0;
  int totalSubtotal = 0;
  int totalDiskon = 0;
  int totalInvoice = 0;

  late TextEditingController customerController;
  final lusinFormat = NumberFormat("0.##");

  final currency = NumberFormat('#,###', 'id_ID');

  @override
  void initState() {
    super.initState();
    customerController = TextEditingController();
    customerController.addListener(() {
      if (selectedCustomer != null && customerController.text.isEmpty) {
        setState(() => selectedCustomer = null);
      }
    });
    fetchCustomerList();
  }

  @override
  void dispose() {
    customerController.dispose();
    super.dispose();
  }

  double toDouble(dynamic val) {
  if (val is double) return val;
  if (val is int) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0;
  return 0;
}

int toInt(dynamic val) {
  if (val is int) return val;
  if (val is double) return val.toInt();
  if (val is String) return double.tryParse(val)?.toInt() ?? 0;
  return 0;
}

  Future<void> fetchCustomerList() async {
    const url = 'https://hayami.id//hayami/customer.php';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          setState(() {
            customerList =
                List<Map<String, dynamic>>.from(jsonData['data'] ?? []);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching customer list: $e');
    }
  }

  List<String> getCustomerOptions(String query) {
    final all = customerList.map((e) => e['id_customer'].toString()).toList();
    final filtered = query.isEmpty
        ? all
        : all
            .where((name) => name.toLowerCase().contains(query.toLowerCase()))
            .toList();
    return ['-- Pilih Customer --', ...filtered];
  }

  Future<void> fetchRekapitulasiData() async {
    final prefs = await SharedPreferences.getInstance();
    final idCabang = prefs.getString('id_cabang') ?? '';
    final from = DateFormat('yyyy-MM-dd').format(fromDate);
    final to = DateFormat('yyyy-MM-dd').format(toDate);
    String url = 'https://hayami.id//pos/rekapitulasi.php?start=$from&end=$to&id_cabang=$idCabang';

    if (selectedCustomer != null && selectedCustomer!.isNotEmpty) {
      url += '&id_customer=${Uri.encodeComponent(selectedCustomer!)}';
    }

    setState(() {
      isLoading = true;
      rekapList = [];
      totalLusin = 0;
      totalSubtotal = 0;
      totalDiskon = 0;
      totalInvoice = 0;
    });

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        double lus = 0;
        int sub = 0, dis = 0, inv = 0;




// Lalu gunakan:

for (var item in data) {
  lus += toDouble(item['lusin']);
  sub += toInt(item['subtotal']);
  dis += toInt(item['discon']);
  inv += toInt(item['total_invoice']);
}



        setState(() {
          rekapList = data;
          totalLusin = lus;
          totalSubtotal = sub;
          totalDiskon = dis;
          totalInvoice = inv;
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
    }

    setState(() => isLoading = false);
  }

  Future<void> printPdf() async {
    final pdf = pw.Document();

    final headers = [
      'Tanggal',
      'Tgl Jatuh Tempo',
      'Transaksi',
      'Customer',
      'Lusin',
      'Subtotal',
      'Diskon',
      'Total',
      'Status',
    ];

final dataRows = rekapList.map((item) {
  return [
    (item['tgl_transaksi'] ?? '').toString().split(' ')[0],
    (item['tgl_jatuh_tempo'] != null &&
            item['tgl_jatuh_tempo'] != '0000-00-00')
        ? (item['tgl_jatuh_tempo'] ?? '').toString().split(' ')[0]
        : '-',
    item['id_transaksi']?.toString() ?? '-',
    item['id_customer']?.toString() ?? '-',
    NumberFormat("0.##").format(double.tryParse(item['lusin']?.toString() ?? '0') ?? 0),
    'Rp ${currency.format(int.tryParse(item['subtotal']?.toString() ?? '0') ?? 0)}',
    'Rp ${currency.format((double.tryParse(item['discon']?.toString() ?? '0') ?? 0).toInt())}',
    'Rp ${currency.format((double.tryParse(item['total_invoice']?.toString() ?? '0') ?? 0).toInt())}',
    (item['status'] != null && item['status'].toString().trim().isNotEmpty)
        ? item['status'].toString()
        : '-',
  ];
}).toList();


    dataRows.add([
      'TOTAL',
      '',
      '',
      '',
      NumberFormat("0.##").format(totalLusin),
      'Rp ${currency.format(totalSubtotal)}',
      'Rp ${currency.format(totalDiskon)}',
      'Rp ${currency.format(totalInvoice)}',
      '',
    ]);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(10),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Rekapitulasi Penjualan',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            pw.Text(
              'Periode: ${DateFormat('dd/MM/yyyy').format(fromDate)} - ${DateFormat('dd/MM/yyyy').format(toDate)}',
              style: const pw.TextStyle(fontSize: 10),
            ),
            pw.Divider(),
          ],
        ),
        build: (context) => [
          pw.Table.fromTextArray(
            headers: headers,
            data: dataRows,
            headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo),
            headerHeight: 25,
            cellHeight: 20,
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            border: pw.TableBorder.all(color: PdfColors.grey),
            columnWidths: {
              0: const pw.FixedColumnWidth(70),
              1: const pw.FixedColumnWidth(80),
              2: const pw.FixedColumnWidth(70),
              3: const pw.FixedColumnWidth(80),
              4: const pw.FixedColumnWidth(50),
              5: const pw.FixedColumnWidth(70),
              6: const pw.FixedColumnWidth(70),
              7: const pw.FixedColumnWidth(70),
              8: const pw.FixedColumnWidth(50),
            },
            cellDecoration: (index, data, rowIndex) {
              if (rowIndex == dataRows.length - 0) {
                return const pw.BoxDecoration(color: PdfColors.green100);
              }
              return const pw.BoxDecoration();
            },
            cellAlignments: {
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
              6: pw.Alignment.centerRight,
              7: pw.Alignment.centerRight,
            },
          ),
        ],
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

Future<void> exportToExcel(BuildContext context) async {
  var status = await Permission.storage.request();  // Izin pertama

  if (!status.isGranted) return;

  final excelFile = excel.Excel.createExcel();
  final sheet = excelFile['Sheet1'];

  // Menulis header
  sheet.appendRow([
    'Tanggal',
    'Tgl Jatuh Tempo',
    'Transaksi',
    'Customer',
    'Lusin',
    'Subtotal',
    'Diskon',
    'Total',
    'Status',
  ]);

  // Menulis data
  for (var item in rekapList) {
    sheet.appendRow([
      (item['tgl_transaksi'] ?? '').toString().split(' ')[0],
      (item['tgl_jatuh_tempo'] != null &&
              item['tgl_jatuh_tempo'] != '0000-00-00')
          ? item['tgl_jatuh_tempo'].toString().split(' ')[0]
          : '-',
      item['id_transaksi']?.toString() ?? '-',
      item['id_customer']?.toString() ?? '-',
      double.tryParse(item['lusin']?.toString() ?? '0') ?? 0,
      int.tryParse(item['subtotal']?.toString() ?? '0') ?? 0,
      double.tryParse(item['discon']?.toString() ?? '0')?.toInt() ?? 0,
      double.tryParse(item['total_invoice']?.toString() ?? '0')?.toInt() ?? 0,
      item['status']?.toString() ?? '-',
    ]);
  }

  // Menambahkan baris total
  sheet.appendRow([
    'TOTAL',
    '',
    '',
    '',
    totalLusin,
    totalSubtotal,
    totalDiskon,
    totalInvoice,
    '',
  ]);

  // Minta izin penyimpanan
  var storagePermissionStatus = await Permission.storage.request(); // Ubah nama variabel disini

  if (!storagePermissionStatus.isGranted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Izin penyimpanan ditolak')),
    );
    return;
  }

  try {
    // Menggunakan getExternalStorageDirectory() yang sesuai
    final directory = await getExternalStorageDirectory();
    final filePath = '${directory!.path}/rekapitulasi_penjualan_${DateTime.now().millisecondsSinceEpoch}.xlsx';

    final fileBytes = excelFile.encode();
    if (fileBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal membuat file Excel')),
      );
      return;
    }

    final file = File(filePath);
    await file.writeAsBytes(fileBytes);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File berhasil disimpan di $filePath')),
    );
  } catch (e) {
    debugPrint("Gagal menyimpan file: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gagal menyimpan file')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rekapitulasi Penjualan',
            style: TextStyle(color: Colors.blue)),
        centerTitle: true,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.blue),
                leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.blue),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: buildDatePicker('Dari Tanggal', fromDate, (picked) {
                if (picked != null) setState(() => fromDate = picked);
              })),
              const SizedBox(width: 8),
              Expanded(
                  child: buildDatePicker('Sampai Tanggal', toDate, (picked) {
                if (picked != null) setState(() => toDate = picked);
              })),
            ]),
            const SizedBox(height: 16),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue val) =>
                  getCustomerOptions(val.text),
              onSelected: (val) {
                if (val == '-- Pilih Customer --') {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    selectedCustomer = null;
                    customerController.clear();
                  });
                } else {
                  setState(() {
                    customerController.text = val;
                    selectedCustomer = val;
                  });
                }
              },
              fieldViewBuilder: (context, textEditingController, focusNode, _) {
                if (customerController.text != textEditingController.text) {
                  textEditingController.value = customerController.value;
                }
                return TextField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Customer (Optional)',
                    border: OutlineInputBorder(),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                  ElevatedButton(
                    onPressed: fetchRekapitulasiData,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white),
                    child: const Text('Cari'),
                  ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: rekapList.isEmpty ? null : printPdf,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo.shade200,
                      foregroundColor: Colors.white),
                  child: const Row(
                    children: [
                      Icon(Icons.print),
                      SizedBox(width: 8),
                      Text('Print'),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed:
                      rekapList.isEmpty ? null : () => exportToExcel(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white),
                  child: const Row(
                    children: [
                      Icon(Icons.file_download),
                      SizedBox(width: 8),
                      Text('Print Excel'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (rekapList.isEmpty)
              const Center(child: Text('Tidak ada data')),
            if (!isLoading && rekapList.isNotEmpty) buildTable(),
          ]),
        ),
      ),
    );
  }

  Widget buildDatePicker(
      String label, DateTime value, Function(DateTime?) onPick) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label),
      const SizedBox(height: 4),
      InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          onPick(picked);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(dateFormat.format(value)),
        ),
      ),
    ]);
  }

  DataCell buildCell(String text, double width, double fontSize,
      {bool isBold = false}) {
    return DataCell(
      SizedBox(
        width: width,
        child: Text(
          text,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }



Widget buildTable() {
  return LayoutBuilder(
    builder: (context, constraints) {
      double tableWidth = constraints.maxWidth;
      double colWidth = tableWidth / 9;
      double fontSize;

      if (tableWidth < 320) {
        fontSize = 10;
      } else if (tableWidth < 400) {
        fontSize = 11;
      } else {
        fontSize = 12;
      }

      return StickyHeader(
        header: Container(
          color: Colors.indigo,
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade400, width: 1),
            columnWidths: {
              for (int i = 0; i < 9; i++) i: FixedColumnWidth(colWidth),
            },
            children: [
              TableRow(
                children: [
                  for (var title in [
                    'Tanggal',
                    'Jatuh Tempo',
                    'Transaksi',
                    'Customer',
                    'Lusin',
                    'Subtotal',
                    'Diskon',
                    'Total',
                    'Status'
                  ])
                    Padding(
                      padding: const EdgeInsets.all(6.0),
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        content: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade400, width: 1),
            columnWidths: {
              for (int i = 0; i < 9; i++) i: FixedColumnWidth(colWidth),
            },
            children: [
              // Data rows
              ...rekapList.map((item) {
                return TableRow(
                  children: [
                    buildCellText(item['tgl_transaksi'].split(' ')[0], fontSize),
                    buildCellText(
                      item['tgl_jatuh_tempo'] == '0000-00-00' ? '-' : item['tgl_jatuh_tempo'],
                      fontSize,
                    ),
                    buildCellText(item['id_transaksi'], fontSize),
                    buildCellText(item['id_customer'], fontSize),
                    buildCellText(NumberFormat("0.##").format(toDouble(item['lusin'])), fontSize),
                    buildCellText('Rp ${currency.format(toInt(item['subtotal']))}', fontSize),
                    buildCellText('Rp ${currency.format(toInt(item['discon']))}', fontSize),
                    buildCellText('Rp ${currency.format(toInt(item['total_invoice']))}', fontSize),
                    buildCellText(item['status'] ?? '-', fontSize),
                  ],
                );
              }).toList(),

              // Total row
              TableRow(
                decoration: BoxDecoration(color: Colors.indigo.shade200),
                children: [
                  buildCellText('TOTAL', fontSize, isBold: true),
                  buildCellText('', fontSize),
                  buildCellText('', fontSize),
                  buildCellText('', fontSize),
                  buildCellText(NumberFormat("0.##").format(totalLusin), fontSize),
                  buildCellText('Rp ${currency.format(totalSubtotal)}', fontSize),
                  buildCellText('Rp ${currency.format(totalDiskon)}', fontSize),
                  buildCellText('Rp ${currency.format(totalInvoice)}', fontSize),
                  buildCellText('', fontSize),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget buildCellText(String text, double fontSize, {bool isBold = false}) {
  return Padding(
    padding: const EdgeInsets.all(6.0),
    child: Text(
      text,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      ),
      textAlign: TextAlign.center,
    ),
  );
}

}
