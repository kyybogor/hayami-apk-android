import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class SalesHelper {
  static final SalesHelper _instance = SalesHelper._internal();
  factory SalesHelper() => _instance;
  SalesHelper._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'mydb.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS m_sales (
            id_sales VARCHAR(100) PRIMARY KEY,
            nm_sales VARCHAR(100) NOT NULL,
            credit_limit DECIMAL(20,2) NOT NULL,
            no_telp VARCHAR(15) NOT NULL,
            email TEXT NOT NULL,
            region TEXT NOT NULL,
            dibuat_oleh VARCHAR(100) NOT NULL,
            dibuat_tgl DATETIME NOT NULL
          )
        ''');
      },
    );
  }

  Future<void> insertOrUpdateSales(List<Map<String, dynamic>> sales) async {
    final db = await database;
    final batch = db.batch();
    for (var s in sales) {
      batch.insert(
        'm_sales',
        s,
        conflictAlgorithm: ConflictAlgorithm.replace, // update kalau sudah ada
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getAllSales() async {
    final db = await database;
    return await db.query('m_sales');
  }
}
