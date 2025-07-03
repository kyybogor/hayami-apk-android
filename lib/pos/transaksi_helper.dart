import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:convert';

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

        // Tambah index untuk mempercepat query
        await db.execute('CREATE INDEX IF NOT EXISTS idx_is_synced ON tb_barang_keluar(is_synced);');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_id_invoice ON tb_barang_keluar(id_invoice);');
      },
      // Contoh onUpgrade jika nanti versi database bertambah
      onUpgrade: (db, oldVersion, newVersion) async {
        // Contoh migrasi data / schema upgrade
        if (oldVersion < newVersion) {
          // Implement schema changes here
        }
      },
    );
  }

  Future<void> saveTransaksiToSQLite(Map<String, dynamic> data) async {
    final db = await database;

    // Validasi minimal no_id dan id_invoice
    if (data['no_id'] == null || data['id_invoice'] == null) {
      throw Exception('Data transaksi harus memiliki no_id dan id_invoice');
    }

    await db.insert(
      'tb_barang_keluar',
      {
        ...data,
        'is_synced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> trySyncIfOnline() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity != ConnectivityResult.none) {
        print("📶 Online: Mulai sinkronisasi transaksi");
        await syncTransaksiToServer();
      } else {
        print("📴 Offline: Tidak bisa sinkronisasi sekarang.");
      }
    } catch (e, stacktrace) {
      print("❌ Gagal cek koneksi atau sinkronisasi: $e");
      print(stacktrace);
    }
  }

  Future<void> syncTransaksiToServer() async {
    final db = await database;

    final List<Map<String, dynamic>> unsynced =
        await db.query('tb_barang_keluar', where: 'is_synced = 0');

    if (unsynced.isEmpty) {
      print("✅ Semua transaksi sudah disinkronkan.");
      return;
    }

    final Map<String, List<Map<String, dynamic>>> groupedByInvoice = {};
    for (final row in unsynced) {
      final invoiceId = row['id_invoice'];
      if (invoiceId == null) continue; // skip data tanpa id_invoice
      if (!groupedByInvoice.containsKey(invoiceId)) {
        groupedByInvoice[invoiceId] = [];
      }
      groupedByInvoice[invoiceId]!.add(row);
    }

    for (final entry in groupedByInvoice.entries) {
      final invoiceId = entry.key;
      final transaksiList = entry.value;
      final trx = transaksiList.first;

      final items = transaksiList.map((item) {
  return {
    "idBahan": item['id_bahan'],
    "model": item['model'],
    "ukuran": item['ukuran'],
    "quantity": item['qty'],
    "unitPrice": item['harga'],
    "disc": item['disc'],
    "total": item['total'],
  };
}).toList();

      // Validasi data utama sebelum dikirim
      if (trx['id_customer'] == null || items.isEmpty) {
        print("❗ Lewati $invoiceId karena data tidak lengkap.");
        continue;
      }

      final body = {
        "idCustomer": trx['id_customer'],
        "sales": trx['sales'],
        "discInvoice": trx['disc_invoice'],
        "subtotal": trx['subtotal_invoice'],
        "grandTotal": trx['total_invoice'],
        "idCabang": trx['id_cabang'],
        "dibuatOleh": trx['dibuat_oleh'],
        "akun": trx['akun'],
        "cash": trx['cash'] == 1 ? trx['total_invoice'] : 0.0,
        "sisa_bayar": trx['sisa_bayar'],
        "items": items,
      };

      try {
        final response = await http.post(
          Uri.parse('http://192.168.1.5/hayami/takepayment.php'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final resData = jsonDecode(response.body);
          if (resData['status'] == 'success') {
            await db.update(
              'tb_barang_keluar',
              {'is_synced': 1},
              where: 'id_invoice = ?',
              whereArgs: [invoiceId],
            );
            print("✅ Sync berhasil: $invoiceId");
          } else {
            print("❌ Gagal simpan di server: ${resData['message']}");
          }
        } else {
          print("❌ HTTP ${response.statusCode} saat sync $invoiceId");
        }
      } catch (e, stacktrace) {
        print("❌ Gagal koneksi saat sync $invoiceId: $e");
        print(stacktrace);
      }
    }
  }
}