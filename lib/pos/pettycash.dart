import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;

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
    final url = Uri.parse(
        'https://hayami.id//pos/petty_cash.php?start=$start&end=$end');

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
          'id_petty': item['id_petty'], 
          'tgl': item['tgl'],
          'keterangan': item['keterangan'],
          'in': inCash,
          'out': outCash,
          'saldo': currentSaldo,
          'bukti_petty':
              item['bukti_petty'], // jika kamu ingin menampilkan bukti
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
    XFile? pickedFile;

    File? pickedImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text("Petty Cash"),
              content: Container(
                width: 500,
                height: 600,
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dropdown Tipe
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
  decoration: const InputDecoration(
    labelText: "Tipe",
    border: OutlineInputBorder(), // Border kotak untuk dropdown
  ),
),
                      const SizedBox(height: 12),

                      // Tanggal
                      TextFormField(
  readOnly: true,
  decoration: InputDecoration(
    labelText: "Tanggal",
    filled: true,
    fillColor: Colors.grey.shade300,
    border: OutlineInputBorder(), // Border kotak untuk tanggal
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

                      // Upload Gambar
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? pickedImageFile = await picker
                                  .pickImage(source: ImageSource.gallery);
                              if (pickedImageFile != null) {
                                setState(() {
                                  pickedImage = File(
                                      pickedImageFile.path); // Simpan gambar
                                });
                              }
                            },
                            child: const Text("Choose File"),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pickedImage == null
                                  ? "No file chosen"
                                  : pickedImage!.path.split('/').last,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Preview Gambar + Tombol Hapus Icon
                      if (pickedImage != null)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade200,
                          ),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  pickedImage!,
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                pickedImage!.path.split('/').last,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              // Icon Hapus
                              // Diubah: Tombol hapus di kanan
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      pickedImage = null;
                                    });
                                  },
                                  icon: const Icon(Icons.delete_forever,
                                      size: 32),
                                  color: Colors.redAccent,
                                  tooltip: "Hapus Gambar",
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
  decoration: const InputDecoration(
    labelText: "Jumlah",
    border: OutlineInputBorder(), // Border kotak untuk jumlah
  ),
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
                  onPressed: () async {
                    if (keteranganController.text.isEmpty ||
                        jumlahController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                "Kolom keterangan dan jumlah wajib diisi")),
                      );
                      return;
                    }

                    Navigator.pop(context);

                    await _submitData(
                      tipe: selectedType,
                      keterangan: keteranganController.text,
                      jumlah: jumlahController.text,
                      imageFile: pickedImage,
                    );
                  },
                  child: const Text("Simpan",
                      style: TextStyle(color: Colors.white)),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void showEditDialog(Map<String, dynamic> data) {
    String selectedType = data['in'] > 0 ? 'In Cash' : 'Out Cash';
    TextEditingController keteranganController =
        TextEditingController(text: data['keterangan']);
    TextEditingController jumlahController = TextEditingController(
        text: (data['in'] > 0 ? data['in'] : data['out']).toString());
    DateTime selectedDate = DateTime.parse(data['tgl']);
    File? pickedImage;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text("Ubah Petty Cash"),
              content: Container(
                width: 500,
                height: 600,
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dropdown Tipe
                     DropdownButtonFormField<String>(
  value: selectedType,
  items: ['In Cash', 'Out Cash']
      .map((e) => DropdownMenuItem(
            value: e,
            child: Text(e),
          ))
      .toList(),
  onChanged: (value) {
    if (value != null) {
      setState(() {
        selectedType = value;
      });
    }
  },
  decoration: const InputDecoration(
    labelText: "Tipe",
    border: OutlineInputBorder(), // Kotak untuk dropdown
  ),
),
                      const SizedBox(height: 12),

                      TextFormField(
  enabled: false, // Menonaktifkan editing
  decoration: InputDecoration(
    labelText: "Tanggal",
    filled: true,
    fillColor: Colors.grey.shade300,
    border: OutlineInputBorder(), // Kotak untuk tanggal
  ),
  initialValue: DateFormat('dd/MM/yyyy').format(selectedDate),
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

                      // Bukti sebelumnya
                      if (data['bukti_petty'] != null &&
                          data['bukti_petty'].toString().isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Bukti Sebelumnya:"),
                            const SizedBox(height: 5),
                            Image.network(
                              'https://hayami.id//pos/${data['bukti_petty']}',
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),

                      // Upload Gambar Baru
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () async {
                              final ImagePicker picker = ImagePicker();
                              final XFile? pickedFile = await picker.pickImage(
                                  source: ImageSource.gallery);
                              if (pickedFile != null) {
                                setState(() {
                                  pickedImage = File(pickedFile.path);
                                });
                              }
                            },
                            child: const Text("Choose File"),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              pickedImage == null
                                  ? "No file chosen"
                                  : pickedImage!.path.split('/').last,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                      // Preview Gambar Baru
                      if (pickedImage != null)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.grey.shade200,
                          ),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  pickedImage!,
                                  height: 120,
                                  width: 120,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                pickedImage!.path.split('/').last,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      pickedImage = null;
                                    });
                                  },
                                  icon: const Icon(Icons.delete_forever,
                                      size: 32),
                                  color: Colors.redAccent,
                                  tooltip: "Hapus Gambar",
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
  decoration: const InputDecoration(
    labelText: "Jumlah",
    border: OutlineInputBorder(), // Kotak untuk jumlah
  ),
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
                  onPressed: () async {
                    if (keteranganController.text.isEmpty ||
                        jumlahController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                "Kolom keterangan dan jumlah wajib diisi")),
                      );
                      return;
                    }

                    Navigator.pop(context);

                    await _submitEditData(
                      idPetty: data['id_petty'],
                      tipe: selectedType,
                      keterangan: keteranganController.text,
                      jumlah: jumlahController.text,
                      tanggal: selectedDate,
                      imageFile: pickedImage,
                    );
                  },
                  child: const Text("Simpan",
                      style: TextStyle(color: Colors.white)),
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.indigo),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitEditData({
    required String idPetty,
    required String tipe,
    required String keterangan,
    required String jumlah,
    required DateTime tanggal,
    File? imageFile,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idUser = prefs.getString('id_user');

    var uri = Uri.parse("https://hayami.id//pos/edit_petty.php");
    var request = http.MultipartRequest("POST", uri);

    request.fields['id_petty'] = idPetty;
    request.fields['tipe'] = tipe == 'In Cash' ? 'in_cash' : 'out_cash';
    request.fields['keterangan'] = keterangan;
    request.fields['jumlah'] = jumlah;
    request.fields['tgl'] = DateFormat('yyyy-MM-dd').format(tanggal);
    request.fields['id_user'] = idUser ?? '';

    if (imageFile != null) {
      request.files.add(
          await http.MultipartFile.fromPath('bukti_petty', imageFile.path));
    }

    final response = await request.send();
    final res = await http.Response.fromStream(response);

    if (response.statusCode == 200) {
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Berhasil disimpan")));
        fetchData(); // refresh tabel
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Gagal: ${data['message']}")));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Terjadi kesalahan koneksi.")));
    }
  }

  Future<void> _submitData({
    required String tipe,
    required String keterangan,
    required String jumlah,
    File? imageFile,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idUser = prefs.getString('id_user');
    String? idCabang = prefs.getString('id_cabang');

    if (idUser == null || idCabang == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User belum login")),
      );
      return;
    }

    var uri = Uri.parse("https://hayami.id//pos/tambah_petty.php");
    var request = http.MultipartRequest("POST", uri);

    request.fields['tipe'] = tipe == 'In Cash' ? 'in_cash' : 'out_cash';
    request.fields['keterangan'] = keterangan;
    request.fields['jumlah'] = jumlah;
    request.fields['id_user'] = idUser;
    request.fields['id_cabang'] = idCabang;

    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('bukti_petty', imageFile.path),
      );
    }

    var response = await request.send();

    if (response.statusCode == 200) {
      final res = await http.Response.fromStream(response);
      final json = jsonDecode(res.body);
      if (json['status'] == 'success') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Data berhasil disimpan.")),
        );
        fetchData(); // Refresh data
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal: ${json['message']}")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Terjadi kesalahan saat mengirim data.")),
      );
    }
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

Future<void> exportToExcel() async {
  var status = await Permission.storage.request();
  if (!status.isGranted) return;

  final workbook = xlsio.Workbook();
  final sheet = workbook.worksheets[0];
  sheet.name = 'Petty Cash';

  final headers = [
    'ID',
    'Tanggal',
    'Keterangan',
    'Uang Masuk',
    'Uang Keluar',
    'Saldo',
  ];

  // Style border semua sisi
  void applyFullBorder(xlsio.Range cell) {
    final style = cell.cellStyle;
    style.borders.top.lineStyle = xlsio.LineStyle.thin;
    style.borders.bottom.lineStyle = xlsio.LineStyle.thin;
    style.borders.left.lineStyle = xlsio.LineStyle.thin;
    style.borders.right.lineStyle = xlsio.LineStyle.thin;
  }

  // Tulis header dengan bold dan border
  for (int col = 0; col < headers.length; col++) {
    final cell = sheet.getRangeByIndex(1, col + 1);
    cell.setText(headers[col]);
    cell.cellStyle.bold = true;
    applyFullBorder(cell);
  }

  // Tulis data dengan border
  for (int row = 0; row < pettyData.length; row++) {
    final item = pettyData[row];
    final values = [
      item['id_petty'].toString(),
      item['tgl'],
      item['keterangan'],
      item['in'].toString(),
      item['out'].toString(),
      item['saldo'].toString(),
    ];

    for (int col = 0; col < values.length; col++) {
      final cell = sheet.getRangeByIndex(row + 2, col + 1);
      cell.setText(values[col]);
      applyFullBorder(cell);
    }
  }

  // Set kolom agar cukup lebar (manual)
  for (int col = 1; col <= headers.length; col++) {
    sheet.getRangeByIndex(1, col).columnWidth = 25; // Ubah angka kalau perlu
  }

  // Simpan ke file
  final bytes = workbook.saveAsStream();
  workbook.dispose();

  final directory = await getExternalStorageDirectory();
  final filePath = '${directory!.path}/petty_cash_export.xlsx';
  final file = File(filePath)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes);

  // Notifikasi sukses
  ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Excel berhasil disimpan di: $filePath'),
    duration: Duration(seconds: 4),
  ),
);
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
          icon: const Icon(Icons.arrow_back,
              color: Colors.blue), // Warna ikon biru
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
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          margin: const EdgeInsets.only(top: 4, right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                              DateFormat('dd/MM/yyyy').format(dariTanggal)),
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
                          padding: const EdgeInsets.symmetric(
                              vertical: 8, horizontal: 12),
                          margin: const EdgeInsets.only(top: 4, right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                              DateFormat('dd/MM/yyyy').format(sampaiTanggal)),
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
                    backgroundColor: Colors
                        .indigo.shade200, // Set the background color to indigo
                    foregroundColor:
                        Colors.white, // Set the text color to white
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
  onPressed: () async {
    await exportToExcel(); // Fungsi untuk export
  },
  child: const Text("Print Excel", style: TextStyle(color: Colors.white)),
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.green,
    foregroundColor: Colors.white,
  ),
),

              ],
            ),
            const SizedBox(height: 20),

            // Saldo Awal
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                width: MediaQuery.of(context).size.width *
                    0.5, // Setengah lebar layar
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
                        border: TableBorder.all(
                            color: Colors.grey.shade300, width: 1),
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
                            decoration:
                                const BoxDecoration(color: Colors.indigo),
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
                                tableCell(DateFormat('dd/MM/yyyy')
                                    .format(DateTime.parse(row['tgl']))),
                                tableCell(row['keterangan'] ?? ""),
                                tableCell(currencyFormat.format(row['in'])),
                                tableCell(
                                    "(${currencyFormat.format(row['out'])})"),
                                tableCell(currencyFormat.format(row['saldo'])),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Center(
                                    child: ElevatedButton(
                                      onPressed: () => showEditDialog(
                                          row), // ← kirim seluruh data, termasuk id_petty
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo.shade200,
                                      ),
                                      child: const Text("Ubah",
                                          style:
                                              TextStyle(color: Colors.white)),
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
