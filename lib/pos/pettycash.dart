import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';


class Pettycash extends StatefulWidget {
  const Pettycash({super.key});

  @override
  State<Pettycash> createState() => _PettycashState();
}

class _PettycashState extends State<Pettycash> {
  DateTime dariTanggal = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime sampaiTanggal = DateTime.now();
  final currencyFormat = NumberFormat("#,##0.00", "id_ID");

  double saldoAwal = 0;
  List<Map<String, dynamic>> pettyData = [];

  Future<void> fetchData() async {
    String start = DateFormat('yyyy-MM-dd').format(dariTanggal);
    String end = DateFormat('yyyy-MM-dd').format(sampaiTanggal);
    final url = Uri.parse('http://192.168.1.25/pos/petty_cash.php?start=$start&end=$end');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      List<dynamic> data = json['data'];
      double initial = json['saldo_awal'].toDouble();

      double currentSaldo = initial;
      List<Map<String, dynamic>> result = [];

      for (var item in data) {
        double inCash = double.tryParse(item['in_cash']) ?? 0;
        double outCash = double.tryParse(item['out_cash']) ?? 0;

        currentSaldo += inCash - outCash;

        result.add({
          'tgl': item['tgl'],
          'keterangan': item['keterangan'],
          'in': inCash,
          'out': outCash,
          'saldo': currentSaldo,
        });
      }

      setState(() {
        pettyData = result;
        saldoAwal = initial;
      });
    }
  }

  void _requestPermission() async {
  var status = await Permission.photos.request();
  if (status.isGranted) {
    print("Permission granted");
  } else {
    print("Permission denied");
  }
}

void showAddNewDialog() {
  String selectedType = 'In Cash';
  TextEditingController keteranganController = TextEditingController();
  TextEditingController jumlahController = TextEditingController();
  DateTime today = DateTime.now();
  File? pickedImage; // Inisialisasi gambar yang dipilih

  // Pastikan dialog ini ada di dalam StatefulWidget yang memanggil setState
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Petty Cash"),
        content: Container(
          width: 500, // Lebar dialog
          height: 600, // Tinggi dialog
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tipe Dropdown
                DropdownButtonFormField<String>(
                  value: selectedType,
                  items: ['In Cash', 'Out Cash']
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) selectedType = value;
                  },
                  decoration: const InputDecoration(labelText: "Tipe"),
                ),
                const SizedBox(height: 12),

                // Tanggal (tidak bisa diubah)
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: "Tanggal",
                    filled: true,
                    fillColor: Colors.grey.shade300,
                  ),
                  initialValue: DateFormat('dd/MM/yyyy').format(today),
                ),
                const SizedBox(height: 12),

                // Keterangan
                TextFormField(
                  controller: keteranganController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Keterangan",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                // Bukti Upload
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? pickedImageFile = await picker.pickImage(source: ImageSource.gallery); // Menggunakan pickImage untuk XFile
                        if (pickedImageFile != null) {
                          print("Gambar terpilih: ${pickedImageFile.path}"); // Debugging log
                          setState(() {
                            pickedImage = File(pickedImageFile.path); // Menyimpan gambar yang dipilih
                          });
                        } else {
                          print("Tidak ada gambar yang dipilih"); // Jika tidak ada gambar yang dipilih
                        }
                      },
                      child: const Text("Choose File"),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pickedImage == null
                            ? "No file chosen"
                            : pickedImage!.path.split('/').last, // Menampilkan nama file gambar
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Menampilkan gambar yang dipilih
                if (pickedImage != null)
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    height: 120,
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade400),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            pickedImage!, // Gambar yang dipilih ditampilkan di sini
                            width: double.infinity,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              pickedImage = null; // Menghapus gambar yang sudah dipilih
                            });
                          },
                          child: const Text("Remove"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent, // Mengganti primary dengan backgroundColor
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),

                // Jumlah
                TextFormField(
                  controller: jumlahController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Jumlah"),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              // Simpan data logic di sini
              print("Simpan: $selectedType, ${keteranganController.text}, ${jumlahController.text}");
              Navigator.pop(context);
            },
            child: const Text("Simpan", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
          ),
        ],
      );
    },
  );
}



  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? dariTanggal : sampaiTanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          dariTanggal = picked;
        } else {
          sampaiTanggal = picked;
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Widget tableHeader(String text) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Center(
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        textAlign: TextAlign.center,
      ),
    ),
  );
}

Widget tableCell(String text) {
  return Padding(
    padding: const EdgeInsets.all(8.0),
    child: Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
      ),
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
  title: const Text(
    'Petty Cash',
    style: TextStyle(
      color: Colors.blue, // Warna teks biru
    ),
  ),
  leading: IconButton(
    icon: const Icon(Icons.arrow_back, color: Colors.blue), // Warna ikon biru
    onPressed: () {
      Navigator.pop(context); // Kembali ke halaman sebelumnya
    },
  ),
  backgroundColor: Colors.white, // Warna latar belakang appBar (optional)
),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Filter tanggal
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Dari Tanggal"),
                      InkWell(
                        onTap: () => _pickDate(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          margin: const EdgeInsets.only(top: 4, right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(DateFormat('dd/MM/yyyy').format(dariTanggal)),
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Sampai Tanggal"),
                      InkWell(
                        onTap: () => _pickDate(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                          margin: const EdgeInsets.only(top: 4, right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(DateFormat('dd/MM/yyyy').format(sampaiTanggal)),
                        ),
                      )
                    ],
                  ),
                ),
                ElevatedButton(
  onPressed: showAddNewDialog,
  child: const Text("Add New"),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.indigo,
    foregroundColor: Colors.white,
  ),
),
    const SizedBox(width: 8),
                ElevatedButton(
  onPressed: fetchData,
  child: const Text("Cari"),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.indigo.shade200, // Set the background color to indigo
    foregroundColor: Colors.white, // Set the text color to white
  ),
),
const SizedBox(width: 8),
ElevatedButton(
  onPressed: () {},
  child: const Text("Export Excel", style: TextStyle(color: Colors.white)),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green, // Set the background color to white
    foregroundColor: Colors.white, // Set the text color to green
  ),
),

              ],
            ),
            const SizedBox(height: 20),

            // Saldo Awal
            Align(
  alignment: Alignment.centerLeft,
  child: Container(
    width: MediaQuery.of(context).size.width * 0.5, // Setengah lebar layar
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: Colors.white, // Warna latar belakang putih
      borderRadius: BorderRadius.circular(10), // Sudut melengkung
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade300, // Bayangan ringan
          spreadRadius: 1,
          blurRadius: 5,
          offset: Offset(0, 2), // Bayangan agak ke bawah
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Saldo Awal:",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          "${currencyFormat.format(saldoAwal)}",
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black, // Warna hijau untuk saldo
          ),
        ),
      ],
    ),
  ),
),

            const SizedBox(height: 12),

            // Header Tabel
            // Tabel Petty Cash
Expanded(
  child: pettyData.isEmpty
      ? const Center(child: Text("Tidak ada data"))
      : SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Table(
            border: TableBorder.all(color: Colors.grey.shade300, width: 1),
            columnWidths: const {
              0: FlexColumnWidth(2), // Tgl
              1: FlexColumnWidth(4), // Keterangan
              2: FlexColumnWidth(2), // In
              3: FlexColumnWidth(2), // Out
              4: FlexColumnWidth(2), // Saldo
              5: FlexColumnWidth(2), // Action
            },
            children: [
              // Header row
              TableRow(
                decoration: const BoxDecoration(color: Colors.indigo),
                children: [
                  tableHeader("Tgl"),
                  tableHeader("Keterangan"),
                  tableHeader("In"),
                  tableHeader("Out"),
                  tableHeader("Saldo"),
                  tableHeader("Action"),
                ],
              ),
              // Data rows
              ...pettyData.map((row) {
                return TableRow(
                  children: [
                    tableCell(DateFormat('dd/MM/yyyy').format(DateTime.parse(row['tgl']))),
                    tableCell(row['keterangan'] ?? ""),
                    tableCell(currencyFormat.format(row['in'])),
                    tableCell("(${currencyFormat.format(row['out'])})"),
                    tableCell(currencyFormat.format(row['saldo'])),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Center(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo.shade200,
                          ),
                          child: const Text("Ubah", style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList()
            ],
          ),
        ),
),

          ],
        ),
      ),
    );
  }
}
