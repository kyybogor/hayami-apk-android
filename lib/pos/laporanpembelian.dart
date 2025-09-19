import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hayami_app/pos/detaillaporanpembelian.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Laporanpembelian extends StatefulWidget {
  const Laporanpembelian({super.key});

  @override
  State<Laporanpembelian> createState() => _LaporanpembelianState();
}

class _LaporanpembelianState extends State<Laporanpembelian> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> invoices = [];
  List<Map<String, dynamic>> filteredInvoices = [];
  bool isLoading = true;

  DateTime? _startDate;
  DateTime? _endDate;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    fetchInvoices();
  }

  Future<void> fetchInvoices() async {
    setState(() {
      isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final rawIdCabang =
        prefs.getString('id_cabang') ?? 'TKB-HAYAMI OFFICIAL-JAKARTA PUSAT';
    final cleanIdCabang = rawIdCabang.replaceAll('\u00A0', ' ').trim();

    if (cleanIdCabang.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    final url = Uri.https(
      'hayami.id',
      '/pos/masuk.php',
      {'id_cabang': cleanIdCabang},
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> invoicesData = data['data'];

        invoices = invoicesData.where((item) {
          return item['status'] == 's';
        }).map<Map<String, dynamic>>((item) {
          return {
            "id": item["id_transaksi"] ?? '-',
            "name": item["id_supplier"] ?? '-',
            "date": item["tgl_transaksi"] ?? '-',
            "total": item["total"] ?? '0',
            "keterangan": item["keterangan"] ?? '-',
            "qty": item["qty"] ?? '0',
            "uom": item["uom"] ?? '-',
          };
        }).toList();

        invoices.sort((a, b) {
          try {
            final dateA = _dateFormat.parse(a['date']);
            final dateB = _dateFormat.parse(b['date']);
            return dateA.compareTo(dateB);
          } catch (_) {
            return 0;
          }
        });

        _applyFilters();
      } else {
        throw Exception('Gagal mengambil data');
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  void _applyFilters() {
    String keyword = _searchController.text.toLowerCase();

    setState(() {
      filteredInvoices = invoices.where((invoice) {
        final bool matchKeyword =
            invoice["id"].toString().toLowerCase().contains(keyword);

        final bool matchDate = () {
          if (_startDate == null && _endDate == null) return true;

          try {
            final date = _dateFormat.parse(invoice['date']);
            if (_startDate != null && date.isBefore(_startDate!)) return false;
            if (_endDate != null && date.isAfter(_endDate!)) return false;
            return true;
          } catch (_) {
            return true;
          }
        }();

        return matchKeyword && matchDate;
      }).toList();

      isLoading = false;
    });
  }

  void _onSearchChanged() => _applyFilters();

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        _applyFilters();
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
        _applyFilters();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text(
            "Laporan Barang Masuk",
            style: TextStyle(color: Colors.blue),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.blue),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Cari ID Transaksi",
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
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectStartDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(Icons.date_range, color: Colors.blue),
                              Text(
                                _startDate != null
                                    ? _dateFormat.format(_startDate!)
                                    : "Dari Tanggal",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectEndDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.shade100),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Icon(Icons.date_range, color: Colors.blue),
                              Text(
                                _endDate != null
                                    ? _dateFormat.format(_endDate!)
                                    : "Sampai Tanggal",
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final invoice = filteredInvoices[index];
                  return ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(invoice["id"] ?? '-'),
                        Text(invoice["name"] ?? '-',
                            style: const TextStyle(fontSize: 18)),
                        Text(invoice["keterangan"] ?? '-',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        Text("Qty: ${invoice["qty"]} ${invoice["uom"]}",
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black54)),
                      ],
                    ),
                    subtitle: Text(invoice["date"] ?? '-'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Card(
                          color: Colors.green.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            child: Text(
                              "${NumberFormat.currency(symbol: "Rp ").format(double.parse(invoice["total"]))}",
                              style: TextStyle(
                                color: Colors.green[800],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_ios,
                            size: 16, color: Colors.grey),
                      ],
                    ),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              Detaillaporanpembelian(invoice: invoice),
                        ),
                      );
                    },
                  );
                },
                childCount: filteredInvoices.length,
              ),
            ),
            if (!isLoading && filteredInvoices.isEmpty)
              const SliverToBoxAdapter(
                child: Center(
                    child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("Tidak ada data ditemukan"),
                )),
              ),
            if (isLoading)
              const SliverToBoxAdapter(
                child: Center(
                    child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                )),
              ),
          ],
        ),
      ),
    );
  }
}
