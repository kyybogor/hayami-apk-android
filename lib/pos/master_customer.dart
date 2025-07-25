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

// ✅ SERVICE
Future<List<Customer>> fetchCustomers() async {
  final response = await http.get(
    Uri.parse('https://hayami.id/pos/customer.php?action=get_all'),
  );

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

  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    futureCustomer = fetchCustomers();
    futureCustomer.then((data) {
      data.sort((a, b) => a.nama.toLowerCase().compareTo(b.nama.toLowerCase()));
      setState(() {
        allCustomers = data;
        filteredCustomers = data;
      });
    });
  }

  void _filter(String query) {
    final filtered = allCustomers.where((cust) {
      return cust.nama.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      filteredCustomers = filtered;
    });
  }

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
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // Sudut lebih melengkung
        ),
        child: Container(
          width: 500,  // Lebar dialog
          height: 400, // Tinggi dialog
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Customer', style: TextStyle(fontSize: 18)),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField('ID Customer', idController),
                      _buildTextField('Nama Customer', namaController),
                      _buildTextField('Kota', kotaController),
                      _buildTextField('Alamat Lengkap', alamatController, maxLines: 3),
                      _buildTextField('No. Telp', telpController),
                      _buildTextField('Email', emailController),
                      _buildTextField('Diskon/Lusin', diskonController),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text('Batal', style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () async {
                      // Validasi data
                      if (idController.text.isEmpty || namaController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('ID dan Nama wajib diisi')),
                        );
                        return;
                      }

                      // Kirim data ke server
                      final response = await _addCustomer(
                        idController.text,
                        namaController.text,
                        kotaController.text,
                        alamatController.text,
                        telpController.text,
                        emailController.text,
                        diskonController.text.isEmpty ? '0' : diskonController.text,
                      );

                      if (response['status'] == 'success') {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Customer berhasil ditambahkan')),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${response['message']}')),
                        );
                      }

                      Navigator.of(context).pop(); // Menutup dialog setelah simpan
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo, // Warna latar belakang tombol
                      foregroundColor: Colors.white,   // Warna teks tombol
                    ),
                    child: Text('Simpan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

// Fungsi untuk mengirim data ke server PHP
Future<Map<String, dynamic>> _addCustomer(
  String idCustomer,
  String namaCustomer,
  String kota,
  String alamatLengkap,
  String noTelp,
  String email,
  String diskonLusin,
) async {
  final url = Uri.parse('http://192.168.1.25/pos/tambah_customer.php');
  final response = await http.post(
    url,
    body: {
      'id_customer': idCustomer,
      'nama_customer': namaCustomer,
      'kota': kota,
      'alamat_lengkap': alamatLengkap,
      'no_telp': noTelp,
      'email': email,
      'diskon_lusin': diskonLusin,
      'id_cabang': '1', // Tambahkan ID Cabang, jika diperlukan
    },
  );

  if (response.statusCode == 200) {
    // Parsing response jika status 200 (OK)
    return json.decode(response.body);
  } else {
    // Menangani error server
    return {'status': 'error', 'message': 'Gagal menghubungi server'};
  }
}

// Fungsi untuk membuat TextField




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
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // Sudut lebih melengkung
        ),
        // Menambahkan batasan ukuran dialog
        child: Container(
          width: 500,  // Lebar dialog
          height: 400, // Tinggi dialog
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Edit Customer', style: TextStyle(fontSize: 18)),
                  IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField('ID Customer', idController, readOnly: true),
                      _buildTextField('Nama Customer', namaController),
                      _buildTextField('Kota', kotaController),
                      _buildTextField('Alamat Lengkap', alamatController, maxLines: 3),
                      _buildTextField('No. Telp', telpController),
                      _buildTextField('Email', emailController),
                      _buildTextField('Diskon/Lusin', diskonController),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text('Batal', style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      if (namaController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Nama wajib diisi')),
                        );
                        return;
                      }
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Customer berhasil diperbarui')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo, // Warna latar belakang tombol
                      foregroundColor: Colors.white,   // Warna teks tombol
                    ),
                    child: Text('Simpan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
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
  return Scrollbar(
    thumbVisibility: true,
    thickness: 12,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor:
              MaterialStateColor.resolveWith((states) => Colors.indigo),
          headingTextStyle: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
          dataRowHeight: 50,
          columnSpacing: 30, // spacing antar kolom
          columns: [
  DataColumn(
    label: SizedBox(
      width: 100,
      child: Text(
        'Kode',
        textAlign: TextAlign.center,
      ),
    ),
  ),
  DataColumn(
    label: SizedBox(
      width: 150,
      child: Text(
        'Nama Customer',
        textAlign: TextAlign.center,
      ),
    ),
  ),
  DataColumn(
    label: SizedBox(
      width: 150,
      child: Text(
        'Alamat',
        textAlign: TextAlign.center,
      ),
    ),
  ),
  DataColumn(
    label: SizedBox(
      width: 120,
      child: Text(
        'No. Telp',
        textAlign: TextAlign.center,
      ),
    ),
  ),
  DataColumn(
    label: SizedBox(
      width: 200,
      child: Text(
        'Email',
        textAlign: TextAlign.center,
      ),
    ),
  ),
  DataColumn(
    label: SizedBox(
      width: 130,
      child: Text(
        'Diskon/Lusin',
        textAlign: TextAlign.center,
      ),
    ),
  ),
  DataColumn(
    label: SizedBox(
      width: 200,
      child: Text(
        'Id Cabang',
        textAlign: TextAlign.center,
      ),
    ),
  ),
  DataColumn(
    label: SizedBox(
      width: 100,
      child: Text(
        'Aksi',
        textAlign: TextAlign.center,
      ),
    ),
  ),
],

          rows: filteredCustomers.map((customer) {
            return DataRow(cells: [
  DataCell(Center(child: Text(customer.kode, textAlign: TextAlign.center))),
  DataCell(Center(child: Text(customer.nama, textAlign: TextAlign.center))),
  DataCell(Center(child: Text(customer.alamat, textAlign: TextAlign.center))),
  DataCell(Center(child: Text(customer.telp, textAlign: TextAlign.center))),
  DataCell(Center(
    child: SizedBox(
      width: 200,
      child: Text(
        customer.email,
        textAlign: TextAlign.center,
      ),
    ),
  )),
  DataCell(Center(child: Text(customer.diskon, textAlign: TextAlign.center))),
  DataCell(Center(child: Text(customer.idCabang, textAlign: TextAlign.center))),
  DataCell(Center(
    child: Row(
      mainAxisSize: MainAxisSize.min, // Supaya Row-nya nggak melebar
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.edit, color: Colors.blue),
          onPressed: () => _showEditCustomerDialog(customer),
        ),
        IconButton(
          icon: Icon(Icons.delete, color: Colors.red),
          onPressed: () {},
        ),
      ],
    ),
  )),
]);
          }).toList(),
          border: TableBorder(
            horizontalInside: BorderSide(width: 1, color: Colors.grey.shade300),
            verticalInside: BorderSide(width: 1, color: Colors.grey.shade300),
            bottom: BorderSide(width: 1, color: Colors.grey.shade300),
            top: BorderSide(width: 1, color: Colors.grey.shade300),
            left: BorderSide(width: 1, color: Colors.grey.shade300),
            right: BorderSide(width: 1, color: Colors.grey.shade300),
          ),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 30, bottom: 10),
        child: FloatingActionButton.extended(
          onPressed: _showAddCustomerDialog,
          backgroundColor: Color(0xFF3B5BA9),
          icon: Icon(Icons.add, color: Colors.white),
          label: Text('Tambah Baru', style: TextStyle(color: Colors.white)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
