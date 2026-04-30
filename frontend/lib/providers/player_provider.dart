import 'package:flutter/material.dart';
import 'dart:async';
import '../models/player.dart';
import '../services/api_service.dart';

class PlayerProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Player> _players = [];
  List<Player> get players => _players;

  List<Player> _topPlayers = [];
  List<Player> get topPlayers => _topPlayers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String? _selectedGender; // null for both, "M" for ATP, "F" for WTA
  String? get selectedGender => _selectedGender;

  Timer? _debounce;
  String _lastQuery = '';
  String get lastQuery => _lastQuery;

  void setGender(String? gender) {
    if (_selectedGender != gender) {
      _selectedGender = gender;
      fetchTopPlayers();
      if (_lastQuery.isNotEmpty) {
        searchPlayers(_lastQuery);
      }
      notifyListeners();
    }
  }

  Future<void> fetchTopPlayers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _topPlayers = await _apiService.getTopPlayers(gender: _selectedGender);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void onSearchChanged(String query) {
    _lastQuery = query;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        searchPlayers(query);
      } else {
        _players = [];
        notifyListeners();
      }
    });
  }

  Future<void> searchPlayers(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response =
          await _apiService.searchPlayers(query, gender: _selectedGender);
      _players = response.items;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
