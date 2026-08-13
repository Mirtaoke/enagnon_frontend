import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/storage/local_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';

class ApiProvider {
  final http.Client _client;

  ApiProvider({http.Client? client}) : _client = client ?? http.Client();

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(LocalStorageKeys.apiToken);
  }

  Map<String, String> _headers(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(String endpoint, {String? token}) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConstants.baseUrl}$endpoint'),
            headers: _headers(token),
          )
          .timeout(ApiConstants.requestTimeout);
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<int>> getBytes(String endpoint, {String? token}) async {
    final response = await _client
        .get(
          Uri.parse('${ApiConstants.baseUrl}$endpoint'),
          headers: _headers(token),
        )
        .timeout(ApiConstants.requestTimeout);
    if (response.statusCode == 200) return response.bodyBytes;
    throw Exception('Export impossible (${response.statusCode})');
  }

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConstants.baseUrl}$endpoint'),
            headers: _headers(token),
            body: jsonEncode(body),
          )
          .timeout(ApiConstants.requestTimeout);
      return _handleResponse(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> put(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final response = await _client
        .put(
          Uri.parse('${ApiConstants.baseUrl}$endpoint'),
          headers: _headers(token),
          body: jsonEncode(body),
        )
        .timeout(ApiConstants.requestTimeout);
    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint, {String? token}) async {
    final response = await _client
        .delete(
          Uri.parse('${ApiConstants.baseUrl}$endpoint'),
          headers: _headers(token),
        )
        .timeout(ApiConstants.requestTimeout);
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.trim().isEmpty) {
        return null;
      }
      return jsonDecode(response.body);
    }
    var message = 'Une erreur est survenue (${response.statusCode}).';
    try {
      final body = jsonDecode(response.body);
      if (body is Map && body['message'] != null) {
        message = '${body['message']}';
      }
    } catch (_) {}
    throw ApiException(response.statusCode, message);
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;
  const ApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}
