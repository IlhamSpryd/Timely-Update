// lib/services/auth_services.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timely/models/register_models.dart' as register_model;

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  static const String _keyIsLoggedIn = 'isLoggedIn';
  static const String _keyUserEmail = 'userEmail';
  static const String _keyUserName = 'userName';
  static const String _keyAuthToken = 'authToken';
  static const String _keyUserProfilePhotoUrl = 'userProfilePhotoUrl';
  static const String _keyUserData = 'userData';
  static const String _keyHasSeenOnboarding = 'hasSeenOnboarding';

  /// Menyimpan data autentikasi setelah login atau registrasi berhasil.
  /// Menerima objek [Data] dari [RegisterModel] untuk kelengkapan.
  Future<void> saveAuthData(register_model.Data authData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyAuthToken, authData.token);
    await prefs.setString(_keyUserEmail, authData.user.email);
    await prefs.setString(_keyUserName, authData.user.name);
    await prefs.setString(_keyUserProfilePhotoUrl, authData.profilePhotoUrl);

    // Simpan seluruh data user sebagai JSON string untuk penggunaan di masa depan
    await prefs.setString(_keyUserData, jsonEncode(authData.user.toJson()));
  }

  // Fungsi saveLogin yang lebih sederhana jika masih diperlukan untuk alur login
  Future<void> saveLogin(String email, String token, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserEmail, email);
    await prefs.setString(_keyUserName, name);
    await prefs.setString(_keyAuthToken, token);
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserEmail);
    await prefs.remove(_keyUserName);
    await prefs.remove(_keyAuthToken);
    await prefs.remove(_keyUserProfilePhotoUrl);
    await prefs.remove(_keyUserData);
  }

  Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserEmail);
  }

  Future<String?> getCurrentUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName);
  }

  Future<String?> getCurrentUserProfilePhotoUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserProfilePhotoUrl);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAuthToken);
  }

  // Mengambil data user lengkap dari SharedPreferences
  Future<register_model.User?> getFullUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_keyUserData);
    if (userDataString != null) {
      return register_model.User.fromJson(json.decode(userDataString));
    }
    return null;
  }

  Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSeenOnboarding) ?? false;
  }

  Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSeenOnboarding, true);
  }
}
