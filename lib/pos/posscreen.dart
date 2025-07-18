import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:hayami_app/pos/cart_db_helper.dart';
import 'package:hayami_app/pos/cart_screen.dart';
import 'package:hayami_app/pos/customer_db_helper.dart';
import 'package:hayami_app/pos/print.dart';
import 'package:hayami_app/pos/stock_db_helper.dart';
import 'package:hayami_app/pos/struk.dart';
import 'package:hayami_app/pos/transaksi_helper.dart';
import 'package:http/http.dart' as http;
import 'package:hayami_app/pos/customer_model.dart';
import 'package:hayami_app/pos/product_order_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

Future<Database> initDatabase() async {
  final dbPath = await getDatabasesPath();
  return openDatabase(
    path.join(dbPath, 'mydb.db'),
    version: 1,
    onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE tb_akun (
          id_akun TEXT PRIMARY KEY,
          tipe TEXT,
          bank TEXT,
          nama_akun TEXT,
          no_akun TEXT,
          status_sj TEXT
        )
      ''');
    },
  );
}

Future<void> saveAccountsToLocalDB(List<Map<String, dynamic>> accounts) async {
  final db = await initDatabase();
  await db.delete('tb_akun');

  for (var item in accounts) {
    await db.insert('tb_akun', {
      'id_akun': item['id_akun']?.toString() ?? '',
      'tipe': item['tipe'] ?? '',
      'bank': item['bank'] ?? '',
      'nama_akun': item['nama_akun'] ?? '',
      'no_akun': item['no_akun'] ?? '',
      'status_sj': item['status_sj'] ?? '',
    });
  }
}

Future<List<Map<String, dynamic>>> loadAccountsFromLocalDB() async {
  final db = await initDatabase();
  return await db.query('tb_akun');
}

Future<bool> isOnline() async {
  try {
    final response = await http.get(Uri.parse('http://192.168.1.11/hayami/customer.php')).timeout(
      const Duration(seconds: 2),
    );
    return response.statusCode == 200;
  } catch (e) {
    return false;
  }
}
class Posscreen extends StatefulWidget {
  const Posscreen({super.key});

  @override
  State<Posscreen> createState() => _PosscreenState();
}

String formatRupiah(dynamic number) {
  final formatter = NumberFormat.decimalPattern('id');
  return formatter.format(number);
}

final currencyFormatter =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

class _PosscreenState extends State<Posscreen> {
  String? currentInvoiceId;
  String? currentTransactionId;
  double subTotal = 0;
  double newDiscount = 0;
  double grandTotal = 0;
  double totalDiskon = 0;
  double totalLusin = 0;
  List<dynamic> diskonCustList = [];
  List<OrderItem> cartItems = [];
  bool isConfirmMode = false;
  List<dynamic> products = [];
  bool isLoading = true;
  String searchQuery = '';
  Customer? selectedCustomer;
  bool showDiscountInput = false;
  final TextEditingController percentController = TextEditingController();
  final TextEditingController nominalController = TextEditingController();
  String selectedPayment = 'cash';
  int selectedTopDuration = 0;
  List<dynamic> allProducts = []; // untuk data asli
  List<String> bahanList = [];
  String? selectedBahan;
  List<Map<String, dynamic>> paymentAccounts = [];
  String? selectedPaymentAccount; // ✅ dipakai oleh Dropdown
  Map<String, dynamic>? selectedPaymentAccountMap;
  String selectedSales = 'Sales 1';
  final TextEditingController cashController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  List<Map<String, dynamic>> splitPayments = [];
  String? selectedSplitMethod;
  final TextEditingController splitAmountController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  final FocusNode barcodeFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    TransaksiHelper.instance.trySyncIfOnline();
    CartDBHelper.instance.syncPendingDrafts();
    fetchProducts();
    fetchPaymentAccounts();
  }
void _handleBarcodeSubmit(String barcodeInput) {
  if (barcodeInput.length < 9) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Barcode harus terdiri dari 9 digit (7 barcode + 2 qty)'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final productBarcode = barcodeInput.substring(0, 7);
  final qtyPcs = int.tryParse(barcodeInput.substring(7, 9)) ?? 0;

  final matchedProduct = allProducts.cast<Map<String, Object?>>().firstWhere(
    (prod) => prod['barcode'].toString() == productBarcode,
    orElse: () => <String, Object?>{},
  );

  if (matchedProduct.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Produk tidak ditemukan dari barcode'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final double stokTersedia = double.tryParse(matchedProduct['stock'].toString()) ?? 0;

  // Cari produk yang sama di cart
  final existingItemIndex = cartItems.indexWhere((item) =>
    item.idTipe == matchedProduct['id_bahan'].toString() &&
    item.productName == matchedProduct['model'].toString() &&
    item.size == matchedProduct['ukuran'].toString()
  );

  double existingQtyPcs = 0;
  if (existingItemIndex != -1) {
    existingQtyPcs = cartItems[existingItemIndex].quantity; // sekarang quantity = PCS
  }

  if ((existingQtyPcs + qtyPcs) > stokTersedia) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Stok tidak cukup. Tersedia hanya ${stokTersedia.toInt()} pcs'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  final unitPrice = double.tryParse(matchedProduct['harga'].toString()) ?? 0;

  setState(() {
    if (existingItemIndex != -1) {
      // Tambah qty jika sudah ada
      final existingItem = cartItems[existingItemIndex];
      final updatedItem = OrderItem(
        idTipe: existingItem.idTipe,
        productName: existingItem.productName,
        size: existingItem.size,
        quantity: existingItem.quantity + qtyPcs,
        unitPrice: existingItem.unitPrice,
      );
      cartItems[existingItemIndex] = updatedItem;
    } else {
      // Tambahkan baru
      final newItem = OrderItem(
        idTipe: matchedProduct['id_bahan'].toString(),
        productName: matchedProduct['model'].toString(),
        size: matchedProduct['ukuran'].toString(),
        quantity: qtyPcs.toDouble(),
        unitPrice: unitPrice,
      );
      cartItems.add(newItem);
    }

    barcodeController.clear();
    FocusScope.of(context).requestFocus(barcodeFocusNode);
  });
}

  Future<void> _handleTakePayment() async {
  double totalDiskon = 0;
  double totalLusin = 0;

  for (var item in cartItems) {
    final double jumlahLusin = item.quantity / 12;
    totalLusin += jumlahLusin;

    final double diskonItem = selectedCustomer!.diskonLusin * jumlahLusin;
    totalDiskon += diskonItem;
  }

  double grandTotal = calculateGrandTotal(
    items: cartItems,
    customer: selectedCustomer,
    manualDiscNominal: double.tryParse(nominalController.text) ?? 0,
    manualDiscPercent: double.tryParse(percentController.text) ?? 0,
  );

  // Simpan transaksi dan dapatkan idTransaksi dulu
  final String idTransaksi = await saveFinalTransaction();

  // Tampilkan struk dengan idTransaksi yg didapat
  await showStrukDialog(
    context,
    cartItems,
    selectedCustomer,
    grandTotal,
    selectedPaymentAccountMap,
    null,
    totalDiskon,
    newDiscount,
    totalLusin,
    splitPayments,
    idTransaksi, // pastikan param ini ada di definisi showStrukDialog
  );

  // Reset transaksi setelah dialog ditutup
  resetTransaction();

  setState(() {
  isLoading = true;
});

await fetchProducts();

setState(() {
  isLoading = false;
});

}


  void resetTransaction() {
    setState(() {
      cartItems.clear();
      selectedCustomer = null;
      nominalController.clear();
      percentController.clear();
      newDiscount = 0;
      grandTotal = 0;
      isConfirmMode = false;
      showDiscountInput = false;
      selectedPaymentAccount = null;
      selectedPaymentAccountMap = null;
      splitPayments.clear();
      splitAmountController.clear();
      cashController.clear();
      notesController.clear();
    });

  }

String generateLocalId() {
  final now = DateTime.now();
  final prefix = "C";
  
  // Format tanggal ddmmyy
  final day = now.day.toString().padLeft(2, '0');
  final month = now.month.toString().padLeft(2, '0');
  final year = (now.year % 100).toString().padLeft(2, '0'); // ambil 2 digit terakhir tahun
  
  // Nomor urut sementara pakai random 4 digit atau microsecond mod 10000
  final count = (now.microsecondsSinceEpoch % 10000).toInt();
  final urutan = count.toString().padLeft(4, '0');
  
  return "$prefix$day$month$year$urutan";
}

  String formatRupiah(dynamic number) {
    final formatter = NumberFormat.decimalPattern('id');
    return formatter.format(number);
  }

  Future<void> showTransactionDialog(
      BuildContext context, double grandTotal) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String idCabang =
        prefs.getString('id_cabang') ?? ''; // Default kosong jika tidak ada
    DateTime selectedDate = DateTime.now();
    final TextEditingController dateController = TextEditingController(
        text: DateFormat('dd/MM/yyyy').format(selectedDate));
    splitAmountController.addListener(() {
      String text =
          splitAmountController.text.replaceAll('.', '').replaceAll(',', '');
      if (text.isEmpty) return;

      final value = int.tryParse(text);
      if (value != null) {
        final newText = formatRupiah(value);
        if (splitAmountController.text != newText) {
          splitAmountController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newText.length),
          );
        }
      }
    });
    cashController.addListener(() {
      String text = cashController.text.replaceAll('.', '').replaceAll(',', '');
      if (text.isEmpty) return;

      final value = int.tryParse(text);
      if (value != null) {
        final newText = formatRupiah(value);
        if (cashController.text != newText) {
          cashController.value = TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(offset: newText.length),
          );
        }
      }
    });

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Transaksi'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    fieldRow(
                      label: 'Tgl Faktur',
                      child: TextField(
                        controller: dateController,
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedDate = picked;
                              dateController.text =
                                  DateFormat('dd/MM/yyyy').format(picked);
                            });
                          }
                        },
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    fieldRow(
  label: 'Pembayaran',
  child: DropdownButtonFormField<String>(
    value: selectedPaymentAccount,
    decoration: const InputDecoration(
      border: OutlineInputBorder(),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    items: paymentAccounts.map((item) {
      String tipe = (item['tipe']?.toString().trim().toUpperCase()) ?? '';
      String displayText = (tipe == 'TRANSFER' || tipe == 'DEBET' || tipe == 'EDC')
          ? '$tipe - ${item['bank'] ?? ''} - ${item['no_akun'] ?? ''}'
          : tipe;

      return DropdownMenuItem<String>(
        value: displayText,
        child: Text(
          displayText,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }).toList(),
    onChanged: (val) {
      setState(() {
        selectedPaymentAccount = val;

        final selectedItem = paymentAccounts.firstWhere(
          (item) {
            String tipe = (item['tipe']?.toString().trim().toUpperCase()) ?? '';
            String displayText = (tipe == 'TRANSFER' || tipe == 'DEBET' || tipe == 'EDC')
                ? '$tipe - ${item['bank'] ?? ''} - ${item['no_akun'] ?? ''}'
                : tipe;
            return displayText == val;
          },
          orElse: () => <String, dynamic>{},
        );

        if (selectedItem.isNotEmpty) {
          selectedPaymentAccountMap = selectedItem;

          if (selectedItem['no_akun'] != null &&
              selectedItem['no_akun'].toString().isNotEmpty) {
            cashController.text = formatRupiah(grandTotal);
          } else {
            cashController.clear();
          }
        } else {
          selectedPaymentAccountMap = null;
          cashController.clear();
        }

        setDialogState(() {});
      });
    },
  ),
),

                    const SizedBox(height: 10),
fieldRow(
  label: 'Sales',
  child: DropdownButtonFormField<String>(
    value: selectedSales,
    decoration: const InputDecoration(
      border: OutlineInputBorder(),
      isDense: true,
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    ),
    items: ['Sales 1', 'Sales 2', 'Sales 3'].map(
      (sales) {
        return DropdownMenuItem<String>(
          value: sales,
          child: Text(sales),
        );
      },
    ).toList(),
    onChanged: (val) {
      setState(() {
        selectedSales = val!;
      });
    },
  ),
),

                    const SizedBox(height: 10),
                    fieldRow(
                      label: 'Cash',
                      child: TextField(
                        controller: cashController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    fieldRow(
                      label: 'Keterangan',
                      child: TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    if (selectedPaymentAccount == 'SPLIT') ...[
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Split Pembayaran',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...splitPayments.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  readOnly: true,
                                  controller: TextEditingController(
                                      text: item['metode']),
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  readOnly: true,
                                  controller: TextEditingController(
                                      text: item['jumlah']),
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero),
                                ),
                                onPressed: () {
                                  setDialogState(
                                      () => splitPayments.remove(item));
                                },
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              value: selectedSplitMethod,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Pilih Metode',
                                isDense: true,
                              ),
                              items: paymentAccounts.map((item) {
                                String tipe = item['tipe']
                                        ?.toString()
                                        .trim()
                                        .toUpperCase() ??
                                    '';
                                String displayText = (tipe == 'TRANSFER' ||
                                        tipe == 'DEBET' ||
                                        tipe == 'EDC')
                                    ? '$tipe - ${item['bank'] ?? ''} - ${item['no_akun'] ?? ''}'
                                    : tipe;
                                return DropdownMenuItem(
                                    value: displayText,
                                    child: Text(displayText));
                              }).toList(),
                              onChanged: (val) {
                                setDialogState(() {
                                  selectedSplitMethod = val;

                                  // Hitung total split sementara
                                  double totalSplit = 0;
                                  for (var item in splitPayments) {
                                    final jumlah = double.tryParse(
                                            item['jumlah']
                                                .toString()
                                                .replaceAll('.', '')
                                                .replaceAll(',', '')) ??
                                        0;
                                    totalSplit += jumlah;
                                  }

                                  final sisa = grandTotal - totalSplit;

                                  // Isi nominal default
                                  splitAmountController.text =
                                      sisa > 0 ? sisa.toStringAsFixed(0) : '';
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: splitAmountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Nominal',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (selectedSplitMethod == null ||
                                  splitAmountController.text.isEmpty) {
                                return;
                              }

                              // Hitung total split saat ini
                              double totalSplit = 0;
                              for (var item in splitPayments) {
                                final jumlah = double.tryParse(item['jumlah']
                                        .toString()
                                        .replaceAll('.', '')
                                        .replaceAll(',', '')) ??
                                    0;
                                totalSplit += jumlah;
                              }

                              // Ambil jumlah yang mau ditambahkan
                              double currentInput = double.tryParse(
                                      splitAmountController.text
                                          .replaceAll('.', '')
                                          .replaceAll(',', '')) ??
                                  0;

                              // Cek jika total split setelah ditambahkan melebihi grandTotal
                              if (totalSplit + currentInput > grandTotal) {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Peringatan'),
                                    content: const Text(
                                        'Total split tidak boleh melebihi Grand Total!'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                                return;
                              }

                              setDialogState(() {
                                splitPayments.add({
                                  'metode': selectedSplitMethod!,
                                  'jumlah': splitAmountController.text,
                                });

                                // Hitung ulang sisa
                                double totalSplitBaru = 0;
                                for (var item in splitPayments) {
                                  final jumlah = double.tryParse(item['jumlah']
                                          .toString()
                                          .replaceAll('.', '')
                                          .replaceAll(',', '')) ??
                                      0;
                                  totalSplitBaru += jumlah;
                                }

                                final sisa = grandTotal - totalSplitBaru;
                                splitAmountController.text =
                                    sisa > 0 ? sisa.toStringAsFixed(0) : '';
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.zero),
                            ),
                            child: const Text('Add'),
                          ),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
              actions: [
                Wrap(
                  spacing: 8, // jarak antar tombol
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.grey,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                        minimumSize: const Size(100, 40),
                      ),
                      child: const Text('Close'),
                    ),
TextButton(
  onPressed: () async {
    // 1. Validasi SPLIT
    double totalSplit = 0;
    for (var item in splitPayments) {
      final jumlah = double.tryParse(
          item['jumlah'].toString().replaceAll('.', '').replaceAll(',', '')) ??
          0;
      totalSplit += jumlah;
    }

    if (selectedPaymentAccount == 'SPLIT' && totalSplit != grandTotal) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Peringatan"),
          content: Text(
              "Total split harus sama dengan Grand Total (${formatRupiah(grandTotal.toInt())})"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final String namaUser = prefs.getString('nm_user') ?? "admin";
      final String idCabang = prefs.getString('id_cabang') ?? "C1";

      // Ganti generate ID transaksi dan invoice pake helper yang sinkron server/offline
      final String idTransaksi = await TransaksiHelper.instance.generateIDTransaksi();
      final String idInvoice = await TransaksiHelper.instance.generateIDInvoice();

      String? akunType;
      double sisaBayar = 0;

      if (selectedPaymentAccount == 'SPLIT') {
        akunType = 'SPLIT';
      } else {
        final tipe = selectedPaymentAccountMap?['tipe'];
        akunType = tipe?.toUpperCase() ?? 'CASH';
        if (akunType == 'HUTANG') {
          sisaBayar = grandTotal;
        }
      }

      final double totalDiskonCustomer = cartItems.fold(0.0, (sum, item) {
        final jumlahDus = item.quantity / 12;
        final diskonPerDus = selectedCustomer?.diskonLusin ?? 0;
        return sum + (diskonPerDus * jumlahDus);
      });

      final double totalDiskonFinal = newDiscount ?? 0;

      for (var item in cartItems) {
        final double harga = item.unitPrice;
        final double diskon = item.discount ?? 0.0;
        final double subtotalItem = harga * item.quantity;
        final double totalItem = subtotalItem - diskon;

        final data = {
          'no_id': const Uuid().v4(),
          'id_transaksi': idTransaksi,
          'tgl_transaksi': DateTime.now().toIso8601String(),
          'id_customer': selectedCustomer?.id ?? '',
          'sales': selectedSales ?? '',
          'keterangan': '',
          'id_bahan': item.idTipe,
          'model': item.productName,
          'ukuran': item.size,
          'qty': item.quantity,
          'uom': 'PCS',
          'harga': harga,
          'subtotal': subtotalItem.toInt(),
          'total': totalItem.toInt(),
          'disc': (selectedCustomer?.diskonLusin ?? 0) * item.quantity / 12,
          'disc_nilai': diskon,
          'ppn': 0.0,
          'status_keluar': 'keluar',
          'jatuh_tempo': 0,
          'tgl_jatuh_tempo': '',
          'by_user_pajak': 1,
          'non_stock': 0,
          'id_invoice': idInvoice,
          'disc_invoice': totalDiskonFinal, // ✅ FIXED HERE
          'cust_invoice': selectedCustomer?.name ?? '',
          'tgl_invoice': DateTime.now().toIso8601String(),
          'subtotal_invoice': subTotal,
          'total_invoice': grandTotal,
          'sisa_bayar': sisaBayar,
          'cash': akunType == 'HUTANG' ? 0 : 1,
          'status': 'baru',
          'from_cust': 0,
          'qty_jenis_1': 0,
          'qty_jenis_2': 0,
          'hhp_jenis_1': 0,
          'hhp_jenis_2': 0,
          'untung': 0,
          'akun': akunType,
          'dibuat_oleh': namaUser,
          'dibuat_tgl': DateTime.now().toIso8601String(),
          'diubah_oleh': '',
          'diubah_tgl': '',
          'id_cabang': idCabang,
          'sts': 1,
          'sts_void': 0,
          'is_synced': 0,
        };

        await TransaksiHelper.instance.saveTransaksiToSQLite(data);

        await StockDBHelper.reduceStockOffline(
          item.idTipe,
          item.productName,
          item.size,
          idCabang,
          item.quantity.toDouble(),
        );
      }
       Navigator.of(context).pop();
await generateAndPrintStrukPdf(
        cartItems: cartItems,
        grandTotal: grandTotal,
        totalDiskon: totalDiskonCustomer,
        newDiscount: newDiscount,
        totalLusin: cartItems.fold(0.0, (sum, item) => sum + (item.quantity / 12)),
        selectedPaymentAccount: selectedPaymentAccountMap ?? {},
        splitPayments: splitPayments,
        collectedBy: namaUser,
        idTransaksi: idTransaksi,
      );
       resetTransaction();
      // Sync jika online
      await TransaksiHelper.instance.trySyncIfOnline();

      // Cetak struk
      

      await fetchProducts();
      resetTransaction();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal menyimpan transaksi: $e")),
      );
    }
  },
  style: TextButton.styleFrom(
    backgroundColor: selectedPaymentAccount == null || selectedPaymentAccount!.isEmpty
        ? Colors.grey
        : Colors.green,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    ),
    minimumSize: const Size(100, 40),
  ),
  child: const Text('Take Payment'),
),

                    TextButton(
onPressed: () async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String namaUser = prefs.getString('nm_user') ?? '';

    final idTransaksi = currentTransactionId ?? generateLocalId();
    final now = DateTime.now();

    // Simpan dulu ke SQLite
    for (var item in cartItems) {
      final draftItem = {
        'id_transaksi': idTransaksi,
        'tgl_transaksi': now.toIso8601String(),
        'id_customer': selectedCustomer!.id,
        'sales': selectedSales,
        'id_bahan': item.idTipe,
        'model': item.productName,
        'ukuran': item.size,
        'qty': item.quantity,
        'uom': 'PCS',
        'harga': item.unitPrice / 12,
        'subtotal': item.total,
        'total': item.total,
        'disc': selectedCustomer!.diskonLusin * item.quantity / 12,
        'disc_invoice': newDiscount,
        'subtotal_invoice': subTotal,
        'total_invoice': grandTotal,
        'dibuat_oleh': namaUser,
        'dibuat_tgl': now.toIso8601String(),
        'id_cabang': idCabang,
        'is_synced': 0,
        'diskon_lusin': selectedCustomer!.diskonLusin ?? 0.0,
      };

      await CartDBHelper.instance.insertOrUpdateCartItem(draftItem);
      await CartDBHelper.instance.syncPendingDrafts();

    }

    await CartDBHelper.instance.syncPendingDrafts();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Draft disimpan")),
    );

    setState(() {
      cartItems.clear();
      selectedCustomer = null;
      nominalController.clear();
      percentController.clear();
      newDiscount = 0;
      showDiscountInput = false;
    });

    
    
    Navigator.pop(context);
  } catch (e) {
    debugPrint("Save Draft Error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Gagal menyimpan draft: $e")),
    );
  }
},

                      style: TextButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        minimumSize: const Size(100, 40),
                      ),
                      child: const Text('Save Draft'),
                    )
                  ],
                )
              ],
            );
          },
        );
      },
    );
  }

  Widget fieldRow({required String label, required Widget child}) {
    const double rowHeight = 40;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 120,
          height: rowHeight,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            border: Border.all(color: Colors.grey.shade400),
          ),
          alignment: Alignment.centerLeft,
          child: Text(label),
        ),
        Expanded(
          child: SizedBox(
            height: rowHeight,
            child: child,
          ),
        ),
      ],
    );
  }

  double hitungHargaFinal({
    required double hargaDasar,
    required double qty, // dalam lusin
    required String idCustomer,
    required String idTipe,
    required int percentage,
    required List<Map<String, dynamic>> diskonList,
  }) {
    final hargaPersentase = hargaDasar * (percentage / 100);

    // Cari diskon dari kombinasi idCustomer dan idTipe
    final diskonData = diskonList.firstWhere(
      (d) => d['id_cust'] == idCustomer && d['id_tipe'] == idTipe,
      orElse: () => {},
    );

    double diskonPerLusin = 0;
    if (diskonData.isNotEmpty && diskonData['discp'] != null) {
      diskonPerLusin = double.tryParse(diskonData['discp']) ?? 0;
    }

    final totalDiskon = diskonPerLusin * qty; // qty dalam lusin
    final totalHarga = (hargaPersentase * qty) - totalDiskon;

    return totalHarga;
  }

  void updateDiscountFromPercent(double percent, double subTotal) {
    final nominal = subTotal * (percent / 100);
    nominalController.text = nominal.toStringAsFixed(0);
  }

  void updateDiscountFromNominal(double nominal, double subTotal) {
    final percent = (nominal / subTotal) * 100;
    percentController.text = percent.toStringAsFixed(2);
  }

Future<String> saveFinalTransaction() async {
  final connectivityResult = await Connectivity().checkConnectivity();
if (connectivityResult != ConnectivityResult.none) {
  await TransaksiHelper.instance.syncTransaksiToServer();
}


  final prefs = await SharedPreferences.getInstance();
  final String? idCabangPref = prefs.getString('id_cabang');
  final String? dibuatOlehPref = prefs.getString('nm_user');

  final url = Uri.parse("http://192.168.1.11/hayami/takepayment.php");

  final double discInvoice = newDiscount;
  final double subtotal =
      cartItems.fold(0, (sum, item) => sum + item.total / 12);
  final double grandTotal = calculateGrandTotal(
    items: cartItems,
    customer: selectedCustomer,
    manualDiscNominal: double.tryParse(nominalController.text) ?? 0,
    manualDiscPercent: double.tryParse(percentController.text) ?? 0,
  );

  String? akunType;
  double cashAmount = 0;
  double sisaBayar = 0;

  if (selectedSplitMethod != null && splitPayments.isNotEmpty) {
    akunType = "SPLIT";
    // Hitung cashAmount dan sisaBayar dari splitPayments jika perlu
  } else if (selectedPaymentAccountMap != null) {
    final tipe = selectedPaymentAccountMap!['tipe'];
    akunType = tipe.toUpperCase(); // HUTANG, CASH, TRANSFER

    if (akunType == 'HUTANG') {
      sisaBayar = grandTotal;
    } else {
      cashAmount = grandTotal;
    }
  }

  final itemsData = cartItems.map((item) {
    return {
      "idBahan": item.idTipe,
      "model": item.productName,
      "ukuran": item.size,
      "quantity": item.quantity,
      "unitPrice": item.unitPrice,
      "disc": selectedCustomer!.diskonLusin * item.quantity / 12,
      "total": item.total,
    };
  }).toList();

  final body = {
    "idCustomer": selectedCustomer?.id ?? "",
    "sales": selectedSales,
    "discInvoice": discInvoice,
    "subtotal": subtotal,
    "grandTotal": grandTotal,
    "idCabang": idCabangPref ?? "C1",
    "dibuatOleh": dibuatOlehPref ?? "admin",
    "items": itemsData,
    "akun": akunType,
    "cash": cashAmount,
    "sisa_bayar": sisaBayar,
  };

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body);
      if (resData['status'] == 'success') {
        print("Sukses simpan transaksi: ${resData['message']}");
        return resData['id_transaksi'] ?? '';
      } else {
        throw Exception('Gagal simpan transaksi: ${resData['message']}');
      }
    } else {
      throw Exception('Server error dengan status code: ${response.statusCode}');
    }
  } catch (e) {
    print("Error simpan transaksi: $e");
    rethrow; // supaya error bisa di-handle di caller jika perlu
  }
}

  Future<void> saveDraft({
    String? existingIdTransaksi,
    String? existingIdInvoice,
    required String idCustomer,
    required String sales,
    required double discInvoice,
    required double subtotal,
    required double grandTotal,
    required String idCabang,
    required String dibuatOleh,
    required List<Map<String, dynamic>> items,
  }) async {
    final url = Uri.parse("http://192.168.1.11/hayami/draft.php");

    final body = {
      "idCustomer": idCustomer,
      "sales": sales,
      "discInvoice": discInvoice,
      "subtotal": subtotal,
      "grandTotal": grandTotal,
      "idCabang": idCabang,
      "dibuatOleh": dibuatOleh,
      "items": items,
      "existingIdTransaksi": existingIdTransaksi,
      "existingIdInvoice": existingIdInvoice,
    };

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final resData = jsonDecode(response.body);
        print("Status: ${resData['status']}, Message: ${resData['message']}");
      } else {
        print("Gagal simpan draft. Kode: ${response.statusCode}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Future<bool> deleteTransaction(String idTransaksi) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.11/hayami/delete_cart.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'id_transaksi': idTransaksi}),
      );

      final responseBody = json.decode(response.body);

      if (response.statusCode == 200 && responseBody['status'] == 'success') {
        return true; // Berhasil hapus
      } else {
        throw Exception(responseBody['message'] ?? 'Gagal menghapus data');
      }
    } catch (e) {
      debugPrint('Delete Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan saat menghapus data.')),
      );
      return false;
    }
  }

Future<void> fetchPaymentAccounts() async {
  final connectivityResult = await Connectivity().checkConnectivity();

  if (connectivityResult != ConnectivityResult.none) {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.11/hayami/akun.php'));
      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          paymentAccounts = List<Map<String, dynamic>>.from(result['data']);

          // Simpan ke SQLite untuk offline
          await saveAccountsToLocalDB(paymentAccounts);
        }
      }
    } catch (e) {
      print('Gagal fetch online: $e');
      paymentAccounts = await loadAccountsFromLocalDB();
    }
  } else {
    // Offline: load dari SQLite
    paymentAccounts = await loadAccountsFromLocalDB();
  }

  setState(() {});
}

Future<void> fetchProducts() async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idCabang = prefs.getString('id_cabang');
    String? idUser = prefs.getString('id_user');

    bool online = false;
    try {
      final response = await http.get(Uri.parse('https://www.google.com')).timeout(Duration(seconds: 5));
      if (response.statusCode == 200) online = true;
    } catch (_) {
      online = false;
    }

    if (online) {
      final stockUrl = Uri.parse('http://192.168.1.11/hayami/stock.php');
      final stockResponse = await http.get(stockUrl);

      if (stockResponse.statusCode == 200) {
        final stockJson = json.decode(stockResponse.body);

        if (stockJson['status'] == 'success' && stockJson['data'] != null) {
          List<dynamic> data = stockJson['data'];
          await StockDBHelper.syncStock(List<Map<String, dynamic>>.from(data));
        }
      }
    }

    final dbResult = await StockDBHelper.fetchStock(
      idCabang: idCabang,
      isAdmin: idUser == 'admin',
    );

    setState(() {
      allProducts = dbResult;
      products = dbResult;
      bahanList = dbResult
          .map<String>((item) => item['id_bahan'].toString())
          .toSet()
          .toList();
      isLoading = false;
    });
  } catch (e) {
    setState(() {
      isLoading = false;
    });
    print('Terjadi kesalahan: $e');
  }
}

  void filterByBahan(String? bahan) {
    setState(() {
      selectedBahan = bahan;
      if (bahan == null || bahan.isEmpty) {
        products = allProducts;
      } else {
        products =
            allProducts.where((item) => item['id_bahan'] == bahan).toList();
      }
    });
  }

Future<List<Customer>> fetchCustomers(String keyword, {bool offline = false}) async {
  print('🔁 fetchCustomers dipanggil dengan offline=$offline');
  print('📥 keyword="$keyword"');

  if (offline) {
    await CustomerDBHelper.initDb();
    return await CustomerDBHelper.fetchCustomers(keyword);
  } else {
    print('🌐 Mengakses API...');

    final response = await http.get(Uri.parse('http://192.168.1.11/hayami/customer.php'));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      if (jsonData['status'] == 'success' && jsonData['data'] is List) {
        final allCustomers = (jsonData['data'] as List)
            .map((data) => Customer.fromJson(data))
            .toList();

        // Filter manual karena API tidak menerima ?keyword=
        // Sinkronisasi ke SQLite setelah fetch online
await CustomerDBHelper.syncCustomers(allCustomers);

// Filter manual karena API tidak menerima ?keyword=
final filtered = allCustomers
    .where((c) => c.nmCustomer.toLowerCase().contains(keyword.toLowerCase()))
    .toList();

        print('🌍 Ambil dari API, hasil filter: ${filtered.length}');
        return filtered;
      } else {
        throw Exception('Data tidak valid');
      }
    } else {
      throw Exception('Gagal memuat data customer: ${response.statusCode}');
    }
  }
}
  Widget buildFormRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(value ?? '',
                  style: const TextStyle(color: Colors.black87)),
            ),
          ),
        ],
      ),
    );
  }

//customer select
  void showCustomerFormDialog(BuildContext context) {
  final customerIdController = TextEditingController();
  Customer? customerData;
  List<Customer> searchResults = [];

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
Future<void> handleCustomerIdChange(String id) async {
  if (id.length >= 3) {
    try {
      final online = await isOnline();
      print('🔌 Status online: $online');

      final customers = await fetchCustomers(id, offline: !online);
      print('✅ Jumlah customer ditemukan: ${customers.length}');

      setDialogState(() => searchResults = customers);
    } catch (e) {
      print('❌ Gagal fetch customer: $e');
      setDialogState(() => searchResults = []);
    }
  } else {
    setDialogState(() => searchResults = []);
  }
}

          void handleCustomerSelection(Customer customer) {
            setDialogState(() {
              customerData = customer;
              customerIdController.text = customer.nmCustomer;
              searchResults = [];
            });
          }

          String getContactNumber(Customer? data) {
            if (data == null) return '';
            return data.telp;
          }

          return Dialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Customer',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const SizedBox(
                            width: 130,
                            child: Text(
                              'Customer ID',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: customerIdController,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: handleCustomerIdChange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (searchResults.isNotEmpty)
                        SizedBox(
                          height: 150,
                          child: ListView.builder(
                            itemCount: searchResults.length,
                            itemBuilder: (context, index) {
                              final customer = searchResults[index];
                              return ListTile(
                                title: Text(customer.nmCustomer),
                                subtitle: Text(
                                  customer.address.isNotEmpty
                                      ? customer.address
                                      : 'Alamat tidak tersedia',
                                ),
                                onTap: () => handleCustomerSelection(customer),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 12),
                      buildFormRow('Customer Name', customerData?.nmCustomer),
                      buildFormRow('Address', customerData?.address),
                      buildFormRow('Contact Number', getContactNumber(customerData)),
                      buildFormRow('Store Type', customerData?.storeType),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.grey,
                            ),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: customerData != null
                                ? () {
                                    setState(() {
                                      selectedCustomer = customerData!;
                                      currentTransactionId = null;
                                    });
                                    Navigator.pop(context);
                                  }
                                : null,
                            child: const Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

  void showProductOrderDialog(
    BuildContext context,
    Map<String, dynamic> representative,
    List<dynamic> allSizes,
  ) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 750),
          child: ProductOrderDialogContent(
            representative: representative,
            allSizes: allSizes,
            selectedCustomer: selectedCustomer,
            currentCart: List<OrderItem>.from(cartItems), // ✅ Tambahkan ini
            onAddToOrder: (updatedItems) {
              setState(() {
                cartItems =
                    updatedItems; // ✅ Replace cartItems dengan yang sudah digabung & divalidasi
              });
            },
          ),
        ),
      ),
    );
  }

  double calculateStock(dynamic item) {
    final rawStock = item['stock'];
    double stock;

    if (rawStock is num) {
      stock = rawStock.toDouble();
    } else if (rawStock is String) {
      stock = double.tryParse(rawStock) ?? 0.0;
    } else {
      return 0.0;
    }

    double result = stock / 12;

    // Bulatkan ke kelipatan 0.25 terdekat
    return (result * 4).round() / 4;
  }

  Widget buildReadOnlyField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade300,
          border: const OutlineInputBorder(),
        ),
        controller: TextEditingController(text: value ?? ''),
      ),
    );
  }

  Widget productGrid() {
    final Map<String, List<dynamic>> grouped = {};

    // 🔍 Filter berdasarkan searchQuery DAN selectedBahan
    final filtered = allProducts.where((item) {
      final tipe = item['id_bahan']?.toLowerCase() ?? '';
      final model = item['model']?.toLowerCase() ?? '';
      final query = searchQuery.toLowerCase();

      final cocokSearch = tipe.contains(query) || model.contains(query);
      final cocokDropdown = selectedBahan == null ||
          selectedBahan!.isEmpty ||
          item['id_bahan'] == selectedBahan;

      return cocokSearch && cocokDropdown;
    }).toList();

    for (var item in filtered) {
      final key = '${item['id_bahan']}|${item['model']}';
      grouped.putIfAbsent(key, () => []).add(item);
    }

    final items = grouped.entries.toList();

    return GridView.count(
      crossAxisCount: 4,
      padding: const EdgeInsets.all(8),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.65,
      children: items.map((entry) {
        final representative = entry.value.first;

        final imgPath = representative['img'];
        final imgUrl = (imgPath is String && imgPath.isNotEmpty)
            ? 'http://192.168.1.11/hayami/$imgPath'
            : 'https://via.placeholder.com/150';

        return GestureDetector(
          onTap: () =>
              showProductOrderDialog(context, representative, entry.value),
          child: Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    '${representative['id_bahan'] ?? ''}',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '${representative['model'] ?? ''}',
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Center(
                      child: Image.network(imgUrl, fit: BoxFit.contain),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    height: 60,
                    child: ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        scrollbars: false,
                        overscroll: false,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        itemCount: entry.value.length,
                        itemBuilder: (context, index) {
                          final item = entry.value[index];
                          final stock = calculateStock(item);
                          if (stock <= 0) return const SizedBox.shrink();

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['ukuran'] ?? '',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  stock.toStringAsFixed(2),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  double calculateGrandTotal({
    required List<OrderItem> items,
    required Customer? customer,
    required double manualDiscNominal,
    required double manualDiscPercent,
  }) {
    double subTotal = cartItems.fold(0, (sum, item) => sum + item.total / 12);
    double autoDisc = 0;

    if (customer != null) {
      autoDisc = items.fold(
        0,
        (sum, item) => sum + (customer.diskonLusin * item.quantity / 12),
      );
    }

    double manualDisc = manualDiscNominal > 0
        ? manualDiscNominal
        : (manualDiscPercent > 0 ? subTotal * manualDiscPercent / 100 : 0);

    return subTotal - autoDisc - manualDisc;
  }
 
  Widget cartSection() {
    final double calculatedGrandTotal = calculateGrandTotal(
      items: cartItems,
      customer: selectedCustomer,
      manualDiscNominal: double.tryParse(nominalController.text) ?? 0,
      manualDiscPercent: double.tryParse(percentController.text) ?? 0,
    );
    double subTotal = cartItems.fold(0, (sum, item) => sum + item.total / 12);
    double totalQty =
        cartItems.fold(0, (sum, item) => sum + item.quantity / 12);

    String formatLusinQty(double qty) {
      if (qty < 1) {
        // Tampilkan dalam pcs (1 lusin = 12 pcs)
        int pcs = (qty * 12).round();
        return '$pcs pcs';
      } else {
        // Tampilkan dalam desimal Lusin
        return qty.toStringAsFixed(qty % 1 == 0 ? 0 : 2) + ' Lusin';
      }
    }

    double calculateAutoDiskon() {
      double autoDiskon = 0;
      if (selectedCustomer != null) {
        final diskonPerLusin = selectedCustomer!.diskonLusin;

        for (var item in cartItems) {
          final qty = item.quantity;

          final potonganDiskon = diskonPerLusin * qty / 12;
          autoDiskon += potonganDiskon;
        }
      }
      return autoDiskon;
    }

    // Hitung diskon otomatis saja
    double totalDiskon = calculateAutoDiskon();

    // Hitung diskon manual dari input nominal dan persen
    double manualDiskonNominal = double.tryParse(nominalController.text) ?? 0;
    double manualDiskonPercent = double.tryParse(percentController.text) != null
        ? (subTotal * (double.tryParse(percentController.text)! / 100))
        : 0;

    newDiscount =
        manualDiskonNominal > 0 ? manualDiskonNominal : manualDiskonPercent;
    grandTotal = subTotal - totalDiskon - newDiscount;
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.zero, // Sudut kotak
                    ),
                  ),
                  onPressed: () => showCustomerFormDialog(context),
                  child: Center(
                    child: Text(
                      selectedCustomer?.nmCustomer ?? 'Select Customer',
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign
                          .center, // supaya teks rata tengah dan wrap ke baris baru
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero, // Sudut kotak
                      ),
                    ),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CartScreen(
                            customerId: selectedCustomer?.nmCustomer ?? '',
                            cartItems: cartItems,
                            grandTotal: grandTotal,
                            onSelect: (entry) {},
                            onDelete: (entry) {},
                          ),
                        ),
                      );

                      if (result != null && result is Map<String, dynamic>) {
                        final selectedItems =
                            result['items'] as List<OrderItem>?;
                        final selectedEntry = result['entry'] as CartEntry?;
                        final String? idTransaksi =
                            result['idTransaksi'] as String?;
                        final String? idInvoice =
                            result['idInvoice'] as String?;

                        if (selectedItems != null && selectedEntry != null) {
                          // Ambil semua nilai diskon dari result
                          final double disc = result['disc'] as double? ??
                              0.0; // diskon otomatis
                          final double discPersen =
                              result['discPersen'] as double? ??
                                  0.0; // diskon manual (%)
                          final double discBaru =
                              result['discBaru'] as double? ??
                                  0.0; // diskon manual (Rp)

                          setState(() {
                            // Ganti cart dan customer
                            cartItems = selectedItems;
                            currentTransactionId = idTransaksi;
                            currentInvoiceId = idInvoice;
                            isConfirmMode = false;

                            selectedCustomer = Customer(
                              id: selectedEntry.customerName,
                              nmCustomer: selectedEntry.customerName,
                              name: '',
                              address: '',
                              telp: '',
                              storeType: '',
                              diskonLusin: selectedEntry.diskonLusin,
                              kota: '',
                              email: '',
                              sourceCustomer: '',
                              noNpwp: '',
                              namaNpwp: '',
                              alamatNpwp: '',
                              idLogin: '',
                              passLogin: '',
                              idCabang: '',
                              sts: '',
                            );
                            // ✅ Diskon otomatis masuk ke bagian 'Discount:'
                            totalDiskon = calculateAutoDiskon();

                            // ✅ Diskon manual masuk ke bagian 'New Discount:'
                            if (discBaru > 0) {
                              // Jika nominal ada, isi hanya nominal
                              nominalController.text =
                                  discBaru.toStringAsFixed(0);
                              percentController.text = '';
                            } else if (discPersen > 0) {
                              // Jika hanya persentase yang tersedia
                              percentController.text =
                                  discPersen.toStringAsFixed(2);
                              nominalController.text = '';
                            } else {
                              // Jika tidak ada diskon manual, kosongkan keduanya
                              nominalController.text = '';
                              percentController.text = '';
                            }
                          });
                        }
                      }
                    },
                    child: const Text(
                      'Cart',
                      style: TextStyle(color: Colors.white),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Expanded(
                          child: Text('Items',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Text('Total',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  ...cartItems.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.idTipe} ${item.productName} - ${item.size}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(currencyFormatter.format(item.total / 12)),
IconButton(
  icon: Icon(Icons.delete, color: Colors.red),
  onPressed: () async {
    final item = cartItems[index];
    final idTipe = item.idTipe;
    final productName = item.productName;
    final size = item.size;

    final idTransaksi = currentTransactionId ?? '';

    // Panggil method hapus dengan tambahan idTransaksi
    await CartDBHelper.instance.deleteCartItemByDetails(idTransaksi, idTipe, productName, size);

    setState(() {
      cartItems.removeAt(index);
    });
  },
),                              ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(item.quantity / 12).toStringAsFixed(2)} Ls @ ${currencyFormatter.format(item.unitPrice / 4)} /3pcs',
                            ),
                            Text(
                              'Total: ${currencyFormatter.format(item.total / 12)}',
                            ),
                          ],
                        ),
                        const Divider(),
                      ],
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isConfirmMode ? Colors.red : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero, // Sudut kotak
                        ),
                      ),
                      onPressed: (cartItems.isEmpty && !isConfirmMode)
                          ? null
                          : () {
                              setState(() {
                                if (isConfirmMode) {
                                  cartItems.clear();
                                  isConfirmMode = false;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Cart cleared')),
                                  );
                                } else {
                                  isConfirmMode = true;
                                }
                              });
                            },
                      child: Text(
                        isConfirmMode ? 'Confirm' : 'Clear Items',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // KIRI
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                showDiscountInput = !showDiscountInput;
                                percentController.clear();
                                nominalController.clear();
                              });
                            },
                            child: const Text('New Discount'),
                          ),
                          const SizedBox(height: 8),
                          const Text('Total QTY:'),
                          Text(formatLusinQty(totalQty)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Sub-Total:'),
                          Text(currencyFormatter.format(subTotal)),
                          const SizedBox(height: 8),
                          const Text('Discount:'), // Diskon otomatis
                          Text(currencyFormatter.format(totalDiskon)),
                          const SizedBox(height: 8),
                          const Text('New Discount:'), // Diskon manual
                          Text(currencyFormatter.format(newDiscount)),
                        ],
                      ),
                    ],
                  ),
                  if (showDiscountInput) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: percentController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Disc (%)',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              final percent = double.tryParse(value) ?? 0;
                              updateDiscountFromPercent(percent, subTotal);
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: nominalController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Disc (Rp.)',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (value) {
                              final nominal = double.tryParse(value) ?? 0;
                              updateDiscountFromNominal(nominal, subTotal);
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero, // Sudut kotak
                        ),
                      ),
onPressed: () async {
  if (selectedCustomer == null || cartItems.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Pilih customer dan minimal 1 produk terlebih dahulu.'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  List<String> produkStokKosong = [];

  for (var item in cartItems) {
    final matchedProduct = allProducts.cast<Map<String, Object?>>().firstWhere(
      (prod) =>
          (prod['id_bahan'] as String?)?.toLowerCase() == item.idTipe.toLowerCase() &&
          (prod['model'] as String?)?.toLowerCase() == item.productName.toLowerCase() &&
          (prod['ukuran'] as String?)?.toLowerCase() == item.size.toLowerCase(),
      orElse: () => <String, Object?>{'stock': 0.0},
    );

    final stock = calculateStock(matchedProduct);

    if (stock < 0.001) {
      produkStokKosong.add('${item.idTipe} - ${item.productName} - ${item.size}');
    }
  }

  if (produkStokKosong.isNotEmpty) {
    // Tampilkan 1 alert berisi daftar produk bermasalah
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stok Tidak Tersedia'),
        content: Text('Maaf, stok untuk produk berikut tidak tersedia:\n\n' +
            produkStokKosong.join('\n')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return;
  }

  // Jika semua stok OK
  showTransactionDialog(context, grandTotal);
},
                      child: Text(
                        'GRAND TOTAL: ${currencyFormatter.format(grandTotal)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
Row(
  children: [
    Expanded(
      child: TextField(
        controller: barcodeController,
        focusNode: barcodeFocusNode,
        decoration: InputDecoration(
          labelText: "Input Barcode",
          labelStyle: const TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
          hintText: "Masukkan barcode produk",
          hintStyle: TextStyle(color: Colors.grey.shade400),
          prefixIcon: Icon(Icons.qr_code_scanner, color: Colors.blue.shade800),
          filled: true,
          fillColor: Colors.grey.shade200,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: barcodeFocusNode.hasFocus
                  ? Colors.blue.shade800
                  : Colors.grey,
              width: 2,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                BorderSide(color: Colors.blue.shade800, width: 2),
          ),
        ),
        onChanged: (val) {
          // Logic jika ingin realtime input
        },
      ),
    ),
    const SizedBox(width: 8),
    ElevatedButton(
  onPressed: () {
    final barcode = barcodeController.text.trim();
    if (barcode.isNotEmpty) {
      _handleBarcodeSubmit(barcode);
    }
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.indigo,
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  child: const Text('Kirim', style: TextStyle(color: Colors.white)),
),
  ],
),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text(
    'POS HAYAMI',
    style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
  ),
  elevation: 0,
  backgroundColor: Colors.white,
  foregroundColor: Colors.blue, // Menetapkan warna biru untuk ikon dan teks
  leading: IconButton(
    icon: const Icon(
      Icons.arrow_back,
      color: Colors.blue, // Mengubah warna ikon back menjadi biru
    ),
    onPressed: () => Navigator.pop(context),
  ),
  actions: [
    IconButton(
      icon: const Icon(Icons.sync, color: Colors.blue), // Mengubah warna ikon sync menjadi biru
      tooltip: 'Sinkronisasi Cart',
      onPressed: () async {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sinkronisasi dimulai...')),
        );
        await CartDBHelper.instance.syncPendingDrafts();
        await TransaksiHelper.instance.trySyncIfOnline();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sinkronisasi selesai, data lokal diperbarui.')),
        );
      },
    ),
  ],
),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: selectedBahan,
                          decoration: const InputDecoration(
                            labelText: 'Pilih Bahan',
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          items: bahanList.map((bahan) {
                            return DropdownMenuItem<String>(
                              value: bahan,
                              child: Text(
                                bahan,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: filterByBahan,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Search by Tipe or Model',
                            prefixIcon: Icon(Icons.search, size: 20),
                            border: OutlineInputBorder(),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                          ),
                          onChanged: (value) =>
                              setState(() => searchQuery = value),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: productGrid()),
                      Expanded(flex: 2, child: cartSection()),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
