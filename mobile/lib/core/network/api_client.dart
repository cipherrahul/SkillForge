import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:skillforge_student/core/constants/app_constants.dart';

class ApiClient {
  static const _storage = FlutterSecureStorage();

  static Future<String?> _getToken() async {
    return await _storage.read(key: AppConstants.tokenKey);
  }

  static Future<Map<String, String>> _authHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  static Future<http.Response> get(String url) async {
    final headers = await _authHeaders();
    return http.get(Uri.parse(url), headers: headers);
  }

  static Future<http.Response> post(String url, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    return http.post(Uri.parse(url), headers: headers,
        body: jsonEncode(body));
  }

  static Future<http.Response> put(String url, Map<String, dynamic> body) async {
    final headers = await _authHeaders();
    return http.put(Uri.parse(url), headers: headers,
        body: jsonEncode(body));
  }

  static Future<http.Response> delete(String url) async {
    final headers = await _authHeaders();
    return http.delete(Uri.parse(url), headers: headers);
  }
}
