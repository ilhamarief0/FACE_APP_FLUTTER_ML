import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:faceabsensiapp/utils/app_constants.dart';
import 'package:faceabsensiapp/models/absensi_history_item.dart';

class AbsensiApi {
  Future<List<dynamic>> fetchKelasData(String token) async {
    final response = await http.get(
      Uri.parse('$apiUrl/kelas'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData['data'] is List) {
        return responseData['data'];
      } else {
        throw Exception('Format data kelas tidak sesuai.');
      }
    } else if (response.statusCode == 401) {
      throw Exception('Sesi habis. Silakan login kembali.');
    } else {
      final Map<String, dynamic> errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Gagal memuat data kelas.');
    }
  }

  Future<List<AbsensiHistoryItem>> fetchAbsensiHistory(String token) async {
    final response = await http.get(
      Uri.parse('$apiUrl/absensiHistory'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = json.decode(response.body);
      if (responseData['data'] is List) {
        return (responseData['data'] as List)
            .map((item) => AbsensiHistoryItem.fromJson(item))
            .toList();
      } else {
        throw Exception('Format data riwayat absensi tidak sesuai.');
      }
    } else {
      throw Exception('Gagal memuat riwayat absensi: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> enrollFace(String userId, String imagePath, String token) async {
    File imageFile = File(imagePath);
    List<int> imageBytes = await imageFile.readAsBytes();
    String base64Image = base64Encode(imageBytes);

    final response = await http.post(
      Uri.parse('$apiUrl/enroll-face'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, dynamic>{
        'id_user': userId,
        'images': [base64Image],
      }),
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      final errorData = json.decode(response.body);
      throw Exception(errorData['message'] ?? 'Gagal merekam wajah!');
    }
  }

  Future<void> processAbsensi(String userId, String kelasId, String type, String imagePath, String token) async {
    File imageFile = File(imagePath);
    List<int> imageBytes = await imageFile.readAsBytes();
    String base64Image = base64Encode(imageBytes);

    final response = await http.post(
      Uri.parse('$apiUrl/detect-face'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(<String, String>{
        'id_user': userId,
        'image': base64Image,
        'id_kelas': kelasId,
        'type': type,
      }),
    ).timeout(const Duration(seconds: 40));

    if (response.statusCode != 200) {
      final errorData = json.decode(response.body);
      String errorMessage = errorData['message'] ?? 'Absensi gagal!';
      if (errorData['errors'] != null) {
        errorMessage += '\n' + errorData['errors'].values.map((e) => e.join(', ')).join('\n');
      }
      throw Exception(errorMessage);
    }
  }
}
