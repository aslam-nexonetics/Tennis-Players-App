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

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  String? _error;
  String? get error => _error;

  // Gender filter: null = all, 'M' = men, 'F' = women
  String _genderFilter = 'M';
  String get genderFilter => _genderFilter;

  Timer? _debounce;
  String _lastQuery = '';
  String get lastQuery => _lastQuery;

  bool _isFetchingMore = false;
  bool get isFetchingMore => _isFetchingMore;

  int _topPlayersPage = 1;
  bool _topPlayersHasMore = true;
  int _searchPage = 1;
  bool _searchHasMore = true;

  bool get topPlayersHasMore => _topPlayersHasMore;
  bool get searchHasMore => _searchHasMore;

  void setGenderFilter(String gender) {
    if (_genderFilter != gender) {
      _genderFilter = gender;
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
      final response = await _apiService.getTtPlayers(
        page: _topPlayersPage,
        gender: _genderFilter,
      );

      if (loadMore) {
        _topPlayers.addAll(response.items);
      } else {
        _topPlayers = response.items;
      }

      _topPlayersHasMore = response.items.length >= 20;
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
      final response = await _apiService.searchTtPlayers(
        query,
        page: _searchPage,
        gender: _genderFilter,
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
