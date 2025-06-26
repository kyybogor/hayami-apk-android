import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:hayami_app/pos/customer_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomerDBHelper {
  static Database? _db;
  static const _dbName = 'mydb.db';
  static const _dbVersion = 1; // Ganti ini saat update struktur
  static const _dbVersionKey = 'db_version';

  /// Inisialisasi database: copy dari assets jika belum ada atau versi berubah
  static Future<void> initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _dbName);
    final prefs = await SharedPreferences.getInstance();

    final exists = await databaseExists(path);
    final currentVersion = prefs.getInt(_dbVersionKey) ?? 0;

    if (!exists || currentVersion < _dbVersion) {
      try {
        if (exists && currentVersion < _dbVersion) {
          await deleteDatabase(path);
          print('🧹 Database lama dihapus karena versi lama.');
        }

        await Directory(dirname(path)).create(recursive: true);

        ByteData data = await rootBundle.load('assets/$_dbName');
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);

        await prefs.setInt(_dbVersionKey, _dbVersion);
        print('✅ Database berhasil disalin atau diperbarui.');
      } catch (e) {
        print('❌ Gagal menyalin database: $e');
      }
    } else {
      print('📦 Database sudah ada dan versi terbaru.');
    }
  }

  /// Getter: buka database jika belum terbuka
  static Future<Database> get database async {
    if (_db != null && _db!.isOpen) return _db!;
    await initDb();
    final path = join(await getDatabasesPath(), _dbName);
    _db = await openDatabase(path);
    return _db!;
  }

  /// Ambil customer berdasarkan keyword (offline mode)
  static Future<List<Customer>> fetchCustomers(String keyword) async {
    final db = await database;
    final result = await db.query(
      'tb_customer',
      where: 'nama_customer LIKE ?',
      whereArgs: ['%$keyword%'],
    );
    return result.map((e) => Customer.fromMap(e)).toList();
  }

  /// Sinkronisasi customer dari data online ke SQLite
  static Future<void> syncCustomers(List<Customer> customers) async {
    final db = await database;

    // Optional: hapus semua data dulu untuk fresh sync
    await db.delete('tb_customer');

    final batch = db.batch();
    for (var customer in customers) {
      batch.insert(
        'tb_customer',
        customer.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
    print('🔄 Sinkronisasi customer selesai (${customers.length} data).');
  }
}
