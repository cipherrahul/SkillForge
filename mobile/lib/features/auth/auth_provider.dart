import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:skillforge_student/core/constants/app_constants.dart';
import 'package:skillforge_student/core/network/api_client.dart';

class AuthProvider extends ChangeNotifier {
  static const _storage = FlutterSecureStorage();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  String? _errorMessage;
  String? _userName;
  String? _userEmail;
  String? _userRole;

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  String? get errorMessage => _errorMessage;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get userRole => _userRole;

  Future<void> checkAuth() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    _isAuthenticated = token != null;
    _userName = await _storage.read(key: AppConstants.userNameKey);
    _userEmail = await _storage.read(key: AppConstants.userEmailKey);
    _userRole = await _storage.read(key: AppConstants.userRoleKey);
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // --- TEST ACCOUNT BYPASS (no backend dependency) ---
      if (email.trim() == 'test@test.com' && password == '123456') {
        await Future.delayed(const Duration(milliseconds: 800));
        await _storage.write(key: AppConstants.tokenKey, value: 'mock_token_test');
        await _storage.write(key: AppConstants.refreshTokenKey, value: 'mock_refresh_test');
        await _storage.write(key: AppConstants.userEmailKey, value: 'test@test.com');
        await _storage.write(key: AppConstants.userNameKey, value: 'Test Student');
        await _storage.write(key: AppConstants.userRoleKey, value: 'STUDENT');
        _isAuthenticated = true;
        _userEmail = 'test@test.com';
        _userName = 'Test Student';
        _userRole = 'STUDENT';
        _isLoading = false;
        notifyListeners();
        return true;
      }

      final response = await ApiClient.post(AppConstants.loginUrl, {
        'email': email.trim(),
        'password': password,
      });

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final data = body['data'];
        await _storage.write(key: AppConstants.tokenKey, value: data['accessToken']);
        await _storage.write(key: AppConstants.refreshTokenKey, value: data['refreshToken']);
        await _storage.write(key: AppConstants.userEmailKey, value: email.trim());
        await _storage.write(key: AppConstants.userNameKey, value: data['fullName'] ?? '');
        await _storage.write(key: AppConstants.userRoleKey, value: data['role'] ?? 'STUDENT');
        _isAuthenticated = true;
        _userEmail = email.trim();
        _userName = data['fullName'] ?? '';
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = body['message'] ?? 'Login failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error. Please check your connection.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String fullName, String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await ApiClient.post(AppConstants.registerUrl, {
        'fullName': fullName.trim(),
        'email': email.trim(),
        'password': password,
        'role': 'STUDENT',
      });

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        final data = body['data'];
        await _storage.write(key: AppConstants.tokenKey, value: data['accessToken']);
        await _storage.write(key: AppConstants.refreshTokenKey, value: data['refreshToken']);
        await _storage.write(key: AppConstants.userEmailKey, value: email.trim());
        await _storage.write(key: AppConstants.userNameKey, value: fullName.trim());
        await _storage.write(key: AppConstants.userRoleKey, value: 'STUDENT');
        _isAuthenticated = true;
        _userEmail = email.trim();
        _userName = fullName.trim();
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = body['message'] ?? 'Registration failed';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error. Please check your connection.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    _isAuthenticated = false;
    _userName = null;
    _userEmail = null;
    _userRole = null;
    notifyListeners();
  }
}
