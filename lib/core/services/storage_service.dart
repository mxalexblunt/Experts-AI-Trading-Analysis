import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_error.dart';

class StorageService {
  StorageService({SharedPreferences? preferences}) : _preferences = preferences;

  SharedPreferences? _preferences;

  Future<SharedPreferences> get _prefs async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  Future<Map<String, dynamic>?> readJson(String key) async {
    final raw = (await _prefs).getString(key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      throw const FormatException('Stored value is not a JSON object.');
    } catch (error) {
      throw AppError(
        message: 'Saved data could not be read.',
        type: AppErrorType.invalidData,
        cause: error,
      );
    }
  }

  Future<List<Map<String, dynamic>>> readJsonList(String key) async {
    final raw = (await _prefs).getString(key);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('Stored value is not a JSON list.');
      }

      return decoded
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(growable: false);
    } catch (error) {
      throw AppError(
        message: 'Saved list could not be read.',
        type: AppErrorType.invalidData,
        cause: error,
      );
    }
  }

  Future<void> writeJson(String key, Map<String, dynamic> value) async {
    await (await _prefs).setString(key, jsonEncode(value));
  }

  Future<void> writeJsonList(
    String key,
    List<Map<String, dynamic>> values,
  ) async {
    await (await _prefs).setString(key, jsonEncode(values));
  }

  Future<List<String>> readStringList(String key) async {
    return (await _prefs).getStringList(key) ?? const [];
  }

  Future<void> writeStringList(String key, List<String> values) async {
    await (await _prefs).setStringList(key, values);
  }

  Future<void> remove(String key) async {
    await (await _prefs).remove(key);
  }
}
