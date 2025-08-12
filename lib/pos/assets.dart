import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AssetsPage extends StatefulWidget {
  const AssetsPage({super.key});

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {
  String idCabang = '';
  late String apiUrl;

  List<dynamic> allData = [];
  List<dynamic> filteredData = [];
  List<String> suggestions = [];

  final TextEditingController idBahanCtrl = TextEditingController();
  final TextEditingController modelCtrl = TextEditingController();
  final TextEditingController ukuranCtrl = TextEditingController();
  final TextEditingController barcodeCtrl = TextEditingController();

  final double col1 = 240; // ID Bahan
  final double col2 = 160; // Model
  final double col3 = 120; // Ukuran
  final double col4 = 100; // Stock
  final double col5 = 100; // Harga
  final double col6 = 140; // Total

  String activeField = '';

  final Map<String, LayerLink> _layerLink = {
    "id_bahan": LayerLink(),
    "model": LayerLink(),
    "ukuran": LayerLink(),
    "barcode": LayerLink(),
  };

  final Map<String, GlobalKey> _fieldKeys = {
    "id_bahan": GlobalKey(),
    "model": GlobalKey(),
    "ukuran": GlobalKey(),
    "barcode": GlobalKey(),
  };

  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _getIdCabang();
  }

  Future<void> _getIdCabang() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      idCabang = prefs.getString('id_cabang') ?? '';
      apiUrl = "https://hayami.id/pos/assets.php?id_cabang=$idCabang";
    });
    fetchData();
  }

  Future<void> fetchData() async {
    if (idCabang.isEmpty) return;
    try {
      var res = await http.get(Uri.parse(apiUrl));
      if (res.statusCode == 200) {
        setState(() {
          allData = json.decode(res.body);
        });
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }
  }

  void _showOverlaySuggestions(String field) {
    _overlayEntry?.remove();
    if (suggestions.isEmpty) return;

    final overlay = Overlay.of(context);

    // Ambil lebar input
    final renderBox = _fieldKeys[field]!.currentContext!.findRenderObject() as RenderBox;
    final width = renderBox.size.width;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          width: width,
          child: CompositedTransformFollower(
            link: _layerLink[field]!,
            showWhenUnlinked: false,
            offset: const Offset(0, 60),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(5),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 150),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      dense: true,
                      title: Text(suggestions[index]),
                      onTap: () => selectSuggestion(suggestions[index], field),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideOverlaySuggestions() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void filterSuggestions(String query, String field) {
    setState(() {
      activeField = field;
      String idBahanVal = idBahanCtrl.text.toLowerCase().trim();
      String modelVal = modelCtrl.text.toLowerCase().trim();

      if (query.isNotEmpty) {
        if (field == "model" && idBahanVal.isNotEmpty) {
          suggestions = allData
              .where((item) =>
                  item["id_bahan"].toString().toLowerCase().trim() == idBahanVal)
              .map((item) => item["model"].toString())
              .where((val) => val.toLowerCase().contains(query.toLowerCase()))
              .toSet()
              .toList();
        } else if (field == "ukuran" &&
            idBahanVal.isNotEmpty &&
            modelVal.isNotEmpty) {
          suggestions = allData
              .where((item) =>
                  item["id_bahan"].toString().toLowerCase().trim() == idBahanVal &&
                  item["model"].toString().toLowerCase().trim() == modelVal)
              .map((item) => item["ukuran"].toString())
              .where((val) => val.toLowerCase().contains(query.toLowerCase()))
              .toSet()
              .toList();
        } else {
          suggestions = allData
              .map((item) => item[field].toString())
              .where((val) => val.toLowerCase().contains(query.toLowerCase()))
              .toSet()
              .toList();
        }
      } else {
        suggestions = [];
      }
    });

    if (suggestions.isNotEmpty) {
      _showOverlaySuggestions(field);
    } else {
      _hideOverlaySuggestions();
    }
  }

  void selectSuggestion(String value, String field) {
    setState(() {
      if (field == "id_bahan") {
        idBahanCtrl.text = value;
        modelCtrl.clear();
        ukuranCtrl.clear();
      } else if (field == "model") {
        modelCtrl.text = value;
        ukuranCtrl.clear();
      } else if (field == "ukuran") {
        ukuranCtrl.text = value;
      } else if (field == "barcode") {
        barcodeCtrl.text = value;
      }

      if (barcodeCtrl.text.isNotEmpty) {
        idBahanCtrl.clear();
        modelCtrl.clear();
        ukuranCtrl.clear();
      }

      if (idBahanCtrl.text.isNotEmpty &&
          modelCtrl.text.isNotEmpty &&
          ukuranCtrl.text.isNotEmpty) {
        barcodeCtrl.clear();
      }

      suggestions = [];
      _hideOverlaySuggestions();
    });
  }

  void clearAllInputs() {
    setState(() {
      idBahanCtrl.clear();
      modelCtrl.clear();
      ukuranCtrl.clear();
      barcodeCtrl.clear();
      suggestions.clear();
      activeField = '';
      filteredData.clear();
    });
    _hideOverlaySuggestions();
  }

  void searchData() {
    setState(() {
      filteredData = allData.where((item) {
        bool match = true;
        if (barcodeCtrl.text.isNotEmpty) {
          match &= item["barcode"]
              .toString()
              .toLowerCase()
              .contains(barcodeCtrl.text.toLowerCase());
        }
        if (idBahanCtrl.text.isNotEmpty) {
          match &= item["id_bahan"]
              .toString()
              .toLowerCase()
              .contains(idBahanCtrl.text.toLowerCase());
        }
        if (modelCtrl.text.isNotEmpty) {
          match &= item["model"]
              .toString()
              .toLowerCase()
              .contains(modelCtrl.text.toLowerCase());
        }
        if (ukuranCtrl.text.isNotEmpty) {
          match &= item["ukuran"]
              .toString()
              .toLowerCase()
              .contains(ukuranCtrl.text.toLowerCase());
        }
        return match;
      }).toList();
    });
  }

  String formatCurrency(dynamic value) {
    final formatter = NumberFormat("#,###", "id_ID");
    return formatter.format(int.tryParse(value.toString()) ?? 0);
  }

  Widget buildSearchField(
      String label, TextEditingController controller, String field) {
    bool disabled = false;

    if (field == "barcode" &&
        idBahanCtrl.text.isNotEmpty &&
        modelCtrl.text.isNotEmpty &&
        ukuranCtrl.text.isNotEmpty) {
      disabled = true;
    }

    if (field != "barcode" && barcodeCtrl.text.isNotEmpty) {
      disabled = true;
    }

    return CompositedTransformTarget(
      link: _layerLink[field]!,
      child: Container(
        key: _fieldKeys[field],
        child: TextField(
          controller: controller,
          enabled: !disabled,
          onChanged: (value) => filterSuggestions(value, field),
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      setState(() {
                        controller.clear();
                        suggestions.clear();
                      });
                      _hideOverlaySuggestions();
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Assets"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        centerTitle: true,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: _hideOverlaySuggestions,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                      flex: 3,
                      child:
                          buildSearchField("ID Bahan", idBahanCtrl, "id_bahan")),
                  const SizedBox(width: 5),
                  Expanded(
                      flex: 3,
                      child: buildSearchField("Model", modelCtrl, "model")),
                  const SizedBox(width: 5),
                  Expanded(
                      flex: 3,
                      child: buildSearchField("Ukuran", ukuranCtrl, "ukuran")),
                ],
              ),
              const SizedBox(height: 8),
              buildSearchField("Barcode", barcodeCtrl, "barcode"),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    height: 36,
                    child: ElevatedButton(
                      onPressed: searchData,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text("Cari"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (filteredData.isNotEmpty)
  Column(
    children: [
      // Header dan body menggunakan SingleChildScrollView
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(
          children: [
            // Header yang tetap berada di atas
            Container(
              color: Colors.indigo,
              child: DataTable(
                columnSpacing: 0,
                headingRowHeight: 36,
                headingTextStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.white,
                ),
                headingRowColor: MaterialStateProperty.all(Colors.indigo),
                border: TableBorder.all(color: Colors.grey.shade200),
                columns: [
                  DataColumn(label: SizedBox(width: col1, child: const Center(child: Text("ID Bahan")))),
                  DataColumn(label: SizedBox(width: col2, child: const Center(child: Text("Model")))),
                  DataColumn(label: SizedBox(width: col3, child: const Center(child: Text("Ukuran")))),
                  DataColumn(label: SizedBox(width: col4, child: const Center(child: Text("Stock")))),
                  DataColumn(label: SizedBox(width: col5, child: const Center(child: Text("Harga")))),
                  DataColumn(label: SizedBox(width: col6, child: const Center(child: Text("Total")))),
                ],
                rows: [],
              ),
            ),
            // Body yang bisa di-scroll secara vertikal dan horizontal
            SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 0,
                  headingRowHeight: 0, // Menyembunyikan header pada body
                  dataRowHeight: 34,
                  dataTextStyle: const TextStyle(fontSize: 12),
                  border: TableBorder.all(color: Colors.grey.shade200),
                  columns: [
                    DataColumn(label: SizedBox(width: col1)),
                    DataColumn(label: SizedBox(width: col2)),
                    DataColumn(label: SizedBox(width: col3)),
                    DataColumn(label: SizedBox(width: col4)),
                    DataColumn(label: SizedBox(width: col5)),
                    DataColumn(label: SizedBox(width: col6)),
                  ],
                  rows: filteredData.map((item) {
                    return DataRow(
                      cells: [
                        DataCell(SizedBox(width: col1, child: Center(child: Text(item["id_bahan"].toString())))),
                        DataCell(SizedBox(width: col2, child: Center(child: Text(item["model"].toString())))),
                        DataCell(SizedBox(width: col3, child: Center(child: Text(item["ukuran"].toString())))),
                        DataCell(SizedBox(width: col4, child: Center(child: Text(item["stock"].toString())))),
                        DataCell(SizedBox(width: col5, child: Center(child: Text(formatCurrency(item["harga"]))))),
                        DataCell(SizedBox(width: col6, child: Center(child: Text(formatCurrency(item["totalHarga"]))))),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  )
            ],
          ),
        ),
      ),
    );
  }
}
