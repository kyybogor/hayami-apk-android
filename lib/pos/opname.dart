import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Opname extends StatefulWidget {
  @override
  _OpnameState createState() => _OpnameState();
}

class _OpnameState extends State<Opname> {
  final GlobalKey<OpnameListFromApiState> _opnameListKey =
      GlobalKey<OpnameListFromApiState>();
  final TextEditingController _namaBarangController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _ukuranController = TextEditingController();
  final TextEditingController _uomController = TextEditingController();

  List<Map<String, dynamic>> _stockData = [];
  String? _idCabang;
  String? _selectedNamaBarang;
  String? _selectedModel;
  String? _selectedUkuran;

  @override
  void initState() {
    super.initState();
    _loadCabangDanData();
  }

  Future<void> _loadCabangDanData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idCabang = prefs.getString('id_cabang');
    if (idCabang == null || idCabang.isEmpty) {
      _showDialog("ID Cabang tidak ditemukan di penyimpanan.");
      return;
    }
    setState(() {
      _idCabang = idCabang;
    });
    fetchSuggestions();
  }

  Future<void> fetchSuggestions() async {
    final response =
        await http.get(Uri.parse('http://192.168.1.2/pos/stock.php'));
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      final List<dynamic> data = jsonResponse['data'];

      final filtered =
          data.where((item) => item['id_cabang'] == _idCabang).toList();

      setState(() {
        _stockData = filtered.cast<Map<String, dynamic>>();
      });
    } else {
      _showDialog("Gagal mengambil data dari server");
    }
  }

  void _tambahStok() async {
    if (_selectedNamaBarang == null ||
        _selectedModel == null ||
        _selectedUkuran == null ||
        _uomController.text.isEmpty) {
      _showDialog("Semua field harus diisi!");
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idUser = prefs.getString('id_user');
    String? idCabang = prefs.getString('id_cabang');

    if (idUser == null || idCabang == null) {
      _showDialog("ID User atau ID Cabang tidak ditemukan.");
      return;
    }

    final match = _stockData.firstWhere(
      (item) =>
          item['id_bahan'] == _selectedNamaBarang &&
          item['model'] == _selectedModel &&
          item['ukuran'] == _selectedUkuran,
      orElse: () => {},
    );

    if (match.isEmpty) {
      _showDialog("Data tidak ditemukan dalam stock JSON.");
      return;
    }

    double stockAwal = double.tryParse(match['stock'] ?? '0') ?? 0;

    final response = await http.post(
      Uri.parse('http://192.168.1.2/pos/tambah_list_opname.php'),
      body: {
        'id_inv_in': idUser,
        'id_product': _selectedNamaBarang!,
        'model': _selectedModel!,
        'ukuran': _selectedUkuran!,
        'stock_awal': stockAwal.toString(),
        'create_by': idUser,
        'id_cabang': idCabang,
      },
    );

    if (response.statusCode == 200) {
      _showDialog("Berhasil: ${response.body}");

      // Reset semua field dan state
      setState(() {
        _selectedNamaBarang = null;
        _selectedModel = null;
        _selectedUkuran = null;

        _namaBarangController.clear();
        _modelController.clear();
        _ukuranController.clear();
        _uomController.clear();
      });

      // 🔁 Muat ulang data ke tabel
      _opnameListKey.currentState?.reloadData();
    } else {
      _showDialog("Gagal menyimpan: ${response.statusCode}");
    }
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
        centerTitle: true,
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
                  return _stockData
                      .map((item) => item['id_bahan'].toString())
                      .toSet()
                      .where((idBahan) => idBahan
                          .toLowerCase()
                          .contains(value.text.toLowerCase()));
                },
                onSelected: (selection) {
                  setState(() {
                    _selectedNamaBarang = selection;
                    _namaBarangController.text = selection;
                    _selectedModel = null;
                    _modelController.clear();
                    _selectedUkuran = null;
                    _ukuranController.clear();
                    _uomController.clear();
                  });
                },
                fieldViewBuilder: (context, textEditingController, focusNode,
                    onFieldSubmitted) {
                  textEditingController.value = TextEditingValue(
                    text: _selectedNamaBarang ?? '',
                    selection: TextSelection.collapsed(
                        offset: (_selectedNamaBarang ?? '').length),
                    composing: TextRange.empty,
                  );
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                        labelText: "Nama Barang", border: InputBorder.none),
                    onChanged: (val) {
                      setState(() {
                        _selectedNamaBarang = val;
                        _selectedModel = null;
                        _modelController.clear();
                        _selectedUkuran = null;
                        _ukuranController.clear();
                        _uomController.clear();
                      });
                    },
                  );
                },
              ),
            ),
            _buildCardInput(
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue value) {
                  if (_selectedNamaBarang == null ||
                      _selectedNamaBarang!.isEmpty) {
                    return const Iterable<String>.empty();
                  }

                  final allModels = _stockData
                      .where((item) => item['id_bahan'] == _selectedNamaBarang)
                      .map((item) => item['model'].toString())
                      .toSet()
                      .toList();
                  if (value.text.isEmpty) return allModels;
                  return allModels
                      .where((model) => model
                          .toLowerCase()
                          .contains(value.text.toLowerCase()))
                      .toList();
                },
                onSelected: (selection) {
                  setState(() {
                    _selectedModel = selection;
                    _modelController.text = selection;
                    _selectedUkuran = null;
                    _ukuranController.clear();
                    _uomController.clear();
                  });
                },
                fieldViewBuilder: (context, textEditingController, focusNode,
                    onFieldSubmitted) {
                  textEditingController.value = TextEditingValue(
                    text: _selectedModel ?? '',
                    selection: TextSelection.collapsed(
                        offset: (_selectedModel ?? '').length),
                    composing: TextRange.empty,
                  );
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                        labelText: "Model", border: InputBorder.none),
                    onChanged: (val) {
                      setState(() {
                        _selectedModel = val;
                        _selectedUkuran = null;
                        _ukuranController.clear();
                        _uomController.clear();
                      });
                    },
                  );
                },
              ),
            ),
            _buildCardInput(
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue value) {
                  if (_selectedNamaBarang == null ||
                      _selectedNamaBarang!.isEmpty ||
                      _selectedModel == null ||
                      _selectedModel!.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  return _stockData
                      .where((item) =>
                          item['id_bahan'] == _selectedNamaBarang &&
                          item['model'] == _selectedModel)
                      .map((item) => item['ukuran'].toString())
                      .toSet()
                      .where((ukuran) => ukuran
                          .toLowerCase()
                          .contains(value.text.toLowerCase()));
                },
                onSelected: (selection) {
                  setState(() {
                    _selectedUkuran = selection;
                    _ukuranController.text = selection;

                    final match = _stockData.firstWhere(
                      (item) =>
                          item['id_bahan'] == _selectedNamaBarang &&
                          item['model'] == _selectedModel &&
                          item['ukuran'] == selection,
                      orElse: () => {},
                    );
                    _uomController.text = match['uom'] ?? '';
                  });
                },
                fieldViewBuilder: (context, textEditingController, focusNode,
                    onFieldSubmitted) {
                  textEditingController.value = TextEditingValue(
                    text: _selectedUkuran ?? '',
                    selection: TextSelection.collapsed(
                        offset: (_selectedUkuran ?? '').length),
                    composing: TextRange.empty,
                  );
                  return TextField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                        labelText: "Ukuran", border: InputBorder.none),
                    onChanged: (val) {
                      setState(() {
                        _selectedUkuran = val;
                      });
                    },
                  );
                },
              ),
            ),
            _buildCardInput(
              child: TextField(
                controller: _uomController,
                readOnly: true,
                decoration:
                    InputDecoration(labelText: "UOM", border: InputBorder.none),
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
            SizedBox(height: 30),
            OpnameListFromApi(key: _opnameListKey),
          ],
        ),
      ),
    );
  }
}

class OpnameListFromApi extends StatefulWidget {
  const OpnameListFromApi({Key? key}) : super(key: key);
  @override
  OpnameListFromApiState createState() => OpnameListFromApiState();
}

class OpnameListFromApiState extends State<OpnameListFromApi> {
  List<Map<String, dynamic>> _opnameData = [];
  bool _loading = true;
  String? _idUser;
  String? _invInId; // Simpan inv_in_id di sini

  // Map untuk simpan controller tiap row index
  final Map<int, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadUserAndFetch();
  }

  @override
  void dispose() {
    _controllers.forEach((key, c) => c.dispose());
    super.dispose();
  }

  void reloadData() {
    if (_idUser != null) {
      setState(() {
        _loading = true;
      });
      _fetchOpnameList(_idUser!);
    }
  }

  Future<void> _loadUserAndFetch() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idUser = prefs.getString('id_user');
    if (idUser == null) {
      setState(() {
        _loading = false;
      });
      _showDialog("ID User tidak ditemukan di Shared Preferences.");
      return;
    }
    setState(() {
      _idUser = idUser;
    });
    await _fetchOpnameList(idUser);
  }

  Future<void> _fetchOpnameList(String idUser) async {
    final url =
        Uri.parse('http://192.168.1.2/pos/opname_list.php?id_inv_in=$idUser');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'];

          String? invInIdFromApi;
          if (data.isNotEmpty && data[0].containsKey('inv_in_id')) {
            invInIdFromApi = data[0]['inv_in_id'];
            // Simpan ke SharedPreferences
            SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setString('inv_in_id', invInIdFromApi!);
          }

          setState(() {
            _opnameData = data.map((e) {
              final map = Map<String, dynamic>.from(e);
              map['qty_asli'] = 0.0;
              map['inv_in_id'] =
                  invInIdFromApi;
              return map;
            }).toList();
            _invInId = invInIdFromApi;
            _loading = false;
            _controllers.clear();
          });
        } else {
          setState(() {
            _loading = false;
          });
          _showDialog('Gagal memuat data opname dari server');
        }
      } else {
        setState(() {
          _loading = false;
        });
        _showDialog(
            'Gagal memuat data opname, status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _loading = false;
      });
      _showDialog('Terjadi kesalahan: $e');
    }
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

  Future<bool> _deleteFromServer(String invInId) async {
  final url = Uri.parse('http://192.168.1.2/pos/delete_opname.php');
  try {
    final response = await http.post(url, body: {'inv_in_id': invInId});
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      return jsonResponse['status'] == 'success';
    } else {
      return false;
    }
  } catch (e) {
    print('Error deleteFromServer: $e');
    return false;
  }
}


  void _updateQtyAsli(int index, String val) {
    final parsed = double.tryParse(val);
    if (parsed != null) {
      setState(() {
        _opnameData[index]['qty_asli'] = parsed;
      });
    }
  }

Future<void> _simpanDanOtorisasi() async {
  if (_invInId == null) {
    _showDialog('inv_in_id belum tersedia.');
    return;
  }

  final url = Uri.parse('http://192.168.1.2/pos/opname.php');

  final payload = {
    'inv_in_id': _invInId,
    'data': _opnameData.map((e) => {
      'id_product': e['id_product'],
      'model': e['model'],
      'ukuran': e['ukuran'],
      'uom': e['uom'],
      'stock_awal': double.tryParse('${e['stock_awal']}') ?? 0.0,
      'qty_asli': e['qty_asli'],
      'id_cabang': e['id_cabang'],
    }).toList(),
  };

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode(payload),
    );

    if (response.statusCode == 200) {
      final res = json.decode(response.body);
      if (res['status'] == 'success') {
        _showDialog('Data berhasil disimpan dan diotorisasi.');
        // opsional: reload data setelah simpan
        reloadData();
      } else {
        _showDialog('Gagal simpan data: ${res['message']}');
      }
    } else {
      _showDialog('Error server: ${response.statusCode}');
    }
  } catch (e) {
    _showDialog('Error: $e');
  }
}


void _removeRow(int index) async {
  final invInId = _opnameData[index]['inv_in_id'];
  if (invInId == null) {
    _showDialog('inv_in_id tidak ditemukan, gagal menghapus data.');
    return;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Konfirmasi'),
      content: Text('Apakah Anda yakin ingin menghapus data ini?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Batal')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text('Hapus')),
      ],
    ),
  );

  if (confirmed != true) return;

  setState(() {
    _loading = true;
  });

  final success = await _deleteFromServer(invInId);

  setState(() {
    _loading = false;
  });

  if (success) {
    setState(() {
      _opnameData.removeAt(index);
      _controllers.remove(index);
      final newControllers = <int, TextEditingController>{};
      for (int i = 0; i < _opnameData.length; i++) {
        if (_controllers.containsKey(i)) {
          newControllers[i] = _controllers[i]!;
        } else {
          newControllers[i] = TextEditingController(
              text:
                  (_opnameData[i]['qty_asli'] as double?)?.toStringAsFixed(2) ??
                      '0.00');
        }
      }
      _controllers
        ..clear()
        ..addAll(newControllers);
    });
    _showDialog('Data berhasil dihapus');
  } else {
    _showDialog('Gagal menghapus data di server.');
  }
}


  @override
  Widget build(BuildContext context) {
    if (_loading) return Center(child: CircularProgressIndicator());

    if (_opnameData.isEmpty)
      return Center(child: Text('Belum ada data opname.'));

    return LayoutBuilder(builder: (context, constraints) {
      final totalWidth = constraints.maxWidth;

      final widths = [
        totalWidth * 0.13,
        totalWidth * 0.27,
        totalWidth * 0.10,
        totalWidth * 0.10,
        totalWidth * 0.10,
        totalWidth * 0.10,
        totalWidth * 0.10,
        totalWidth * 0.10,
      ];

      TableRow header = TableRow(
        decoration: BoxDecoration(color: Colors.grey[300]),
        children: [
          _buildCell('Id Product', widths[0], isHeader: true),
          _buildCell('Nama Product', widths[1], isHeader: true),
          _buildCell('Ukuran', widths[2], isHeader: true),
          _buildCell('Qty Awal', widths[3], isHeader: true),
          _buildCell('Qty Asli', widths[4], isHeader: true),
          _buildCell('Qty Opname', widths[5], isHeader: true),
          _buildCell('UOM', widths[6], isHeader: true),
          _buildCell('Hapus', widths[7], isHeader: true),
        ],
      );

      List<TableRow> rows = [];
      for (int i = 0; i < _opnameData.length; i++) {
        final item = _opnameData[i];
        final stockAwal = double.tryParse(item['stock_awal'] ?? '0') ?? 0;
        final qtyAsli = item['qty_asli'] as double? ?? 0.0;
        final qtyOpname = qtyAsli - stockAwal;

        if (!_controllers.containsKey(i)) {
          _controllers[i] =
              TextEditingController(text: qtyAsli.toStringAsFixed(2));
          _controllers[i]!.addListener(() {
            final val = _controllers[i]!.text;
            final parsed = double.tryParse(val);
            if (parsed != null && _opnameData[i]['qty_asli'] != parsed) {
              setState(() {
                _opnameData[i]['qty_asli'] = parsed;
              });
            }
          });
        } else {
          if (_controllers[i]!.text != qtyAsli.toStringAsFixed(2)) {
            _controllers[i]!.text = qtyAsli.toStringAsFixed(2);
          }
        }

        rows.add(TableRow(
          children: [
            _buildCell(item['id_bahan'] ?? '', widths[0]),
            _buildCell('${item['id_product']} - ${item['model']}', widths[1]),
            _buildCell(item['ukuran'] ?? '', widths[2]),
            _buildCell(stockAwal.toStringAsFixed(2), widths[3]),
            _buildInputCell(i, widths[4]),
            _buildCell(qtyOpname.toStringAsFixed(2), widths[5]),
            _buildCell(item['uom'] ?? '', widths[6]),
            _buildDeleteCell(i, widths[7]),
          ],
        ));
      }

      return Column(
        children: [
          // Table dibungkus scroll supaya bisa scroll
          SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Table(
              border: TableBorder.all(color: Colors.grey),
              columnWidths: {
                0: FixedColumnWidth(widths[0]),
                1: FixedColumnWidth(widths[1]),
                2: FixedColumnWidth(widths[2]),
                3: FixedColumnWidth(widths[3]),
                4: FixedColumnWidth(widths[4]),
                5: FixedColumnWidth(widths[5]),
                6: FixedColumnWidth(widths[6]),
                7: FixedColumnWidth(widths[7]),
              },
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              children: [header, ...rows],
            ),
          ),

          SizedBox(height: 20),

          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: () {
                _simpanDanOtorisasi();
              },
              icon: Icon(Icons.save, color: Colors.black),
              label: Text("Simpan & Otorisasi",
                  style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: TextStyle(fontSize: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildCell(String text, double width, {bool isHeader = false}) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Text(
        text,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildInputCell(int index, double width) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: TextFormField(
        controller: _controllers[index],
        keyboardType: TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildDeleteCell(int index, double width) {
    return Container(
      width: width,
      alignment: Alignment.center,
      child: IconButton(
        icon: Icon(Icons.delete, color: Colors.red),
        onPressed: () {
          _removeRow(index);
        },
        tooltip: 'Hapus baris',
      ),
    );
  }
}
