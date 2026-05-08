import 'package:flutter/material.dart';
import 'dart:async';
import '../models/football_national_team.dart';
import '../services/api_service.dart';

class FootballNationalTeamProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<FootballNationalTeam> _teams = [];
  List<FootballNationalTeam> get teams => _teams;

  List<FootballNationalTeam> _topTeams = [];
  List<FootballNationalTeam> get topTeams => _topTeams;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  String? _error;
  String? get error => _error;
  
  String _selectedCategory = 'men';
  String get selectedCategory => _selectedCategory;

  Timer? _debounce;
  String _lastQuery = '';
  String get lastQuery => _lastQuery;

  int _currentPage = 1;
  int _pageSize = 20;
  bool _hasMore = true;
  int _totalTeams = 0;

  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  int get totalTeams => _totalTeams;

  Future<void> fetchTopTeams() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
  
    try {
      _topTeams = await _apiService.getFootballTopTeams(limit: 50, category: _selectedCategory);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _teams = [];
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
    fetchTopTeams();
  }

  void onSearchChanged(String query) {
    _lastQuery = query;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        searchTeams(query);
      } else {
        _teams = [];
        _currentPage = 1;
        _hasMore = true;
        notifyListeners();
      }
    });
  }

  Future<void> searchTeams(String query) async {
    if (_isSearching) return;
    _isSearching = true;
    _error = null;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  
    try {
      final response = await _apiService.searchFootballTeams(
        query, 
        category: _selectedCategory,
        page: _currentPage,
        size: _pageSize,
      );
      _teams = response.items;
      _totalTeams = response.total;
      _hasMore = _teams.length < _totalTeams;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSearching = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreTeams() async {
    if (_isLoading || !_hasMore || _lastQuery.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await _apiService.searchFootballTeams(
        _lastQuery,
        category: _selectedCategory,
        page: nextPage,
        size: _pageSize,
      );
      
      if (response.items.isNotEmpty) {
        _teams.addAll(response.items);
        _currentPage = nextPage;
        _hasMore = _teams.length < _totalTeams;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _teams = [];
    _lastQuery = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
