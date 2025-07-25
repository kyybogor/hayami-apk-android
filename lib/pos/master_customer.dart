import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    title: 'Master Customer',
    home: CustomerPage(),
    debugShowCheckedModeBanner: false,
  ));
}

// MODEL
class Customer {
  final String kode;
  final String nama;
  final String alamat;
  final String telp;
  final String email;
  final String diskon;
  final String idCabang;

  Customer({
    required this.kode,
    required this.nama,
    required this.alamat,
    required this.telp,
    required this.email,
    required this.diskon,
    required this.idCabang,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      kode: json['id_customer'] ?? '',
      nama: json['nama_customer'] ?? '',
      alamat: json['kota'] ?? '',
      telp: json['no_telp'] ?? '',
      email: json['email'] ?? '',
      diskon: json['diskon_lusin'] ?? '0.00',
      idCabang: json['id_cabang'] ?? '',
    );
  }
}

// SERVICE
Future<List<Customer>> fetchCustomers() async {
  final response =
      await http.get(Uri.parse('https://hayami.id/pos/customer.php'));

  if (response.statusCode == 200) {
    final Map<String, dynamic> jsonData = json.decode(response.body);
    if (jsonData['status'] == 'success') {
      final List<dynamic> customerList = jsonData['data'];
      return customerList.map((item) => Customer.fromJson(item)).toList();
    } else {
      throw Exception('Status bukan success');
    }
  } else {
    throw Exception('Gagal mengambil data');
  }
}

// UI
class CustomerPage extends StatefulWidget {
  @override
  _CustomerPageState createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  late Future<List<Customer>> futureCustomer;
  List<Customer> allCustomers = [];
  List<Customer> filteredCustomers = [];

  int currentPage = 1;
  int rowsPerPage = 10;

  TextEditingController searchController = TextEditingController();
  TextEditingController searchControllerTop = TextEditingController();

  final List<int> rowsOptions = [10, 25, 50, 100];

  @override
  void initState() {
    super.initState();
    futureCustomer = fetchCustomers();
    futureCustomer.then((data) {
      data.sort((a, b) =>
          a.nama.toLowerCase().compareTo(b.nama.toLowerCase())); // Sorting A-Z
      setState(() {
        allCustomers = data;
        filteredCustomers = data;
      });
    });
  }

  // ADDED: Show Add Customer Dialog
  void _showAddCustomerDialog() {
    final idController = TextEditingController();
    final namaController = TextEditingController();
    final kotaController = TextEditingController();
    final alamatController = TextEditingController();
    final telpController = TextEditingController();
    final emailController = TextEditingController();
    final diskonController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Customer'),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField('ID Customer', idController),
                _buildTextField('Nama Customer', namaController),
                _buildTextField('Kota', kotaController),
                _buildTextField('Alamat Lengkap', alamatController,
                    maxLines: 3),
                _buildTextField('No. Telp', telpController),
                _buildTextField('Email', emailController),
                _buildTextField('Diskon/Lusin', diskonController),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[400],
              ),
              child: Text('Batal', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                // Validasi singkat
                if (idController.text.isEmpty || namaController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('ID dan Nama wajib diisi')),
                  );
                  return;
                }

                // TODO: Kirim ke backend atau tambahkan ke list

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Customer berhasil ditambahkan')),
                );
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showEditCustomerDialog(Customer customer) {
    final idController = TextEditingController(text: customer.kode);
    final namaController = TextEditingController(text: customer.nama);
    final kotaController = TextEditingController(text: customer.alamat);
    final alamatController = TextEditingController();
    final telpController = TextEditingController(text: customer.telp);
    final emailController = TextEditingController(text: customer.email);
    final diskonController = TextEditingController(text: customer.diskon);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Edit Customer'),
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField('ID Customer', idController, readOnly: true),
                _buildTextField('Nama Customer', namaController),
                _buildTextField('Kota', kotaController),
                _buildTextField('Alamat Lengkap', alamatController,
                    maxLines: 3),
                _buildTextField('No. Telp', telpController),
                _buildTextField('Email', emailController),
                _buildTextField('Diskon/Lusin', diskonController),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(backgroundColor: Colors.grey[400]),
              child: Text('Batal', style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                // Validasi dan simpan perubahan
                if (namaController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Nama wajib diisi')),
                  );
                  return;
                }

                // TODO: Kirim perubahan ke backend

                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Customer berhasil diperbarui')),
                );
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

// ADDED: Reusable field builder
  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          SizedBox(height: 4),
          TextField(
            controller: controller,
            maxLines: maxLines,
            readOnly: readOnly,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              fillColor: readOnly ? Colors.grey[200] : null,
              filled: readOnly,
            ),
          ),
        ],
      ),
    );
  }

  void _filter(String query) {
    final filtered = allCustomers.where((cust) {
      return cust.nama.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredCustomers = filtered;
      currentPage = 1;
    });
  }

  List<Customer> getPaginatedData() {
    final startIndex = (currentPage - 1) * rowsPerPage;
    final endIndex =
        (startIndex + rowsPerPage).clamp(0, filteredCustomers.length);
    return filteredCustomers.sublist(startIndex, endIndex);
  }

  Widget _buildSearchBox() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Cari Nama Customer',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: _filter,
      ),
    );
  }

  Widget _buildDataTable() {
    final dataToShow = getPaginatedData();

    return Scrollbar(
      thumbVisibility: true,
      thickness: 12, // <- agar lebih tebal
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Kode')),
              DataColumn(label: Text('Nama Customer')),
              DataColumn(label: Text('Alamat')),
              DataColumn(label: Text('No. Telp')),
              DataColumn(label: Text('Email')),
              DataColumn(label: Text('Diskon/Lusin')),
              DataColumn(label: Text('Id Cabang')),
              DataColumn(label: Text('Aksi')),
            ],
            rows: dataToShow.map((customer) {
              return DataRow(cells: [
                DataCell(Text(customer.kode)),
                DataCell(Text(customer.nama)),
                DataCell(Text(customer.alamat)),
                DataCell(Text(customer.telp)),
                DataCell(Text(customer.email)),
                DataCell(Text(customer.diskon)),
                DataCell(Text(customer.idCabang)),
                DataCell(Row(
                  children: [
                    // IconButton(
                    //   icon: Icon(Icons.add, color: Colors.green),
                    //   onPressed: _showAddCustomerDialog,
                    // ),
                    IconButton(
                      icon: Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditCustomerDialog(customer),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Master Customer', style: TextStyle(color: Colors.blue)),
        centerTitle: true,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchBox(),
          Expanded(
            child: FutureBuilder<List<Customer>>(
              future: futureCustomer,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(child: CircularProgressIndicator());
                if (snapshot.hasError)
                  return Center(child: Text('Error: ${snapshot.error}'));

                return Column(
                  children: [
                    Expanded(child: _buildDataTable()),
                  ],
                );
              },
            ),
          ),
        ],
      ),

      // ⬇️ Tambahkan ini di sini (di dalam Scaffold)
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
            right: 90, bottom: 50), // ⬅️ agar agak ke kiri dan naik sedikit
        child: FloatingActionButton.extended(
          onPressed: _showAddCustomerDialog,
          backgroundColor: Color(0xFF3B5BA9), // warna biru sesuai contoh
          icon: Icon(Icons.add, color: Colors.white),
          label: Text('Tambah Baru', style: TextStyle(color: Colors.white)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // ⬅️ kotak rounded
          ),
        ),
      ),
    );
  }
}
