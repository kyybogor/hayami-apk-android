import 'dart:convert';
import 'package:hayami_app/Login/LoginHelper.dart';
import 'package:http/http.dart' as http;

class GudangApiService {
  static const String _baseUrl = 'https://hayami.id/apps/erp/api-android/api/login.php';

  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {'status': 'error', 'message': 'Gagal koneksi ke server (Gudang).'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi error (Gudang): $e'};
    }
  }
}
class PosApiService {
  static const String _baseUrl = 'http://192.168.1.9/hayami/loginpos.php';

  /// Fungsi login user (online dulu, jika gagal coba offline)
  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    try {
      print('Login online: user=$email');
      final response = await http.post(
        Uri.parse(_baseUrl),
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        print('Response API: $result');

        if (result['status'] == 'success') {
          final user = result['user'];

          // Simpan data user ke SQLite dengan password plain dari input user
          await LoginSQLiteHelper.insertOrUpdateUser({
            'id_karyawan': user['id_karyawan'],
            'user_id': user['id_user'],
            'pass': password, // simpan password plain untuk login offline
            'nama_lengkap': user['nm_user'],
            'alamat': user['alamat'],
            'no_telp': user['no_telp'],
            'grup': user['grup'],
            'jenis_pajak': user['jenis_pajak'],
            'cabang': user['id_cabang'],
          });

          return result;
        } else {
          print('Login online gagal, coba offline...');
          return await _tryOfflineLogin(email, password);
        }
      } else {
        print('Server error status: ${response.statusCode}');
        return await _tryOfflineLogin(email, password);
      }
    } catch (e) {
      print('Exception saat login online: $e');
      return await _tryOfflineLogin(email, password);
    }
  }

  /// Coba login offline dari SQLite
static Future<Map<String, dynamic>> _tryOfflineLogin(String email, String password) async {
  print('Mencoba login offline...');
  final localUser = await LoginSQLiteHelper.getUserByCredentials(email, password);
  if (localUser != null) {
    print('Login offline berhasil: $localUser');

    // Mapping ulang field ke format yang diinginkan
    final mappedUser = {
      "id_karyawan": localUser["id_karyawan"] ?? "",
      "id_user": localUser["user_id"] ?? "",
      "nm_user": localUser["nama_lengkap"] ?? "",
      "alamat": localUser["alamat"] ?? "",
      "no_telp": localUser["no_telp"] ?? "",
      "grup": localUser["grup"] ?? "",
      "jenis_pajak": localUser["jenis_pajak"] ?? "",
      "id_cabang": localUser["cabang"] ?? "",
    };

    return {
      'status': 'success',
      'message': 'Login offline berhasil',
      'user': mappedUser,
    };
  } else {
    print('Login offline gagal, user tidak ditemukan');
    return {
      'status': 'error',
      'message': 'User untuk POS tidak ditemukan.',
    };
  }
}
}