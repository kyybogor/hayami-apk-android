import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hayami_app/Dashboard/dashboardscreen.dart';
import 'package:hayami_app/produk/produkdetail.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class ProdukPage extends StatefulWidget {
  const ProdukPage({Key? key}) : super(key: key);

  @override
  State<ProdukPage> createState() => _ProdukPageState();
}

class _ProdukPageState extends State<ProdukPage> {
  bool _showChart = true;

  List<Map<String, dynamic>> _allProduk = [];
  Map<String, List<Map<String, dynamic>>> _groupedProdukByTipeModel = {};
  List<List<Map<String, dynamic>>> _produkGroupedList = [];

  int _loadedGroupCount = 0;
  final int _groupLoadSize = 10;

  bool _isLoading = false;
  bool _hasMore = true;

  int totalProduk = 0;
  int produkHampirHabis = 0;
  int produkHabis = 0;

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  Timer? _debounce;

  // Untuk pagination hasil search di client side
  List<Map<String, dynamic>> _searchResults = [];
  int _searchDisplayCount = 0;
  final int _searchLoadSize = 20;
  bool _searchHasMore = false;

  Map<String, List<Map<String, dynamic>>> groupByTipeModel(
      List<Map<String, dynamic>> data) {
    Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var item in data) {
      final key = '${item['tipe']}-${item['gambar']}';
      if (!grouped.containsKey(key)) {
        grouped[key] = [];
      }
      grouped[key]!.add(item);
    }
    return grouped;
  }

  @override
  void initState() {
    super.initState();
    _fetchProduk();
    _scrollController.addListener(_scrollListener);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      final query = _searchController.text.trim();
      if (query.isEmpty) {
        setState(() {
          _searchQuery = '';
          _searchResults = [];
          _searchDisplayCount = 0;
          _searchHasMore = false;
          _hasMore = true;
          _loadedGroupCount = (_groupLoadSize < _produkGroupedList.length)
              ? _groupLoadSize
              : _produkGroupedList.length;
        });
      } else {
        setState(() {
          _searchQuery = query.toLowerCase();
          _searchResults = [];
          _searchDisplayCount = 0;
          _searchHasMore = false;
          _hasMore = false;
          _loadedGroupCount = 0;
          _isLoading = true;
        });
        _fetchSearchProduk(query);
      }
    });
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
          _groupedProdukByTipeModel = groupByTipeModel(_allProduk);
          _produkGroupedList =
              _groupProduk(_allProduk); // bisa hapus jika tidak dipakai lagi
          _loadedGroupCount =
              (_groupLoadSize < _groupedProdukByTipeModel.length)
                  ? _groupLoadSize
                  : _groupedProdukByTipeModel.length;
          _hasMore = _loadedGroupCount < _groupedProdukByTipeModel.length;
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

  Future<void> _fetchSearchProduk(String skuQuery) async {
    final encodedSku = Uri.encodeComponent(skuQuery);
    final url = Uri.parse(
        'https://hayami.id/apps/erp/api-android/api/searchproduk.php?sku=$encodedSku');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        List<Map<String, dynamic>> results = [];

        if (jsonResponse is List) {
          results = List<Map<String, dynamic>>.from(jsonResponse);
        } else if (jsonResponse['all_product'] != null) {
          results =
              List<Map<String, dynamic>>.from(jsonResponse['all_product']);
        }

        setState(() {
          _searchResults = results;
          _searchDisplayCount = results.length > _searchLoadSize
              ? _searchLoadSize
              : results.length;
          _searchHasMore = results.length > _searchDisplayCount;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        print('Gagal load search produk');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error saat search produk: $e');
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
    if (_isLoading) return;

    if (_searchQuery.isNotEmpty) {
      if (_searchHasMore) {
        setState(() {
          final remaining = _searchResults.length - _searchDisplayCount;
          final loadCount =
              remaining > _searchLoadSize ? _searchLoadSize : remaining;
          _searchDisplayCount += loadCount;
          _searchHasMore = _searchResults.length > _searchDisplayCount;
        });
      }
    } else {
      // load more produk normal
      if (_hasMore) {
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
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 150) {
      _loadMoreGroups();
    }
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

  String cleanImageUrl(String url) {
    if (url.isEmpty) return '';
    if (!url.startsWith('http')) {
      return 'https://hayami.id/apps/erp/' + url;
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = screenWidth > 600 ? 3 : 2;

    final groupedEntries = _groupedProdukByTipeModel.entries.toList();
    final displayGroups = groupedEntries.take(_loadedGroupCount).toList();

    return Scaffold(
      resizeToAvoidBottomInset: true,
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
      body: SafeArea(
  child: Padding(
    padding: const EdgeInsets.all(16),
    child: SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 80,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Cari produk...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10), // diperbaiki
            ),
          ),
          const SizedBox(height: 12),
          if (_searchQuery.isEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusCard(
                    'Produk Tersedia',
                    (totalProduk - produkHampirHabis - produkHabis).toString(),
                    Colors.green,
                  ),
                  _buildStatusCard(
                      'Produk Hampir Habis',
                      produkHampirHabis.toString(),
                      Colors.orange),
                  _buildStatusCard(
                      'Produk Habis', produkHabis.toString(), Colors.red),
                  _buildStatusCard(
                      'Total Produk', totalProduk.toString(), Colors.blue),
                ],
              ),
            ),
          const SizedBox(height: 20),
          if (_searchQuery.isEmpty)
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
          if ((_searchQuery.isEmpty && _showChart) || _searchQuery.isNotEmpty)
            GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: displayGroups.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.8,
              ),
              itemBuilder: (context, index) {
                final entry = displayGroups[index];
                final produkList = entry.value;
                final firstProduk = produkList.first;

                return _buildGroupedProdukCard(
                  '${firstProduk['tipe']} - ${firstProduk['gambar']}',
                  firstProduk['img'] ?? '',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProdukDetailPage(produk: produkList.first),
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
    ),
  ),
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
                margin: const EdgeInsets.only(right: 12),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: imgUrl.isEmpty
                            ? Container(
                                color: Colors.grey.shade300,
                                child: const Center(
                                  child: Icon(Icons.image_not_supported,
                                      size: 50, color: Colors.grey),
                                ),
                              )
                            : Image.network(
                                imgUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: Colors.grey.shade300,
                                  child: const Center(
                                    child: Icon(Icons.broken_image,
                                        size: 50, color: Colors.grey),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupedProdukCard(
      String title, String imagePath, VoidCallback onTap) {
    final imgUrl = cleanImageUrl(imagePath);
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: imgUrl.isEmpty
                    ? Container(
                        color: Colors.grey.shade300,
                        child: const Center(
                            child: Icon(Icons.image_not_supported)),
                      )
                    : Image.network(
                        imgUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade300,
                          child: const Center(child: Icon(Icons.broken_image)),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}