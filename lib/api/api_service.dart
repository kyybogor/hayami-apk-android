import 'dart:convert';
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
  static const String _baseUrl = 'http://192.168.1.8/hayami/loginpos.php';

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
        return {'status': 'error', 'message': 'Gagal koneksi ke server (POS).'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi error (POS): $e'};
    }
  }
}
