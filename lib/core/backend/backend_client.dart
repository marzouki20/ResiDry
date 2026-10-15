import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class BackendException implements Exception {
  const BackendException(this.code);
  final String code;
}

/// Tokens stay in memory; users sign in again after restarting the app.
class BackendClient {
  static const baseUrl = String.fromEnvironment('RESIDRY_API_URL');
  static bool get enabled => baseUrl.isNotEmpty;
  static String? _token;
  static Map<String, dynamic>? account;

  static bool _isPrivateDevelopmentHost(String host) {
    if (host == '127.0.0.1' || host == 'localhost' || host == '10.0.2.2') {
      return true;
    }
    final parts = host.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((part) => part == null)) return false;
    final values = parts.cast<int>();
    if (values.any((part) => part < 0 || part > 255)) return false;
    return values[0] == 10 ||
        (values[0] == 172 && values[1] >= 16 && values[1] <= 31) ||
        (values[0] == 192 && values[1] == 168);
  }

  static const roles = {
    'Livreur': 'DRIVER',
    'Administrateur': 'ADMIN',
    'Résident': 'RESIDENT',
    'Société de lavage': 'LAUNDRY'
  };

  static Future<Map<String, dynamic>> authenticate(
      String path, Map<String, dynamic> data) async {
    final value = await request(path, method: 'POST', body: data);
    if (value is! Map<String, dynamic> ||
        value['token'] is! String ||
        (value['token'] as String).isEmpty ||
        value['account'] is! Map<String, dynamic>) {
      throw const BackendException('invalid_response');
    }
    _token = value['token'] as String;
    account = value['account'] as Map<String, dynamic>;
    return account!;
  }

  static Future<void> logout() async {
    try {
      if (_token != null) await request('/api/auth/logout', method: 'POST');
    } finally {
      _token = null;
      account = null;
    }
  }

  static Future<dynamic> request(String path,
      {String method = 'GET', Map<String, dynamic>? body}) async {
    final response = await _send(path, method: method, body: body);
    if (response.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response));
    } catch (_) {
      throw const BackendException('invalid_response');
    }
  }

  static Future<List<int>> document(String path) => _send(path);
  static Future<List<int>> _send(String path,
      {String method = 'GET', Map<String, dynamic>? body}) async {
    if (!enabled) throw const BackendException('not_configured');
    final uri = Uri.parse('${baseUrl.replaceAll(RegExp(r'/$'), '')}$path');
    if (uri.scheme != 'https' &&
        (kReleaseMode ||
            uri.scheme != 'http' ||
            !_isPrivateDevelopmentHost(uri.host))) {
      throw const BackendException('https_required');
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client
          .openUrl(method, uri)
          .timeout(const Duration(seconds: 15));
      if (_token != null) req.headers.set('Authorization', 'Bearer $_token');
      if (body != null) {
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode(body));
      }
      final res = await req.close().timeout(const Duration(seconds: 350));
      final bytes = await res
          .fold<List<int>>([], (value, part) => value..addAll(part)).timeout(
              const Duration(seconds: 30));
      if (res.statusCode >= 400) {
        String code = 'server_error';
        try {
          code = (jsonDecode(utf8.decode(bytes)) as Map)['error'] as String;
        } catch (_) {}
        throw BackendException(code);
      }
      return bytes;
    } on BackendException {
      rethrow;
    } catch (_) {
      throw const BackendException('connection_failed');
    } finally {
      client.close(force: true);
    }
  }
}
