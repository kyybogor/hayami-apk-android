import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RingkasanStokGudangPage extends StatefulWidget {
  const RingkasanStokGudangPage({super.key});

  @override
  _RingkasanStokGudangPageState createState() =>
      _RingkasanStokGudangPageState();
}

class _RingkasanStokGudangPageState extends State<RingkasanStokGudangPage> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    final response =
        await http.get(Uri.parse('http://192.168.1.8/hiyami/produk.php'));

    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);

      if (jsonResponse['status'] == 'success') {
        final List<dynamic> data = jsonResponse['data'];

        setState(() {
          products = data.map((item) {
            final gudang = item['gudang'] ?? {};
            return {
              'name': item['produk_name'] ?? 'N/A',
              'code': item['produk_code'] ?? '',
              'details': {
                'Unassigned':
                    int.tryParse(gudang['unassigned'].toString()) ?? 0,
                'Gudang Utama':
                    int.tryParse(gudang['gudang_utama'].toString()) ?? 0,
                'Gudang Elektronik':
                    int.tryParse(gudang['gudang_elektronik'].toString()) ?? 0,
              },
            };
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data tidak valid dari server')),
        );
      }
    } else {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal mengambil data dari server')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalStock = products.fold(0, (sum, item) {
      final details = item['details'] as Map<String, int>;
      return sum + details.values.fold(0, (a, b) => a + b);
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ringkasan Stok Gudang', style: TextStyle(color: Colors.blueAccent, fontSize: 20),),
        foregroundColor: Colors.blueAccent,
        centerTitle: true,
        leading: const BackButton(),
        actions: [
          IconButton(icon: const Icon(Icons.filter_alt), onPressed: () {}),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: products.length + 1,
                    itemBuilder: (context, index) {
                      if (index < products.length) {
                        final product = products[index];
                        final details = product['details'] as Map<String, int>;
                        final detailTotal =
                            details.values.fold(0, (a, b) => a + b);

                        return Column(
                          children: [
                            ListTile(
                              title: Text(product['name']),
                              subtitle: Text(product['code']),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.amber,
                                    child: Text(
                                      '$detailTotal',
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.white),
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
                                    builder: (_) => DetailStokPage(
                                      productName: product['name'],
                                      details: product['details'],
                                    ),
                                  ),
                                );
                              },
                            ),
                            const Divider(height: 1),
                          ],
                        );
                      } else {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              Text('$totalStock'),
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
        onPressed: fetchProducts,
        child: const Icon(Icons.download),
      ),
    );
  }
}

class DetailStokPage extends StatelessWidget {
  final String productName;
  final Map<String, int> details;

  const DetailStokPage({
    super.key,
    required this.productName,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    int total = details.values.fold(0, (a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        title: Text(productName),
        centerTitle: true,
        leading: const BackButton(),
      ),
      body: Column(
        children: [
          ...details.entries.map((entry) => ListTile(
                title: Text(entry.key),
                trailing: Text(entry.value.toString()),
              )),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text('$total'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
