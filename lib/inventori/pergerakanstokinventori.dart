import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class InventoryMovementPage extends StatefulWidget {
  const InventoryMovementPage({super.key});

  @override
  _InventoryMovementPageState createState() => _InventoryMovementPageState();
}

class _InventoryMovementPageState extends State<InventoryMovementPage> {
  List<dynamic> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchInventory();
  }

  Future<void> fetchInventory() async {
    final url = Uri.parse('http://192.168.1.8/Hiyami/produk.php');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        setState(() {
          products = jsonData['data'];
          isLoading = false;
        });
      } else {
        throw Exception('Gagal memuat data');
      }
    } catch (e) {
      print(e);
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pergerakan Stok Inventori', style: TextStyle(color: Colors.blueAccent, fontSize: 20),),
        foregroundColor: Colors.blueAccent,
        centerTitle: true,
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () {},
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: products.length + 1,
              itemBuilder: (context, index) {
                if (index < products.length) {
                  final item = products[index];
                  return Column(
                    children: [
                      ListTile(
                        title: Text(item['produk_name']),
                        subtitle: Text(item['produk_code']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                item['stok'].toString(),
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_ios,
                                size: 12, color: Colors.grey),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InventoryDetailPage(item: item),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1),
                    ],
                  );
                } else {
                  // Bagian Total
                  return Column(
                    children: [
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              products
                                  .fold<int>(
                                      0,
                                      (sum, item) =>
                                          sum + int.parse(item['stok']))
                                  .toString(),
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              }),
      floatingActionButton: FloatingActionButton(
        onPressed: fetchInventory,
        child: const Icon(Icons.download),
      ),
    );
  }
}

class InventoryDetailPage extends StatelessWidget {
  final Map<String, dynamic> item;

  const InventoryDetailPage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final details = [
      {'label': 'Kode', 'value': item['produk_code']},
      {'label': 'Stok', 'value': item['stok'].toString()},
      {'label': 'Penjualan', 'value': item['penjualan'].toString()},
      {'label': 'HPP', 'value': item['hpp']},
      {'label': 'Harga Jual', 'value': item['harga_jual']},
      {'label': 'Nominal Stok', 'value': item['nominal_stok']},
      {'label': 'Nominal Penjualan', 'value': item['nominal_penjualan']},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(item['produk_name']),
        centerTitle: true,
        leading: const BackButton(),
      ),
      body: ListView(
        children: [
          ...details.map((e) => Column(
                children: [
                  ListTile(
                    title: Text(e['label']!),
                    trailing: Text(e['value']!),
                  ),
                  const Divider(height: 5),
                ],
              )),
          const SizedBox(
            height: 20,
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      foregroundColor: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StockMovementDetailPage(
                            kontaks: item['kontaks'] ?? [],
                            name: item['produk_name']),
                      ),
                    );
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Lihat detail pergerakan"),
                      Icon(Icons.arrow_forward_ios, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StockMovementDetailPage extends StatelessWidget {
  final List<dynamic> kontaks;
  final String name;

  const StockMovementDetailPage(
      {super.key, required this.kontaks, required this.name});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("$name"),
        centerTitle: true,
        leading: const BackButton(),
      ),
      body: kontaks.isEmpty
          ? const Center(child: Text('Tidak ada transaksi.'))
          : ListView.builder(
              itemCount: kontaks.length,
              itemBuilder: (context, index) {
                final k = kontaks[index];
                final qty = int.parse(k['barang_kontak']['jumlah']);
                return Column(
                  children: [
                    ListTile(
                      title: Text('${k['kontak_name']} (${k['kontak_code']})'),
                      subtitle: Text(k['kontak_date']),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: qty < 0 ? Colors.red[200] : Colors.green[300],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          qty.abs().toString(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    const Divider(height: 1), 
                  ],
                );
              },
            ),
    );
  }
}
