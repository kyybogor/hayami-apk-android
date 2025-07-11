import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Opname extends StatefulWidget {
  @override
  _OpnameState createState() => _OpnameState();
}

class _OpnameState extends State<Opname> {
  final TextEditingController _namaBarangController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _ukuranController = TextEditingController();
  final TextEditingController _uomController = TextEditingController();

  List<String> _namaBarangList = [];
  List<String> _modelList = [];

  @override
  void initState() {
    super.initState();
    fetchSuggestions();
  }

  Future<void> fetchSuggestions() async {
    final response = await http.get(Uri.parse('http://192.168.1.4/pos/tb_stock.php'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        _namaBarangList = data.map((item) => item['nama_barang'].toString()).toSet().toList();
        _modelList = data.map((item) => item['model'].toString()).toSet().toList();
      });
    } else {
      _showDialog("Gagal mengambil data dari server");
    }
  }

  void _tambahStok() {
    String nama = _namaBarangController.text;
    String model = _modelController.text;
    String ukuran = _ukuranController.text;
    String uom = _uomController.text;

    if (nama.isEmpty || model.isEmpty || ukuran.isEmpty || uom.isEmpty) {
      _showDialog("Semua field harus diisi!");
      return;
    }

    _showDialog("Data berhasil ditambahkan:\n$nama - $model - $ukuran - $uom");
  }

  void _showDialog(String msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Info"),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          )
        ],
      ),
    );
  }

  Widget _buildCardInput({required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update Stock"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCardInput(
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue value) {
                  if (value.text.isEmpty) return const Iterable<String>.empty();
                  return _namaBarangList.where((item) =>
                      item.toLowerCase().contains(value.text.toLowerCase()));
                },
                onSelected: (selection) => _namaBarangController.text = selection,
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  controller.text = _namaBarangController.text;
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(labelText: "Nama Barang", border: InputBorder.none),
                  );
                },
              ),
            ),
            _buildCardInput(
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue value) {
                  if (value.text.isEmpty) return const Iterable<String>.empty();
                  return _modelList.where((item) =>
                      item.toLowerCase().contains(value.text.toLowerCase()));
                },
                onSelected: (selection) => _modelController.text = selection,
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  controller.text = _modelController.text;
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(labelText: "Model", border: InputBorder.none),
                  );
                },
              ),
            ),
            _buildCardInput(
              child: TextField(
                controller: _ukuranController,
                decoration: InputDecoration(labelText: "Ukuran", border: InputBorder.none),
              ),
            ),
            _buildCardInput(
              child: TextField(
                controller: _uomController,
                decoration: InputDecoration(labelText: "UOM", border: InputBorder.none),
              ),
            ),
            SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _tambahStok,
                child: Text("Tambah"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
