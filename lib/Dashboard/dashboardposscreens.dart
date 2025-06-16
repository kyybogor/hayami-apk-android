import 'package:flutter/material.dart';
import 'package:hayami_app/Login/loginScreen.dart';
import 'package:hayami_app/pos/posscreen.dart';
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
    {
      'icon': Icons.bar_chart,
      'label': 'Laporan',
      'color': Colors.purple,
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
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          },
        ),
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
                    'Yu  mudahkan keuangan bisnis dengan Hayami',
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: menuItems.map((item) {
                  return InkWell(
                    onTap: () {
                      switch (item['label']) {
                        case 'POS':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const Posscreen(),
                            ),
                          );
                          break;
                        // case 'Laporan':
                        //   Navigator.push(
                        //     context,
                        //     MaterialPageRoute(
                        //       builder: (_) => Laporanperusahaan(),
                        //     ),
                        //   );
                        //   break;
                        default:
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Navigasi ke ${item['label']} belum tersedia'),
                            ),
                          );
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            double screenWidth =
                                MediaQuery.of(context).size.width;
                            double iconSize = screenWidth > 600
                                ? 36 
                                : 26;
                            double containerSize = screenWidth > 600 ? 72 : 48;

                            return Container(
                              width: containerSize,
                              height: containerSize,
                              decoration: BoxDecoration(
                                color: item['color']?.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(item['icon'],
                                  color: item['color'], size: iconSize),
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item['label'],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
