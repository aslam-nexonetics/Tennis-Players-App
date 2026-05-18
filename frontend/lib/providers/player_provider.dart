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

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  bool _isFetchingMore = false;
  bool get isFetchingMore => _isFetchingMore;

  String? _error;
  String? get error => _error;

  String _selectedGender = 'M'; // "M" for ATP, "F" for WTA
  String get selectedGender => _selectedGender;

  Timer? _debounce;
  String _lastQuery = '';
  String get lastQuery => _lastQuery;

  int _topPlayersPage = 1;
  bool _topPlayersHasMore = true;
  int _searchPage = 1;
  bool _searchHasMore = true;

  bool get topPlayersHasMore => _topPlayersHasMore;
  bool get searchHasMore => _searchHasMore;

  void setGender(String gender) {
    if (_selectedGender != gender) {
      _selectedGender = gender;
      _topPlayersPage = 1;
      _topPlayersHasMore = true;
      _topPlayers = [];
      fetchTopPlayers();
      if (_lastQuery.isNotEmpty) {
        _searchPage = 1;
        _searchHasMore = true;
        _players = [];
        searchPlayers(_lastQuery);
      }
      notifyListeners();
    }
  }

  Future<void> fetchTopPlayers({bool loadMore = false}) async {
    if (_isLoading || _isFetchingMore || (loadMore && !_topPlayersHasMore))
      return;

    if (loadMore) {
      _isFetchingMore = true;
    } else {
      _isLoading = true;
    }
    _error = null;
    if (!loadMore) {
      _topPlayersPage = 1;
      _topPlayersHasMore = true;
    }
    notifyListeners();

    try {
      final response = await _apiService.getPlayers(
        page: _topPlayersPage,
        gender: _selectedGender,
      );

      if (loadMore) {
        _topPlayers.addAll(response.items);
      } else {
        _topPlayers = response.items;
      }

      _topPlayersHasMore = response.items.length >= 20; // Page size is 20
      if (_topPlayersHasMore) _topPlayersPage++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  void onSearchChanged(String query) {
    _lastQuery = query;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _searchPage = 1;
        _searchHasMore = true;
        _players = [];
        searchPlayers(query);
      } else {
        _players = [];
        notifyListeners();
      }
    });
  }

  Future<void> searchPlayers(String query, {bool loadMore = false}) async {
    if (_isSearching || _isFetchingMore || (loadMore && !_searchHasMore))
      return;

    if (loadMore) {
      _isFetchingMore = true;
    } else {
      _isSearching = true;
    }
    _error = null;
    if (!loadMore) {
      _searchPage = 1;
      _searchHasMore = true;
    }
    notifyListeners();

    try {
      final response = await _apiService.searchPlayers(
        query,
        page: _searchPage,
        gender: _selectedGender,
      );

      if (loadMore) {
        _players.addAll(response.items);
      } else {
        _players = response.items;
      }

      _searchHasMore = response.items.length >= 20;
      if (_searchHasMore) _searchPage++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isSearching = false;
      _isFetchingMore = false;
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
