import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class UmurPiutangPage extends StatefulWidget {
  const UmurPiutangPage({super.key});

  @override
  _UmurPiutangPageState createState() => _UmurPiutangPageState();
}

class _UmurPiutangPageState extends State<UmurPiutangPage> {
  List<Map<String, dynamic>> piutangList = [];

  @override
  void initState() {
    super.initState();
    fetchPiutangData();
  }

  Future<void> fetchPiutangData() async {
    final response =
        await http.get(Uri.parse('http://192.168.1.9/Hiyami/jurnal.php'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        piutangList = data.map((item) {
          final dueDate = DateTime.parse(item['due']);
          final currentDate = DateTime.now();
          final isPastDue = dueDate.isBefore(currentDate);

          return {
            'name': item['nama'],
            'total': double.parse(item['amount']),
            'due': item['due'],
            'status':
                isPastDue ? 'Sudah Lewat Jatuh Tempo' : 'Belum Jatuh Tempo',
          };
        }).toList();
      });
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.blueAccent,
        title: const Text('Umur Piutang', style: TextStyle(color: Colors.blueAccent, fontSize: 20),),
        centerTitle: true,
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {},
          ),
        ],
      ),
      body: piutangList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              itemCount: piutangList.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = piutangList[index];
                return ListTile(
                  title: Text(item['name']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item['total'].toStringAsFixed(0).replaceAllMapped(
                                RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                (Match m) => '${m[1]}.',
                              ),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailPiutangPage(
                          name: item['name'],
                          total: item['total'],
                          due: item['due'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: "share",
            onPressed: () {},
            backgroundColor: Colors.lightBlue,
            child: const Icon(Icons.share),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "download",
            onPressed: () {},
            child: const Icon(Icons.download),
          ),
        ],
      ),
    );
  }
}

class DetailPiutangPage extends StatelessWidget {
  final String name;
  final double total;
  final String due;

  const DetailPiutangPage({
    super.key,
    required this.name,
    required this.total,
    required this.due,
  });

  @override
  Widget build(BuildContext context) {
    final dueDate = DateTime.parse(due);
    final now = DateTime.now();
    final diffDays = now.difference(dueDate).inDays;

    Map<String, int> detail = {
      '< 1 Bulan': 0,
      '1 s/d <= 2 bulan': 0,
      '2 s/d <= 3 bulan': 0,
      '3 s/d <= 4 bulan': 0,
      '> 4 bulan': 0,
      'Belum Jatuh Tempo': 0,
    };

    if (dueDate.isAfter(now)) {
      detail['Belum Jatuh Tempo'] = total.toInt();
    } else if (diffDays <= 30) {
      detail['< 1 Bulan'] = total.toInt();
    } else if (diffDays <= 60) {
      detail['1 s/d <= 2 bulan'] = total.toInt();
    } else if (diffDays <= 90) {
      detail['2 s/d <= 3 bulan'] = total.toInt();
    } else if (diffDays <= 120) {
      detail['3 s/d <= 4 bulan'] = total.toInt();
    } else {
      detail['> 4 bulan'] = total.toInt();
    }

    final entries = detail.entries.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: entries.length + 1,
        separatorBuilder: (context, index) => const Divider(
          height: 20,
        ),
        itemBuilder: (context, index) {
          if (index < entries.length) {
            final e = entries[index];
            return Row(
              children: [
                Expanded(
                  child: Text(
                    e.key,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                Text(
                  e.value.toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]}.'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          } else {
            return Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Text(
                  total.toStringAsFixed(0).replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (Match m) => '${m[1]}.'),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            );
          }
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: "share_detail",
            onPressed: () {},
            backgroundColor: Colors.lightBlue,
            child: const Icon(Icons.share),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "download_detail",
            onPressed: () {},
            child: const Icon(Icons.download),
          ),
        ],
      ),
    );
  }
}
