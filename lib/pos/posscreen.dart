import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hayami_app/pos/cart_screen.dart';
import 'package:hayami_app/pos/struk.dart';
import 'package:http/http.dart' as http;
import 'package:hayami_app/pos/customer_model.dart';
import 'package:hayami_app/pos/product_order_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
  List<dynamic> paymentAccounts = [];
  String? selectedPaymentAccount; // ✅ dipakai oleh Dropdown
  Map<String, dynamic>? selectedPaymentAccountMap; 
  String selectedSales = 'Sales 1';
  final TextEditingController cashController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  List<Map<String, dynamic>> splitPayments = [];
  String? selectedSplitMethod;
  final TextEditingController splitAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProducts();
    fetchPaymentAccounts();
  }

  void _handleTakePayment() {
  double grandTotal = cartItems.fold(0, (sum, item) => sum + item.total);

  showStrukDialog(
    context,
    cartItems,
    selectedCustomer,
    grandTotal,
    selectedPaymentAccountMap,
    null,
  );
}

  String formatRupiah(dynamic number) {
    final formatter = NumberFormat.decimalPattern('id');
    return formatter.format(number);
  }

  void showTransactionDialog(BuildContext context, double grandTotal) {
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
    ),
    items: paymentAccounts.map((item) {
      String tipe = item['tipe']?.toString().trim().toUpperCase() ?? '';
      String displayText = (tipe == 'TRANSFER' || tipe == 'DEBET' || tipe == 'EDC')
          ? '$tipe - ${item['bank'] ?? ''} - ${item['no_akun'] ?? ''}'
          : tipe;

      return DropdownMenuItem<String>(
        value: displayText,
        child: Text(displayText),
      );
    }).toList(),
    onChanged: (val) {
      setState(() {
        selectedPaymentAccount = val;

        final selectedItem = paymentAccounts.firstWhere(
          (item) {
            String tipe = item['tipe']?.toString().trim().toUpperCase() ?? '';
            String displayText = (tipe == 'TRANSFER' || tipe == 'DEBET' || tipe == 'EDC')
                ? '$tipe - ${item['bank'] ?? ''} - ${item['no_akun'] ?? ''}'
                : tipe;
            return displayText == val;
          },
          orElse: () => <String, dynamic>{},
        );

        // Pastikan Map tidak kosong
        if (selectedItem.isNotEmpty) {
          selectedPaymentAccountMap = selectedItem;
        } else {
          selectedPaymentAccountMap = null;
        }

        if (selectedItem['no_akun'] != null &&
            selectedItem['no_akun'].toString().isNotEmpty) {
          cashController.text = formatRupiah(grandTotal);
        } else {
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
                        ),
                        items: ['Sales 1', 'Sales 2', 'Sales 3']
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (val) =>
                            setState(() => selectedSales = val!),
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
  onPressed: _handleTakePayment,
  style: TextButton.styleFrom(
    backgroundColor: Colors.green,
    foregroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(6),
    ),
    minimumSize: const Size(100, 40),
  ),
  child: const Text('Take Payment'),
),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6)),
                        minimumSize: const Size(100, 40),
                      ),
                      child: const Text('Save Draft'),
                    ),
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

  Future<void> fetchPaymentAccounts() async {
    final response =
        await http.get(Uri.parse('http://192.168.1.8/hayami/akun.php'));
    if (response.statusCode == 200) {
      final result = json.decode(response.body);
      if (result['status'] == 'success') {
        setState(() {
          paymentAccounts = result['data'];
        });
      }
    }
  }

  Future<void> fetchProducts() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? idCabang = prefs.getString('id_cabang');
      String? idUser = prefs.getString('id_user');

      if (idUser == 'admin') {
        final stockUrl = Uri.parse('http://192.168.1.8/hayami/stock.php');
        final stockResponse = await http.get(stockUrl);

        if (stockResponse.statusCode == 200) {
          final stockJson = json.decode(stockResponse.body);

          if (stockJson['status'] == 'success' &&
              stockJson['data'] != null &&
              stockJson['data'].isNotEmpty) {
            idCabang = stockJson['data'][0]['id_cabang'].toString();

            await prefs.setString('idCabang', idCabang);
          } else {
            throw Exception(
                'Data cabang tidak ditemukan di response stock.php.');
          }
        } else {
          throw Exception(
              'Gagal mengambil cabang dari stock.php: ${stockResponse.statusCode}');
        }
      } else {
        if (idCabang == null || idCabang.isEmpty) {
          throw Exception('Cabang belum diset untuk user bukan admin.');
        }
      }

      final url =
          Uri.parse('http://192.168.1.8/hayami/stockpos.php?cabang=$idCabang');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonResult = json.decode(response.body);
        if (jsonResult['status'] == 'success') {
          setState(() {
            allProducts = jsonResult['data'];
            products = allProducts;
            bahanList = allProducts
                .map<String>((item) => item['id_bahan'].toString())
                .toSet()
                .toList();
            isLoading = false;
          });
        } else {
          throw Exception('Status bukan success: ${jsonResult['status']}');
        }
      } else {
        throw Exception('Gagal memuat produk: ${response.statusCode}');
      }
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

  Future<List<Customer>> fetchCustomers(String keyword) async {
    final response = await http.get(
      Uri.parse('http://192.168.1.8/hayami/customer.php'),
    );

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);

      if (jsonData['status'] == 'success' && jsonData['data'] is List) {
        final allCustomers = (jsonData['data'] as List)
            .map((data) => Customer.fromJson(data))
            .toList();

        return allCustomers
            .where((c) =>
                c.nmCustomer.toLowerCase().contains(keyword.toLowerCase()))
            .toList();
      } else {
        throw Exception('Data tidak ditemukan atau status bukan success');
      }
    } else {
      throw Exception('Gagal memuat data customer: ${response.statusCode}');
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
                  final customers = await fetchCustomers(id);
                  setDialogState(() => searchResults = customers);
                } catch (_) {
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
              return (data.telp ?? '').isNotEmpty ? data.telp! : '';
            }

            return Dialog(
              insetPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
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
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const SizedBox(
                              width: 130,
                              child: Text('Customer ID',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w500)),
                            ),
                            Expanded(
                              child: TextField(
                                controller: customerIdController,
                                decoration: const InputDecoration(
                                  contentPadding:
                                      EdgeInsets.symmetric(horizontal: 12),
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
                                  subtitle: Text(customer.address.isNotEmpty
                                      ? customer.address
                                      : 'Alamat tidak tersedia'),
                                  onTap: () =>
                                      handleCustomerSelection(customer),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 12),
                        buildFormRow('Customer Name', customerData?.nmCustomer),
                        buildFormRow('Address', customerData?.address),
                        buildFormRow(
                            'Contact Number', getContactNumber(customerData)),
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
                              ),
                              onPressed: customerData != null
                                  ? () {
                                      setState(() =>
                                          selectedCustomer = customerData!);
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
            onAddToOrder: (items) {
              setState(() {
                cartItems.addAll(items);
              });
            },
            selectedCustomer: selectedCustomer,
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
            ? 'http://192.168.1.8/hayami/$imgPath'
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

  Widget cartSection() {
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

    // Pilih diskon manual yang aktif, nominal dulu jika ada
    double newDiscount =
        manualDiskonNominal > 0 ? manualDiskonNominal : manualDiskonPercent;

    // Total akhir
    double grandTotal = subTotal - totalDiskon - newDiscount;

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
                            isConfirmMode = false;

                            selectedCustomer = Customer(
                              id: selectedEntry.customerName,
                              nmCustomer: selectedEntry.customerName,
                              name: '',
                              address: '',
                              telp: '',
                              storeType: '',
                              diskonLusin: 0.0,
                            );

                            // ✅ Diskon otomatis masuk ke bagian 'Discount:'
                            totalDiskon = disc;

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
                                '${item.productName} - ${item.size}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(currencyFormatter.format(item.total / 12)),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  cartItems.removeAt(index);
                                  isConfirmMode = false;
                                });
                              },
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                '${(item.quantity / 12)} Ls @ Rp ${((item.unitPrice / 4)).toStringAsFixed(0)}'),
                            Text(
                                'Total: ${currencyFormatter.format((item.total / 12))}'),
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
                      onPressed: () {
                        if (selectedCustomer == null || cartItems.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Pilih customer dan minimal 1 produk terlebih dahulu.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        showTransactionDialog(context, grandTotal);
                      },
                      child: Text(
                        'GRAND TOTAL: ${currencyFormatter.format(grandTotal)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
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
        title: const Text('POS Screen'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
