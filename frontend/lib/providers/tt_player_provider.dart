import 'package:flutter/material.dart';
import 'dart:async';
import '../models/tt_player.dart';
import '../services/api_service.dart';

class TtPlayerProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<TableTennisPlayer> _players = [];
  List<TableTennisPlayer> get players => _players;

  List<TableTennisPlayer> _topPlayers = [];
  List<TableTennisPlayer> get topPlayers => _topPlayers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Gender filter: null = all, 'M' = men, 'F' = women
  String? _genderFilter;
  String? get genderFilter => _genderFilter;

  Timer? _debounce;
  String _lastQuery = '';
  String get lastQuery => _lastQuery;

  void setGenderFilter(String? gender) {
    _genderFilter = gender;
    notifyListeners();
    fetchTopPlayers();
  }

  Future<void> fetchTopPlayers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _topPlayers = await _apiService.getTtTopPlayers(
        limit: 50,
        gender: _genderFilter,
      );
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
      final response = await _apiService.searchTtPlayers(
        query,
        gender: _genderFilter,
      );
      _players = response.items;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _players = [];
    _lastQuery = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
