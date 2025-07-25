import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    title: 'List Account',
    home: AkunPage(),
    debugShowCheckedModeBanner: false,
  ));
}

// MODEL
class Akun {
  final String idAkun;
  final String tipe;
  final String bank;
  final String namaAkun;
  final String noAkun;

  Akun({
    required this.idAkun,
    required this.tipe,
    required this.bank,
    required this.namaAkun,
    required this.noAkun,
  });

  factory Akun.fromJson(Map<String, dynamic> json) {
    return Akun(
      idAkun: json['id_akun'] ?? '',
      tipe: json['tipe'] ?? '',
      bank: json['bank'] ?? '',
      namaAkun: json['nama_akun'] ?? '',
      noAkun: json['no_akun'] ?? '',
    );
  }
}

// SERVICE
Future<List<Akun>> fetchAkun() async {
  final response = await http.get(Uri.parse('https://hayami.id/pos/akun.php'));

  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    if (jsonData['status'] == 'success') {
      final List list = jsonData['data'];
      return list.map((e) => Akun.fromJson(e)).toList();
    } else {
      throw Exception("Status bukan success");
    }
  } else {
    throw Exception("Gagal mengambil data");
  }
}

// UI
class AkunPage extends StatefulWidget {
  @override
  _AkunPageState createState() => _AkunPageState();
}

class _AkunPageState extends State<AkunPage> {
  late Future<List<Akun>> futureAkun;
  List<Akun> allAkun = [];
  List<Akun> filteredAkun = [];

  int currentPage = 1;
  int rowsPerPage = 10;
  final rowsOptions = [10, 25, 50];

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureAkun = fetchAkun();
    futureAkun.then((data) {
      setState(() {
        allAkun = data;
        filteredAkun = data;
      });
    });
  }

  void _filter(String query) {
    final filtered = allAkun.where((akun) {
      return akun.namaAkun.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredAkun = filtered;
      currentPage = 1;
    });
  }

  List<Akun> getPaginatedData() {
    final startIndex = (currentPage - 1) * rowsPerPage;
    final endIndex = (startIndex + rowsPerPage).clamp(0, filteredAkun.length);
    return filteredAkun.sublist(startIndex, endIndex);
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Cari Nama Akun',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: _filter,
      ),
    );
  }

  Widget _buildTopFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            height: 36,
            padding: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: rowsPerPage,
                items: rowsOptions.map((value) {
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      rowsPerPage = value;
                      currentPage = 1;
                    });
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable() {
    final dataToShow = getPaginatedData();

    return Scrollbar(
      thumbVisibility: true,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Account Code')),
              DataColumn(label: Text('Name')),
              DataColumn(label: Text('Detail')),
              DataColumn(label: Text('Category')),
              DataColumn(label: Text('Currency')),
              DataColumn(label: Text('Balance')),
              DataColumn(label: Text('Action')),
            ],
            rows: dataToShow.map((akun) {
              return DataRow(cells: [
                DataCell(Text(akun.idAkun)),
                DataCell(Text(akun.namaAkun)),
                DataCell(Text(akun.noAkun.isNotEmpty ? akun.noAkun : 'none')),
                DataCell(Text(akun.tipe)),
                DataCell(Text('IDR')),
                DataCell(Text('0')),
                DataCell(Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.orange),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {},
                    ),
                  ],
                )),
              ]);
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination() {
    final totalEntries = filteredAkun.length;
    final start = ((currentPage - 1) * rowsPerPage) + 1;
    final end = (start + rowsPerPage - 1).clamp(1, totalEntries);
    final totalPages = (totalEntries / rowsPerPage).ceil();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Showing $start to $end of $totalEntries entries"),
          Row(
            children: [
              TextButton(
                onPressed: currentPage > 1
                    ? () => setState(() => currentPage--)
                    : null,
                child: Text("Previous"),
              ),
              ...List.generate(totalPages, (index) {
                final i = index + 1;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor:
                          i == currentPage ? Colors.blue : Colors.white,
                      foregroundColor:
                          i == currentPage ? Colors.white : Colors.black,
                    ),
                    onPressed: () => setState(() => currentPage = i),
                    child: Text('$i'),
                  ),
                );
              }),
              TextButton(
                onPressed: currentPage < totalPages
                    ? () => setState(() => currentPage++)
                    : null,
                child: Text("Next"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('List Account', style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchBox(),
          _buildTopFilterRow(),
          Expanded(
            child: FutureBuilder<List<Akun>>(
              future: futureAkun,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());
                if (snapshot.hasError)
                  return Center(child: Text('Error: ${snapshot.error}'));

                return Column(
                  children: [
                    Expanded(child: _buildDataTable()),
                    _buildPagination(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 80, bottom: 50),
        child: FloatingActionButton.extended(
          onPressed: () {
            // Tambah Akun
          },
          backgroundColor: Colors.green,
          icon: Icon(Icons.add),
          label: Text('Add Account'),
        ),
      ),
    );
  }
}
