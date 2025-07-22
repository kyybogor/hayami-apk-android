import 'package:flutter/material.dart';
import 'package:hayami_app/pos/laporan_rekapitulasi.dart';
import 'package:hayami_app/pos/laporan_retur.dart';
import 'package:hayami_app/pos/laporanpembelian.dart';
import 'package:hayami_app/pos/laporanpiutang.dart';
import 'package:hayami_app/pos/stockcard.dart';
import 'package:hayami_app/pos/stockdetail.dart';

class Laporanpos extends StatelessWidget {
  const Laporanpos ({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
    "label": "Laporan Pembelian",
    "icon": Icons.receipt, // Icon for purchase report
    "color": Colors.blue,
    "page": const Laporanpembelian(),
  },
  {
    "label": "Stock Card",
    "icon": Icons.inventory, // Icon for inventory card
    "color": Colors.orange,
    "page": const StockCard(),
  },
  {
    "label": "Stock Detail",
    "icon": Icons.list_alt, // Icon for stock details
    "color": Colors.green,
    "page": const Stockdetail(),
  },
  {
    "label": "Laporan Piutang",
    "icon": Icons.account_balance_wallet, // Icon for receivables
    "color": Colors.purple,
    "page": const RekapHutangPage(),
  },
  {
    "label": "Laporan Retur",
    "icon": Icons.undo, // Icon for returns
    "color": Colors.purple,
    "page": const LaporanRetur(),
  },
  {
    "label": "Rekapitulasi Penjualan",
    "icon": Icons.bar_chart, // Icon for sales recap
    "color": Colors.purple,
    "page": const RekapitulasiPage(),
  }
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.blue),
        title: const Text(
          'Laporan',
          style: TextStyle(color: Colors.blue),
        ),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF5F5F5),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          itemCount: menuItems.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(12),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                leading: CircleAvatar(
                  backgroundColor: item["color"],
                  child: Icon(item["icon"], color: Colors.white),
                ),
                title: Text(
                  item["label"],
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => item["page"]),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
