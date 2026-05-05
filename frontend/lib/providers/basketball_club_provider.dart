import 'package:flutter/material.dart';
import '../models/basketball_club.dart';
import '../services/api_service.dart';
import 'dart:async';

class BasketballClubProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<BasketballClub> _topClubs = [];
  List<BasketballClub> _searchResults = [];
  bool _isLoading = false;
  String _error = '';
  String _selectedCategory = 'men'; // 'men' or 'women'
  Timer? _debounce;
  String _currentQuery = '';

  List<BasketballClub> get topClubs => _topClubs;
  List<BasketballClub> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get error => _error;
  String get selectedCategory => _selectedCategory;
  String get lastQuery => _currentQuery;

  int _currentPage = 1;
  int _pageSize = 20;
  bool _hasMore = true;
  int _totalClubs = 0;

  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  int get totalClubs => _totalClubs;

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _searchResults = [];
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
    fetchTopClubs();
  }

  Future<void> fetchTopClubs() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _topClubs = await _apiService.getBasketballTopClubs(category: _selectedCategory, limit: 50);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchClubs(String query) {
    _currentQuery = query;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (query.isEmpty) {
        _searchResults = [];
        _currentPage = 1;
        _hasMore = true;
        notifyListeners();
        return;
      }

      _isLoading = true;
      _currentPage = 1;
      _hasMore = true;
      notifyListeners();

      try {
        final response = await _apiService.searchBasketballClubs(
          query, 
          category: _selectedCategory,
          page: _currentPage,
          size: _pageSize,
        );
        _searchResults = response.items;
        _totalClubs = response.total;
        _hasMore = _searchResults.length < _totalClubs;
      } catch (e) {
        _error = e.toString();
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> fetchMoreClubs() async {
    if (_isLoading || !_hasMore || _currentQuery.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await _apiService.searchBasketballClubs(
        _currentQuery,
        category: _selectedCategory,
        page: nextPage,
        size: _pageSize,
      );
      
      if (response.items.isNotEmpty) {
        _searchResults.addAll(response.items);
        _currentPage = nextPage;
        _hasMore = _searchResults.length < _totalClubs;
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
    _searchResults = [];
    _currentQuery = '';
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  }

  Future<BasketballClub> getClubDetail(int id) async {
    try {
      return await _apiService.getBasketballClubDetail(id);
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
