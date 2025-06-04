import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:hayami_app/Dashboard/dashboardscreen.dart';
import 'package:hayami_app/produk/produkdetail.dart';

String cleanImageUrl(String path) {
  if (path.isEmpty) return '';
  if (path.startsWith('http')) return path;
  return 'https://hayami.id/apps/erp/${path.replaceAll('\\', '/')}';
}

class ProdukPage extends StatefulWidget {
  const ProdukPage({super.key});

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  bool _showChart = true;
  List<Map<String, dynamic>> _allProduk = [];
  List<List<Map<String, dynamic>>> _produkGroupedList = [];
  int _loadedGroupCount = 0;
  final int _groupLoadSize = 3;
  bool _isLoading = false;
  bool _hasMore = true;

  int totalProduk = 0;
  int produkHampirHabis = 0;
  int produkHabis = 0;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchProduk();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 150) {
      if (_hasMore && !_isLoading) {
        _loadMoreGroups();
      }
    }
  }

  String FormatRupiah(dynamic amount) {
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

  Future<void> _fetchProduk() async {
    setState(() => _isLoading = true);

    final url = Uri.parse(
        'https://hayami.id/apps/erp/api-android/api/master_produk.php');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['all_product'];

        int tersedia =
            int.tryParse(jsonResponse['product_tersedia'].toString()) ?? 0;
        int sedikit =
            int.tryParse(jsonResponse['product_sedikit'].toString()) ?? 0;
        int habis = int.tryParse(jsonResponse['product_habis'].toString()) ?? 0;

        setState(() {
          _allProduk = List<Map<String, dynamic>>.from(data);
          _produkGroupedList = _groupProduk(_allProduk);
          _loadedGroupCount = (_groupLoadSize < _produkGroupedList.length)
              ? _groupLoadSize
              : _produkGroupedList.length;
          _hasMore = _loadedGroupCount < _produkGroupedList.length;
          _isLoading = false;

          totalProduk = tersedia + sedikit + habis;
          produkHampirHabis = sedikit;
          produkHabis = habis;
        });
      } else {
        setState(() => _isLoading = false);
        print('Gagal load produk');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error: $e');
    }
  }

  List<List<Map<String, dynamic>>> _groupProduk(
      List<Map<String, dynamic>> data) {
    List<List<Map<String, dynamic>>> groups = [];
    for (int i = 0; i < data.length; i += 2) {
      groups.add(data.skip(i).take(2).toList());
    }
    return groups;
  }

  void _loadMoreGroups() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        final nextCount = _loadedGroupCount + _groupLoadSize;
        if (nextCount >= _produkGroupedList.length) {
          _loadedGroupCount = _produkGroupedList.length;
          _hasMore = false;
        } else {
          _loadedGroupCount = nextCount;
        }
        _isLoading = false;
      });
    });
  }

  List<Map<String, dynamic>> _filterProduk(
      List<Map<String, dynamic>> produkList) {
    if (_searchQuery.isEmpty) return produkList;

    return produkList.where((produk) {
      final sku = (produk['sku'] ?? '').toString().toLowerCase();
      final nama = (produk['nama'] ?? '').toString().toLowerCase();
      return sku.contains(_searchQuery) || nama.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    final loadedProduk = _produkGroupedList
        .take(_loadedGroupCount)
        .expand((group) => group)
        .toList();

    final filteredProduk = _filterProduk(loadedProduk);

    return Scaffold(
      drawer: const KledoDrawer(),
      appBar: AppBar(
        title: const Text('Produk', style: TextStyle(color: Colors.blue)),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined),
            onPressed: () {},
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      body: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Cari produk...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 12),

          // Status Cards
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildStatusCard(
                    'Produk Tersedia',
                    (totalProduk - produkHampirHabis - produkHabis).toString(),
                    Colors.green),
                _buildStatusCard('Produk Hampir Habis',
                    produkHampirHabis.toString(), Colors.orange),
                _buildStatusCard(
                    'Produk Habis', produkHabis.toString(), Colors.red),
                _buildStatusCard(
                    'Total Produk', totalProduk.toString(), Colors.blue),
              ],
            ),
          ),
          const SizedBox(height: 20),

          InkWell(
            onTap: () {
              setState(() {
                _showChart = !_showChart;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _showChart ? 'Sembunyikan' : 'Lihat Selengkapnya',
                  style: const TextStyle(
                      color: Colors.blue, fontWeight: FontWeight.bold),
                ),
                Icon(_showChart ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (_showChart)
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: filteredProduk.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 0.95,
              ),
              itemBuilder: (context, index) {
                final produk = filteredProduk[index];
                return _buildChartPlaceholder(
                  produk['sku'] ?? '',
                  screenWidth / 2,
                  produk['img'] ?? '',
                  produk['harga'] ?? '0',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProdukDetailPage(produk: produk),
                      ),
                    );
                  },
                );
              },
            ),

          if (_isLoading) ...[
            const SizedBox(height: 16),
            const Center(child: CircularProgressIndicator()),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String count, Color color) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Container(
      width: screenWidth * 0.65,
      height: 80,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  count,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartPlaceholder(
      String title, double width, String imagePath, String harga,
      {required VoidCallback onTap}) {
    final imgUrl = cleanImageUrl(imagePath);

    return GestureDetector(
      onTap: onTap,
      child: StatefulBuilder(
        builder: (context, setInnerState) {
          bool isPressed = false;
          return Listener(
            onPointerDown: (_) => setInnerState(() => isPressed = true),
            onPointerUp: (_) => setInnerState(() => isPressed = false),
            child: AnimatedScale(
              scale: isPressed ? 0.97 : 1.0,
              duration: const Duration(milliseconds: 120),
              child: Container(
                width: width - 24,
                height: 220,
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imgUrl.isEmpty
                            ? Container(
                                color: Colors.grey.shade300,
                                width: double.infinity,
                                child: const Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 50,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : Image.network(
                                imgUrl,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: Colors.grey.shade300,
                                  width: double.infinity,
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 50,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      FormatRupiah(harga),
                      style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
