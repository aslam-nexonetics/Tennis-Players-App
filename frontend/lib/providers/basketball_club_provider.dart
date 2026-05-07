import 'package:flutter/material.dart';
import '../models/basketball_club.dart';
import '../services/api_service.dart';
import 'dart:async';

class BasketballClubProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<BasketballClub> _topClubs = [];
  List<BasketballClub> _searchResults = [];
  bool _isLoading = false;
  bool _isFetchingMore = false;
  String _error = '';
  String _selectedCategory = 'men'; // 'men' or 'women'
  Timer? _debounce;
  String _currentQuery = '';

  List<BasketballClub> get topClubs => _topClubs;
  List<BasketballClub> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isFetchingMore => _isFetchingMore;
  String get error => _error;
  String get selectedCategory => _selectedCategory;
  String get lastQuery => _currentQuery;

  int _topClubsPage = 1;
  bool _topClubsHasMore = true;
  int _searchPage = 1;
  bool _searchHasMore = true;
  int _pageSize = 20;

  bool get topClubsHasMore => _topClubsHasMore;
  bool get searchHasMore => _searchHasMore;

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _topClubs = [];
    _topClubsPage = 1;
    _topClubsHasMore = true;
    _searchResults = [];
    _searchPage = 1;
    _searchHasMore = true;
    notifyListeners();
    fetchTopClubs();
    if (_currentQuery.isNotEmpty) {
      searchClubs(_currentQuery);
    }
  }

  Future<void> fetchTopClubs({bool loadMore = false}) async {
    if (_isLoading || _isFetchingMore || (loadMore && !_topClubsHasMore)) return;

    if (loadMore) {
      _isFetchingMore = true;
    } else {
      _isLoading = true;
    }
    _error = '';
    if (!loadMore) {
      _topClubsPage = 1;
      _topClubsHasMore = true;
    }
    notifyListeners();

    try {
      final response = await _apiService.getBasketballClubs(
        category: _selectedCategory,
        page: _topClubsPage,
        size: _pageSize,
      );
      
      if (loadMore) {
        _topClubs.addAll(response.items);
      } else {
        _topClubs = response.items;
      }
      
      _topClubsHasMore = response.items.length >= _pageSize;
      if (_topClubsHasMore) _topClubsPage++;
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  void searchClubs(String query) {
    _currentQuery = query;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
        _searchResults = [];
        _searchPage = 1;
        _searchHasMore = true;
        notifyListeners();
        return;
      }
      _searchPage = 1;
      _searchHasMore = true;
      _searchResults = [];
      searchClubsCall(query);
    });
  }

  Future<void> searchClubsCall(String query, {bool loadMore = false}) async {
    if (_isLoading || _isFetchingMore || (loadMore && !_searchHasMore)) return;

    if (loadMore) {
      _isFetchingMore = true;
    } else {
      _isLoading = true;
    }
    _error = '';
    if (!loadMore) {
      _searchPage = 1;
      _searchHasMore = true;
    }
    notifyListeners();

    try {
      final response = await _apiService.searchBasketballClubs(
        query, 
        category: _selectedCategory,
        page: _searchPage,
        size: _pageSize,
      );
      
      if (loadMore) {
        _searchResults.addAll(response.items);
      } else {
        _searchResults = response.items;
      }
      
      _searchHasMore = response.items.length >= _pageSize;
      if (_searchHasMore) _searchPage++;
      
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults = [];
    _currentQuery = '';
    _searchPage = 1;
    _searchHasMore = true;
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
