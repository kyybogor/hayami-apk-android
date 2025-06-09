import 'package:flutter/material.dart';
import 'package:hayami_app/Dashboard/dashboardscreen.dart';
import 'package:hayami_app/Laporan%20%20Perusahaan/laporanaruskas.dart';
import 'package:hayami_app/Laporan%20%20Perusahaan/laporanhutangpiutang.dart';
import 'package:hayami_app/Laporan%20%20Perusahaan/laporanlabarugi.dart';
import 'package:hayami_app/Laporan%20%20Perusahaan/laporanneracasaldo.dart';
import 'package:hayami_app/Laporan%20%20Perusahaan/laporanperubahanmodal.dart';

class Laporanperusahaan extends StatelessWidget {
  const Laporanperusahaan({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        "label": "Arus Kas",
        "icon": Icons.trending_up,
        "color": Colors.blue,
        "page": const Laporanaruskas(),
      },
      {
        "label": "Neraca Saldo",
        "icon": Icons.account_balance,
        "color": Colors.orange,
        "page": const Laporanneracasaldo(),
      },
      {
        "label": "Laba Rugi",
        "icon": Icons.bar_chart,
        "color": Colors.green,
        "page": const Laporanlabarugi(),
      },
      {
        "label": "Hutang Piutang",
        "icon": Icons.money_off,
        "color": Colors.red,
        "page": const Laporanhutangpiutang(),
      },
      {
        "label": "Perubahan Modal",
        "icon": Icons.swap_horiz,
        "color": Colors.purple,
        "page": const Laporanperubahanmodal(),
      },
    ];

    return Scaffold(
  appBar: AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.black),
    title: const Text(
      'Laporan',
      style: TextStyle(color: Colors.blue),
    ),
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Dashboardscreen()),
      );
    },
    ),
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
