import 'package:flutter/material.dart';
import 'package:hayami_app/Login/loginScreen.dart';
import 'package:hayami_app/Pembelian/pembelianscreen.dart';
import 'package:hayami_app/Pembelian/pemesananpembelian.dart';
import 'package:hayami_app/Pembelian/penawaran_pembelian/penawaranpembelian.dart';
import 'package:hayami_app/Pembelian/pengirimanpembelian.dart';
import 'package:hayami_app/Pembelian/tagihanpembelian.dart';
import 'package:hayami_app/Penjualan/penjualanscreen.dart';
import 'package:hayami_app/akun/akunscreen.dart';
import 'package:hayami_app/assetetap/assetetap.dart';
import 'package:hayami_app/biaya/biayascreen.dart';
import 'package:hayami_app/customer/customer.dart';
import 'package:hayami_app/kas%20&%20bank/kasdanbank.dart';
import 'package:hayami_app/kasbank/kasbank.dart';
import 'package:hayami_app/kontak/kontakscreen.dart';
import 'package:hayami_app/laporan/laporanscreen.dart';
import 'package:hayami_app/laporan/penjualan/penjualanprodukperpelanggan.dart';
import 'package:hayami_app/pemesanan/pemesananscreen.dart';
import 'package:hayami_app/penawaran/penawaranscreen.dart';
import 'package:hayami_app/produk/produk.dart';
import 'package:hayami_app/tagihan/tagihanscreen.dart';
import 'package:hayami_app/pengiriman/pengirimanscreen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Dashboardscreen(),
  ));
}

class KasBankModel {
  final String nama;
  final double nominal;

  KasBankModel({required this.nama, required this.nominal});

  factory KasBankModel.fromJson(Map<String, dynamic> json) {
    return KasBankModel(
      nama: json['nama'],
      nominal: double.tryParse(json['nominal']) ?? 0.0,
    );
  }
}

class Dashboardscreen extends StatefulWidget {
  const Dashboardscreen({super.key});

  @override
  State<Dashboardscreen> createState() => _DashboardscreenState();
}

class _DashboardscreenState extends State<Dashboardscreen> {
  List<KasBankModel> kasList = [];
  bool isKasLoading = true;

  @override
  void initState() {
    super.initState();
    fetchKasFromApi();
  }

  Future<void> fetchKasFromApi() async {
    const String apiUrl =
        "http://hayami.id/apps/erp/api-android/api/kasdanbank.php";
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          kasList = data.map((json) => KasBankModel.fromJson(json)).toList();
          isKasLoading = false;
        });
      } else {
        throw Exception('Failed to load Kas data');
      }
    } catch (e) {
      print('Error fetching kas data: $e');
      setState(() {
        isKasLoading = false;
      });
    }
  }

  String formatCurrency(double amount) {
    return 'Rp ' +
        amount.toStringAsFixed(0).replaceAllMapped(
              RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
              (Match m) => '${m[1]}.',
            );
  }

  String getAbbreviation(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return words.take(2).map((e) => e[0]).join().toUpperCase();
    } else {
      return name.substring(0, 1).toUpperCase();
    }
  }

  final List<Map<String, dynamic>> menuItems = [
    {
      'icon': Icons.shopping_bag,
      'label': 'Penjualan',
      'color': Colors.redAccent
    },
    {
      'icon': Icons.shopping_cart,
      'label': 'Pembelian',
      'color': Colors.blueAccent
    },
    {'icon': Icons.money_off, 'label': 'Biaya', 'color': Colors.orangeAccent},
    {'icon': Icons.inventory, 'label': 'Produk', 'color': Colors.green},
    {'icon': Icons.bar_chart, 'label': 'Laporan', 'color': Colors.purple},
    {
      'icon': Icons.account_balance,
      'label': 'Kas & Bank',
      'color': Colors.teal
    },
    {'icon': Icons.domain, 'label': 'Aset Tetap', 'color': Colors.indigo},
    {'icon': Icons.contacts, 'label': 'Kontak', 'color': Colors.brown},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: Image.asset(
          'assets/image/hayamilogo.png',
          height: 48,
          fit: BoxFit.contain,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Icon(Icons.notifications_none, color: Colors.white),
          )
        ],
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
      drawer: const KledoDrawer(),
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
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hi pengguna!',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  SizedBox(height: 6),
                  Text('Yuk mudahkan keuangan bisnis dengan Hayami',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
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
                      offset: const Offset(0, 4)),
                ],
              ),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: menuItems.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 9,
                  crossAxisSpacing: 9,
                ),
                itemBuilder: (context, index) {
                  var item = menuItems[index];
                  return InkWell(
                    onTap: () {
                      switch (item['label']) {
                        case 'Penjualan':
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const Penjualanscreen()));
                          break;
                        case 'Pembelian':
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const Pembelianscreen()));
                          break;
                        case 'Biaya':
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const BiayaPage()));
                          break;
                        case 'Produk':
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => ProdukPage()));
                          break;
                        case 'Laporan':
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => LaporanPage()));
                          break;
                        case 'Kas & Bank':
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const KasDanBank()));
                          break;
                        case 'Aset Tetap':
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AssetPage()));
                          break;
                        case 'Kontak':
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const KontakScreen()));
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
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: item['color']?.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(item['icon'],
                              color: item['color'], size: 26),
                        ),
                        const SizedBox(height: 6),
                        Text(item['label'],
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w500),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),

            // SISA ISI TETAP (Kas & Bank, Performa Bisnis, Button)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Kas & Bank',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: isKasLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: kasList.map((kas) {
                            return Row(
                              children: [
                                _buildKasCard(
                                  label: kas.nama,
                                  amount: formatCurrency(kas.nominal),
                                  color: Colors.blue[100]!,
                                  abbreviation: getAbbreviation(kas.nama),
                                ),
                                const SizedBox(width: 12),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildKasCard({
    required String label,
    required String amount,
    required Color color,
    required String abbreviation,
  }) {
    return Container(
      width: 180,
      height: 80,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                abbreviation,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(amount,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class KledoDrawer extends StatefulWidget {
  const KledoDrawer({super.key});

  @override
  State<KledoDrawer> createState() => _KledoDrawerState();
}

class _KledoDrawerState extends State<KledoDrawer> {
  int? selectedIndex;
  String? selectedSubItem;

  final menuItems = const [
    {'icon': Icons.house, 'title': 'Beranda'},
    {
      'icon': Icons.shopping_bag,
      'title': 'Penjualan',
      'children': [
        'Overview Penjualan',
        'Tagihan',
        'Pengiriman',
        'Pemesanan',
        'Penawaran'
      ]
    },
    {
      'icon': Icons.shopping_cart,
      'title': 'Pembelian',
      'children': [
        'Overview Pembelian',
        'Tagihan Pembelian',
        'Pengiriman Pembelian',
        'Pemesanan Pembelian',
        'Penawaran Pembelian'
      ]
    },
    {'icon': Icons.money_off, 'title': 'Biaya'},
    {'icon': Icons.inventory_2, 'title': 'Produk'},
    {'icon': Icons.local_shipping, 'title': 'Inventori'},
    {'icon': Icons.bar_chart, 'title': 'Laporan'},
    {'icon': Icons.account_balance, 'title': 'Kas & Bank'},
    {'icon': Icons.person, 'title': 'Akun'},
    {'icon': Icons.domain, 'title': 'Aset Tetap'},
    {'icon': Icons.contacts, 'title': 'Kontak'},
    {'icon': Icons.settings, 'title': 'Pengaturan'},
    {'icon': Icons.help_outline, 'title': 'FAQ'},
    {'icon': Icons.exit_to_app, 'title': 'Keluar'},
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1E3C72),
              Color.fromARGB(255, 33, 83, 167),
              Color(0xFF2A5298), // Menahan warna akhir biar flat di bawah
            ],
            stops: [0.2, 0.6, 0.5], // Stop gradasi di tengah
            begin: Alignment.topLeft,

            end: Alignment.bottomRight,
          ),
        ),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.transparent),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Hayami',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text('User',
                          style: TextStyle(color: Colors.white, fontSize: 16)),
                      Text('Your Instation',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 14)),
                    ],
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
            ),
            ...menuItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = selectedIndex == index;

              if (item.containsKey('children')) {
                return Theme(
                  data: Theme.of(context)
                      .copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    collapsedIconColor: Colors.white,
                    iconColor: Colors.white,
                    leading:
                        Icon(item['icon'] as IconData, color: Colors.white),
                    title: Text(item['title'] as String,
                        style: const TextStyle(color: Colors.white)),
                    children: (item['children'] as List<String>).map((subItem) {
                      final isSubSelected =
                          selectedIndex == index && selectedSubItem == subItem;
                      return Container(
                        color:
                            isSubSelected ? Colors.white24 : Colors.transparent,
                        child: ListTile(
                            contentPadding:
                                const EdgeInsets.only(left: 72, right: 16),
                            title: Text(subItem,
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: isSubSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal)),
                            onTap: () {
                              setState(() {
                                selectedIndex = index;
                                selectedSubItem = subItem;
                              });
                              Navigator.pop(context);

                              Widget? destination;

                              switch (subItem) {
                                case 'Overview Penjualan':
                                  destination =
                                      const Penjualanscreen(); // ganti sesuai nama halamanmu
                                  break;
                                case 'Tagihan':
                                  destination = const TagihanPage();
                                  break;
                                case 'Pengiriman':
                                  destination = const PengirimanPage();
                                  break;
                                case 'Pemesanan':
                                  destination = const PemesananPage();
                                  break;
                                case 'Penawaran':
                                  destination = const PenawaranPage();
                                  break;
                                case 'Pesanan Pembelian':
                                  //destination = const PesananPembelianPage();
                                  break;
                                case 'Penawaran Pembelian':
                                  //destination = const PenawaranPembelianPage();
                                  break;
                              }
                              switch (subItem) {
                                case 'Overview Pembelian':
                                  destination = const Pembelianscreen();
                                  break;
                                case 'Tagihan Pembelian':
                                  destination = const TagihanPembelianPage();
                                  break;
                                case 'Pengiriman Pembelian':
                                  destination = const PengirimanPembelianPage();
                                  break;
                                case 'Pemesanan Pembelian':
                                  destination = const PemesananPembelianPage();
                                  break;
                                case 'Penawaran Pembelian':
                                  destination = const PenawaranPembelianPage();
                                  break;
                              }

                              if (destination != null) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => destination!),
                                );
                              }
                            }),
                      );
                    }).toList(),
                  ),
                );
              } else {
                return Column(
                  children: [
                    Container(
                      color: isSelected ? Colors.white24 : Colors.transparent,
                      child: ListTile(
                        leading:
                            Icon(item['icon'] as IconData, color: Colors.white),
                        title: Text(item['title'] as String,
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal)),
                        onTap: () {
                          setState(() {
                            selectedIndex = index;
                            selectedSubItem = null;
                          });
                          Navigator.pop(context);

                          Widget? destination;
                          if (item['title'] == 'Beranda') {
                            destination = const Dashboardscreen();
                          }

                          if (item['title'] == 'Biaya') {
                            destination = const BiayaPage();
                          }

                          if (item['title'] == 'Produk') {
                            destination = ProdukPage();
                          }

                          if (item['title'] == 'Kas & Bank') {
                            destination = KasDanBank();
                          }

                          if (item['title'] == 'Laporan') {
                            destination = LaporanPage();
                          }

                          if (item['title'] == 'Aset Tetap') {
                            destination = const AssetPage();
                          }

                          if (item['title'] == 'Kontak') {
                            destination = const KontakScreen();
                          }

                          if (item['title'] == 'Akun') {
                            destination = const Akunscreen();
                          }

                          if (item['title'] == 'Keluar') {
                            destination = const LoginPage();
                          }

                          if (destination != null) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => destination!),
                            );
                          }
                        },
                      ),
                    ),
                    if (['Inventori', 'Kontak', 'FAQ', 'Keluar']
                        .contains(item['title']))
                      const Divider(
                          color: Colors.white54, indent: 16, endIndent: 16),
                  ],
                );
              }
            }).toList(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  // WhatsApp action
                },
                icon: const FaIcon(FontAwesomeIcons.whatsapp),
                label: const Text('Halo, ada yang bisa saya bantu?'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 40),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
