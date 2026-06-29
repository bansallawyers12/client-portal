import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CacheHelper {
  static const Duration defaultMaxAge = Duration(minutes: 30);

  static Future<void> saveData({
    required String key,
    required List<dynamic> data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(data.map((e) => e.toJson()).toList());
    await prefs.setString(key, jsonString);
  }

  static Future<List<T>> loadData<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    if (jsonString == null) return [];
    final List decoded = jsonDecode(jsonString);
    return decoded.map<T>((e) => fromJson(e)).toList();
  }

  static Future<void> saveEnvelope({
    required String key,
    required dynamic data,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      key,
      jsonEncode({
        'cachedAt': DateTime.now().toIso8601String(),
        'data': data,
      }),
    );
  }

  static Future<dynamic> loadEnvelope(
    String key, {
    Duration maxAge = defaultMaxAge,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(key);
    if (jsonString == null) return null;

    try {
      final envelope = jsonDecode(jsonString) as Map<String, dynamic>;
      final cachedAt = DateTime.tryParse(envelope['cachedAt']?.toString() ?? '');
      if (cachedAt == null) return null;
      if (DateTime.now().difference(cachedAt) > maxAge) return null;
      return envelope['data'];
    } catch (_) {
      return null;
    }
  }

  static Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}