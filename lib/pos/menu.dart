import 'package:flutter/material.dart';
import 'package:hayami_app/pos/barangmasuk.dart';
import 'package:hayami_app/pos/opname.dart';
import 'package:hayami_app/pos/penjualanharian.dart';
import 'package:hayami_app/pos/returbarang.dart';

class Menu extends StatelessWidget {
  const Menu ({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        "label": "Barang Masuk",
        "icon": Icons.inventory, // Better icon for stock/inventory
        "color": Colors.blue,
        "page": const Barangmasuk(),
      },
      {
        "label": "List Penjualan",
        "icon": Icons.shopping_cart, // Better icon for sales list
        "color": Colors.orange,
        "page": const Penjualanharian(),
      },
      {
        "label": "Opname",
        "icon": Icons.assignment, // Better icon for stock check/stocktaking
        "color": Colors.green,
        "page": Opname(),
      },
      {
        "label": "Retur Barang",
        "icon": Icons.restore_from_trash, // Icon for return or undo
        "color": Colors.purple,
        "page": const Returbarang(),
      }
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.blue),
        title: const Text(
          'Menu',
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
