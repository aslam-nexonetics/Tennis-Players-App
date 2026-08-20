import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_api_service.dart';
import '../services/authenticated_client.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  String? _accessToken;
  String? _refreshToken;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  Completer<bool>? _refreshCompleter;

  User? get user => _user;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isLoggedIn => _user != null && _accessToken != null;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;

  static const String _keyAccessToken = 'auth_access_token';
  static const String _keyRefreshToken = 'auth_refresh_token';
  static const String _keyUserData = 'auth_user_data';

  AuthProvider() {
    initializeAuth();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Thread-safe token refresh mechanism with mutex lock using Completer.
  Future<bool> refreshAccessToken() async {
    // If a refresh operation is already in progress, await its result
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    if (_refreshToken == null || _refreshToken!.isEmpty) {
      await logout();
      return false;
    }

    final completer = Completer<bool>();
    _refreshCompleter = completer;

    try {
      debugPrint('[AUTH PROVIDER] Exchanging refresh token for new access token...');
      final tokenRes = await AuthApiService.refreshToken(_refreshToken!);
      _accessToken = tokenRes.accessToken;
      _refreshToken = tokenRes.refreshToken;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAccessToken, _accessToken!);
      await prefs.setString(_keyRefreshToken, _refreshToken!);

      if (_user == null) {
        try {
          _user = await AuthApiService.fetchProfile(_accessToken!);
          await _saveUserToPrefs(_user!);
        } catch (_) {}
      }

      notifyListeners();
      completer.complete(true);
      return true;
    } catch (e) {
      debugPrint('[AUTH PROVIDER] Refresh token exchange failed: $e');
      await logout();
      completer.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  /// Returns a valid access token. Automatically triggers token refresh if expiring soon.
  Future<String?> getValidAccessToken() async {
    if (_accessToken == null || _refreshToken == null) {
      return null;
    }

    if (JwtUtils.isTokenExpiringSoon(_accessToken!)) {
      debugPrint('[AUTH PROVIDER] Token expiring soon. Triggering preemptive refresh...');
      final success = await refreshAccessToken();
      if (!success) return null;
    }

    return _accessToken;
  }

  Future<void> initializeAuth() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_keyAccessToken);
      _refreshToken = prefs.getString(_keyRefreshToken);
      final rawUser = prefs.getString(_keyUserData);

      if (rawUser != null) {
        try {
          _user = User.fromJson(json.decode(rawUser));
        } catch (_) {}
      }

      if (_accessToken != null) {
        // Verify current token or refresh if needed
        try {
          _user = await AuthApiService.fetchProfile(_accessToken!);
          await _saveUserToPrefs(_user!);
        } catch (e) {
          // Access token might be expired, try refresh token
          if (_refreshToken != null) {
            await refreshAccessToken();
          } else {
            await _clearPrefs();
          }
        }
      }
    } catch (_) {
      // Local storage read error fallback
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<bool> login({
    required String identifier,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authRes = await AuthApiService.login(
        identifier: identifier,
        password: password,
      );
      _accessToken = authRes.accessToken;
      _refreshToken = authRes.refreshToken;
      _user = authRes.user;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAccessToken, _accessToken!);
      await prefs.setString(_keyRefreshToken, _refreshToken!);
      if (_user != null) {
        await _saveUserToPrefs(_user!);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String username,
    required String password,
    String? fullName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authRes = await AuthApiService.register(
        email: email,
        username: username,
        password: password,
        fullName: fullName,
      );
      _accessToken = authRes.accessToken;
      _refreshToken = authRes.refreshToken;
      _user = authRes.user;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAccessToken, _accessToken!);
      await prefs.setString(_keyRefreshToken, _refreshToken!);
      if (_user != null) {
        await _saveUserToPrefs(_user!);
      }

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    if (_refreshToken != null) {
      AuthApiService.logout(_refreshToken!);
    }
    await _clearPrefs();
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> updateProfile({String? fullName, String? email}) async {
    final validToken = await getValidAccessToken();
    if (validToken == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await AuthApiService.updateProfile(
        accessToken: validToken,
        fullName: fullName,
        email: email,
      );
      _user = updatedUser;
      await _saveUserToPrefs(_user!);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final validToken = await getValidAccessToken();
    if (validToken == null) return false;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await AuthApiService.changePassword(
        accessToken: validToken,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<String?> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final msg = await AuthApiService.forgotPassword(email);
      _isLoading = false;
      notifyListeners();
      return msg;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<String?> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final msg = await AuthApiService.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      _isLoading = false;
      notifyListeners();
      return msg;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<void> _saveUserToPrefs(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserData, json.encode(user.toJson()));
  }

  Future<void> _clearPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyUserData);
  }
}
