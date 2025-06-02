import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class TambahPesananPage extends StatefulWidget {
  const TambahPesananPage({super.key});

  @override
  State<TambahPesananPage> createState() => _TambahPesananPageState();
}

class _TambahPesananPageState extends State<TambahPesananPage> {

  List<String> supplierList = [];
  String selectedSupplier = '';

  List<String> skuList = [];
  String selectedSKU = '';

  Map<String, double> cart = {};

  Map<String, double> manualPrices = {};

  Map<String, TextEditingController> priceControllers = {};

  final TextEditingController _keteranganController = TextEditingController();
  final TextEditingController _seriPekerjaanController = TextEditingController();

  late String tanggalHariIni;

  bool isExpanded = true;

  @override
  void initState() {
    super.initState();
    fetchSuppliers();
    fetchProducts();

    final now = DateTime.now();
    tanggalHariIni = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    for (var c in priceControllers.values) {
      c.dispose();
    }
    _keteranganController.dispose();
    _seriPekerjaanController.dispose();
    super.dispose();
  }

  Future<void> fetchSuppliers() async {
    final url = Uri.parse('https://hayami.id/apps/erp/api-android/api/supplier.php');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final suppliers = data['data'] as List;
        setState(() {
          supplierList = suppliers.map((e) => e['nm_supplier'] as String).toList();
        });
      } else {
        print('Gagal ambil data supplier');
      }
    } catch (e) {
      print('Error fetch supplier: $e');
    }
  }

Future<void> simpanPesananKeServer() async {
  final url = Uri.parse('https://hayami.id/apps/erp/api-android/api/tambahpesanan.php');

  final items = cart.entries.map((entry) {
    final sku = entry.key;
    final lusin = entry.value;
    final cost = manualPrices[sku] ?? 0.0;

    // Cari produk berdasarkan sku
    final product = productList.firstWhere((p) => p['sku'] == sku, orElse: () => {});

    final idTipe = product['id_tipe'] ?? '';
    final size = product['size'] ?? '';

    return {
      "sku": sku,
      "lusin": lusin,
      "cost": cost,
      "id_tipe": idTipe,
      "size": size,
    };
  }).toList();

  final body = jsonEncode({
    "supplier": selectedSupplier,
    "keterangan": _keteranganController.text,
    "seri": _seriPekerjaanController.text,
    "tanggal": tanggalHariIni,
    "items": items,
  });

  try {
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    final data = json.decode(response.body);
    if (data['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${data['message']}")),
      );
      setState(() {
        cart.clear();
        manualPrices.clear();
        priceControllers.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal: ${data['message']}")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}


List<Map<String, dynamic>> productList = [];

Future<void> fetchProducts() async {
  final url = Uri.parse('https://hayami.id/apps/erp/api-android/api/master_produk.php');
  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final products = data['all_product'] as List;
      setState(() {
        productList = products.map((e) => e as Map<String, dynamic>).toList();
        skuList = productList.map((e) => e['sku'] as String).toList();
      });
    } else {
      print('Gagal ambil data produk');
    }
  } catch (e) {
    print('Error fetch produk: $e');
  }
}

  void addToCart(String sku) {
    setState(() {
      cart[sku] = (cart[sku] ?? 0.0) + 0.5;
      if (!priceControllers.containsKey(sku)) {
        priceControllers[sku] = TextEditingController(text: '');
      }
      manualPrices[sku] = manualPrices[sku] ?? 0.0;
    });
  }

  void removeFromCart(String sku) {
    setState(() {
      final current = cart[sku] ?? 0.0;
      if (current - 0.5 >= 0) {
        cart[sku] = current - 0.5;
      }
    });
  }

  void deleteFromCart(String sku) {
    setState(() {
      cart.remove(sku);
      manualPrices.remove(sku);
      priceControllers[sku]?.dispose();
      priceControllers.remove(sku);
    });
  }

  String formatRupiah(String s) {
    String angka = s.replaceAll(RegExp(r'[^0-9]'), '');
    if (angka.isEmpty) return '';
    final buffer = StringBuffer();
    int len = angka.length;
    int count = 0;
    for (int i = len - 1; i >= 0; i--) {
      buffer.write(angka[i]);
      count++;
      if (count % 3 == 0 && i != 0) {
        buffer.write('.');
      }
    }
    return buffer.toString().split('').reversed.join('');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Pesanan'),
        centerTitle: true,
        leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          isExpanded = !isExpanded;
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Tambah Pesanan",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),


                    if (isExpanded) ...[
                      const Text("Pilih Supplier", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                          return supplierList.where((supplier) =>
                              supplier.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (selection) {
                          setState(() => selectedSupplier = selection);
                        },
                        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                          controller.text = selectedSupplier;
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            onEditingComplete: onEditingComplete,
                            decoration: InputDecoration(
                              hintText: 'Ketik nama supplier',
                              filled: true,
                              fillColor: Colors.grey.shade200,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      const Text("Pilih SKU", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                          return skuList.where((sku) =>
                              sku.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (selection) {
                          setState(() => selectedSKU = selection);
                        },
                        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                          controller.text = selectedSKU;
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            onEditingComplete: onEditingComplete,
                            decoration: InputDecoration(
                              hintText: 'Ketik SKU produk',
                              filled: true,
                              fillColor: Colors.grey.shade200,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      const Text("Keterangan", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _keteranganController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Masukkan keterangan',
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text("Seri Pekerjaan", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _seriPekerjaanController,
                        decoration: InputDecoration(
                          hintText: 'Masukkan seri pekerjaan',
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      const Text("Tanggal", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: TextEditingController(text: tanggalHariIni),
                        enabled: false,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade200,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ] else ...[
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
                          return skuList.where((sku) =>
                              sku.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                        },
                        onSelected: (selection) {
                          setState(() => selectedSKU = selection);
                        },
                        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                          controller.text = selectedSKU;
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            onEditingComplete: onEditingComplete,
                            decoration: InputDecoration(
                              hintText: 'Ketik SKU produk',
                              filled: true,
                              fillColor: Colors.grey.shade200,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          if (selectedSupplier.isEmpty && isExpanded) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Supplier harus diisi')),
                            );
                            return;
                          }
                          if (selectedSKU.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('SKU harus diisi')),
                            );
                            return;
                          }
                          addToCart(selectedSKU);
                          setState(() {
                            selectedSKU = '';
                          });
                        },
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text("Simpan Pesanan"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text("Keranjang Pesanan:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (cart.isEmpty)
              const Text("Keranjang kosong")
            else
              Column(
                children: cart.entries.map((entry) {
                  final sku = entry.key;
                  final qty = entry.value;
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sku,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () => removeFromCart(sku),
                              ),
                              Text("${qty.toStringAsFixed(1)} lusin", style: const TextStyle(fontSize: 16)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => addToCart(sku),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: 110,
                                child: TextField(
                                  controller: priceControllers[sku],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: "Harga",
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (value) {
                                    String formatted = formatRupiah(value);
                                    if (formatted != value) {
                                      final cursorPos = priceControllers[sku]!.selection.baseOffset;
                                      priceControllers[sku]!.text = formatted;
                                      priceControllers[sku]!.selection = TextSelection.fromPosition(
                                        TextPosition(offset: formatted.length),
                                      );
                                    }
                                    setState(() {
                                      manualPrices[sku] = double.tryParse(formatted.replaceAll('.', '')) ?? 0.0;
                                    });
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deleteFromCart(sku),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
onPressed: () {
  if (cart.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Keranjang masih kosong")),
    );
    return;
  }
  simpanPesananKeServer();
},
          icon: const Icon(Icons.check),
          label: const Text("Konfirmasi Pesanan"),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }
}
