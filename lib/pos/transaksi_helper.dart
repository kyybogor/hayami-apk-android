import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class TransaksiHelper {
  static final TransaksiHelper instance = TransaksiHelper._internal();
  static Database? _database;

  TransaksiHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'pos.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
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
    sts INTEGER,
    sts_void INTEGER,
    is_synced INTEGER DEFAULT 0
            );
        ''');
      },
    );
  }

  Future<void> saveTransaksiToSQLite(Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('tb_barang_keluar', {
      ...data,
      'is_synced': 0,
    });
  }

  Future<void> syncTransaksiToServer() async {
    final db = await database;
    final unsynced = await db.query('tb_barang_keluar', where: 'is_synced = 0');

    for (final trx in unsynced) {
      final response = await http.post(
        Uri.parse('https://your-api.com/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(trx),
      );

      if (response.statusCode == 200) {
        await db.update(
          'tb_barang_keluar',
          {'is_synced': 1},
          where: 'no_id = ?',
          whereArgs: [trx['no_id']],
        );
      }
    }
  }
}
