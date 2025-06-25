import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hayami_app/pemesanan/konfirmasipesanan.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Customer {
  final String idCustomer;
  final String nmCustomer;
  final String nmType;      // tambah ini
  final double percentage;  // tambah ini

  Customer({
    required this.idCustomer,
    required this.nmCustomer,
    required this.nmType,
    required this.percentage,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      idCustomer: json['id_customer'] ?? '',
      nmCustomer: json['nm_customer'] ?? '',
      nmType: json['nm_type'] ?? '',
      percentage: double.tryParse(json['percentage'] ?? '100') ?? 100.0,
    );
  }
}


class Diskon {
  final String idCust;
  final String idTipe;
  final double discp;

  Diskon({
    required this.idCust,
    required this.idTipe,
    required this.discp,
  });

  factory Diskon.fromJson(Map<String, dynamic> json) {
    return Diskon(
      idCust: json['id_cust'] ?? '',
      idTipe: json['id_tipe'] ?? '',
      discp: double.tryParse(json['discp'] ?? '0.0') ?? 0.0,
    );
  }
}


class Produk {
  final String sku;
  final String idTipe;
  final double qty;
  final double qtyclear;
  final double qtycleardo;
  final double harga; // harga dasar tanpa persentase
  double orderQty;
  
  // Diskon per lusin (rupiah)
  double diskonPerLusin;

  // Persentase harga berdasarkan tipe customer (misal: 100, 120, 144, 230)
  double percentage;

  Produk({
    required this.sku,
    required this.idTipe,
    required this.qty,
    required this.qtyclear,
    required this.qtycleardo,
    required this.harga,
    this.orderQty = 0.0,
    this.diskonPerLusin = 0.0,
    this.percentage = 100.0, // default 100% (harga dasar)
  });

  factory Produk.fromJson(Map<String, dynamic> json) {
    return Produk(
      sku: json['sku'] ?? '',
      idTipe: json['id_tipe'] ?? '',
      qty: double.tryParse(json['qty'] ?? '0') ?? 0.0,
      qtyclear: double.tryParse(json['qtyclear'] ?? '0') ?? 0.0,
      qtycleardo: double.tryParse(json['qtycleardo'] ?? '0') ?? 0.0,
      harga: double.tryParse(json['harga'] ?? '0') ?? 0.0,
      // percentage tidak didapat dari JSON produk, harus di-set dari luar sesuai tipe customer
    );
  }

  double get availableQty => qty - (qtyclear + qtycleardo);

  // Harga sudah disesuaikan dengan persentase customer
  double get hargaAdjusted => harga * (percentage / 100);

  // Total harga dengan diskon per lusin, sudah disesuaikan harga
  double get totalHarga {
    double diskonPerSetengahLusin = diskonPerLusin / 2;

    int lusin = orderQty.floor();
    double sisa = orderQty - lusin;

    double diskonTotal = lusin * diskonPerLusin + (sisa >= 0.5 ? diskonPerSetengahLusin : 0);

    double hargaTotal = hargaAdjusted * orderQty;

    double hargaSetelahDiskon = hargaTotal - diskonTotal;

    return hargaSetelahDiskon < 0 ? 0 : hargaSetelahDiskon;
  }

  // Total harga normal tanpa diskon tapi dengan penyesuaian persentase
  double get totalHargaNormal {
    return hargaAdjusted * orderQty;
  }
}

class Tambahpesanan extends StatefulWidget {
  const Tambahpesanan({super.key});

  @override
  State<Tambahpesanan> createState() => _TambahpesananState();
}

class _TambahpesananState extends State<Tambahpesanan> {
  final TextEditingController customerController = TextEditingController();
final TextEditingController skuController = TextEditingController();
  String? selectedCustomer;
  String? selectedSku;

  Customer? selectedCustomerObj;
  List<Customer> customers = [];
  List<Produk> skus = [];
  List<Produk> cartItems = [];

  List<Diskon> diskonList = [];
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
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List<dynamic> customerData = jsonResponse['customer_data'] ?? [];
      final List<dynamic> diskonData = jsonResponse['diskon_cust_data'] ?? [];

      if (!mounted) return; // ✅ CEK DULU apakah widget masih aktif

      setState(() {
        customers = customerData
            .map((json) => Customer.fromJson(json))
            .where((c) => c.nmCustomer.isNotEmpty)
            .toList();

        diskonList = diskonData
            .map((json) => Diskon.fromJson(json))
            .toList();
      });
    } else {
      throw Exception('Gagal mengambil data customer');
    }
  } catch (e) {
    print('Error fetchCustomers: $e');

    if (!mounted) return; // ✅ Hindari error kalau widget sudah dispose

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gagal memuat data customer')),
    );
  }
}



  Future<void> fetchSkus() async {
  try {
    final response = await http.get(
      Uri.parse('http://hayami.id/apps/erp/api-android/api/master_produk.php'),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final List<dynamic> data = jsonResponse['all_product'] ?? [];

      if (!mounted) return; // ✅ Cek apakah widget masih hidup

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

    if (!mounted) return; // ✅ Cegah akses context setelah dispose

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
                  _autocompleteCustomerDropdown(),
                  const SizedBox(height: 24),
                  _autocompleteSkuDropdown(),
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
  );

  // Cari diskon untuk customer & id_tipe
  double diskonLusin = 0.0;
  if (selectedCustomerObj != null) {
    final matchingDiskon = diskonList.firstWhere(
      (d) =>
          d.idCust == selectedCustomerObj!.idCustomer &&
          d.idTipe == selectedProduct.idTipe,
      orElse: () => Diskon(idCust: '', idTipe: '', discp: 0.0),
    );
    diskonLusin = matchingDiskon.discp;
  }

  final alreadyInCart = cartItems.any((item) =>
    item.sku == selectedProduct.sku && item.idTipe == selectedProduct.idTipe);

if (alreadyInCart) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('Produk ${selectedProduct.sku} sudah ada di keranjang.'),
    duration: Duration(seconds: 2),
  ));
} else {
  setState(() {
    cartItems.add(Produk(
      sku: selectedProduct.sku,
      idTipe: selectedProduct.idTipe,
      qty: selectedProduct.qty,
      qtyclear: selectedProduct.qtyclear,
      qtycleardo: selectedProduct.qtycleardo,
      harga: selectedProduct.harga,
      orderQty: 0.0,
      diskonPerLusin: diskonLusin,
      percentage: selectedCustomerObj?.percentage ?? 100.0,
    ));
    selectedSku = null;
  });

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text('Pesanan untuk $selectedCustomer - ${selectedProduct.sku} disimpan.'),
  ));
}
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
if (item.diskonPerLusin > 0)
  Text(
    'Diskon: Rp ${NumberFormat("#,##0", "id_ID").format(item.diskonPerLusin)} / lusin',
    style: const TextStyle(fontSize: 12, color: Colors.green),
  ),
const SizedBox(height: 8),
                              Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text(
      'Available: ${item.availableQty.toStringAsFixed(2)}',
      style: const TextStyle(fontSize: 13),
    ),
    const SizedBox(height: 8),
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Quantity picker
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                setState(() {
                  if (item.orderQty > 0) {
                    item.orderQty -= 0.5;
                  }
                });
              },
            ),
            Container(
              width: 70,
              alignment: Alignment.center,
              child: Text(
                '${item.orderQty.toStringAsFixed(1)} lusin',
                style: const TextStyle(fontSize: 14),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () {
                setState(() {
                  if (item.orderQty + 0.5 <= item.availableQty) {
                    item.orderQty += 0.5;
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Stok tidak mencukupi. Maksimum ${item.availableQty.toStringAsFixed(1)} lusin.',
                        ),
                      ),
                    );
                  }
                });
              },
            ),
          ],
        ),

        // Total harga dan delete icon
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            children: [
              Text(
                'Rp ${NumberFormat("#,##0", "id_ID").format(item.totalHargaNormal)}',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  setState(() {
                    cartItems.remove(item);
                  });
                },
              ),
            ],
          ),
        ),
      ],
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
                      label: const Text("Konfirmasi Pesanan"),
                      onPressed: () {
  if (selectedCustomerObj == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Silakan pilih customer terlebih dahulu')),
    );
    return;
  }

  if (cartItems.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Keranjang masih kosong')),
    );
    return;
  }

  final bool hasValidQty = cartItems.any((item) => item.orderQty > 0);

  if (!hasValidQty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Isi jumlah pesanan terlebih dahulu')),
    );
    return;
  }

  // Jika semua valid, lanjut
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => KonfirmasiPesanan(
        selectedCustomer: selectedCustomerObj!.nmCustomer,
        cartItems: cartItems,
      ),
    ),
  );
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
        textEditingController: customerController, // ⬅ Ganti di sini
        focusNode: FocusNode(),
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text == '') {
            return const Iterable<String>.empty();
          }
          return customers
              .map((e) => e.nmCustomer)
              .where((option) => option
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase()))
              .take(20); // ⬅ Tambahan: Batasi hasil (opsional)
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
          final cust = customers.firstWhere((c) => c.nmCustomer == selection);
          setState(() {
            selectedCustomer = selection;
            selectedCustomerObj = cust;
            customerController.text = selection; // update controller
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
        textEditingController: skuController, // ✅ gunakan controller yang sudah dibuat
        focusNode: FocusNode(),
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<String>.empty();
          }
          return skus
              .map((e) => e.sku)
              .where((option) => option
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase()));
        },
        fieldViewBuilder:
            (context, controller, focusNode, onFieldSubmitted) {
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
            skuController.text = selection; // ✅ update teks controller
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