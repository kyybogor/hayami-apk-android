import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hayami_app/pos/posscreen.dart';
import 'package:http/http.dart' as http;
import 'package:hayami_app/Dashboard/dashboardscreen.dart';
import 'package:hayami_app/pemesanan/pemesananscreen.dart';
import 'package:hayami_app/tagihan/tagihanscreen.dart';
import 'package:hayami_app/pengiriman/pengirimanscreen.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Penjualanscreen extends StatefulWidget {
  const Penjualanscreen({super.key});

  @override
  State<Penjualanscreen> createState() => _PenjualanscreenState();
}

bool isBulanSelected = true;

String formatRupiah(dynamic amount) {
  try {
    final value = double.tryParse(amount.toString()) ?? 0;
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(value);
  } catch (e) {
    return 'Rp 0';
  }
}

Future<List<Map<String, dynamic>>> fetchStatCards(
    {required bool isMonthly}) async {
  const url = 'http://hayami.id/apps/erp/api-android/api/penjualan_bulan.php';
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final jsonData = json.decode(response.body);
    final selectedData =
        isMonthly ? jsonData['bulan_lalu'] : jsonData['tahun_ini'];
    final subtitleText = isMonthly ? 'Bulan Ini' : 'Tahun Ini';

    return [
      {
        'title': 'Total Penjualan',
        'amount': selectedData['total_penjualan']['total_nilai'],
        'count': selectedData['total_penjualan']['jumlah_data'].toString(),
        'subtitle': subtitleText,
        'growth': ''
      },
      {
        'title': 'Pembayaran Diterima',
        'amount': selectedData['pembayaran_diterima']['total_nilai'],
        'count': selectedData['pembayaran_diterima']['jumlah_data'].toString(),
        'subtitle': subtitleText,
        'growth': ''
      },
      {
        'title': 'Menunggu Pembayaran',
        'amount': selectedData['menunggu_pembayaran']['total_nilai'],
        'count': selectedData['menunggu_pembayaran']['jumlah_data'].toString(),
        'subtitle': subtitleText,
        'growth': ''
      },
      {
        'title': 'Jatuh Tempo',
        'amount': selectedData['jatuh_tempo']['total_nilai'],
        'count': selectedData['jatuh_tempo']['jumlah_data'].toString(),
        'subtitle': subtitleText,
        'growth': ''
      },
    ];
  } else {
    throw Exception('Gagal memuat data');
  }
}

class _PenjualanscreenState extends State<Penjualanscreen> {
  List<bool> isSelected = [true, false];
  int currentPage = 0;
  Future<List<Map<String, dynamic>>>? futureStatCards;

  String idUser = '';
  String jabatanUser = '';

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      idUser = prefs.getString('id_user') ?? 'User';
      jabatanUser = prefs.getString('jabatan') ?? 'Instansi Anda';
    });
  }

  @override
  void initState() {
    super.initState();
    loadUserData();
    futureStatCards = fetchStatCards(isMonthly: isBulanSelected);
  }

  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const KledoDrawer(),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildAppBar(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildIconMenu(),
                const SizedBox(height: 16),
                _buildToggleWaktu(),
                const SizedBox(height: 16),
                _buildStatCards(),
                const SizedBox(height: 25),
                _buildPieChartCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return ClipPath(
      clipper: BottomWaveClipper(),
      child: Container(
        height: 130,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Builder(
                    builder: (context) => Padding(
                      padding: const EdgeInsets.only(top: 28),
                      child: Container(
                        height: 48,
                        width: 48,
                        child: IconButton(
                          icon: const Icon(Icons.menu, color: Colors.white),
                          iconSize: 26,
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 28),
                    child: Text(
                      'Penjualan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MenuIcon(
            icon: Icons.receipt_long,
            color: Colors.redAccent,
            label: 'Tagihan',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TagihanPage()),
              );
            },
          ),
          _MenuIcon(
            icon: Icons.local_shipping,
            color: Colors.lightBlue,
            label: 'Pengiriman',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PengirimanPage()),
              );
            },
          ),
          _MenuIcon(
            icon: Icons.access_time,
            color: Colors.lightGreen,
            label: 'Pemesanan',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PemesananPage()),
              );
            },
          ),
          if (idUser == 'admin')
            _MenuIcon(
              icon: Icons.point_of_sale,
              color: Colors.deepPurple,
              label: 'POS',
              onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const Posscreen()),
              );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildToggleWaktu() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ToggleButtons(
        isSelected: [isBulanSelected, !isBulanSelected],
        onPressed: (int index) {
          setState(() {
            isBulanSelected = index == 0;
            futureStatCards = fetchStatCards(isMonthly: isBulanSelected);
          });
        },
        borderRadius: BorderRadius.circular(8),
        selectedBorderColor: Colors.blue,
        selectedColor: Colors.blue,
        fillColor: Colors.blue.withOpacity(0.1),
        color: Colors.black54,
        constraints: const BoxConstraints(minHeight: 30, minWidth: 85),
        children: const [
          Text('Bulan'),
          Text('Tahun'),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: futureStatCards,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Gagal memuat data: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Tidak ada data'));
        }

        final statsData = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isBulanSelected ? 'Tagihan Bulanan' : 'Tagihan Tahunan',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: statsData.map((data) {
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    width: 200,
                    child: _StatCard(
                      title: data['title'] ?? '-',
                      amount: formatRupiah(data['amount'] ?? '0'),
                      growth: data['growth'] ?? '-',
                      count: data['count'] ?? '0',
                      subtitle: data['subtitle'] ?? '',
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPieChartCard() {
    int totalPages = 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performa Penjualan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 260,
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: PageController(viewportFraction: 1),
                  itemCount: totalPages,
                  onPageChanged: (index) {
                    setState(() {
                      currentPage = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Penjualan Per Produk Bulan Ini',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Icon(Icons.filter_alt_outlined),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (index == 0) ...[
                              _buildToggleProdukKategori(),
                              const SizedBox(height: 12),
                            ],
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Center(
                                    child: Text('Chart Placeholder')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalPages, (index) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: currentPage == index
                          ? Colors.blueAccent
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToggleProdukKategori() {
    return ToggleButtons(
      isSelected: isSelected,
      onPressed: (int index) {
        setState(() {
          for (int i = 0; i < isSelected.length; i++) {
            isSelected[i] = i == index;
          }
        });
      },
      borderRadius: BorderRadius.circular(8),
      selectedBorderColor: Colors.blue,
      selectedColor: Colors.blue,
      fillColor: Colors.blue.withOpacity(0.1),
      color: Colors.black54,
      constraints: const BoxConstraints(minHeight: 23, minWidth: 70),
      children: const [
        Text('Produk'),
        Text('Kategori'),
      ],
    );
  }
}

class _MenuIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  const _MenuIcon({
    required this.icon,
    required this.color,
    required this.label,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title, amount, growth, count, subtitle;

  const _StatCard({
    required this.title,
    required this.amount,
    required this.growth,
    required this.count,
    required this.subtitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(amount,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(growth,
              style: const TextStyle(color: Colors.green, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(subtitle, style: const TextStyle(fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(6)),
                child: Text(count, style: const TextStyle(fontSize: 12)),
              )
            ],
          )
        ],
      ),
    );
  }
}

class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 30);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height - 30);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}