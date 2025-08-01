import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MaterialApp(home: LaporanRetur()));

class LaporanRetur extends StatefulWidget {
  const LaporanRetur({super.key});

  @override
  State<LaporanRetur> createState() => _LaporanReturState();
}

class _LaporanReturState extends State<LaporanRetur> {
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();
  String? selectedBahan;
  String? selectedCustomer;
  List<dynamic> bahanList = [];
  List<dynamic> stockList = [];
  List<Map<String, dynamic>> customerList = [];
  bool isLoading = false;

  List<dynamic> laporanRetur = [];

  int totalReturCustomer = 0;
  int totalReturGudang = 0;
  int grandTotal = 0;

  late TextEditingController bahanController;
  late TextEditingController customerController;
  late TextEditingController barcodeController;

  @override
  void initState() {
    super.initState();
    bahanController = TextEditingController();
    customerController = TextEditingController();
    barcodeController = TextEditingController();

      barcodeController.addListener(() {
    setState(() {}); // supaya UI refresh ketika barcode berubah
  });
  
    bahanController.addListener(() {
      if (bahanController.text.isEmpty && selectedBahan != null) {
        setState(() => selectedBahan = null);
      }
    });

    customerController.addListener(() {
      if (customerController.text.isEmpty && selectedCustomer != null) {
        setState(() => selectedCustomer = null);
      }
    });

    fetchBahanModel();
    fetchCustomerList();
    fetchStockData();
  }

  @override
  void dispose() {
    bahanController.dispose();
    customerController.dispose();
    barcodeController.dispose();
    super.dispose();
  }

  Future<void> fetchCustomerList() async {
    final url = 'https://hayami./pos/customer.php';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          setState(() {
            customerList = List<Map<String, dynamic>>.from(jsonData['data']);
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching customer list: $e');
    }
  }

  Future<void> fetchBahanModel() async {
    final url = 'https://hayami.id/pos/bahan.php';
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
      debugPrint('Error fetching bahan: $e');
    }
  }

  List<String> getBahanOptions(String query) {
    if (bahanList.isEmpty) return [];
    final allBahan = bahanList
        .map((e) => e['nama_bahan']?.toString() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    final suggestions = query.isEmpty
        ? allBahan
        : allBahan
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();

    return ['', ...suggestions];
  }

  List<String> getCustomerOptions(String query) {
    final allCustomers =
        customerList.map((e) => e['nama_customer'].toString()).toList();

    final suggestions = query.isEmpty
        ? allCustomers
        : allCustomers
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();

    return ['', ...suggestions];
  }

  Future<void> fetchStockData() async {
    final prefs = await SharedPreferences.getInstance();
    final idCabang = prefs.getString('id_cabang') ?? '';
    final url = 'https://hayami.id/pos/stock.php?id_cabang=$idCabang';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        if (jsonData['status'] == 'success') {
          setState(() {
            stockList = jsonData['data'];
          });
        }
      } else {
        debugPrint('Failed to fetch stock: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching stock data: $e');
    }
  }

  List<String> getBarcodeSuggestions(String query) {
    return stockList
        .map((item) => item['barcode']?.toString() ?? '')
        .where((barcode) => barcode.toLowerCase().contains(query.toLowerCase()))
        .toSet()
        .toList();
  }

Future<void> fetchLaporanRetur() async {
  final from = DateFormat('yyyy-MM-dd').format(fromDate);
  final to = DateFormat('yyyy-MM-dd').format(toDate);
  final prefs = await SharedPreferences.getInstance();
  final idCabang = prefs.getString('id_cabang') ?? '';

  String url =
      'https://hayami.id/pos/laporan_retur.php?start_date=$from&end_date=$to&id_cabang=$idCabang';

  if (selectedBahan != null && selectedBahan!.isNotEmpty) {
    url += '&id_bahan=${Uri.encodeComponent(selectedBahan!)}';
  }

  if (selectedCustomer != null && selectedCustomer!.isNotEmpty) {
    url += '&id_customer=${Uri.encodeComponent(selectedCustomer!)}';
  }

  if (barcodeController.text.isNotEmpty) {
    url += '&barcode=${Uri.encodeComponent(barcodeController.text)}';
  }

  setState(() {
    isLoading = true;
    laporanRetur = [];
    totalReturCustomer = 0;
    totalReturGudang = 0;
    grandTotal = 0;
  });

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      setState(() {
        laporanRetur = jsonData['data'] ?? [];
        totalReturCustomer = jsonData['total_retur_customer'] ?? 0;
        totalReturGudang = jsonData['total_retur_gudang'] ?? 0;
        grandTotal = jsonData['grand_total'] ?? 0;
      });
    }
  } catch (e) {
    debugPrint('Error fetching laporan retur: $e');
  }

  setState(() => isLoading = false);
}

  Widget buildDetailTable(List details, String idTransaksi, String idCustomer) {
    final currencyFormat = NumberFormat('#,###', 'id_ID');
    return Table(
      border: TableBorder.all(color: Colors.grey.shade300),
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: IntrinsicColumnWidth(),
        2: FlexColumnWidth(),
        3: IntrinsicColumnWidth(),
        4: IntrinsicColumnWidth(),
        5: IntrinsicColumnWidth(),
        6: IntrinsicColumnWidth(),
        7: IntrinsicColumnWidth(),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: Colors.indigo),
          children: const [
            Padding(
              padding: EdgeInsets.all(8),
              child: Center(
                  child:
                      Text("Tanggal", style: TextStyle(color: Colors.white))),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Center(
                  child: Text("ID Transaksi",
                      style: TextStyle(color: Colors.white))),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Center(
                  child: Text("Nama Barang",
                      style: TextStyle(color: Colors.white))),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Center(
                  child: Text("Ukuran", style: TextStyle(color: Colors.white))),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Center(
                  child: Text("Qty", style: TextStyle(color: Colors.white))),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Center(
                  child: Text("UOM", style: TextStyle(color: Colors.white))),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Center(
                  child: Text("Price", style: TextStyle(color: Colors.white))),
            ),
            Padding(
              padding: EdgeInsets.all(8),
              child: Center(
                  child: Text("Total", style: TextStyle(color: Colors.white))),
            ),
          ],
        ),
        ...details.map((item) {
          return TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['tgl'].toString().split(' ')[0]),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '$idTransaksi\n$idCustomer',
                  style: const TextStyle(height: 1.3),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text("${item['id_bahan']} ${item['id_model'] ?? ''}"),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['ukuran'].toString()),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['qty'].toString()),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(item['uom'].toString()),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text("Rp " + currencyFormat.format(item['price'])),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text("Rp " + currencyFormat.format(item['total'])),
              ),
            ],
          );
        }).toList(),
      ],
    );
  }

  final currencyFormat = NumberFormat('#,###', 'id_ID');

  Widget buildTotalRow(String label, int value, {double fontSize = 14}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.green,
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(left: 12, right: 20),
              child: Text(
                label,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.white,
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 0, right: 12),
              child: Text(
                "Rp " + currencyFormat.format(value),
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: fontSize,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title:
            const Text('Laporan Retur', style: TextStyle(color: Colors.blue)),
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
                            if (picked != null)
                              setState(() => fromDate = picked);
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
                            if (picked != null) setState(() => toDate = picked);
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
                    child: bahanList.isEmpty
                        ? const SizedBox(
                            height: 60,
                            child: Center(child: CircularProgressIndicator()))
                        : Autocomplete<String>(
                            optionsBuilder: (TextEditingValue val) {
                              final bahanOptions = getBahanOptions(val.text);
                              final List<String> results = [
                                '',
                                ...bahanOptions
                              ];
                              return results.where((option) => option
                                  .toLowerCase()
                                  .contains(val.text.toLowerCase()));
                            },
                            onSelected: (val) {
                              if (val == '') {
                                setState(() {
                                  selectedBahan = null;
                                  bahanController.text = '';
                                });
                              } else {
                                final selected = bahanList.firstWhere(
                                  (b) => b['nama_bahan'] == val,
                                  orElse: () => {},
                                );
                                setState(() {
                                  selectedBahan = selected.isNotEmpty
                                      ? selected['nama_bahan']
                                      : null;
                                  bahanController.text = val;
                                });
                              }
                            },
                            initialValue:
                                TextEditingValue(text: selectedBahan ?? ''),
                            fieldViewBuilder: (context, textEditingController,
                                focusNode, onEditingComplete) {
                              if (bahanController.text !=
                                  textEditingController.text) {
                                bahanController.value =
                                    textEditingController.value;
                              }
                              return TextField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Nama Bahan (Optional)',
                                  border: OutlineInputBorder(),
                                ),
                                onEditingComplete: onEditingComplete,
                              );
                            },
                          ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: customerList.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : Autocomplete<String>(
                            optionsBuilder: (TextEditingValue val) {
                              final customerOptions =
                                  getCustomerOptions(val.text);
                              final List<String> results = [
                                '',
                                ...customerOptions
                              ];
                              return results.where((option) => option
                                  .toLowerCase()
                                  .contains(val.text.toLowerCase()));
                            },
                            onSelected: (val) {
                              if (val == '') {
                                setState(() {
                                  selectedCustomer = null;
                                  customerController.text = '';
                                });
                              } else {
                                final selected = customerList.firstWhere(
                                  (c) => c['nama_customer'] == val,
                                  orElse: () => {},
                                );
                                setState(() {
                                  selectedCustomer = selected.isNotEmpty
                                      ? selected['id_customer']
                                      : null;
                                  customerController.text = val;
                                });
                              }
                            },
                            initialValue: TextEditingValue(
                                text: selectedCustomer != null
                                    ? customerController.text
                                    : ''),
                            fieldViewBuilder: (context, textEditingController,
                                focusNode, onEditingComplete) {
                              if (customerController.text !=
                                  textEditingController.text) {
                                customerController.value =
                                    textEditingController.value;
                              }
                              return TextField(
                                controller: textEditingController,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Customer (Optional)',
                                  border: OutlineInputBorder(),
                                ),
                                onEditingComplete: onEditingComplete,
                              );
                            },
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }
                  return getBarcodeSuggestions(textEditingValue.text);
                },
                fieldViewBuilder: (BuildContext context,
                    TextEditingController textEditingController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted) {
                  if (barcodeController.text != textEditingController.text) {
                    barcodeController.value = textEditingController.value;
                  }

                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Barcode',
                      border: OutlineInputBorder(),
                    ),
                  );
                },
                onSelected: (String selection) {
                  barcodeController.text = selection;
                  final selectedItem = stockList.firstWhere(
                    (item) => item['barcode'] == selection,
                    orElse: () => {},
                  );

                  // Lakukan sesuatu, misalnya isi ID Bahan dan lainnya:
                  if (selectedItem.isNotEmpty) {
                    setState(() {
                      bahanController.text = selectedItem['id_bahan'] ?? '';
                      // ...tambahkan controller lain jika perlu
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchLaporanRetur,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search),
                    SizedBox(width: 8),
                    Text('Cari'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (laporanRetur.isEmpty)
                const Center(child: Text('Data tidak ditemukan'))
              else
                Column(
                  children: [
                    ...laporanRetur.map((item) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            color: Colors.grey.shade100,
                            padding: const EdgeInsets.all(8),
                          ),
                          buildDetailTable(item['details'],
                              item['id_transaksi'], item['id_customer']),
                          Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.all(12),
                            color: Colors.indigo.shade200,
                            child: Text(
                              'Total: Rp ${currencyFormat.format(item['total'])}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                    buildTotalRow('Total Retur Customer', totalReturCustomer),
                    const Divider(height: 1, color: Colors.white),
                    buildTotalRow('Total Retur Gudang', totalReturGudang),
                    const Divider(height: 1, color: Colors.white),
                    buildTotalRow('Grand Total', grandTotal, fontSize: 20),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
