import 'package:shared_preferences/shared_preferences.dart';
import '../../core/storage/local_storage.dart';
import 'dart:convert';

class StorageProvider {
  static const _pendingOperationsKey = 'pending_operations';
  static const _cachedUserKey = 'cached_user';
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LocalStorageKeys.apiToken, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(LocalStorageKeys.apiToken);
  }

  Future<void> removeToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(LocalStorageKeys.apiToken);
    await prefs.remove(_cachedUserKey);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedUserKey, jsonEncode(user));
  }

  Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_cachedUserKey);
    return value == null ? null : Map<String, dynamic>.from(jsonDecode(value));
  }

  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> saveNavigationIndex(String role, int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('navigation_index_$role', index);
  }

  Future<int> getNavigationIndex(String role) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('navigation_index_$role') ?? 0;
  }

  Future<List<Map<String, dynamic>>> getPendingOperations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingOperationsKey);
    if (raw == null || raw.isEmpty) return [];
    return (jsonDecode(raw) as List)
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  Future<void> queueOperation(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final operations = await getPendingOperations();
    operations.add({
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'endpoint': endpoint,
      'body': body,
      'queued_at': DateTime.now().toIso8601String(),
    });
    await _savePendingOperations(operations);
  }

  Future<void> removePendingOperation(String id) async {
    final operations = await getPendingOperations();
    operations.removeWhere((item) => item['id'] == id);
    await _savePendingOperations(operations);
  }

  Future<void> _savePendingOperations(
    List<Map<String, dynamic>> operations,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingOperationsKey, jsonEncode(operations));
  }
}
