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
  Timer? _debounce;

  List<BasketballClub> get topClubs => _topClubs;
  List<BasketballClub> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  String get error => _error;

  Future<void> fetchTopClubs() async {
    _isLoading = true;
    _error = '';
    notifyListeners();

    try {
      _topClubs = await _apiService.getBasketballTopClubs();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchClubs(String query) {
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
        final response = await _apiService.searchBasketballClubs(query);
        _searchResults = response.items;
      } catch (e) {
        _error = e.toString();
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    });
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
