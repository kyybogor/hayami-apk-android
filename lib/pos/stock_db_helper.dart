import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StockDBHelper {
  static Database? _db;
  static const _dbName = 'mydb.db';
  static const _dbVersion = 1;
  static const _dbVersionKey = 'db_stock_version';

  static Future<void> initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _dbName);
    final prefs = await SharedPreferences.getInstance();

    final exists = await databaseExists(path);

    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load('assets/$_dbName');
        List<int> bytes =
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
        await prefs.setInt(_dbVersionKey, _dbVersion);

        print('✅ Database produk berhasil disalin dari assets.');
      } catch (e) {
        print('❌ Gagal menyalin database produk: $e');
      }
    } else {
      print('📦 Database produk sudah ada, tidak disalin ulang.');
    }
  }

  static Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    await initDb();
    final path = join(await getDatabasesPath(), _dbName);

    _db = await openDatabase(
      path,
      version: _dbVersion,
      onOpen: (db) async {
        print('🔍 Mengecek dan memperbarui struktur tb_stock...');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS tb_stock (
            id_stock TEXT PRIMARY KEY,
            id_cabang TEXT,
            id_bahan TEXT,
            model TEXT,
            ukuran TEXT,
            stock REAL,
            lokasi_gudang TEXT
          )
        ''');
      },
    );

    return _db!;
  }

  static Future<void> syncStock(List<Map<String, dynamic>> data) async {
    final db = await database;
    await db.delete('tb_stock');

    final batch = db.batch();

    for (var item in data) {
      batch.insert(
        'tb_stock',
        {
          'id': item['id'].toString(),
          'id_transaksi_stock': item['id_transaksi_stock'].toString(),
          'tgl_masuk': item['tgl_masuk'].toString(),
          'id_bahan': item['id_bahan'].toString(),
          'model': item['model'].toString(),
          'ukuran': item['ukuran'].toString(),
          'stock': double.tryParse(item['stock'].toString()) ?? 0.0,
          'stock_retur': int.tryParse(item['stock_retur'].toString()) ?? 0,
          'uom': item['uom'].toString(),
          'harga': int.tryParse(item['harga'].toString()) ?? 0,
          'barcode': item['barcode'].toString(),
          'image': item['image'].toString(),
          'id_cabang': item['id_cabang'].toString(),
          'sts': int.tryParse(item['sts'].toString()) ?? 1,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    print('🔄 Sinkronisasi stok selesai (${data.length} data).');
  }

  static Future<void> reduceStockOffline(
    String idBahan,
    String model,
    String ukuran,
    String idCabang,
    double qtyToReduce,
  ) async {
    final db = await database;

    // Ambil semua baris yang cocok
    final stockData = await db.query(
      'tb_stock',
      columns: ['id', 'stock'],
      where: 'id_bahan = ? AND model = ? AND ukuran = ? AND id_cabang = ?',
      whereArgs: [idBahan, model, ukuran, idCabang],
      orderBy: 'tgl_masuk ASC', // FIFO logic
    );

    if (stockData.isEmpty) {
      print(
          '⚠ Tidak ditemukan stok untuk: $idBahan - $model - $ukuran - $idCabang');
      return;
    }

    double remainingQty = qtyToReduce;

    for (final row in stockData) {
      final String rowId = row['id'].toString();
      double currentStock = double.tryParse(row['stock'].toString()) ?? 0;

      if (remainingQty <= 0) break;

      double reduceAmount =
          currentStock >= remainingQty ? remainingQty : currentStock;
      double newStock = currentStock - reduceAmount;
      remainingQty -= reduceAmount;

      await db.update(
        'tb_stock',
        {'stock': newStock},
        where: 'id = ?',
        whereArgs: [rowId],
      );

      print('✅ Kurangi stok ID $rowId: $currentStock → $newStock');
    }

    if (remainingQty > 0) {
      print('⚠ Stok tidak cukup! Sisa belum dikurangi: $remainingQty');
    } else {
      print('🛒 Stok lokal berhasil dikurangi total: $qtyToReduce');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchStock(
      {String? idCabang, bool isAdmin = false}) async {
    final db = await database;

    if (isAdmin) {
      return await db.query(
        'tb_stock',
        where: 'stock > 0',
      );
    } else {
      if (idCabang == null || idCabang.isEmpty) {
        throw Exception('ID Cabang tidak tersedia untuk user non-admin.');
      }

      return await db.query(
        'tb_stock',
        where: 'id_cabang = ? AND stock > 0',
        whereArgs: [idCabang],
      );
    }
  }
}
