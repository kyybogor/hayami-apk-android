import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hayami_app/pemesanan/konfirmasipesanan.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Customer {
  final String idCustomer;
  final String nmCustomer;

  Customer({required this.idCustomer, required this.nmCustomer});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      idCustomer: json['id_customer'] ?? '',
      nmCustomer: json['nm_customer'] ?? '',
    );
  }
}

class Produk {
  final String sku;
  final double qty;
  final double qtyclear;
  final double qtycleardo;
  final double harga;
  double orderQty; // jumlah yang dipesan dalam satuan lusin

  Produk({
    required this.sku,
    required this.qty,
    required this.qtyclear,
    required this.qtycleardo,
    required this.harga,
    this.orderQty = 0.0,
  });

  factory Produk.fromJson(Map<String, dynamic> json) {
    return Produk(
      sku: json['sku'] ?? '',
      qty: double.tryParse(json['qty'] ?? '0') ?? 0.0,
      qtyclear: double.tryParse(json['qtyclear'] ?? '0') ?? 0.0,
      qtycleardo: double.tryParse(json['qtycleardo'] ?? '0') ?? 0.0,
      harga: double.tryParse(json['harga'] ?? '0') ?? 0.0,
    );
  }

  double get availableQty => qty - (qtyclear + qtycleardo);
  double get totalHarga => orderQty * harga;
}

class Tambahpesanan extends StatefulWidget {
  const Tambahpesanan({super.key});

  @override
  State<Tambahpesanan> createState() => _TambahpesananState();
}

class _TambahpesananState extends State<Tambahpesanan> {
  String? selectedCustomer;
  String? selectedSku;

  List<Customer> customers = [];
  List<Produk> skus = [];
  List<Produk> cartItems = [];

  @override
  void initState() {
    super.initState();
    fetchCustomers();
    fetchSkus();
  }

  Future<void> fetchCustomers() async {
    try {
      final response = await http.get(
        Uri.parse('http://hayami.id/apps/erp/api-android/api/kontak.php'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          customers = data
              .map((json) => Customer.fromJson(json))
              .where((c) => c.nmCustomer.isNotEmpty)
              .toList();
        });
      } else {
        throw Exception('Gagal mengambil data customer');
      }
    } catch (e) {
      print('Error fetchCustomers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat data customer')),
      );
    }
  }

  Future<void> fetchSkus() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://hayami.id/apps/erp/api-android/api/master_produk.php'),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['all_product'] ?? [];

        setState(() {
          skus = data
              .map((json) => Produk.fromJson(json))
              .where((p) => p.sku.isNotEmpty)
              .toList();
        });
      } else {
        throw Exception('Gagal mengambil data SKU');
      }
    } catch (e) {
      print('Error fetchSkus: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal memuat data SKU')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F9),
      appBar: AppBar(
        centerTitle: true,
        title:
            const Text("Tambah Pesanan", style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // FORM UTAMA DALAM CONTAINER
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  customers.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _autocompleteCustomerDropdown(),
                  const SizedBox(height: 24),
                  skus.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _autocompleteSkuDropdown(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_outline,
                          size: 20, color: Colors.white),
                      label: const Text("Simpan Pesanan",
                          style: TextStyle(fontSize: 15)),
                      onPressed: () {
                        if (selectedCustomer != null && selectedSku != null) {
                          final selectedProduct = skus.firstWhere(
                            (p) => p.sku == selectedSku,
                            orElse: () => Produk(
                              sku: selectedSku!,
                              qty: 0,
                              qtyclear: 0,
                              qtycleardo: 0,
                              harga: 0,
                              orderQty: 0.0,
                            ),
                          );

                          setState(() {
                            cartItems.add(Produk(
                              sku: selectedProduct.sku,
                              qty: selectedProduct.qty,
                              qtyclear: selectedProduct.qtyclear,
                              qtycleardo: selectedProduct.qtycleardo,
                              harga: selectedProduct.harga,
                              orderQty: 0.0,
                            ));
                            selectedSku = null;
                          });

                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                                'Pesanan untuk $selectedCustomer - ${selectedProduct.sku} disimpan.'),
                          ));
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Lengkapi semua data.')),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        shadowColor: Colors.blueAccent.withOpacity(0.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // SPASI ANTARA FORM DAN KERANJANG
            const SizedBox(height: 32),

            // KERANJANG PESANAN DI LUAR CONTAINER
            if (cartItems.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("🛒 Keranjang Pesanan:",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...cartItems.map((item) => Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.sku,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  // Available
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'Available: ${item.availableQty.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),

                                  // Quantity Picker (0.5 step)
                                  Expanded(
                                    flex: 4,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                              Icons.remove_circle_outline),
                                          onPressed: () {
                                            setState(() {
                                              if (item.orderQty > 0) {
                                                item.orderQty -= 0.5;
                                              }
                                            });
                                          },
                                        ),
                                        Text(
                                            '${item.orderQty.toStringAsFixed(1)} lusin',
                                            style:
                                                const TextStyle(fontSize: 14)),
                                        IconButton(
                                          icon: const Icon(
                                              Icons.add_circle_outline),
                                          onPressed: () {
                                            setState(() {
                                              item.orderQty += 0.5;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Total Harga & Delete
                                  Expanded(
                                    flex: 3,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        children: [
                                          Text(
                                            'Rp ${NumberFormat("#,##0", "id_ID").format(item.totalHarga)}',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red),
                                            onPressed: () {
                                              setState(() {
                                                cartItems.remove(item);
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      )),

                  const SizedBox(height: 24),

// Tombol Next
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text("Lanjut ke Konfirmasi"),
                      onPressed: () {
  if (selectedCustomer != null && cartItems.isNotEmpty) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => KonfirmasiPesanan(
  selectedCustomer: selectedCustomer!,
  cartItems: cartItems,
),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lengkapi customer dan isi keranjang')),
    );
  }
},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _autocompleteCustomerDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("🧑 Pilih Customer",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        RawAutocomplete<String>(
          textEditingController:
              TextEditingController(text: selectedCustomer ?? ''),
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text == '') {
              return const Iterable<String>.empty();
            }
            return customers.map((e) => e.nmCustomer).where((option) => option
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase()));
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Ketik nama customer',
                filled: true,
                fillColor: const Color(0xFFF1F3F6),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) {
                onFieldSubmitted();
                setState(() {
                  selectedCustomer = value;
                });
              },
            );
          },
          onSelected: (String selection) {
            setState(() {
              selectedCustomer = selection;
            });
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: options.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return ListTile(
                      title: Text(option),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _autocompleteSkuDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("📦 Pilih SKU",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        RawAutocomplete<String>(
          textEditingController: TextEditingController(text: selectedSku ?? ''),
          focusNode: FocusNode(),
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text == '') {
              return const Iterable<String>.empty();
            }
            return skus.map((e) => e.sku).where((option) => option
                .toLowerCase()
                .contains(textEditingValue.text.toLowerCase()));
          },
          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                hintText: 'Ketik SKU produk',
                filled: true,
                fillColor: const Color(0xFFF1F3F6),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) {
                onFieldSubmitted();
                setState(() {
                  selectedSku = value;
                });
              },
            );
          },
          onSelected: (String selection) {
            setState(() {
              selectedSku = selection;
            });
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: options.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    final option = options.elementAt(index);
                    return ListTile(
                      title: Text(option),
                      onTap: () => onSelected(option),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
