import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ===================== Model =====================
class Customer {
  final String name;
  final List<SalesDetail> details;

  Customer({required this.name, required this.details});

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      name: json['nama'] ?? '',
      details: (json['barang_kontak'] as List<dynamic>?)
              ?.map((item) => 
              SalesDetail.fromJson(item))
              .toList() ?? 
          [],
    );
  }
}

class SalesDetail {
  final String? product;
  final String qty;
  final String total;
  final String code;

  SalesDetail({
    this.product,
    required this.qty,
    required this.total,
    required this.code,
  });

  factory SalesDetail.fromJson(Map<String, dynamic> json) {
    return SalesDetail(
      product: json['produk']?['name'] ?? '-',
      qty: json['jumlah'] ?? '0',
      total: json['total'] ?? '0',
      code: json['produk']?['code'] ?? '-',
    );
  }
}

// ===================== Sales List Page =====================
class SalesListPage extends StatefulWidget {
  const SalesListPage({super.key});

  @override
  _SalesListPageState createState() => _SalesListPageState();
}

class _SalesListPageState extends State<SalesListPage> {
  Future<List<Customer>> fetchSalesData() async {
    final response =
        await http.get(Uri.parse('http://192.168.1.9/Hiyami/jurnal.php'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Customer.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.blueAccent,
        title: const Text('Penjualan Produk per Pelanggan', style: TextStyle(color: Colors.blueAccent, fontSize: 20),),
        centerTitle: true,
        leading: const BackButton(),
      ),
      body: FutureBuilder<List<Customer>>(
        future: fetchSalesData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Text('Gagal mengambil data: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Data kosong'));
          }

          final salesData = snapshot.data!;

          return ListView.builder(
            itemCount: salesData.length,
            itemBuilder: (context, index) {
              final customer = salesData[index];

              int totalQty = customer.details.fold(0, (sum, item) {
                int qty = int.tryParse(item.qty) ?? 0;
                return sum + qty;
              });
              
              return Column(
                children: [
                  ListTile(
                    title: Text(customer.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 30,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              totalQty.toString(),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.black,
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SalesDetailPage(
                            customerName: customer.name,
                            details: customer.details,
                          ),
                        ),
                      );
                    },
                  ),
                  const Divider(thickness: 1, color: Colors.grey, height: 10,), 
                ],
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "share",
            mini: true,
            onPressed: () {},
            child: const Icon(Icons.share),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "download",
            child: const Icon(Icons.download),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}


// ===================== Detail Page =====================
class SalesDetailPage extends StatelessWidget {
  final String customerName;
  final List<SalesDetail> details;

  const SalesDetailPage({
    super.key,
    required this.customerName,
    required this.details,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(customerName),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: details.isEmpty
            ? const Center(child: Text('Tidak ada detail penjualan.'))
            : ListView.builder(
                itemCount: details.length,
                itemBuilder: (context, index) {
                  final item = details[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Nama Produk',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(item.product ?? 'Produk tidak diketahui'),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Kode',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(item.code),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Kuantitas',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(item.qty),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Rp ${item.total}'),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(
                          height: 20,
                        )
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
