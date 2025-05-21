import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class BankDetailPage extends StatefulWidget {
  final Map<String, dynamic> bank;

  BankDetailPage({required this.bank});

  @override
  _BankDetailPageState createState() => _BankDetailPageState();
}

class _BankDetailPageState extends State<BankDetailPage> {
  late Map<String, dynamic> bank;

  @override
  void initState() {
    super.initState();
    bank = widget.bank;
  }

  Future<void> _editBankDialog() async {
    TextEditingController namaBankController =
        TextEditingController(text: bank['nama_bank']);
    TextEditingController noRekeningController =
        TextEditingController(text: bank['no_rekening']);

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Edit Data Bank'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: namaBankController,
                decoration: InputDecoration(labelText: 'Nama Bank'),
              ),
              TextField(
                controller: noRekeningController,
                decoration: InputDecoration(labelText: 'No. Rekening'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final response = await http.post(
                Uri.parse(
                    'http://192.168.1.13/nindo/bank/bank_api.php?action=edit'),
                body: {
                  'id': bank['id'].toString(),
                  'nama_bank': namaBankController.text,
                  'no_rekening': noRekeningController.text,
                },
              );

              if (response.statusCode == 200) {
                setState(() {
                  bank['nama_bank'] = namaBankController.text;
                  bank['no_rekening'] = noRekeningController.text;
                });
                Navigator.pop(context, true);
              } else {
                Navigator.pop(context, false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal update data')),
                );
              }
            },
            child: Text('Simpan'),
          ),
        ],
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data berhasil diupdate')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Detail Bank', style: TextStyle(color: Colors.blue)),
        backgroundColor: Colors.grey[100],
        iconTheme: IconThemeData(color: Colors.blue),
        actions: [
          PopupMenuButton<String>(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'edit') _editBankDialog();
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem(
                  value: 'edit',
                  child: Row(children: [
                    Icon(Icons.edit),
                    SizedBox(width: 10),
                    Text('Edit')
                  ])),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildInfoTile(
                    icon: Icons.account_balance,
                    label: 'Nama Bank',
                    value: bank['nama_bank'] ?? ''),
                _buildInfoTile(
                    icon: Icons.credit_card,
                    label: 'No. Rekening',
                    value: bank['no_rekening'] ?? ''),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.blue[50],
              child: Icon(icon, color: Colors.blue),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: Colors.grey, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(value, style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Divider(),
        SizedBox(height: 16),
      ],
    );
  }
}
