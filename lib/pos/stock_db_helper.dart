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
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
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
        item.map((key, value) => MapEntry(key, value.toString())),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit(noResult: true);
    print('🔄 Sinkronisasi stok selesai (${data.length} data).');
  }

  static Future<void> reduceStockOffline(String idBahan, String ukuran, double qtyToReduce) async {
    final db = await database;

    // Ambil stok saat ini berdasarkan id_bahan dan ukuran
    final stockData = await db.query(
      'tb_stock',
      columns: ['stock'],
      where: 'id_bahan = ? AND ukuran = ?',
      whereArgs: [idBahan, ukuran],
    );

    if (stockData.isNotEmpty) {
      double currentStock = double.tryParse(stockData.first['stock'].toString()) ?? 0;
      double newStock = currentStock - qtyToReduce;
      if (newStock < 0) newStock = 0;

      await db.update(
        'tb_stock',
        {'stock': newStock},
        where: 'id_bahan = ? AND ukuran = ?',
        whereArgs: [idBahan, ukuran],
      );

      print('🛒 Stok lokal dikurangi untuk $idBahan ($ukuran): $currentStock -> $newStock');
    } else {
      print('⚠ Tidak ditemukan stok untuk $idBahan dengan ukuran $ukuran');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchStock({String? idCabang, bool isAdmin = false}) async {
    final db = await database;

    if (isAdmin) {
      return await db.query('tb_stock');
    } else {
      if (idCabang == null || idCabang.isEmpty) {
        throw Exception('ID Cabang tidak tersedia untuk user non-admin.');
      }

      return await db.query(
        'tb_stock',
        where: 'id_cabang = ?',
        whereArgs: [idCabang],
      );
    }
  }
}
