import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class EditBankScreen extends StatefulWidget {
  final Map<String, dynamic> bankData;

  const EditBankScreen({super.key, required this.bankData});

  @override
  State<EditBankScreen> createState() => _EditBankScreenState();
}

class _EditBankScreenState extends State<EditBankScreen> {
  late TextEditingController _dateController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  bool isTerimaDana = true;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.bankData["date"]);
    _amountController =
        TextEditingController(text: widget.bankData["amount"].toString());
    _descriptionController =
        TextEditingController(text: widget.bankData["title"]);
    isTerimaDana =
        (widget.bankData["subtitle"]?.toLowerCase() ?? "") == "terima dana";
  }

  @override
  void dispose() {
    _dateController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String cleanAmount(String input) {
    return input.replaceAll(RegExp(r'[^0-9.]'), '');
  }

  void saveChanges() async {
    if (_dateController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Semua field harus diisi')),
      );
      return;
    }

    final uri =
        Uri.parse('http://hayami.id/apps/erp/api-android/api/transaksi_bank.php');

    print('Data yang dikirim:');
    print({
      'id': widget.bankData['id'].toString(),
      'date': _dateController.text,
      'amount': cleanAmount(_amountController.text),
      'title': _descriptionController.text,
      'subtitle': isTerimaDana ? 'Terima Dana' : 'Kirim Dana',
      'action': 'update',
    });

    final response = await http.post(uri, body: {
      'id': widget.bankData['id'].toString(),
      'date': _dateController.text,
      'amount': cleanAmount(_amountController.text),
      'title': _descriptionController.text,
      'subtitle': isTerimaDana ? 'Terima Dana' : 'Kirim Dana',
      'action': 'update',
    });

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final jsonRes = jsonDecode(response.body);
      if (jsonRes['success'] == true) {
        // Perbarui widget.bankData dengan data yang baru setelah update berhasil
        setState(() {
          widget.bankData['date'] = _dateController.text;
          widget.bankData['amount'] = cleanAmount(_amountController.text);
          widget.bankData['title'] = _descriptionController.text;
          widget.bankData['subtitle'] =
              isTerimaDana ? 'Terima Dana' : 'Kirim Dana';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perubahan berhasil disimpan.')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Gagal menyimpan: ${jsonRes['message'] ?? 'Unknown error'}')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server error: ${response.statusCode}')),
      );
    }
  }

  Future<void> pickDate() async {
    List<String> parts = _dateController.text.split('/');
    DateTime initialDate;
    try {
      initialDate = DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      initialDate = DateTime.now();
    }

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      final formatted =
          "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      _dateController.text = formatted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.blue),
        title: Center(
          child: const Text(
            "Edit Bank Statement",
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.normal, // Remove the bold effect
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text("Tanggal"),
                  subtitle: GestureDetector(
                    onTap: pickDate,
                    child: AbsorbPointer(
                      child: TextField(
                        controller: _dateController,
                        decoration: const InputDecoration.collapsed(
                            hintText: "Pilih Tanggal"),
                      ),
                    ),
                  ),
                ),
                const Divider(),
                const Text("Tipe Penyesuaian",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text("Kirim Dana"),
                        value: false,
                        groupValue: isTerimaDana,
                        onChanged: (value) =>
                            setState(() => isTerimaDana = value ?? false),
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text("Terima Dana"),
                        value: true,
                        groupValue: isTerimaDana,
                        onChanged: (value) =>
                            setState(() => isTerimaDana = value ?? true),
                      ),
                    ),
                  ],
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.attach_money),
                  title: const Text("Total"),
                  subtitle: TextField(
                    controller: _amountController,
                    decoration: const InputDecoration.collapsed(
                        hintText: "Jumlah Uang"),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.chat_outlined),
                  title: const Text("Deskripsi"),
                  subtitle: TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration.collapsed(
                        hintText: "Masukkan Deskripsi"),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.blue),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Batal",
                            style: TextStyle(color: Colors.blue)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text("Simpan",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
