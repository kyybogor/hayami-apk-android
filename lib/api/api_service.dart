import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String _baseUrl = 'http://192.168.1.10/connect/JSON/login.php';

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
        return {'status': 'error', 'message': 'Gagal koneksi ke server.'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Terjadi error: $e'};
    }
  }
}
