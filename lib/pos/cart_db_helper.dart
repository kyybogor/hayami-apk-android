import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CartDBHelper {
  static Database? _database;
  static final CartDBHelper instance = CartDBHelper._internal();

  CartDBHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('hayami.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tb_barang_keluar (
        no_id TEXT PRIMARY KEY,
        id_transaksi TEXT,
        tgl_transaksi TEXT,
        id_customer TEXT,
        sales TEXT,
        keterangan TEXT,
        id_bahan TEXT,
        model TEXT,
        ukuran TEXT,
        qty REAL,
        uom TEXT,
        harga REAL,
        subtotal INTEGER,
        total INTEGER,
        disc REAL,
        disc_nilai REAL,
        ppn REAL,
        status_keluar TEXT,
        jatuh_tempo INTEGER,
        tgl_jatuh_tempo TEXT,
        by_user_pajak INTEGER,
        non_stock INTEGER,
        id_invoice TEXT,
        disc_invoice REAL,
        cust_invoice TEXT,
        tgl_invoice TEXT,
        subtotal_invoice REAL,
        total_invoice REAL,
        sisa_bayar REAL,
        cash INTEGER,
        status TEXT,
        from_cust INTEGER,
        qty_jenis_1 INTEGER,
        qty_jenis_2 INTEGER,
        hhp_jenis_1 INTEGER,
        hhp_jenis_2 INTEGER,
        untung INTEGER,
        akun TEXT,
        dibuat_oleh TEXT,
        dibuat_tgl TEXT,
        diubah_oleh TEXT,
        diubah_tgl TEXT,
        id_cabang TEXT,
        sts TEXT,
        sts_void INTEGER,
        is_synced INTEGER DEFAULT 0,
        diskon_lusin REAL DEFAULT 0
      )
    ''');
  }

  String generateNoId() {
    final now = DateTime.now();
    final prefix = "IK";
    final mm = now.month.toString().padLeft(2, '0');
    final yy = now.year.toString().substring(2);
    final random = DateTime.now().microsecondsSinceEpoch.remainder(1000000);
    return '$prefix$mm$yy$random';
  }

  double parseDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

Future<void> insertOrUpdateCartItem(Map<String, dynamic> item) async {
  final db = await database;

  final idTransaksi = item['id_transaksi'];
  final idBahan = item['id_bahan'];
  final model = item['model'];
  final ukuran = item['ukuran'];

  final quantity = parseDouble(item['quantity'] ?? item['qty']);
  final unitPrice = parseDouble(item['unitPrice'] ?? item['harga']);
  final disc = parseDouble(item['disc']);

  final subtotal = quantity * unitPrice;
  final total = subtotal - disc;

  // Cari apakah item ini sudah ada
  final existing = await db.query(
    'tb_barang_keluar',
    where: 'id_transaksi = ? AND id_bahan = ? AND model = ? AND ukuran = ? AND sts_void = 0',
    whereArgs: [idTransaksi, idBahan, model, ukuran],
  );

  final noId = existing.isNotEmpty
      ? existing.first['no_id']
      : generateNoId();

  final validItem = <String, dynamic>{
    'no_id': noId,
    'id_transaksi': idTransaksi,
    'tgl_transaksi': item['tgl_transaksi'] ?? '',
    'id_customer': item['id_customer'] ?? '',
    'sales': item['sales'] ?? '',
    'keterangan': item['keterangan'] ?? '',
    'id_bahan': idBahan,
    'model': model,
    'ukuran': ukuran,
    'qty': quantity,
    'uom': item['uom'] ?? 'PCS',
    'harga': unitPrice,
    'subtotal': subtotal,
    'total': total,
    'disc': disc,
    'disc_nilai': parseDouble(item['disc_nilai']),
    'ppn': parseDouble(item['ppn']),
    'status_keluar': item['status_keluar'] ?? '',
    'jatuh_tempo': item['jatuh_tempo'] ?? 0,
    'tgl_jatuh_tempo': item['tgl_jatuh_tempo'] ?? '',
    'by_user_pajak': item['by_user_pajak'] ?? 0,
    'non_stock': item['non_stock'] ?? 0,
    'id_invoice': item['id_invoice'] ?? '',
    'disc_invoice': parseDouble(item['disc_invoice']),
    'cust_invoice': item['cust_invoice'] ?? '',
    'tgl_invoice': item['tgl_invoice'] ?? '',
    'subtotal_invoice': subtotal,
    'total_invoice': total,
    'sisa_bayar': parseDouble(item['sisa_bayar']),
    'cash': item['cash'] ?? 0,
    'status': item['status'] ?? '',
    'from_cust': item['from_cust'] ?? 0,
    'qty_jenis_1': item['qty_jenis_1'] ?? 0,
    'qty_jenis_2': item['qty_jenis_2'] ?? 0,
    'hhp_jenis_1': item['hhp_jenis_1'] ?? 0,
    'hhp_jenis_2': item['hhp_jenis_2'] ?? 0,
    'untung': item['untung'] ?? 0,
    'akun': item['akun'] ?? '',
    'dibuat_oleh': item['dibuat_oleh'] ?? '',
    'dibuat_tgl': item['dibuat_tgl'] ?? '',
    'diubah_oleh': item['diubah_oleh'] ?? '',
    'diubah_tgl': item['diubah_tgl'] ?? '',
    'id_cabang': item['id_cabang'] ?? '',
    'sts': item['sts'] ?? '',
    'sts_void': item['sts_void'] ?? 0,
    'is_synced': item['is_synced'] ?? 0,
    'diskon_lusin': parseDouble(item['diskon_lusin']),
  };

  await db.insert(
    'tb_barang_keluar',
    validItem,
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<List<Map<String, dynamic>>> getAllCartData() async {
  final db = await database;
  return await db.query(
    'tb_barang_keluar',
    where: "id_transaksi LIKE '%C%' AND sts_void = 0",
  );
}

  Future<void> clearCart() async {
    final db = await database;
    await db.delete('tb_barang_keluar', where: "id_transaksi LIKE '%C%'");
  }

  Future<List<Map<String, dynamic>>> getCartDetailsById(String idTransaksi) async {
    final db = await database;
    return await db.query(
      'tb_barang_keluar',
      where: 'id_transaksi = ?',
      whereArgs: [idTransaksi],
    );
  }

Future<void> syncPendingDrafts() async {
  final connectivity = await Connectivity().checkConnectivity();
  if (connectivity == ConnectivityResult.none) return;

  final db = await database;

  // 1. Sinkronisasi data yang dihapus (sts_void = 1 dan is_synced = 0)
  final voided = await db.query(
    'tb_barang_keluar',
    where: 'sts_void = 1 AND is_synced = 0',
    distinct: true,
    columns: ['id_transaksi'],
  );

  for (var item in voided) {
    final idTransaksi = item['id_transaksi'];
    try {
      final response = await http.post(
        Uri.parse("http://192.168.1.9/hayami/delete_cart.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({'id_transaksi': idTransaksi}),
      );

      final res = jsonDecode(response.body);
      if (response.statusCode == 200 && res['status'] == 'success') {
        // Tandai sebagai tersinkron
        await db.update(
          'tb_barang_keluar',
          {'is_synced': 1},
          where: 'id_transaksi = ?',
          whereArgs: [idTransaksi],
        );
      }
    } catch (e) {
      print("Sync delete error for $idTransaksi: $e");
    }
  }

  // 2. Sinkronisasi data cart draft yang belum tersinkron (is_synced = 0, tidak dihapus)
  final unsynced = await db.query(
    'tb_barang_keluar',
    where: 'is_synced = 0 AND sts_void = 0',
  );

  if (unsynced.isEmpty) return;

  // Kelompokkan berdasarkan id_transaksi
  final grouped = <String, List<Map<String, dynamic>>>{};
  for (var row in unsynced) {
    final rawId = row['id_transaksi'];
    final id = (rawId != null && rawId.toString().isNotEmpty)
        ? rawId.toString()
        : 'UNDEFINED';

    grouped.putIfAbsent(id, () => []).add(row);
  }

for (var entry in grouped.entries) {
  final transaksiId = entry.key;
  final items = entry.value;

  await db.update(
  'tb_barang_keluar',
  {'is_synced': -1}, // status "sedang dikirim"
  where: 'id_transaksi = ? AND is_synced = 0',
  whereArgs: [transaksiId],
);


  final body = {
    "existingIdTransaksi": transaksiId,
    "idCustomer": items.first['id_customer'],
    "sales": items.first['sales'],
    "discInvoice": items.first['disc_invoice'] ?? 0,
    "subtotal": items.map((e) => e['qty'] * e['harga']).fold(0.0, (a, b) => a + b),
    "grandTotal": items.map((e) => (e['qty'] * e['harga']) - (e['disc'] ?? 0)).fold(0.0, (a, b) => a + b),
    "idCabang": items.first['id_cabang'],
    "dibuatOleh": items.first['dibuat_oleh'],
"items": items.map((e) {
  final qty = parseDouble(e['qty']);
  final harga = parseDouble(e['harga']);
  final disc = parseDouble(e['disc']);
  final subtotal = qty * harga;
  final total = subtotal - disc;

  return {
    "noId": e['no_id'], // ⬅️ Tambahkan ini!
    "idBahan": e['id_bahan'],
    "model": e['model'],
    "ukuran": e['ukuran'],
    "quantity": qty,
    "unitPrice": harga,
    "subtotal": subtotal,
    "total": total,
    "disc": disc,
  };
}).toList()
  };

  final existingSync = await db.query(
  'tb_barang_keluar',
  where: 'id_transaksi = ? AND is_synced = 1',
  whereArgs: [transaksiId],
);

if (existingSync.isNotEmpty) {
  print('Data $transaksiId sudah pernah disinkron. Lewati.');
  continue;
}


  try {
    final response = await http.post(
      Uri.parse("http://192.168.1.9/hayami/draft.php"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    final res = jsonDecode(response.body);
    if (response.statusCode == 200 && res['status'] == 'success') {
      for (var item in items) {
        await db.update(
          'tb_barang_keluar',
          {'is_synced': 1},
          where: 'no_id = ?',
          whereArgs: [item['no_id']],
        );
      }
    }
  } catch (e) {
    print("Sync error for $transaksiId: $e");
  }
}
}


Future<void> markCartAsDeleted(String idTransaksi, {bool isSynced = false}) async {
  final db = await database;
  final result = await db.update(
    'tb_barang_keluar',
    {
      'sts_void': 1,
      'is_synced': isSynced ? 1 : 0,
    },
    where: 'id_transaksi = ?',
    whereArgs: [idTransaksi],
  );

  if (result == 0) {
    print("‼️ GAGAL DELETE: Tidak ada data dengan id_transaksi = '$idTransaksi'");
  } else {
    print("✅ markCartAsDeleted - ID: $idTransaksi | Rows updated: $result");
  }
}

Future<void> deleteCartItemByDetails(
  String idTransaksi,
  String idTipe,
  String productName,
  String size,
) async {
  final db = await database;
  await db.delete(
    'tb_barang_keluar',
    where: 'id_transaksi = ? AND id_bahan = ? AND model = ? AND ukuran = ?',
    whereArgs: [idTransaksi, idTipe, productName, size],
  );
}



}
