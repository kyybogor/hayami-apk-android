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
  static const _dbVersion = 1;
  static const _dbVersionKey = 'db_version';

  /// Tidak akan menghapus database lagi, hanya menyalin kalau belum ada
  static Future<void> initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, _dbName);

    final exists = await databaseExists(path);
    if (!exists) {
      try {
        await Directory(dirname(path)).create(recursive: true);
        ByteData data = await rootBundle.load('assets/$_dbName');
        List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
        await File(path).writeAsBytes(bytes, flush: true);
        print('✅ Database berhasil disalin dari assets.');
      } catch (e) {
        print('❌ Gagal menyalin database: $e');
      }
    } else {
      print('📦 Database sudah ada, tidak disalin ulang.');
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
        print('🔍 Mengecek struktur tb_customer...');
        // Tambahkan kolom baru jika perlu (contoh: phone_number)
        try {
          await db.execute("ALTER TABLE tb_customer ADD COLUMN phone_number TEXT");
          print('🆕 Kolom phone_number ditambahkan ke tb_customer.');
        } catch (e) {
          // Biasanya error karena kolom sudah ada — ini bisa diabaikan
          print('ℹ️ Kolom phone_number sudah ada atau gagal ditambahkan: $e');
        }

        // Jika ingin membuat ulang tabel jika belum ada (optional)
        await db.execute('''
          CREATE TABLE IF NOT EXISTS tb_customer (
            id_customer TEXT PRIMARY KEY,
            nama_customer TEXT,
            phone_number TEXT
            -- Tambahkan kolom lain jika perlu
          )
        ''');
      },
    );

    return _db!;
  }

  static Future<List<Customer>> fetchCustomers(String keyword) async {
    final db = await database;
    final result = await db.query(
      'tb_customer',
      where: 'nama_customer LIKE ?',
      whereArgs: ['%$keyword%'],
    );
    return result.map((e) => Customer.fromMap(e)).toList();
  }

  static Future<void> syncCustomers(List<Customer> customers) async {
    final db = await database;
    await db.delete('tb_customer');

    final batch = db.batch();
    for (var customer in customers) {
      print('📝 Simpan: ${customer.nmCustomer}');
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
