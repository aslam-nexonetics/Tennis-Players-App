import 'package:flutter/material.dart';
import 'dart:async';
import '../models/football_player.dart';
import '../services/api_service.dart';

class FootballPlayerProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<FootballPlayer> _players = [];
  List<FootballPlayer> get players => _players;

  List<FootballPlayer> _topPlayers = [];
  List<FootballPlayer> get topPlayers => _topPlayers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Timer? _debounce;

  Future<void> fetchTopPlayers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _topPlayers = await _apiService.getFootballTopPlayers(limit: 50);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void onSearchChanged(String query) {
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
      final response = await _apiService.searchFootballPlayers(query);
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
