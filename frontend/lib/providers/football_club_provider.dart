import 'package:flutter/material.dart';
import 'dart:async';
import '../models/football_club.dart';
import '../services/api_service.dart';

class FootballClubProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<FootballClub> _clubs = [];
  List<FootballClub> get clubs => _clubs;

  List<FootballClub> _topClubs = [];
  List<FootballClub> get topClubs => _topClubs;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

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
  int _totalClubs = 0;

  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  int get totalClubs => _totalClubs;

  Future<void> fetchTopClubs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
  
    try {
      _topClubs = await _apiService.getFootballTopClubs(limit: 50, category: _selectedCategory);
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
    _clubs = [];
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
    fetchTopClubs();
  }

  void onSearchChanged(String query) {
    _lastQuery = query;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        searchClubs(query);
      } else {
        _clubs = [];
        _currentPage = 1;
        _hasMore = true;
        notifyListeners();
      }
    });
  }

  Future<void> searchClubs(String query) async {
    _isLoading = true;
    _error = null;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  
    try {
      final response = await _apiService.searchFootballClubs(
        query, 
        category: _selectedCategory,
        page: _currentPage,
        size: _pageSize,
      );
      _clubs = response.items;
      _totalClubs = response.total;
      _hasMore = _clubs.length < _totalClubs;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMoreClubs() async {
    if (_isLoading || !_hasMore || _lastQuery.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await _apiService.searchFootballClubs(
        _lastQuery,
        category: _selectedCategory,
        page: nextPage,
        size: _pageSize,
      );
      
      if (response.items.isNotEmpty) {
        _clubs.addAll(response.items);
        _currentPage = nextPage;
        _hasMore = _clubs.length < _totalClubs;
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
    _clubs = [];
    _lastQuery = '';
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
