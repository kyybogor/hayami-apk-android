import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditProductPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const EditProductPage({super.key, required this.product});

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaController;
  late TextEditingController _hargaController;
  late TextEditingController _minimController;
  late TextEditingController _maximController;
  late TextEditingController _brandController;

  String? _selectedKategori;
  List<String> _kategoriList = [];

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController(text: widget.product['nm_product'] ?? '');
    _hargaController = TextEditingController(text: widget.product['price']?.toString() ?? '');
    _minimController = TextEditingController(text: widget.product['minim']?.toString() ?? '');
    _maximController = TextEditingController(text: widget.product['maxim']?.toString() ?? '');
    _brandController = TextEditingController(text: widget.product['brand'] ?? '');
    _selectedKategori = widget.product['brand'];
    _fetchKategori();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _minimController.dispose();
    _maximController.dispose();
    _brandController.dispose();
    super.dispose();
  }

  Future<void> _fetchKategori() async {
    final url = Uri.parse('http://192.168.1.9/hiyami/kategori.php');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> kategoriData = json.decode(response.body);
        setState(() {
          _kategoriList = kategoriData
              .map((kategori) => kategori['nama_kategori'] as String)
              .toList();
          if (_selectedKategori != null && !_kategoriList.contains(_selectedKategori)) {
            _kategoriList.add(_selectedKategori!);
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat kategori')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan jaringan')),
      );
    }
  }

  Future<void> _submitEdit() async {
    if (_formKey.currentState!.validate()) {
      if (_brandController.text.isEmpty && _selectedKategori == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Brand atau Kategori harus diisi')),
        );
        return;
      }

      final url = Uri.parse('http://192.168.1.9/nindo2/edit_produk.php');
      try {
final response = await http.post(url, body: {
  'id_product': widget.product['id_product'].toString(),
  'nm_product': _namaController.text,
  'gambar': '', // kosong sementara, bisa diisi kalau kamu pakai upload
  'qty': widget.product['qty'].toString(), // default nilai awal, bisa ditambahkan form jika perlu
  'minim': _minimController.text,
  'maxim': _maximController.text,
  'price': _hargaController.text,
  'brand': _brandController.text.isNotEmpty
      ? _brandController.text
      : (_selectedKategori ?? ''),
  'id_cabang': 'pusat',
});


        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Produk berhasil diperbarui')),
            );
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal mengubah produk: ${data['message']}')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Terjadi kesalahan jaringan')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan saat mengirim data')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration inputDecoration(String label) => InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
          border: InputBorder.none,
        );

    Widget buildTextField({
      required TextEditingController controller,
      required String label,
      TextInputType? keyboardType,
      String? Function(String?)? validator,
    }) =>
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.blue),
          ),
          child: TextFormField(
            controller: controller,
            decoration: inputDecoration(label),
            keyboardType: keyboardType,
            validator: validator,
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Ubah Produk')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              buildTextField(
                controller: _namaController,
                label: 'Nama Produk',
                validator: (v) => (v == null || v.isEmpty) ? 'Masukkan nama produk' : null,
              ),
              const SizedBox(height: 16),
              buildTextField(
                controller: _hargaController,
                label: 'Harga Jual',
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Masukkan harga jual' : null,
              ),
              const SizedBox(height: 16),
              buildTextField(
                controller: _minimController,
                label: 'Minimal Stok',
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Masukkan minimal stok' : null,
              ),
              const SizedBox(height: 16),
              buildTextField(
                controller: _maximController,
                label: 'Maksimal Stok',
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Masukkan maksimal stok' : null,
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.blue),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedKategori,
                  onChanged: (value) {
                    setState(() {
                      _selectedKategori = value;
                    });
                  },
                  items: _kategoriList
                      .map((kategori) => DropdownMenuItem<String>(
                            value: kategori,
                            child: Text(kategori),
                          ))
                      .toList(),
                  decoration: inputDecoration('Kategori'),
                  validator: (v) => v == null || v.isEmpty ? 'Pilih kategori' : null,
                ),
              ),
              const SizedBox(height: 16),
              buildTextField(
                controller: _brandController,
                label: 'Brand (opsional)',
                validator: null,
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: _submitEdit,
                  child: const Text('Simpan Perubahan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
