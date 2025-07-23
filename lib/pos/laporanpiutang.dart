import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

void main() => runApp(const MaterialApp(home: RekapHutangPage()));

class RekapHutangPage extends StatefulWidget {
  const RekapHutangPage({super.key});

  @override
  State<RekapHutangPage> createState() => _RekapHutangPageState();
}

class _RekapHutangPageState extends State<RekapHutangPage> {
  double total = 0;
  double totalTerbayar = 0;
  double totalOutstanding = 0;
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();
  String? selectedCustomer;

  bool isLoading = false;
  List<Map<String, dynamic>> hasilData = [];

  List<Map<String, dynamic>> customerList = [];

  @override
  void initState() {
    super.initState();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    final url = 'http://192.168.1.25/hayami/customer.php';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          setState(() {
            customerList = List<Map<String, dynamic>>.from(jsonData['data']);
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Gagal ambil data customer: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error ambil data customer: $e')),
      );
    }
  }

  String getCustomerName(String idCustomer) {
    final customer = customerList.firstWhere(
      (c) => c['id_customer'] == idCustomer,
      orElse: () => {},
    );
    if (customer.isNotEmpty) {
      return customer['nama_customer'] ?? idCustomer;
    }
    return idCustomer;
  }

  Future<void> exportToExcel(
    BuildContext context,
    List<Map<String, dynamic>> hasilData,
    double total,
    double totalTerbayar,
    double totalOutstanding,
  ) async {
    Future<bool> requestStoragePermission() async {
      if (Platform.isAndroid) {
        final statusManage = await Permission.manageExternalStorage.status;
        if (statusManage.isGranted) return true;

        final result = await Permission.manageExternalStorage.request();
        if (result.isGranted) return true;

        if (result.isPermanentlyDenied) {
          await openAppSettings();
        }
        return false;
      } else {
        final status = await Permission.storage.request();
        if (status.isGranted) return true;

        if (status.isPermanentlyDenied) {
          await openAppSettings();
        }
        return false;
      }
    }

    if (!await requestStoragePermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Izin penyimpanan tidak diberikan')),
      );
      return;
    }

    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Laporan Piutang';

    final formatDate = DateFormat('dd/MM/yyyy');
    final formatCurrency =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    final headers = [
      'Tanggal',
      'Tagihan',
      'No.Transaksi',
      'Customer',
      'Lusin',
      'Total',
      'Terbayar',
      'Outstanding',
      'Status',
    ];
    final headerRowIndex = 3;

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(headerRowIndex, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle.bold = true;
      cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
    }

    for (int i = 0; i < hasilData.length; i++) {
      final row = hasilData[i];
      final rowIndex = headerRowIndex + 1 + i;
      final values = [
        formatDate.format(DateTime.parse(row['tanggal'])),
        formatDate.format(DateTime.parse(row['tagihan'])),
        row['noTransaksi'].toString(),
        row['customer'].toString(),
        row['lusin'].toString(),
        formatCurrency.format(row['total']),
        formatCurrency.format(row['terbayar']),
        formatCurrency.format(row['outstanding']),
        row['status'].toString(),
      ];

      for (int col = 0; col < values.length; col++) {
        final cell = sheet.getRangeByIndex(rowIndex, col + 1);
        cell.setText(values[col]);
        cell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      }
    }

    int totalRow = headerRowIndex + 1 + hasilData.length;

    void addTotalRow(String label, double value) {
      final mergedRange = sheet.getRangeByIndex(totalRow, 1, totalRow, 8);
      mergedRange.merge();
      final labelCell = sheet.getRangeByIndex(totalRow, 1);
      final valueCell = sheet.getRangeByIndex(totalRow, 9);
      labelCell.setText(label);
      valueCell.setText(formatCurrency.format(value));
      labelCell.cellStyle.bold = true;
      valueCell.cellStyle.bold = true;
      mergedRange.cellStyle.borders.left.lineStyle = xlsio.LineStyle.thin;
      mergedRange.cellStyle.borders.top.lineStyle = xlsio.LineStyle.thin;
      mergedRange.cellStyle.borders.right.lineStyle = xlsio.LineStyle.thin;
      mergedRange.cellStyle.borders.bottom.lineStyle = xlsio.LineStyle.thin;
      valueCell.cellStyle.borders.all.lineStyle = xlsio.LineStyle.thin;
      totalRow++;
    }

    addTotalRow('Total', total);
    addTotalRow('Total Terbayar', totalTerbayar);
    addTotalRow('Total Outstanding', totalOutstanding);

    for (int i = 1; i <= headers.length; i++) {
      sheet.getRangeByIndex(headerRowIndex, i).columnWidth = 20;
    }

    final bytes = workbook.saveAsStream();
    workbook.dispose();

    final downloadDir = Directory('/storage/emulated/0/Download');
    if (!downloadDir.existsSync()) {
      await downloadDir.create(recursive: true);
    }

    String getAvailableFilePath(String baseName, String extension) {
      int counter = 1;
      String fileName = '$baseName.$extension';
      String fullPath = '${downloadDir.path}/$fileName';

      while (File(fullPath).existsSync()) {
        fileName = '$baseName ($counter).$extension';
        fullPath = '${downloadDir.path}/$fileName';
        counter++;
      }
      return fullPath;
    }

    final filePath = getAvailableFilePath('laporan_piutang', 'xlsx');
    final file = File(filePath);
    await file.writeAsBytes(bytes, flush: true);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('File berhasil disimpan di $filePath')),
    );
  }

  Future<void> printPdf() async {
    final pdf = pw.Document();

    final headers = [
      'Tanggal',
      'Tagihan',
      'No.Transaksi',
      'Customer',
      'Lusin',
      'Total',
      'Terbayar',
      'Outstanding',
      'Status',
    ];

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 20),
        header: (context) => pw.Text(
          'Laporan Piutang Customer',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${context.pageNumber} / ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ),
        build: (context) {
          return [
            pw.Table.fromTextArray(
              headers: headers,
              data: hasilData.map((data) {
                return [
                  data['tanggal'],
                  data['tagihan'],
                  data['noTransaksi'],
                  data['customer'],
                  data['lusin'].toString(),
                  NumberFormat.currency(
                          locale: 'id', symbol: 'Rp ', decimalDigits: 0)
                      .format(data['total']),
                  NumberFormat.currency(
                          locale: 'id', symbol: 'Rp ', decimalDigits: 0)
                      .format(data['terbayar']),
                  NumberFormat.currency(
                          locale: 'id', symbol: 'Rp ', decimalDigits: 0)
                      .format(data['outstanding']),
                  data['status'],
                ];
              }).toList(),
              border: pw.TableBorder.all(width: 0.5),
              headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10),
              headerDecoration: pw.BoxDecoration(color: PdfColors.indigo),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding:
                  const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 4),
              cellStyle: pw.TextStyle(fontSize: 9),
              columnWidths: {
                0: const pw.IntrinsicColumnWidth(),
                1: const pw.IntrinsicColumnWidth(),
                2: const pw.IntrinsicColumnWidth(),
                3: const pw.IntrinsicColumnWidth(),
                4: const pw.IntrinsicColumnWidth(),
                5: const pw.IntrinsicColumnWidth(),
                6: const pw.IntrinsicColumnWidth(),
                7: const pw.IntrinsicColumnWidth(),
                8: const pw.IntrinsicColumnWidth(),
              },
            ),
            pw.SizedBox(height: 12),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                      'Total: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(total)}',
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold, fontSize: 11)),
                  pw.Text(
                    'Total Terbayar: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(totalTerbayar)}',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 11),
                  ),
                  pw.Text(
                    'Total Outstanding: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(totalOutstanding)}',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 11),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  String formatOnlyDate(String? dateTimeStr) {
    if (dateTimeStr == null || dateTimeStr.isEmpty) return '';
    try {
      final dt = DateTime.parse(dateTimeStr);
      return DateFormat('yyyy-MM-dd').format(dt);
    } catch (e) {
      return dateTimeStr.split(' ').first;
    }
  }

  Future<void> cariData() async {
    setState(() {
      isLoading = true;
      hasilData = [];
    });

    final prefs = await SharedPreferences.getInstance();
    final idCabang = prefs.getString('id_cabang') ?? '';
    final from = DateFormat('yyyy-MM-dd').format(fromDate);
    final to = DateFormat('yyyy-MM-dd').format(toDate);
    final url =
        'http://192.168.1.25/pos/laporan_hutang.php?tanggal_from=$from&tanggal_to=$to&id_cabang=$idCabang';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);

        setState(() {
          hasilData = jsonData.where((item) {
            if (selectedCustomer == null || selectedCustomer!.isEmpty) {
              return true;
            }
            return item['id_customer']
                .toString()
                .toLowerCase()
                .contains(selectedCustomer!.toLowerCase());
          }).map<Map<String, dynamic>>((item) {
            return {
              'tanggal': formatOnlyDate(item['tgl_transaksi']),
              'tagihan': formatOnlyDate(item['tgl_jatuh_tempo']),
              'noTransaksi': item['id_transaksi'] ?? '',
              'customer': item['id_customer'] ?? '',
              'lusin': item['lusin'] ?? 0,
              'total': double.tryParse(item['total_invoice'] ?? '0') ?? 0,
              'terbayar': double.tryParse(item['dibayar'].toString()) ?? 0,
              'outstanding':
                  double.tryParse(item['sisa_bayar'].toString()) ?? 0,
              'status': item['status_hutang'] ?? '',
            };
          }).toList();

          total = hasilData.fold(0, (sum, item) => sum + item['total']);
          totalTerbayar =
              hasilData.fold(0, (sum, item) => sum + item['terbayar']);
          totalOutstanding =
              hasilData.fold(0, (sum, item) => sum + item['outstanding']);
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal mengambil data: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Piutang Customer'),
        centerTitle: true,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    flex: 1,
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(dateFormat.format(fromDate)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    flex: 1,
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 14),
                            margin: const EdgeInsets.only(top: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(6),
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
              const Text('Customer'),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return customerList
                      .map((c) => c['id_customer'].toString())
                      .where((nama) => nama
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (String selection) {
                  setState(() {
                    selectedCustomer = selection;
                  });
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onEditingComplete) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    decoration: const InputDecoration(
                      hintText: 'ID customer (opsional)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      selectedCustomer = value;
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: cariData,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white),
                    child: const Text('Cari'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (hasilData.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Tidak ada data untuk dicetak')),
                        );
                        return;
                      }
                      printPdf();
                    },
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
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (hasilData.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Tidak ada data untuk diekspor')),
                        );
                        return;
                      }
                      exportToExcel(context, hasilData, total, totalTerbayar,
                          totalOutstanding);
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white),
                    child: const Row(
                      children: [
                        Icon(Icons.file_download),
                        SizedBox(width: 8),
                        Text('Excel'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (hasilData.isEmpty)
                const Center(child: Text('Belum ada data ditampilkan.'))
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Container(
                      width: constraints.maxWidth,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: Colors.grey, width: 1), // border luar penuh
                      ),
                      child: DataTable(
  columnSpacing: 10,
  headingRowColor: MaterialStateProperty.all(Colors.indigo),
  border: TableBorder(
    horizontalInside: BorderSide(width: 1, color: Colors.grey),
    verticalInside: BorderSide(width: 1, color: Colors.grey),
  ),
  columns: [
    DataColumn(
      label: Expanded(
        child: Center(
          child: Text(
            'Tanggal',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white, // Menetapkan warna teks menjadi putih
            ),
          ),
        ),
      ),
    ),
    DataColumn(
      label: Expanded(
        child: Center(
          child: Text(
            'Tagihan',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white, // Menetapkan warna teks menjadi putih
            ),
          ),
        ),
      ),
    ),
    DataColumn(
      label: Expanded(
        child: Center(
          child: Text(
            'No.Transaksi',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white, // Menetapkan warna teks menjadi putih
            ),
          ),
        ),
      ),
    ),
    DataColumn(
      label: Expanded(
        child: Center(
          child: Text(
            'Customer',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white, // Menetapkan warna teks menjadi putih
            ),
          ),
        ),
      ),
    ),
    DataColumn(
      label: Expanded(
        child: Center(
          child: Text(
            'Lusin',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white, // Menetapkan warna teks menjadi putih
            ),
          ),
        ),
      ),
    ),
    DataColumn(
      label: Expanded(
        child: Center(
          child: Text(
            'Total',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white, // Menetapkan warna teks menjadi putih
            ),
          ),
        ),
      ),
    ),
    DataColumn(
      label: Expanded(
        child: Center(
          child: Text(
            'Terbayar',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white, // Menetapkan warna teks menjadi putih
            ),
          ),
        ),
      ),
    ),
    DataColumn(
      label: Expanded(
        child: Center(
          child: Text(
            'Outstanding',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white, // Menetapkan warna teks menjadi putih
            ),
          ),
        ),
      ),
    ),
    DataColumn(
      label: Expanded(
        child: Center(
          child: Text(
            'Status',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white, // Menetapkan warna teks menjadi putih
            ),
          ),
        ),
      ),
    ),
  ],
  rows: hasilData.map((data) {
    return DataRow(cells: [
      DataCell(Center(child: Text(data['tanggal']))),
      DataCell(Center(child: Text(data['tagihan']))),
      DataCell(Center(child: Text(data['noTransaksi']))),
      DataCell(Center(child: Text(data['customer']))),
      DataCell(Center(child: Text(data['lusin'].toString()))),
      DataCell(Center(
          child: Text(NumberFormat.currency(
                  locale: 'id',
                  symbol: 'Rp ',
                  decimalDigits: 0)
              .format(data['total'])))),
      DataCell(Center(
          child: Text(NumberFormat.currency(
                  locale: 'id',
                  symbol: 'Rp ',
                  decimalDigits: 0)
              .format(data['terbayar'])))),
      DataCell(Center(
          child: Text(NumberFormat.currency(
                  locale: 'id',
                  symbol: 'Rp ',
                  decimalDigits: 0)
              .format(data['outstanding'])))),
      DataCell(Center(child: Text(data['status']))),
    ]);
  }).toList(),
),
                    );
                  },
                ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(total)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Total Terbayar: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(totalTerbayar)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Total Outstanding: ${NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0).format(totalOutstanding)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
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
