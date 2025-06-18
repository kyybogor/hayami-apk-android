import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hayami_app/pos/cart_screen.dart';
import 'package:http/http.dart' as http;
import 'package:hayami_app/pos/customer_model.dart';
import 'package:hayami_app/pos/product_order_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Posscreen extends StatefulWidget {
  const Posscreen({super.key});

  @override
  State<Posscreen> createState() => _PosscreenState();
}

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

  @override
  void initState() {
    super.initState();
    fetchProducts();
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
    Uri.parse('http://192.168.1.35/glorboo/tb_customer.php'),
  );

  if (response.statusCode == 200) {
    final jsonData = jsonDecode(response.body);

    if (jsonData['status'] == 'success' && jsonData['data'] is List) {
      final allCustomers = (jsonData['data'] as List)
          .map((data) => Customer.fromJson(data))
          .toList();

      return allCustomers.where((c) =>
        c.nmCustomer.toLowerCase().contains(keyword.toLowerCase())
      ).toList();
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
    final stock = item['stock'];
    if (stock is num) {
      return stock.toDouble();
    } else if (stock is String) {
      return double.tryParse(stock) ?? 0.0;
    } else {
      return 0.0;
    }
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
                  Column(
                    children: entry.value.map((item) {
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
                              stock.toStringAsFixed(1),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
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
    double subTotal = cartItems.fold(0, (sum, item) => sum + item.total);
    double totalQty = cartItems.fold(0, (sum, item) => sum + item.quantity);

    double calculateAutoDiskon() {
  double autoDiskon = 0;
  if (selectedCustomer != null) {
    final diskonPerLusin = selectedCustomer!.diskonLusin;

    for (var item in cartItems) {
      final qty = item.quantity;

      final potonganDiskon = diskonPerLusin * qty;
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
                            Text('Rp ${item.total.toStringAsFixed(0)}'),
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
                                '${item.quantity} @ Rp ${item.unitPrice.toStringAsFixed(0)}'),
                            Text('Total: Rp ${item.total.toStringAsFixed(0)}'),
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
                          Text('${totalQty.toStringAsFixed(1)} Lusin'),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Sub-Total:'),
                          Text('Rp ${subTotal.toStringAsFixed(0)}'),
                          const SizedBox(height: 8),
                          const Text('Discount:'), // Diskon otomatis
                          Text('Rp ${totalDiskon.toStringAsFixed(0)}'),
                          const SizedBox(height: 8),
                          const Text('New Discount:'), // Diskon manual
                          Text('Rp ${newDiscount.toStringAsFixed(0)}'),
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
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Payment',
                            isDense: true,
                          ),
                          value: selectedPayment,
                          items: const [
                            DropdownMenuItem(
                                value: 'cash', child: Text('Cash')),
                            DropdownMenuItem(
                                value: 'credit', child: Text('Credit')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedPayment = value!;
                              selectedTopDuration =
                                  (selectedPayment == 'cash') ? 0 : 30;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: (selectedPayment == 'credit')
                            ? DropdownButtonFormField<int>(
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Durasi Top',
                                  isDense: true,
                                ),
                                value: selectedTopDuration,
                                items: const [
                                  DropdownMenuItem(
                                      value: 30, child: Text('30 Hari')),
                                  DropdownMenuItem(
                                      value: 60, child: Text('60 Hari')),
                                  DropdownMenuItem(
                                      value: 90, child: Text('90 Hari')),
                                  DropdownMenuItem(
                                      value: 120, child: Text('120 Hari')),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedTopDuration = value!;
                                  });
                                },
                              )
                            : TextField(
                                enabled: false,
                                controller: TextEditingController(
                                  text: '0',
                                ),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Durasi Top',
                                  isDense: true,
                                ),
                              ),
                      ),
                    ],
                  ),
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
                      onPressed: () {},
                      child: Text(
                        'GRAND TOTAL: Rp ${grandTotal.toStringAsFixed(0)}',
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
                        child: SizedBox(
                          height: 40,
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
                                child: Text(bahan,
                                    overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: filterByBahan,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            decoration: const InputDecoration(
                              hintText: 'Search by Tipe or Model',
                              prefixIcon: Icon(Icons.search),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onChanged: (value) =>
                                setState(() => searchQuery = value),
                          ),
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
