import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hayami_app/pemesanan/detailpesanan.dart';
import 'package:hayami_app/pemesanan/tambahpesanan.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class PemesananPage extends StatefulWidget {
  const PemesananPage({super.key});

  @override
  State<PemesananPage> createState() => _PemesananPageState();
}

class _PemesananPageState extends State<PemesananPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> dataList = [];
  List<Map<String, dynamic>> filteredList = [];
  bool isLoading = true;

  String selectedMonth = DateFormat('MM').format(DateTime.now());
  String selectedYear = DateFormat('yyyy').format(DateTime.now());

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    fetchPemesananData();
  }

Future<void> fetchPemesananData() async {
  setState(() => isLoading = true);

  try {
    final response = await http.get(Uri.parse('http://hayami.id/apps/erp/api-android/api/po1.php'));

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      if (jsonResponse["status"] == "success" && jsonResponse["data"] != null) {
        final List<dynamic> jsonData = jsonResponse["data"];

        dataList = jsonData.map<Map<String, dynamic>>((item) {
          return {
            "id_cust": item["id_cust"] ?? "-",
            "id_po1": item["id_po1"] ?? "-",
            "dibuat_tgl": item["dibuat_tgl"] ?? "-",
            "subtotal": item["subttl"] ?? "0",
            "qty": item["qty"] ?? "0",
            "disc": item["disc"] ?? "-",
            "tierlist": item["tierlist"] ?? "-",
            "payment": item["payment"] ?? "-",
            "top": item["top"].toString(),
            "tgltop": item["tgltop"] ?? "-",
            "site": item["site"] ?? "-",
            "tax": item["tax"] ?? "-",
            "ppn": item["ppn"] ?? "-",
            "disc_persen": item["disc_persen"].toString(),
            "disc_baru": item["disc_baru"] ?? "-",
            "remark": item["remark"] ?? "-",
            "dibuat_oleh": item["dibuat_oleh"] ?? "-",
            "flag": item["flag"] ?? "-",
            "hide": item["hide"].toString(),
            "notif": item["notif"].toString(),
            "id_gudang": item["id_gudang"] ?? "-",
            "items": item["items"] ?? [],
          };
        }).toList();

        filterData();
      } else {
        print("Data kosong atau status bukan success");
      }
    } else {
      print("Failed to load data. Status code: ${response.statusCode}");
    }
  } catch (e) {
    print("Error fetching data: $e");
  }

  setState(() => isLoading = false);
}

  void _onSearchChanged() {
    filterData();
  }

  void filterData() {
    String keyword = _searchController.text.toLowerCase();

    setState(() {
      filteredList = dataList.where((item) {
        final dateStr = item["dibuat_tgl"];
        bool matchMonth = true;
        bool matchYear = true;

        // Handle tanggal "0000-00-00" atau kosong supaya tidak error parsing
        if (dateStr == "0000-00-00" || dateStr.isEmpty || dateStr == "-") {
          matchMonth = true;
          matchYear = true;
        } else {
          try {
            DateTime parsedDate;
            if (dateStr.contains('/')) {
              parsedDate = DateFormat('dd/MM/yyyy').parse(dateStr);
            } else {
              parsedDate = DateFormat('yyyy-MM-dd').parse(dateStr);
            }

            matchMonth = selectedMonth == 'Semua' ||
                selectedMonth == parsedDate.month.toString().padLeft(2, '0');
            matchYear = selectedYear == 'Semua' ||
                selectedYear == parsedDate.year.toString();
          } catch (e) {
            print("Gagal parse tanggal: $dateStr");
            matchMonth = true;
            matchYear = true;
          }
        }

        // Pencarian keyword fleksibel: cari di id_cust dan id_po1
        bool matchKeyword = keyword.isEmpty ||
            item["id_cust"].toString().toLowerCase().contains(keyword) ||
            item["id_po1"].toString().toLowerCase().contains(keyword);

        return matchKeyword && matchMonth && matchYear;
      }).toList();
    });
  }

  String formatRupiah(String value) {
    try {
      final amount = double.parse(value);
      return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(amount);
    } catch (e) {
      return "Rp 0";
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pemesanan", style: TextStyle(color: Colors.blue)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.blue),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Cari",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedMonth,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.calendar_today),
                      labelText: "Bulan",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.blue.shade50,
                    ),
                    items: [
                      'Semua',
                      ...List.generate(12, (index) {
                        final month = (index + 1).toString().padLeft(2, '0');
                        return month;
                      })
                    ].map((month) {
                      return DropdownMenuItem(
                        value: month,
                        child: Text(
                          month == 'Semua'
                              ? 'Semua Bulan'
                              : DateFormat('MMMM').format(DateTime(0, int.parse(month))),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedMonth = value;
                          filterData();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedYear,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.date_range),
                      labelText: "Tahun",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.blue.shade50,
                    ),
                    items: ['Semua', '2023', '2024', '2025'].map((year) {
                      return DropdownMenuItem(
                        value: year,
                        child: Text(year == 'Semua' ? 'Semua Tahun' : year),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedYear = value;
                          filterData();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredList.isEmpty
                    ? const Center(child: Text("Tidak ada data ditemukan"))
                    : ListView.builder(
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final data = filteredList[index];
                          final rawFlag = data['flag']?.toString() ?? '';
String status;
if (rawFlag.toLowerCase() == 'so partially created') {
  status = 'Partially Created';
} else if (rawFlag.isNotEmpty) {
  status = rawFlag;
} else {
  status = 'Pemesanan';
}

                          return Column(
                            children: [
                              ListTile(
  title: Text(data["id_cust"].toString().isEmpty ? "-" : data["id_cust"]),
  subtitle: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(data["id_po1"]),
      Text(data["dibuat_tgl"]),
    ],
  ),
  trailing: Column(
  mainAxisSize: MainAxisSize.min, // ⬅ penting: biar tinggi menyesuaikan isi
  crossAxisAlignment: CrossAxisAlignment.end,
  children: [
    Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        formatRupiah(data["subtotal"]),
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
    const SizedBox(height: 4),
    Flexible( // ⬅ opsional, membantu jika teks terlalu panjang
      child: Text(
        status,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ],
),
  onTap: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetailPemesananPage(invoice: data),
      ),
    );
  },
),

                              const Divider(height: 1),
                            ],
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const Tambahpesanan()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
