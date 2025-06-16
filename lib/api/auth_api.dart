import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:faceabsensiapp/utils/app_constants.dart';

class AuthApi {
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        throw Exception(errorData['message'] ?? 'Respons tidak diketahui');
      }
    } catch (e) {
      String errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      if (e is http.ClientException && e.message.contains('Failed host lookup')) {
        errorMessage = 'Tidak dapat terhubung ke server. Pastikan URL server benar dan perangkat terhubung ke internet.';
      } else if (e is TimeoutException) {
        errorMessage = 'Permintaan ke server memakan waktu terlalu lama. Periksa koneksi internet atau status server.';
      }
      throw Exception(errorMessage);
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_name');
    await prefs.remove('user_id');
    await prefs.remove('is_face_recorded');
  }
}
