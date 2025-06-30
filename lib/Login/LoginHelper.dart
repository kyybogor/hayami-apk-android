import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LoginSQLiteHelper {
  static Database? _db;
  static const _dbName = 'mydb.db'; // pastikan file db ada di assets

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

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
    }

    return openDatabase(path, readOnly: false);
  }

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  /// Insert or update ke tabel tb_karyawan
  static Future<void> insertOrUpdateUser(Map<String, dynamic> user) async {
    final dbClient = await db;
    print('Menyimpan user ke SQLite: $user');
    await dbClient.insert(
      'tb_karyawan',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Cari user berdasarkan user_id dan password plain (offline login)
  static Future<Map<String, dynamic>?> getUserByCredentials(String email, String password) async {
    final dbClient = await db;
    print('Mencari user offline dengan user_id=$email dan pass=$password');
    final res = await dbClient.query(
      'tb_karyawan',
      where: 'user_id = ? AND pass = ?',
      whereArgs: [email, password],
    );
    print('Hasil query offline login: $res');
    return res.isNotEmpty ? res.first : null;
  }
}
