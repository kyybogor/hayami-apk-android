import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:hayami_app/pos/customer_model.dart';
import 'package:hayami_app/pos/product_order_dialog.dart';

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
    final response = await http.get(Uri.parse(
        'https://hayami.id/apps/erp/api-android/api/master_produk.php'));
    if (response.statusCode == 200) {
      final jsonResult = json.decode(response.body);
      setState(() {
        products = jsonResult['all_product'];
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load products');
    }
  }

Future<List<Customer>> fetchCustomers(String keyword) async {
  final response = await http.get(Uri.parse(
      'http://hayami.id/apps/erp/api-android/api/kontak.php'));
  if (response.statusCode == 200) {
    final jsonData = jsonDecode(response.body);
    diskonCustList = jsonData['diskon_cust_data'];      final allCustomers = (jsonData['customer_data'] as List)
          .map((c) => Customer.fromJson(c))
          .toList();
      return allCustomers
          .where(
              (c) => c.nmCustomer.toLowerCase().contains(keyword.toLowerCase()))
          .toList();
    } else {
      throw Exception('Failed to load customers');
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
              if ((data.telp ?? '').isNotEmpty) return data.telp!;
              return data.telp2 ?? '';
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
                        buildFormRow('Store Type', customerData?.salesman),
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

  void showProductOrderDialog(BuildContext context,
      Map<String, dynamic> representative, List<dynamic> allSizes) {
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
  diskonData: diskonCustList, // <- ini perlu Anda simpan saat fetch customer
),

        ),
      ),
    );
  }

  double calculateStock(dynamic item) {
    final qty = double.tryParse(item['qty']) ?? 0.0;
    final clear = double.tryParse(item['qtyclear']) ?? 0.0;
    final doClear = double.tryParse(item['qtycleardo']) ?? 0.0;
    return qty - (clear + doClear);
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
    final filtered = products.where((item) {
      final tipe = item['tipe']?.toLowerCase() ?? '';
      final model = item['gambar']?.toLowerCase() ?? '';
      final query = searchQuery.toLowerCase();
      return tipe.contains(query) || model.contains(query);
    }).toList();

    for (var item in filtered) {
      final key = '${item['id_tipe']}|${item['tipe']}|${item['gambar']}';
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
        final imgUrl = 'https://hayami.id/apps/erp/${representative['img']}';
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
                    representative['tipe'],
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    representative['gambar'],
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
                                child: Text(item['size'],
                                    style: const TextStyle(fontSize: 12))),
                            const SizedBox(width: 10),
                            Text(stock.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 12)),
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

  double calculateTotalDiskon() {
  double autoDiskon = 0;
  if (selectedCustomer != null) {
    final customerId = selectedCustomer!.id;
    final percentage = int.tryParse(selectedCustomer!.percentage) ?? 100;

    for (var item in cartItems) {
      final hargaDasar = item.unitPrice;
      final qty = item.quantity;

      final diskonEntry = diskonCustList.firstWhere(
        (d) => d['id_cust'] == customerId && d['id_tipe'] == item.idTipe,
        orElse: () => {},
      );

      final diskonPerLusin = double.tryParse(diskonEntry['discp'] ?? '0') ?? 0;

      final hargaSetelahPersen = hargaDasar * (percentage / 100);
      final potonganDiskon = diskonPerLusin * qty;

      autoDiskon += potonganDiskon;
    }
  }

  final manualDiskon = double.tryParse(nominalController.text) ?? 0;

  return autoDiskon + manualDiskon;
}

  double totalDiskon = calculateTotalDiskon();
  double grandTotal = subTotal - totalDiskon;

  return Container(
    padding: const EdgeInsets.all(12),
    color: Colors.grey[100],
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
                onPressed: () => showCustomerFormDialog(context),
                child: Text(selectedCustomer?.nmCustomer ?? 'Select Customer'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
                onPressed: () {},
                child: const Text('Cart'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Scrollable content area
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
                    Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
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
                              style: const TextStyle(fontWeight: FontWeight.bold),
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () {
                      setState(() {
                        if (isConfirmMode) {
                          cartItems.clear();
                          isConfirmMode = false;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cart cleared')),
                          );
                        } else {
                          isConfirmMode = true;
                        }
                      });
                    },
                    child: Text(isConfirmMode ? 'Confirm' : 'Clear Items'),
                  ),
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Sub-Total :'),
        Text('Rp ${subTotal.toStringAsFixed(0)}'),
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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total QTY :'),
                        Text('${(totalQty).toStringAsFixed(1)} Lusin'),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Discount :'),
                        Text('Rp ${totalDiskon.toStringAsFixed(0)}'),
                      ],
                    ),
                  ],
                ),
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
                        items: const [
                          DropdownMenuItem(value: 'cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'credit', child: Text('Credit')),
                        ],
                        onChanged: (value) {},
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: TextField(
                        enabled: false,
                        decoration: InputDecoration(
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
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                    onPressed: () {},
                    child: Text(
                      'GRAND TOTAL: Rp ${grandTotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
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
                      SizedBox(
                        width: 300,
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