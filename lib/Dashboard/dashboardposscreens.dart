import 'package:flutter/material.dart';
import 'package:hayami_app/Login/loginScreen.dart';
import 'package:hayami_app/pos/barangmasuk.dart';
import 'package:hayami_app/pos/penjualanharian.dart';
import 'package:hayami_app/pos/pettycash.dart';
import 'package:hayami_app/pos/returbarang.dart';
import 'package:hayami_app/pos/opname.dart';
import 'package:hayami_app/pos/master_customer.dart';
import 'package:hayami_app/pos/master_akun.dart';
import 'package:hayami_app/pos/laporanpos.dart';
import 'package:hayami_app/pos/menu.dart';
import 'package:hayami_app/pos/posscreen.dart';
import 'package:hayami_app/webview/webview.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DashboardScreenPos extends StatefulWidget {
  const DashboardScreenPos({super.key});

  @override
  State<DashboardScreenPos> createState() => _DashboardScreenPosState();
}

class _DashboardScreenPosState extends State<DashboardScreenPos> {
  String nmUser = '';

  @override
  void initState() {
    super.initState();
    loadUserName();
  }

  Future<bool?> showLogoutConfirmation() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah anda yakin ingin keluar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Tidak'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );
  }

  Future<void> loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nmUser = prefs.getString('nm_user') ?? 'pengguna';
    });
  }

  final List<Map<String, dynamic>> menuItems = [
    {
      'icon': Icons.point_of_sale,
      'label': 'POS',
      'color': Colors.deepPurple,
    },
    // {
    //   'icon': Icons.bar_chart,
    //   'label': 'Menu',
    //   'color': Colors.purple,
    // },
    {
      'icon': Icons.assignment,
      'label': 'Laporan',
      'color': Colors.blue,
    },
    {
      'icon': Icons.inventory,
      'label': 'Barang Masuk',
      'color': Colors.blue,
    },
    {
      'icon': Icons.shopping_cart,
      'label': 'List Penjualan',
      'color': Colors.orange,
    },
    {
      'icon': Icons.assignment,
      'label': 'Opname',
      'color': Colors.green,
    },
    {
      'icon': Icons.restore_from_trash,
      'label': 'Retur Barang',
      'color': Colors.purple,
    },
    {
      'icon': Icons.attach_money,
      'label': 'Petty Cash',
      'color': Colors.green,
    },
    {
      'icon': Icons.people,
      'label': 'Master Customer',
      'color': Colors.blue,
    },
    {
      'icon': Icons.account_circle,
      'label': 'Master Akun',
      'color': Colors.blue,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () async {
              final confirm = await showLogoutConfirmation();
              if (confirm == true) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                // Gunakan PageRouteBuilder untuk menambahkan efek geser
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const LoginPage(), // Halaman yang dituju
                    transitionsBuilder:
                        (context, animation, secondaryAnimation, child) {
                      const begin = Offset(1.0, 0.0); // Geser dari kanan
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;

                      var tween = Tween(begin: begin, end: end)
                          .chain(CurveTween(curve: curve));
                      var offsetAnimation = animation.drive(tween);

                      return SlideTransition(
                          position: offsetAnimation, child: child);
                    },
                    transitionDuration: const Duration(milliseconds: 800),
                  ),
                );
              }
            }),
        title: Image.asset(
          'assets/image/hayamilogo.png',
          height: 48,
          fit: BoxFit.contain,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi $nmUser!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Yuk, mudahkan keuangan bisnis dengan Hayami',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // tetap 3 kolom
                  crossAxisSpacing: 2, // jarak horizontal lebih kecil
                  mainAxisSpacing: 2, // jarak vertikal lebih kecil
                  childAspectRatio: 3, // biar lebih kotak & padat
                ),
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  final item = menuItems[index];
                  return InkWell(
                    onTap: () {
                      switch (item['label']) {
                        case 'POS':
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const Posscreen()));
                          break;
                        case 'Laporan':
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const Laporanpos()));
                          break;
                        case 'Barang Masuk':
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const Barangmasuk()));
                          break;
                        case 'List Penjualan':
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const Penjualanharian()));
                          break;
                        case 'Opname':
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => Opname()));
                          break;
                        case 'Retur Barang':
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const Returbarang()));
                          break;
                        case 'Petty Cash':
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const Pettycash()));
                          break;
                        case 'Master Customer':
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => CustomerPage()));
                          break;
                        case 'Master Akun':
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => AkunPage()));
                          break;
                        default:
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Navigasi ke ${item['label']} belum tersedia')),
                          );
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: item['color'].withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item['icon'],
                              color: item['color'], size: 40),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['label'],
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
