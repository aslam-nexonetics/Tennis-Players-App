import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' as http;
import '../providers/auth_provider.dart';
import 'auth_api_service.dart';

class JwtUtils {
  /// Decodes a JWT token string without external libraries and returns its payload map.
  static Map<String, dynamic>? parseJwtPayload(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final resp = utf8.decode(base64Url.decode(normalized));
      return json.decode(resp) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  /// Checks if a JWT token is expired or expiring within [threshold].
  static bool isTokenExpiringSoon(String token, {Duration threshold = const Duration(seconds: 60)}) {
    final payload = parseJwtPayload(token);
    if (payload == null || !payload.containsKey('exp')) return true;
    final expSeconds = payload['exp'];
    if (expSeconds is! int && expSeconds is! double) return true;
    final expDate = DateTime.fromMillisecondsSinceEpoch((expSeconds as num).toInt() * 1000, isUtc: true);
    final now = DateTime.now().toUtc();
    return expDate.subtract(threshold).isBefore(now);
  }
}

class AuthenticatedClient {
  final AuthProvider authProvider;
  final http.Client _client;

  AuthenticatedClient(this.authProvider, [http.Client? client])
      : _client = client ?? http.Client();

  Map<String, String> _buildHeaders(String? token, Map<String, String>? extraHeaders) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Executes an HTTP request with automatic token validation, 401 interception, and retry.
  Future<http.Response> request({
    required String method,
    required Uri url,
    Map<String, String>? headers,
    Object? body,
  }) async {
    // 1. Get valid access token (refreshes preemptively if expiring soon)
    String? token = await authProvider.getValidAccessToken();

    // 2. Perform original request
    final reqHeaders = _buildHeaders(token, headers);
    http.Response response = await _sendRequest(method, url, reqHeaders, body);

    // 3. Handle 401 Unauthorized by attempting token refresh and retrying request once
    if (response.statusCode == 401) {
      debugPrint('[AUTH CLIENT] Received 401 for $url. Attempting refresh token exchange...');
      final refreshed = await authProvider.refreshAccessToken();
      if (refreshed) {
        token = authProvider.accessToken;
        debugPrint('[AUTH CLIENT] Token refreshed successfully. Retrying request to $url');
        final retryHeaders = _buildHeaders(token, headers);
        response = await _sendRequest(method, url, retryHeaders, body);
      } else {
        debugPrint('[AUTH CLIENT] Token refresh failed. Request unauthorized.');
        throw AuthApiException('Session expired. Please sign in again.', statusCode: 401);
      }
    }

    return response;
  }

  Future<http.Response> get(Uri url, {Map<String, String>? headers}) =>
      request(method: 'GET', url: url, headers: headers);

  Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body}) =>
      request(method: 'POST', url: url, headers: headers, body: body);

  Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body}) =>
      request(method: 'PUT', url: url, headers: headers, body: body);

  Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body}) =>
      request(method: 'DELETE', url: url, headers: headers, body: body);

  Future<http.Response> _sendRequest(
    String method,
    Uri url,
    Map<String, String> headers,
    Object? body,
  ) async {
    switch (method.toUpperCase()) {
      case 'GET':
        return await _client.get(url, headers: headers);
      case 'POST':
        return await _client.post(url, headers: headers, body: body);
      case 'PUT':
        return await _client.put(url, headers: headers, body: body);
      case 'DELETE':
        return await _client.delete(url, headers: headers, body: body);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }
}
