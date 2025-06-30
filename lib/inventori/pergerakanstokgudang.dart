import 'dart:convert'; // Untuk parsing JSON
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Untuk melakukan request HTTP


class StockMovementPage extends StatefulWidget {
  const StockMovementPage({super.key});

  @override
  _StockMovementPageState createState() => _StockMovementPageState();
}

class _StockMovementPageState extends State<StockMovementPage> {
  String selectedWarehouse = "Unassigned";
  List<Product> products = [];
  bool isLoading = true;

  int getTotalStock() {
    int total = 0;

    for (var product in products) {
      String stockValue;

      if (selectedWarehouse == "Unassigned") {
        stockValue = product.stock.unassigned;
      } else if (selectedWarehouse == "Gudang Utama") {
        stockValue = product.stock.gudangUtama;
      } else if (selectedWarehouse == "Gudang Elektronik") {
        stockValue = product.stock.gudangElektronik;
      } else {
        stockValue = '0';
      }

      total += int.tryParse(stockValue) ?? 0;
    }

    return total;
  }

  final List<String> warehouses = [
    "Unassigned",
    "Gudang Utama",
    "Gudang Elektronik",
  ];

  @override
  void initState() {
    super.initState();
    fetchProducts(); 
  }

  Future<void> fetchProducts() async {
    final response = await http.get(Uri.parse(
        'http://192.168.1.9/Hiyami/produk.php'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          json.decode(response.body);

      final List<Product> loadedProducts = [];
      for (var product in data['data']) {
        loadedProducts.add(Product.fromJson(product));
      }

      setState(() {
        products = loadedProducts;
        isLoading = false;
      });
    } else {
      throw Exception('Failed to load products');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pergerakan Stok Gudang", style: TextStyle(color: Colors.blueAccent, fontSize: 20),),
        foregroundColor: Colors.blueAccent,
        centerTitle: true,
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Pilih Gudang",
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius:
                              BorderRadius.circular(40), // lebih bulat
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedWarehouse,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded),
                            isExpanded: true,
                            borderRadius: BorderRadius.circular(30),
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black87),
                            items: warehouses.map((warehouse) {
                              return DropdownMenuItem<String>(
                                value: warehouse,
                                child: Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warehouse_rounded,
                                          size: 18, color: Colors.blueGrey),
                                      const SizedBox(width: 10),
                                      Text(warehouse),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) async {
                              setState(() {
                                isLoading = true;
                              });

                              await Future.delayed(const Duration(milliseconds: 350));

                              setState(() {
                                selectedWarehouse = value!;
                                isLoading = false;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: products.length + 1,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index < products.length) {
                        final product = products[index];
                        return ListTile(
                          title: Text(product.name),
                          subtitle: Text(product.code),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 34,
                                height: 25,
                                decoration: BoxDecoration(
                                  color: Colors.amber[600],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    selectedWarehouse == "Unassigned"
                                        ? formatNumber(product.stock.unassigned)
                                        : selectedWarehouse == "Gudang Utama"
                                            ? formatNumber(
                                                product.stock.gudangUtama)
                                            : formatNumber(
                                                product.stock.gudangElektronik),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_ios, size: 16),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailPage(
                                  product: product,
                                  warehouse: selectedWarehouse,
                                ),
                              ),
                            );
                          },
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                getTotalStock()
                                    .toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.download),
      ),
    );
  }

  String formatNumber(String value) {
    int number = int.tryParse(value) ?? 0;
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return value; 
    }
  }
}

class Product {
  final String name;
  final String code;
  final Stock stock;

  Product({
    required this.name,
    required this.code,
    required this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      name: json['produk_name'],
      code: json['produk_code'],
      stock: Stock.fromJson(json['gudang']),
    );
  }
}

class Stock {
  final String unassigned;
  final String gudangUtama;
  final String gudangElektronik;

  Stock({
    required this.unassigned,
    required this.gudangUtama,
    required this.gudangElektronik,
  });

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      unassigned: json['unassigned'].toString(),
      gudangUtama: json['gudang_utama'].toString(),
      gudangElektronik: json['gudang_elektronik'].toString(),
    );
  }
}

class ProductDetailPage extends StatelessWidget {
  final Product product;
  final String warehouse;

  const ProductDetailPage({super.key, 
    required this.product,
    required this.warehouse,
  });

  @override
  Widget build(BuildContext context) {
    String warehouseStock = "";
    if (warehouse == "Unassigned") {
      warehouseStock = product.stock.unassigned;
    } else if (warehouse == "Gudang Utama") {
      warehouseStock = product.stock.gudangUtama;
    } else if (warehouse == "Gudang Elektronik") {
      warehouseStock = product.stock.gudangElektronik;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        centerTitle: true,
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          ListTile(
            title: const Text("Kode"),
            trailing: Text(product.code),
          ),
          const Divider(),
          ListTile(
            title: const Text("Kuantitas di Gudang"),
            trailing: Text(warehouseStock),
          ),
          const Divider(),
          const ListTile(
            title: Text("Kuantitas Awal"),
            trailing: Text("0"),
          ),
          const Divider(),
          const ListTile(
            title: Text("Pergerakan Kuantitas"),
            trailing: Text("0"),
          ),
          const Divider(),
          const ListTile(
            title: Text("Kuantitas Akhir"),
            trailing: Text("0"),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[200],
                foregroundColor: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size.fromHeight(48),
              ),
              onPressed: () {
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Lihat detail pergerakan"),
                  Icon(Icons.arrow_forward_ios),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
