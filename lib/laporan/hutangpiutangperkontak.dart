import 'package:flutter/material.dart';
import 'package:hayami_app/kontak/kontakscreen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class Hutangpiutangperkontak extends StatefulWidget {
  const Hutangpiutangperkontak({super.key});

  @override
  State<Hutangpiutangperkontak> createState() => _HutangpiutangperkontakState();
}

class _HutangpiutangperkontakState extends State<Hutangpiutangperkontak> {
  List<dynamic> allContacts = [];
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchContacts();
  }

  Future<void> fetchContacts() async {
    final response =
        await http.get(Uri.parse("http://192.168.1.10/connect/JSON/kontak.php"));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        allContacts = data;
      });
    }
  }

  Color getAmountColor(num amount) {
    if (amount < 0) {
      return Colors.redAccent;
    } else {
      return const Color.fromARGB(255, 102, 220, 165);
    }
  }

  String formatRupiah(num number) {
    final formatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    return formatter.format(number);
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> filtered = allContacts
        .where((item) =>
            item['nama'].toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        foregroundColor: Colors.blueAccent,
        title: const Text("Hutang Piutang", style: TextStyle(color: Colors.blueAccent, fontSize: 20),),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Cari nama...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) => setState(() => searchQuery = value),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (context, index) => const Divider(
                height: 0.1, // tetap bisa dipakai untuk jarak
                thickness: 0.2, // ini yang mengatur ketebalan garis
                color: Colors.grey,
              ),
              itemBuilder: (context, index) {
                final item = filtered[index];
                final amount = num.tryParse(item['amount'].toString()) ?? 0;

                return ListTile(
                  title: Text(
                    item['nama'],
                    style: const TextStyle(
                      fontSize: 14, // atau 13 jika ingin lebih kecil lagi
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: getAmountColor(amount),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          formatRupiah(amount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  //onTap: () {
                   // Navigator.push(
                      //context,
                      //MaterialPageRoute(
                        //builder: (context) => DetailKontak(data: item),
                      //),
                    //);
                 // },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
