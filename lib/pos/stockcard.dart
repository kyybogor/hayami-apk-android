import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MaterialApp(home: StockCard()));

class StockCard extends StatefulWidget {
  const StockCard({super.key});

  @override
  State<StockCard> createState() => _StockCardState();
}

class _StockCardState extends State<StockCard> {
  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();
  String? selectedBahan;
  String? selectedModel;

  List<dynamic> bahanList = [];

  bool isLoading = false;

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    final response = await http.get(Uri.parse('http://192.168.1.2/pos/stock.php'));

    if (response.statusCode == 200) {
      final jsonData = json.decode(response.body);
      if (jsonData['status'] == 'success') {
        setState(() {
          bahanList = jsonData['data'];
        });
      }
    }
    setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  List<String> getBahanOptions(String query) {
    final allBahan = bahanList.map((e) => e['id_bahan'].toString()).toSet().toList();
    return allBahan.where((item) => item.toLowerCase().contains(query.toLowerCase())).toList();
  }

  List<String> getModelOptions(String query) {
    if (selectedBahan == null) return [];
    final models = bahanList
        .where((item) => item['id_bahan'] == selectedBahan)
        .map((item) => item['model'].toString())
        .toSet()
        .toList();
    return models.where((item) => item.toLowerCase().contains(query.toLowerCase())).toList();
  }

  @override
Widget build(BuildContext context) {
  final dateFormat = DateFormat('dd/MM/yyyy');

  return Scaffold(
    resizeToAvoidBottomInset: true,
    appBar: AppBar(
      title: const Text('Stock Card Detail'),
      backgroundColor: Colors.indigo,
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Dari Tanggal'),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: fromDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => fromDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(dateFormat.format(fromDate)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8), // Dipersempit jaraknya
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sampai Tanggal'),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: toDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() => toDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(dateFormat.format(toDate)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ID Bahan'),
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text == '') return const Iterable<String>.empty();
                          return getBahanOptions(textEditingValue.text);
                        },
                        onSelected: (String selection) {
                          setState(() {
                            selectedBahan = selection;
                            selectedModel = null;
                          });
                        },
                        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8), // Dipersempit
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Model'),
                      Autocomplete<String>(
                        optionsBuilder: (TextEditingValue textEditingValue) {
                          if (textEditingValue.text == '' || selectedBahan == null) {
                            return const Iterable<String>.empty();
                          }
                          return getModelOptions(textEditingValue.text);
                        },
                        onSelected: (String selection) {
                          setState(() => selectedModel = selection);
                        },
                        fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                          return TextField(
                            controller: controller,
                            focusNode: focusNode,
                            decoration: const InputDecoration(border: OutlineInputBorder()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    // aksi pencarian
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                  child: const Text('Cari'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    // aksi print
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Row(
                    children: [
                      Icon(Icons.print),
                      SizedBox(width: 8),
                      Text('Print'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else
              const SizedBox(
                height: 200, // Tempat hasil pencarian nanti
                child: Center(child: Text('Tampilkan tabel hasil di sini...')),
              ),
          ],
        ),
      ),
    ),
  );
}

}
