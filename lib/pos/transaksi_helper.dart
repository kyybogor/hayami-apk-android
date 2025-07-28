import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TransaksiHelper {
  static final TransaksiHelper instance = TransaksiHelper._internal();
  static Database? _database;

  TransaksiHelper._internal();

  static const String _prefsKeyCounterTransaksi = 'last_server_counter_transaksi';

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
    version: 2, // UBAH versi ke 2
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

      await db.execute('CREATE INDEX IF NOT EXISTS idx_is_synced ON tb_barang_keluar(is_synced);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_id_invoice ON tb_barang_keluar(id_invoice);');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS tb_pembayaran (
          no_id INTEGER PRIMARY KEY AUTOINCREMENT,
          id_pembayaran TEXT NOT NULL,
          tgl_bayar TEXT NOT NULL,
          metode TEXT NOT NULL,
          nominal INTEGER NOT NULL,
          keterangan TEXT NOT NULL,
          dibuat_oleh TEXT NOT NULL,
          dibuat_tgl TEXT NOT NULL,
          id_cabang TEXT NOT NULL,
          sts INTEGER NOT NULL
        );
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS tb_petty_cash (
          id_petty TEXT PRIMARY KEY,
          tgl TEXT NOT NULL,
          keterangan TEXT NOT NULL,
          in_cash REAL NOT NULL,
          out_cash REAL NOT NULL,
          bukti_petty TEXT NOT NULL,
          dibuat_oleh TEXT NOT NULL,
          dibuat_tgl TEXT NOT NULL,
          diubah_oleh TEXT NOT NULL,
          diubah_tgl TEXT NOT NULL,
          id_cabang TEXT NOT NULL,
          sts INTEGER NOT NULL
        );
      ''');
    },

    onUpgrade: (db, oldVersion, newVersion) async {
      if (oldVersion < 2) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS tb_pembayaran (
            no_id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_pembayaran TEXT NOT NULL,
            tgl_bayar TEXT NOT NULL,
            metode TEXT NOT NULL,
            nominal INTEGER NOT NULL,
            keterangan TEXT NOT NULL,
            dibuat_oleh TEXT NOT NULL,
            dibuat_tgl TEXT NOT NULL,
            id_cabang TEXT NOT NULL,
            sts INTEGER NOT NULL
          );
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS tb_petty_cash (
            id_petty TEXT PRIMARY KEY,
            tgl TEXT NOT NULL,
            keterangan TEXT NOT NULL,
            in_cash REAL NOT NULL,
            out_cash REAL NOT NULL,
            bukti_petty TEXT NOT NULL,
            dibuat_oleh TEXT NOT NULL,
            dibuat_tgl TEXT NOT NULL,
            diubah_oleh TEXT NOT NULL,
            diubah_tgl TEXT NOT NULL,
            id_cabang TEXT NOT NULL,
            sts INTEGER NOT NULL
          );
        ''');
      }
    },
  );
}


  Future<int> _fetchLastCountTransaksiFromServer() async {
    final response = await http.get(Uri.parse('https://hayami.id/pos/last_id.php'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['status'] == 'success') {
        int count = data['lastCount'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt(_prefsKeyCounterTransaksi, count);
        return count;
      }
    }
    throw Exception('Gagal ambil count transaksi dari server');
  }

  Future<int> _getLocalCounterTransaksi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_prefsKeyCounterTransaksi) ?? 0;
  }

  Future<void> _incrementLocalCounterTransaksi() async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(_prefsKeyCounterTransaksi) ?? 0;
    await prefs.setInt(_prefsKeyCounterTransaksi, current + 1);
  }

  Future<String> generateIDTransaksi() async {
    int count;
    try {
      count = await _fetchLastCountTransaksiFromServer();
    } catch (_) {
      count = await _getLocalCounterTransaksi();
    }
    count++;
    await _incrementLocalCounterTransaksi();

    final now = DateTime.now();
    final year = DateFormat('yy').format(now);
    final month = DateFormat('MM').format(now);
    final counter = count.toString().padLeft(4, '0');

    return 'SO/$year$month/$counter';
  }

  Future<String> generateIDInvoice() async {
    final now = DateTime.now();
    final year = DateFormat('yyyy').format(now);
    final month = DateFormat('MM').format(now);
    final prefs = await SharedPreferences.getInstance();
    int counter = (prefs.getInt('local_invoice_counter') ?? 0) + 1;
    await prefs.setInt('local_invoice_counter', counter);

    final padded = counter.toString().padLeft(5, '0');
    return 'INV-$year-$month-$padded';
  }

Future<void> saveTransaksiToSQLite(Map<String, dynamic> data) async {
  final db = await database;
  final prefs = await SharedPreferences.getInstance();

  final dibuatOleh = prefs.getString('id_user') ?? 'system';
  final idCabang = prefs.getString('id_cabang') ?? '';

  if (data['no_id'] == null || data['id_invoice'] == null) {
    throw Exception('Data transaksi harus memiliki no_id dan id_invoice');
  }

  await db.insert(
    'tb_barang_keluar',
    {
      ...data,
      'dibuat_oleh': dibuatOleh,
      'id_cabang': idCabang,
      'is_synced': 0,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}


Future<void> savePembayaranSplitToSQLite(List<Map<String, dynamic>> pembayaranSplit) async {
  final db = await database;
  final prefs = await SharedPreferences.getInstance();

  final dibuatOleh = prefs.getString('id_user') ?? 'system';
  final idCabang = prefs.getString('id_cabang') ?? '';

  for (final pembayaran in pembayaranSplit) {
    final metode = pembayaran['metode'];
    final nominalStr = pembayaran['nominal'] ?? pembayaran['jumlah'] ?? '0';
    final nominal = int.tryParse(nominalStr.toString().replaceAll('.', '')) ?? 0;

    final tglBayar = pembayaran['tgl_bayar'] ?? DateTime.now().toIso8601String();
    final idPembayaran = pembayaran['id_transaksi'] ?? pembayaran['id_pembayaran'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    final keterangan = pembayaran['keterangan'] ?? '';
    final dibuatTgl = DateTime.now().toIso8601String();
    final sts = 0;

    await db.insert('tb_pembayaran', {
      'id_pembayaran': idPembayaran,
      'tgl_bayar': tglBayar,
      'metode': metode,
      'nominal': nominal,
      'keterangan': keterangan,
      'dibuat_oleh': dibuatOleh,
      'dibuat_tgl': dibuatTgl,
      'id_cabang': idCabang,
      'sts': sts,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    if (metode.toUpperCase() == 'CASH') {
      final idPetty = DateTime.now().millisecondsSinceEpoch.toString();

      await db.insert('tb_petty_cash', {
        'id_petty': idPetty,
        'tgl': tglBayar,
        'keterangan': 'Pembayaran CASH split: $keterangan',
        'in_cash': nominal,
        'out_cash': 0,
        'bukti_petty': '',
        'dibuat_oleh': dibuatOleh,
        'dibuat_tgl': dibuatTgl,
        'diubah_oleh': dibuatOleh,
        'diubah_tgl': dibuatTgl,
        'id_cabang': idCabang,
        'sts': sts,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
}

Future<List<Map<String, dynamic>>> getUnsyncedPembayaran() async {
  final db = await database;
  final List<Map<String, dynamic>> result =
      await db.query('tb_pembayaran', where: 'sts = ?', whereArgs: [0]);
  return result;
}



Future<void> trySyncIfOnline() async {
  try {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none) {
      print("📶 Online: Mulai sinkronisasi transaksi");

      // Ambil data split yang belum disinkron
      final pembayaranSplit = await getUnsyncedPembayaran();

      // Kirim untuk sinkronisasi
      await syncTransaksiToServer(pembayaranSplit: pembayaranSplit);
    } else {
      print("📴 Offline: Tidak bisa sinkronisasi sekarang.");
    }
  } catch (e, stacktrace) {
    print("❌ Gagal cek koneksi atau sinkronisasi: $e");
    print(stacktrace);
  }
}


Future<void> syncTransaksiToServer({List<Map<String, dynamic>>? pembayaranSplit}) async {
  final db = await database;

  final List<Map<String, dynamic>> unsynced =
      await db.query('tb_barang_keluar', where: 'is_synced = 0');

  if (unsynced.isEmpty && (pembayaranSplit == null || pembayaranSplit.isEmpty)) {
    print("✅ Semua transaksi dan pembayaran sudah disinkronkan.");
    return;
  }

  pembayaranSplit ??= [];

  // Simpan dulu pembayaranSplit ke SQLite
  for (final pembayaran in pembayaranSplit) {
    final metode = pembayaran['metode'];
    final nominalStr = pembayaran['nominal'] ?? pembayaran['jumlah'] ?? '0';
    final nominal = int.tryParse(nominalStr.toString().replaceAll('.', '')) ?? 0;

    final tglBayar = pembayaran['tgl_bayar'] ?? DateTime.now().toIso8601String();
    final idPembayaran = pembayaran['id_transaksi'] ?? pembayaran['id_pembayaran'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    final keterangan = pembayaran['keterangan'] ?? '';
    final dibuatOleh = pembayaran['dibuat_oleh'] ?? 'system';
    final dibuatTgl = pembayaran['dibuat_tgl'] ?? DateTime.now().toIso8601String();
    final idCabang = pembayaran['id_cabang'] ?? '';
    final sts = 1;

    // Simpan ke tb_pembayaran
    await db.insert('tb_pembayaran', {
      'id_pembayaran': idPembayaran,
      'tgl_bayar': tglBayar,
      'metode': metode,
      'nominal': nominal,
      'keterangan': keterangan,
      'dibuat_oleh': dibuatOleh,
      'dibuat_tgl': dibuatTgl,
      'id_cabang': idCabang,
      'sts': sts,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    // Jika metode CASH, simpan juga ke tb_petty_cash
    if (metode.toUpperCase() == 'CASH') {
      final idPetty = DateTime.now().millisecondsSinceEpoch.toString();

      await db.insert('tb_petty_cash', {
        'id_petty': idPetty,
        'tgl': tglBayar,
        'keterangan': 'Pembayaran CASH split: $keterangan',
        'in_cash': nominal,
        'out_cash': 0,
        'bukti_petty': '',
        'dibuat_oleh': dibuatOleh,
        'dibuat_tgl': dibuatTgl,
        'diubah_oleh': dibuatOleh,
        'diubah_tgl': dibuatTgl,
        'id_cabang': idCabang,
        'sts': sts,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // Lanjutkan proses sinkronisasi transaksi seperti semula
  final Map<String, List<Map<String, dynamic>>> groupedByInvoice = {};
  for (final row in unsynced) {
    final invoiceId = row['id_invoice'];
    if (invoiceId == null) continue;
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
      "pembayaranSplit": pembayaranSplit,
    };

    print("📤 Kirim data transaksi ke server:");
    print(jsonEncode(body));

    try {
      final response = await http.post(
        Uri.parse('https://hayami.id/pos/takepayment.php'),
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

    // Update sts jadi 1 untuk pembayaran yang sudah dikirim
    for (final pembayaran in pembayaranSplit) {
      final idPembayaran = pembayaran['id_transaksi'] ?? pembayaran['id_pembayaran'];
      if (idPembayaran != null) {
        await db.update(
          'tb_pembayaran',
          {'sts': 1},
          where: 'id_pembayaran = ?',
          whereArgs: [idPembayaran],
        );
      }
    }

    print("✅ Sync berhasil: $invoiceId");
  } else {
    print("❌ Gagal simpan di server: ${resData['message']}");
  }
}
 else {
        print("❌ HTTP ${response.statusCode} saat sync $invoiceId");
      }
    } catch (e, stacktrace) {
      print("❌ Gagal koneksi saat sync $invoiceId: $e");
      print(stacktrace);
    }
  }
}
}
