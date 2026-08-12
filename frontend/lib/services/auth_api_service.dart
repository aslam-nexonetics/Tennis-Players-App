import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:http/http.dart' as http;
import '../models/user.dart';

class AuthApiException implements Exception {
  final String message;
  final int? statusCode;

  AuthApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class AuthApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://192.168.29.84:8000';
    }
    return 'http://localhost:8000';
  }

  static Map<String, String> _headers([String? token]) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static String _parseError(http.Response response) {
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map && decoded.containsKey('detail')) {
        final detail = decoded['detail'];
        if (detail is String) return detail;
        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first.containsKey('msg')) {
            return first['msg'].toString();
          }
          return detail.join(', ');
        }
      }
    } catch (_) {}
    return 'HTTP Error ${response.statusCode}: ${response.reasonPhrase ?? 'Request failed'}';
  }

  static Future<AuthTokenResponse> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final payload = {
      'email': email.trim().toLowerCase(),
      'username': username.trim(),
      'password': password,
      'full_name': fullName?.trim().isEmpty ?? true ? null : fullName?.trim(),
    };
    debugPrint('[AUTH API] POST $url | payload: ${json.encode(payload)}');

    try {
      final response = await http.post(
        url,
        headers: _headers(),
        body: json.encode(payload),
      );

      debugPrint('[AUTH API] Response status: ${response.statusCode} | body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return AuthTokenResponse.fromJson(decoded);
      } else {
        final errorMsg = _parseError(response);
        throw AuthApiException(errorMsg, statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('[AUTH API ERROR] register: $e');
      if (e is AuthApiException) rethrow;
      throw AuthApiException('Cannot connect to server at $baseUrl. Please verify the backend API server is running on port 8000.');
    }
  }

  static Future<AuthTokenResponse> login({
    required String identifier,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final payload = {
      'username_or_email': identifier.trim(),
      'password': password,
    };
    debugPrint('[AUTH API] POST $url | identifier: ${identifier.trim()}');

    try {
      final response = await http.post(
        url,
        headers: _headers(),
        body: json.encode(payload),
      );

      debugPrint('[AUTH API] Response status: ${response.statusCode} | body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return AuthTokenResponse.fromJson(decoded);
      } else {
        final errorMsg = _parseError(response);
        throw AuthApiException(errorMsg, statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('[AUTH API ERROR] login: $e');
      if (e is AuthApiException) rethrow;
      throw AuthApiException('Cannot connect to server at $baseUrl. Please verify the backend API server is running on port 8000.');
    }
  }

  static Future<AuthTokenResponse> refreshToken(String refreshToken) async {
    final url = Uri.parse('$baseUrl/auth/refresh');
    debugPrint('[AUTH API] POST $url');

    try {
      final response = await http.post(
        url,
        headers: _headers(),
        body: json.encode({'refresh_token': refreshToken}),
      );

      debugPrint('[AUTH API] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return AuthTokenResponse.fromJson(decoded);
      } else {
        throw AuthApiException(_parseError(response), statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('[AUTH API ERROR] refreshToken: $e');
      if (e is AuthApiException) rethrow;
      throw AuthApiException('Failed to refresh authentication session.');
    }
  }

  static Future<void> logout(String refreshToken) async {
    final url = Uri.parse('$baseUrl/auth/logout');
    debugPrint('[AUTH API] POST $url');
    try {
      await http.post(
        url,
        headers: _headers(),
        body: json.encode({'refresh_token': refreshToken}),
      );
    } catch (e) {
      debugPrint('[AUTH API ERROR] logout: $e');
    }
  }

  static Future<User> fetchProfile(String accessToken) async {
    final url = Uri.parse('$baseUrl/auth/me');
    debugPrint('[AUTH API] GET $url');
    try {
      final response = await http.get(url, headers: _headers(accessToken));
      debugPrint('[AUTH API] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return User.fromJson(decoded);
      } else {
        throw AuthApiException(_parseError(response), statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('[AUTH API ERROR] fetchProfile: $e');
      if (e is AuthApiException) rethrow;
      throw AuthApiException('Could not load user profile.');
    }
  }

  static Future<User> updateProfile({
    required String accessToken,
    String? fullName,
    String? email,
  }) async {
    final url = Uri.parse('$baseUrl/auth/me');
    final Map<String, dynamic> body = {};
    if (fullName != null) body['full_name'] = fullName.trim();
    if (email != null && email.isNotEmpty) body['email'] = email.trim().toLowerCase();
    debugPrint('[AUTH API] PUT $url');

    try {
      final response = await http.put(
        url,
        headers: _headers(accessToken),
        body: json.encode(body),
      );
      debugPrint('[AUTH API] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return User.fromJson(decoded);
      } else {
        throw AuthApiException(_parseError(response), statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('[AUTH API ERROR] updateProfile: $e');
      if (e is AuthApiException) rethrow;
      throw AuthApiException('Failed to update profile details.');
    }
  }

  static Future<String> changePassword({
    required String accessToken,
    required String currentPassword,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/auth/me/password');
    debugPrint('[AUTH API] POST $url');
    try {
      final response = await http.post(
        url,
        headers: _headers(accessToken),
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );
      debugPrint('[AUTH API] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded['message'] ?? 'Password successfully updated';
      } else {
        throw AuthApiException(_parseError(response), statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('[AUTH API ERROR] changePassword: $e');
      if (e is AuthApiException) rethrow;
      throw AuthApiException('Failed to change password.');
    }
  }

  static Future<String> forgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/auth/forgot-password');
    debugPrint('[AUTH API] POST $url');
    try {
      final response = await http.post(
        url,
        headers: _headers(),
        body: json.encode({'email': email.trim().toLowerCase()}),
      );
      debugPrint('[AUTH API] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded['message'] ?? 'If an account exists, a reset link has been sent.';
      } else {
        throw AuthApiException(_parseError(response), statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('[AUTH API ERROR] forgotPassword: $e');
      if (e is AuthApiException) rethrow;
      throw AuthApiException('Failed to process forgot password request.');
    }
  }

  static Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final url = Uri.parse('$baseUrl/auth/reset-password');
    debugPrint('[AUTH API] POST $url');
    try {
      final response = await http.post(
        url,
        headers: _headers(),
        body: json.encode({
          'token': token.trim(),
          'new_password': newPassword,
        }),
      );
      debugPrint('[AUTH API] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        return decoded['message'] ?? 'Password reset successfully.';
      } else {
        throw AuthApiException(_parseError(response), statusCode: response.statusCode);
      }
    } catch (e) {
      debugPrint('[AUTH API ERROR] resetPassword: $e');
      if (e is AuthApiException) rethrow;
      throw AuthApiException('Failed to reset password.');
    }
  }
}
