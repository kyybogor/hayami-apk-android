
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
    final currentVersion = prefs.getInt(_dbVersionKey) ?? 0;

    if (!exists || currentVersion < _dbVersion) {
      try {
        if (exists) {
          await deleteDatabase(path);
          print('🧹 Database lama dihapus karena versi lama.');
        }

        await Directory(dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load('assets/$_dbName');
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
        await prefs.setInt(_dbVersionKey, _dbVersion);

        print('✅ Database produk berhasil disalin atau diperbarui.');
      } catch (e) {
        print('❌ Gagal menyalin database produk: $e');
      }
    } else {
      print('📦 Database produk sudah ada dan versi terbaru.');
    }
  }

  static Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    await initDb();
    final path = join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(path);
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
