import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hayami_app/pos/barangmasuk.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class Detailbarangmasuk extends StatefulWidget {
  final Map<String, dynamic> invoice;

  const Detailbarangmasuk({super.key, required this.invoice});

  @override
  State<Detailbarangmasuk> createState() => _DetailbarangmasukState();
}

class _DetailbarangmasukState extends State<Detailbarangmasuk> {
  List<dynamic> barang = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchProduct();
  }

  void showPrintBarcodeDialog() {
  final selectedItems = <Map<String, dynamic>>[];  // Barang yang dipilih
  final TextEditingController qtyController = TextEditingController();
  bool isSelectAll = false;  // Untuk menentukan apakah semua barang dipilih

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
                          selectedItems.addAll(barang.cast<Map<String, dynamic>>());
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
                      subtitle: Text("Model: ${item['model']} | Stok: ${item['jumlah']} ${item['uom']}"),
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

Future<void> generateAndPrintBarcodePdf(
    List<Map<String, dynamic>> items, int qtyPerBarcode) async {
  final pdf = pw.Document();
  int totalPages = 0;

  for (var item in items) {
    final rawBarcode = item['barcode'] ?? '';
    final barcodeBase = rawBarcode.replaceAll(RegExp(r'[^0-9]'), '').padLeft(7, '0');

    if (barcodeBase.length != 7) continue; // Skip jika barcode tidak valid

    final stockLusin = double.tryParse(item['jumlah'] ?? '0') ?? 0;
    final stockPcs = (stockLusin * 12).toInt();  // Ubah lusin menjadi pcs

    // Menghitung jumlah barcode yang perlu dicetak
    int remaining = stockPcs;
    int barcodeCount = (remaining / qtyPerBarcode).ceil();  // Jumlah barcode yang perlu dicetak

    while (remaining > 0) {
      final qty = remaining >= qtyPerBarcode ? qtyPerBarcode : remaining;
      final qtyString = qty.toString().padLeft(2, '0');  // Menambahkan dua digit untuk qty
      final fullBarcode = "$barcodeBase$qtyString";  // Gabungkan barcode dengan qty

      // Menambahkan halaman baru ke PDF untuk setiap barcode
      pdf.addPage(
  pw.Page(
    build: (pw.Context context) {
      return pw.Center(
        child: pw.Column(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            // Bagian atas: ID_BAHAN dan qty
            pw.Center(
  child: pw.Text(
    '${item['nama_barang'] ?? ''}  x$qty',
    textAlign: pw.TextAlign.center,
    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
  ),
),

            pw.SizedBox(height: 2),
            
            // Baris kedua: Model dan Ukuran
            pw.Text(
              '${item['model'] ?? ''} ${item['ukuran'] ?? ''}',
              style: pw.TextStyle(fontSize: 10),
            ),
            pw.SizedBox(height: 8),

            // Barcode
            pw.BarcodeWidget(
              barcode: pw.Barcode.code128(),
              data: fullBarcode,
              width: 150,
              height: 50,
              drawText: false,
            ),
            pw.SizedBox(height: 4),

            // Nomor barcode di bawah gambar
            pw.Text(
              fullBarcode,
              style: pw.TextStyle(fontSize: 12),
            ),
          ],
        ),
      );
    },
  ),
);

      remaining -= qty;
      totalPages++;  // Hitung total halaman yang dicetak
    }
  }

  if (totalPages == 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Tidak ada barcode valid untuk dicetak.")),
    );
    return;
  }

  // Proses pencetakan PDF
  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}

Future<void> fetchProduct() async {
  setState(() {
    isLoading = true;
  });

  final idTransaksi = widget.invoice['id']?.toString() ?? '';
  final url = Uri.parse("http://192.168.1.11/pos/masuk_detail.php?id_transaksi=$idTransaksi");

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        final List<dynamic> produkList = jsonData['data'];

        // Mengambil data stock
        final stockResponse = await http.get(Uri.parse('http://192.168.1.11/hayami/stock.php'));
        final List<dynamic> stockList = json.decode(stockResponse.body)['data'];

        // Menyamakan data produk dengan stock
        final List<Map<String, dynamic>> parsedProduk = produkList.map<Map<String, dynamic>>((item) {
          final matchingStock = stockList.firstWhere(
            (stockItem) => stockItem['id_bahan'] == item['id_product'] &&
                           stockItem['model'] == item['model'] &&
                           stockItem['ukuran'] == item['ukuran'],
            orElse: () => null,
          );

          final barcode = matchingStock != null ? matchingStock['barcode'] : '';

          final qty = double.tryParse(item['qty']?.toString() ?? '0') ?? 0;
          final harga = double.tryParse(item['harga']?.toString() ?? '0') ?? 0;
          final total = double.tryParse(item['total']?.toString() ?? '0') ?? 0;

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
    final idTransaksi = widget.invoice['id']?.toString() ?? '';
    final prefs = await SharedPreferences.getInstance();
    final idCabang = prefs.getString('id_cabang') ?? '';
    final url = Uri.parse('http://192.168.1.11/pos/inbond.php?id_transaksi=$idTransaksi&id_cabang=$idCabang');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Konfirmasi"),
          content: const Text("Apakah Anda yakin ingin approve transaksi ini?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Tidak"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  final response = await http.get(url);
                  if (response.statusCode == 200) {
                    final data = json.decode(response.body);
                    if (data['status'] == 'success') {
                      setState(() {
                        widget.invoice['status'] = 's';
                      });
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => Barangmasuk()),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Barang berhasil di-approve")),
                      );
                    }
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
              },
              child: const Text("Ya"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Detail Barang Masuk", style: TextStyle(color: Colors.blue)),
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
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: barang.length,
                        itemBuilder: (context, index) {
                          final item = barang[index];
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
                  onPressed: handleApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Approve',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            ),
          if (widget.invoice['status']?.toString() == 's')
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: showPrintBarcodeDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
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
            ),
        ],
      ),
    );
  }
}
