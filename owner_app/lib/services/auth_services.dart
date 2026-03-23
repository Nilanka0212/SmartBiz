import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AuthService {
  static const String _tokenKey = 'owner_token';
  static const String _ownerKey = 'owner_data';

  // ── Save login data ──
  static Future<void> saveLogin({
    required String token,
    required Map<String, dynamic> owner,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_ownerKey, jsonEncode(owner));
  }

  // ── Check if logged in ──
  // No time limit — stays logged in until
  // cache cleared or manually logged out
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    return token != null; // ← just checks if token exists
  }

  // ── Get saved owner data ──
  static Future<Map<String, dynamic>?> getOwner() async {
    final prefs    = await SharedPreferences.getInstance();
    final ownerStr = prefs.getString(_ownerKey);
    if (ownerStr == null) return null;
    return jsonDecode(ownerStr);
  }

  // ── Get saved token ──
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // ── Clear login (logout) ──
  static Future<void> clearLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_ownerKey);
  }
}