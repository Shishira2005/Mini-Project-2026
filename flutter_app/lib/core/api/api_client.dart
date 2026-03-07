// Lightweight HTTP client wrapper used by feature services.
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({required this.baseUrl, http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _httpClient;

  Future<dynamic> get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final response = await _httpClient.get(uri);
    return _decodeResponse(response);
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _httpClient.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body ?? {}),
    );
    return _decodeResponse(response);
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _httpClient.patch(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body ?? {}),
    );
    return _decodeResponse(response);
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _httpClient.put(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body ?? {}),
    );
    return _decodeResponse(response);
  }

  Future<dynamic> delete(String path) async {
    final uri = Uri.parse('$baseUrl$path');
    final response = await _httpClient.delete(uri);
    return _decodeResponse(response);
  }

  dynamic _decodeResponse(http.Response response) {
    final payload = response.body.isEmpty ? {} : jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return payload;
    }

    final message = payload is Map<String, dynamic>
        ? payload['message']?.toString() ?? 'Request failed'
        : 'Request failed';
    throw Exception(message);
  }
}
