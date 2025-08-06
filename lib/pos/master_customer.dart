import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  final String kota;
  final String alamat;
  final String telp;
  final String email;
  final String diskon;
  final String idCabang;

  Customer({
    required this.kode,
    required this.nama,
    required this.kota,
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
      kota: json['kota'] ?? '',
      alamat: json['alamat_lengkap'] ?? '',
      telp: json['no_telp'] ?? '',
      email: json['email'] ?? '',
      diskon: json['diskon_lusin'] ?? '0.00',
      idCabang: json['id_cabang'] ?? '',
    );
  }
}

// ✅ SERVICE
Future<List<Customer>> fetchCustomers() async {
  final prefs = await SharedPreferences.getInstance();
  final String? idCabang = prefs.getString('id_cabang');

  if (idCabang == null || idCabang.isEmpty) {
    throw Exception('id_cabang tidak ditemukan di SharedPreferences');
  }
  final response = await http.get(
    Uri.parse('https://hayami.id/pos/customer.php'),
  );

  if (response.statusCode == 200) {
    final Map<String, dynamic> jsonData = json.decode(response.body);
    if (jsonData['status'] == 'success') {
      final List<dynamic> customerList = jsonData['data'];
      final allCustomers = customerList
          .map((item) => Customer.fromJson(item))
          .toList();
      final filteredCustomers = allCustomers
          .where((customer) => customer.idCabang == idCabang)
          .toList();

      return filteredCustomers;
    } else {
      throw Exception('Status bukan success');
    }
  } else {
    throw Exception('Gagal mengambil data dari server');
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
          width: 500,
          height: 400,
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

                      // Pengecekan duplikat ID dan Nama customer
                      final isDuplicateID = allCustomers.any((cust) => cust.kode.toLowerCase() == idController.text.toLowerCase());
                      final isDuplicateNama = allCustomers.any((cust) => cust.nama.toLowerCase() == namaController.text.toLowerCase());

                      if (isDuplicateID || isDuplicateNama) {
                        // Menampilkan AlertDialog jika ID atau Nama customer sudah ada
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('Error'),
                              content: Text(isDuplicateID
                                  ? 'ID customer sudah ada!'
                                  : 'Nama customer sudah ada!'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop(); // Menutup dialog error
                                  },
                                  child: Text('Tutup'),
                                ),
                              ],
                            );
                          },
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

                        // Tambah customer ke list dan refresh tampilan
                        final newCustomer = Customer(
                          kode: idController.text,
                          nama: namaController.text,
                          kota: kotaController.text,
                          alamat: alamatController.text,
                          telp: telpController.text,
                          email: emailController.text,
                          diskon: diskonController.text.isEmpty ? '0' : diskonController.text,
                          idCabang: (await SharedPreferences.getInstance()).getString('id_cabang') ?? '',
                        );

                        setState(() {
                          allCustomers.add(newCustomer);
                          filteredCustomers = List.from(allCustomers);
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: ${response['message']}')),
                        );
                      }

                      Navigator.of(context).pop(); // Menutup dialog setelah simpan
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
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

Future<void> _deleteCustomer(String idCustomer) async {
  final url = 'https://hayami.id/pos/hapus_customer.php?id_customer=$idCustomer';

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      // Asumsi API sukses menghapus data jika status 200
      // Bisa ditambahkan cek response.body jika API memberikan pesan

      // Hapus customer dari list di UI (setState untuk merefresh UI)
      setState(() {
        // Menghapus customer dari list berdasarkan id
        allCustomers.removeWhere((customer) => customer.kode == idCustomer);
        filteredCustomers = List.from(allCustomers);  // Update filteredCustomers juga
      });

      // Menampilkan SnackBar bahwa customer berhasil dihapus
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Customer berhasil dihapus')),
      );
    } else {
      // Menampilkan error jika gagal menghapus
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus customer')),
      );
    }
  } catch (e) {
    // Menampilkan error jika ada exception
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
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
      SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idCabang = prefs.getString('id_cabang');

  final url = Uri.parse('https://hayami.id/pos/tambah_customer.php');
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
      'id_cabang': idCabang,
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

  void _showEditCustomerDialog(Customer customer) {
  final idController = TextEditingController(text: customer.kode);
  final namaController = TextEditingController(text: customer.nama);
  final kotaController = TextEditingController(text: customer.kota);
  final alamatController = TextEditingController(text: customer.alamat);
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
onPressed: () async {
    if (namaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nama wajib diisi')),
      );
      return;
    }

final prefs = await SharedPreferences.getInstance();
final idCabang = prefs.getString('id_cabang') ?? '';

final updatedCustomer = Customer(
  kode: idController.text,
  nama: namaController.text,
  kota: kotaController.text,
  alamat: alamatController.text,
  telp: telpController.text,
  email: emailController.text,
  diskon: diskonController.text,
  idCabang: idCabang, // ← dari SharedPreferences
);

    updateCustomer(updatedCustomer);  // Update data ke server
    Navigator.of(context).pop();
  },
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.indigo,
    foregroundColor: Colors.white,
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

Future<void> updateCustomer(Customer customer) async {
  final url = Uri.parse('https://hayami.id/pos/edit_customer.php');

  // Siapkan data untuk dikirim
  final Map<String, String> data = {
    'id_customer': customer.kode,
    'nama_customer': customer.nama,
    'kota': customer.kota,
    'alamat_lengkap': customer.alamat,
    'no_telp': customer.telp,
    'email': customer.email,
    'diskon_lusin': customer.diskon,
  };

  try {
    final response = await http.post(url, body: data);

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);

      if (responseData['status'] == 'success') {
        // Jika update berhasil
        ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Customer berhasil diperbarui')),
);

// Update data lokal agar langsung terlihat perubahan di UI
setState(() {
  int index = allCustomers.indexWhere((c) => c.kode == customer.kode);
  if (index != -1) {
    allCustomers[index] = customer;
    filteredCustomers = List.from(allCustomers);
  }
});

      } else {
        // Jika gagal update
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['message'])),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghubungi server')),
      );
    }
  } catch (e) {
    print('Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Terjadi kesalahan saat mengupdate data')),
    );
  }
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
  onPressed: () async {
    // Konfirmasi hapus dulu (optional tapi disarankan)
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Konfirmasi'),
        content: Text('Yakin ingin menghapus customer ini?'),
        actions: [
          TextButton(
            child: Text('Batal'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text('Hapus'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteCustomer(customer.kode);
    }
  },
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