import 'package:flutter/material.dart';
import 'package:hayami_app/pos/customer_model.dart';
import 'package:hayami_app/pos/product_order_dialog.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Posscreen extends StatefulWidget {
  const Posscreen({super.key});

  @override
  State<Posscreen> createState() => _PosscreenState();
}

void showProductOrderDialog(BuildContext context, Map<String, dynamic> representative, List<dynamic> allSizes) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40), // Sedikit lebih longgar dari 80
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 750, // Ukuran lebih besar dari sebelumnya (600)
        ),
        child: ProductOrderDialogContent(
          representative: representative,
          allSizes: allSizes,
        ),
      ),
    ),
  );
}

Future<List<Customer>> fetchCustomers(String keyword) async {
  final response = await http.get(Uri.parse('http://hayami.id/apps/erp/api-android/api/kontak.php'));

  if (response.statusCode == 200) {
    final jsonData = jsonDecode(response.body);
    List<Customer> allCustomers = (jsonData['customer_data'] as List)
        .map((c) => Customer.fromJson(c))
        .toList();

    return allCustomers
        .where((c) => c.nmCustomer.toLowerCase().contains(keyword.toLowerCase()))
        .toList();
  } else {
    throw Exception('Failed to load customers');
  }
}


class _PosscreenState extends State<Posscreen> {
  List<dynamic> products = [];
  bool isLoading = true;
  String searchQuery = '';
  Customer? selectedCustomer;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
  const url = 'https://hayami.id/apps/erp/api-android/api/master_produk.php';
  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final jsonResult = json.decode(response.body);
    setState(() {
      products = jsonResult['all_product']; // ambil list produk dari key 'all_product'
      isLoading = false;
    });
  } else {
    throw Exception('Failed to load products');
  }
}

void showCustomerSearchDialog() {
  String keyword = '';
  List<Customer> results = [];
  bool isLoading = false;

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text('Select Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by Customer Name',
                ),
                onChanged: (value) async {
                  keyword = value;
                  setState(() {
                    isLoading = true;
                  });
                  results = await fetchCustomers(keyword);
                  setState(() {
                    isLoading = false;
                  });
                },
              ),
              const SizedBox(height: 10),
              isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      height: 300,
                      width: 400,
                      child: ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (context, index) {
                          final customer = results[index];
                          return ListTile(
                            title: Text(customer.nmCustomer),
                            subtitle: Text(customer.name),
                            onTap: () {
                              setState(() {
                                selectedCustomer = customer;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
            ],
          ),
        );
      });
    },
  );
}


  double calculateStock(dynamic item) {
    double qty = double.tryParse(item['qty']) ?? 0.0;
    double clear = double.tryParse(item['qtyclear']) ?? 0.0;
    double doClear = double.tryParse(item['qtycleardo']) ?? 0.0;
    return qty - (clear + doClear);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
  appBar: AppBar(
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        Navigator.pop(context); // kembali ke halaman sebelumnya
      },
    ),
    title: const Text('POS Screen'),
    elevation: 0,
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
  ),
  body: isLoading
    ? const Center(child: CircularProgressIndicator())
    : Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                    onChanged: (value) {
                      setState(() {
                        searchQuery = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: productGrid(),
                ),
                Expanded(
                  flex: 2,
                  child: cartSection(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

Widget productGrid() {
  Map<String, List<dynamic>> grouped = {};

  final filteredProducts = products.where((item) {
    final tipe = item['tipe']?.toLowerCase() ?? '';
    final model = item['gambar']?.toLowerCase() ?? '';
    final query = searchQuery.toLowerCase();
    return tipe.contains(query) || model.contains(query);
  }).toList();

  for (var item in filteredProducts) {
    String key = '${item['id_tipe']}|${item['tipe']}|${item['gambar']}';
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

      final tipe = representative['tipe'];
      final model = representative['gambar'];


      return GestureDetector(
  onTap: () {
    showProductOrderDialog(context, representative, entry.value);
  },
  child: Card(
    elevation: 2,
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            tipe,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            model,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),

          // Gambar Produk
          Expanded(
            child: Center(
              child: Image.network(
                imgUrl,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Daftar Size dan Stok (> 0)
          Column(
            children: entry.value.map((item) {
              double stok = calculateStock(item);
              if (stok <= 0) return const SizedBox.shrink(); // Jangan tampilkan jika stok 0

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['size'],
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      stok.toStringAsFixed(1),
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                ),
                onPressed: showCustomerSearchDialog,
                child: const Text('Select Customer'),
              ),
            ),
            if (selectedCustomer != null) ...[
  const SizedBox(height: 12),
  Card(
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Customer Name: ${selectedCustomer!.name}', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Address: ${selectedCustomer!.address}'),
          Text('Contact: ${selectedCustomer!.telp.isNotEmpty ? selectedCustomer!.telp : selectedCustomer!.telp2}'),
          Text('Store Type: ${selectedCustomer!.salesman}'),
        ],
      ),
    ),
  )
],
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyan,
                ),
                onPressed: () {},
                child: const Text('Cart'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(
              child: Text(
                'Items',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              'Total',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const Divider(),
        const SizedBox(height: 8),
        // Tombol Confirm
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () {},
            child: const Text('Confirm'),
          ),
        ),
        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 8),

        // Info Detail
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            ElevatedButton(
              onPressed: null,
              child: Text('New Discount'),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sub-Total :'),
                Text('Rp.0'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total QTY :'),
                Text('0 Lusin'),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Discount :'),
                Text('Rp.0'),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Payment Dropdown dan Durasi
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
            Expanded(
              child: TextField(
                enabled: false,
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

        // Tombol GRAND TOTAL
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
            ),
            onPressed: () {},
            child: const Text(
              'GRAND TOTAL: Rp.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    ),
  );
}
}
