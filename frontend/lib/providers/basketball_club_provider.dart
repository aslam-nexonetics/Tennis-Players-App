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

  void setCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
    // Refresh data when category changes
    fetchTopClubs();
    if (_currentQuery.isNotEmpty) {
      searchClubs(_currentQuery);
    }
  }

  Future<void> fetchTopClubs() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _topClubs = await _apiService.getBasketballTopClubs(category: _selectedCategory);
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
        notifyListeners();
        return;
      }

      _isLoading = true;
      notifyListeners();

      try {
        final response = await _apiService.searchBasketballClubs(query, category: _selectedCategory);
        _searchResults = response.items;
      } catch (e) {
        _error = e.toString();
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void clearSearch() {
    _searchResults = [];
    _currentQuery = '';
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
