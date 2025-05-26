import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'pergerakanstok.dart';
import 'transaksiterkini.dart';
import 'transfergudang.dart';
import 'unit.dart';

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

class ProductDetailPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // Data yang digunakan untuk Transaksi Terkini dan Transfer Gudang
    List<Map<String, String>> transaksiTerkini = [
      {'title': 'Tagihan Penjualan', 'amount': '899.099', 'date': '15/04/2025'},
      {'title': 'Tagihan Penjualan', 'amount': '998.000', 'date': '15/04/2025'},
      {'title': 'Tagihan Pembelian', 'amount': '598.000', 'date': '14/04/2025'}
    ];

    List<Map<String, String>> transferGudang = [
      {'kode': 'WT/00004', 'tanggal': '09/03/2025'},
      {'kode': 'WT/00003', 'tanggal': '08/03/2025'},
      {'kode': 'WT/00002', 'tanggal': '07/03/2025'}
    ];

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(product['produk_name']!, style: const TextStyle(fontSize: 20)),
            Text(product['produk_code'], style: const TextStyle(fontSize: 12)),
          ],
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          PopupMenuButton<String>(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              switch (value) {
                case 'audit':
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Lihat Audit'),
                      content:
                          const Text('Menampilkan log audit untuk produk ini.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Tutup'),
                        ),
                      ],
                    ),
                  );
                  break;
                case 'ubah':
                case 'duplikat':
                case 'konversi':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur belum tersedia.')),
                  );
                  break;
                case 'arsipkan':
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Produk telah diarsipkan.')),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'audit',
                child: Row(
                  children: [
                    Icon(Icons.history, size: 20),
                    SizedBox(width: 8),
                    Text('Lihat Audit'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'ubah',
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 20),
                    SizedBox(width: 8),
                    Text('Ubah'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'duplikat',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 20),
                    SizedBox(width: 8),
                    Text('Duplikat'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'konversi',
                child: Row(
                  children: [
                    Icon(Icons.swap_horiz, size: 20),
                    SizedBox(width: 8),
                    Text('Konversi Satuan'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'arsipkan',
                child: Row(
                  children: [
                    Icon(Icons.archive, size: 20),
                    SizedBox(width: 8),
                    Text('Arsipkan'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menampilkan info produk seperti stok, penjualan, dan hpp
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildInfoCard('Stok di tangan', product['stok'].toString(),
                      Colors.pink),
                  _buildInfoCard('Penjualan', product['penjualan'].toString(),
                      Colors.orange),
                  _buildInfoCard(
                      'Hpp', product['hpp_value'].toString(), Colors.blue),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('assets/kneel_boots.jpg'),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.inventory_2),
                        const SizedBox(width: 8),
                        Text(product['produk_name']!)
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.category),
                        const SizedBox(width: 8),
                        Text('Kategori: ' +product['kategori']!)
                      ]),
                      const SizedBox(height: 4),
                      const Row(children: [
                        Icon(Icons.straighten),
                        SizedBox(width: 8),
                        Text('Satuan: Pcs')
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.shopping_bag),
                        const SizedBox(width: 8),
                        Text('Harga Beli: ${formatRupiah(product['hpp'])}')
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.sell),
                        const SizedBox(width: 8),
                        Text(
                            'Harga Jual: ${formatRupiah(product['harga_jual'])}')
                      ]),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionHeaderWithAction(context, 'Unit', 'Tambah konversi satuan',
                actionColor: Colors.blue),
            const SizedBox(height: 8),
            const Text('Satuan Dasar: Pcs'),
            const SizedBox(
              height: 8,
            ),
            _sectionHeader('Gudang'),
            const SizedBox(height: 8),
            if (product['gudang']?['unassigned'] == null &&
                product['gudang']?['gudang_utama'] == null &&
                product['gudang']?['gudang_elektronik'] == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Tidak ada data gudang.'),
              )
            else ...[
              if (product['gudang']?['unassigned'] != null)
                _buildWarehouseRow(
                    'Unassigned', product['gudang']['unassigned'].toString()),
              if (product['gudang']?['gudang_utama'] != null)
                _buildWarehouseRow('Gudang Utama',
                    product['gudang']['gudang_utama'].toString()),
              if (product['gudang']?['gudang_elektronik'] != null)
                _buildWarehouseRow('Gudang Elektronik',
                    product['gudang']['gudang_elektronik'].toString()),
              const Divider(),
              _buildWarehouseRow(
                'Total',
                product['total_gudang']?.toString() ?? '0',
                isBold: true,
              ),
            ],
            const SizedBox(height: 24),
            _sectionHeaderWithAction(
                context, 'Transaksi Terkini', 'Lihat Semua',
                actionColor: Colors.blue),
            const SizedBox(height: 8),
            // Menampilkan transaksi terkini
            ...transaksiTerkini.map((trx) {
              return _buildTransactionRow(trx['title']!, trx['amount']!,
                  trx['date']!);
            }).toList(),
            const SizedBox(height: 24),
            _sectionHeaderWithAction(context, 'Pergerakan Stok', 'Lihat Semua',
                actionColor: Colors.blue),
            const SizedBox(height: 8),
            _buildStockMovement('Tagihan Penjualan', '-2', Colors.red),
            _buildStockMovement('Tagihan Pembelian', '+2', Colors.green),
            _buildStockMovement('Tagihan Penjualan', '-3', Colors.red),
            const SizedBox(height: 24),
            _sectionHeaderWithAction(context, 'Transfer Gudang', 'Lihat Semua',
                actionColor: Colors.blue),
            const SizedBox(height: 8),
            // Menampilkan transfer gudang
            ...transferGudang.map((transfer) {
              return ListTile(
                title: Text(transfer['kode']!),
                subtitle: Text(transfer['tanggal']!),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              );
            }).toList(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // Widget untuk menampilkan info card
  Widget _buildInfoCard(String title, String value, Color color) {
    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildWarehouseRow(String name, String qty, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name,
              style:
                  isBold ? const TextStyle(fontWeight: FontWeight.bold) : null),
          Text(qty,
              style:
                  isBold ? const TextStyle(fontWeight: FontWeight.bold) : null),
        ],
      ),
    );
  }

  // Widget untuk menampilkan transaksi terkini
  Widget _buildTransactionRow(String title, String amount, String date) {
    return ListTile(
      title: Text(title),
      subtitle: Text(date),
      trailing:
          Text(amount, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  // Widget untuk menampilkan pergerakan stok
  Widget _buildStockMovement(String title, String qty, Color color) {
    return ListTile(
      title: Text(title),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(qty, style: TextStyle(color: color)),
      ),
    );
  }

  // Widget untuk menampilkan header
  Widget _sectionHeader(String title) {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
    );
  }

  // Widget untuk menampilkan header dengan aksi
  Widget _sectionHeaderWithAction(
      BuildContext context, String title, String actionText,
      {Color actionColor = Colors.black}) {
    return Container(
      width: double.infinity,
      color: Colors.grey.shade200,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          InkWell(
            onTap: () {
              if (title == 'Unit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KonversiSatuanPage()),
                );
              } else if (title == 'Transaksi Terkini') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TransaksiTerkiniPage(product: product,)),
                );
              } else if (title == 'Pergerakan Stok') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PergerakanstokPage(product: product)),
                );
              } else if (title == 'Transfer Gudang') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TransferGudangPage(product: product,)),
                );
              }
            },
            child: Text(
              actionText,
              style: TextStyle(
                color: actionColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}