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
    _clubs = []; // Clear current search results when switching category
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
        notifyListeners();
      }
    });
  }

  Future<void> searchClubs(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
  
    try {
      final response = await _apiService.searchFootballClubs(query, category: _selectedCategory);
      _clubs = response.items;
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
