import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> saveToken(String token) async {
    await init();
    await _prefs?.setString(_tokenKey, token);
  }

  static String? getToken() {
    return _prefs?.getString(_tokenKey);
  }

  static Future<void> saveUser(Map<String, dynamic> userMap) async {
    await init();
    await _prefs?.setString(_userKey, jsonEncode(userMap));
  }

  static Map<String, dynamic>? getUser() {
    final raw = _prefs?.getString(_userKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearAll() async {
    await init();
    await _prefs?.remove(_tokenKey);
    await _prefs?.remove(_userKey);
  }
}
