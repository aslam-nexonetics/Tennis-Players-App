import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import '../models/player.dart';
import '../models/tt_player.dart';
import '../models/football_club.dart';
import '../models/basketball_player.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      // Production backend on Render
      return 'https://tennis-players-app.onrender.com';
      // return 'http://localhost:8000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      // Physical Android device on LAN
      return 'http://192.168.29.84:8000';
    }
    // iOS simulator, macOS, Linux, Windows desktop
    return 'http://localhost:8000';
  }

  Future<PlayerListResponse> getPlayers({int page = 1, int size = 20}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/players/?page=$page&size=$size'),
    );
    if (response.statusCode == 200) {
      return PlayerListResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load players');
    }
  }

  Future<PlayerListResponse> searchPlayers(
    String query, {
    int page = 1,
    int size = 20,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/players/search?q=$query&page=$page&size=$size'),
    );
    if (response.statusCode == 200) {
      return PlayerListResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to search players');
    }
  }

  Future<Player> getPlayerDetail(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/players/$id'));
    if (response.statusCode == 200) {
      return Player.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load player details');
    }
  }

  Future<List<Player>> getTopPlayers({int limit = 10}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/players/top?limit=$limit'),
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((i) => Player.fromJson(i)).toList();
    } else {
      throw Exception('Failed to load top players');
    }
  }

  // ── Table Tennis ─────────────────────────────────────────────────────────

  Future<TtPlayerListResponse> searchTtPlayers(
    String query, {
    int page = 1,
    int size = 20,
    String? gender,
  }) async {
    var url = '$baseUrl/tt-players/search?q=$query&page=$page&size=$size';
    if (gender != null) url += '&gender=$gender';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return TtPlayerListResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to search TT players');
    }
  }

  Future<TableTennisPlayer> getTtPlayerDetail(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/tt-players/$id'));
    if (response.statusCode == 200) {
      return TableTennisPlayer.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load TT player details');
    }
  }

  Future<List<TableTennisPlayer>> getTtTopPlayers({
    int limit = 50,
    String? gender,
  }) async {
    var url = '$baseUrl/tt-players/top?limit=$limit';
    if (gender != null) url += '&gender=$gender';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((i) => TableTennisPlayer.fromJson(i)).toList();
    } else {
      throw Exception('Failed to load top TT players');
    }
  }

  // ── Football ─────────────────────────────────────────────────────────────

  Future<FootballClubListResponse> searchFootballClubs(
    String query, {
    int page = 1,
    int size = 20,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/football-clubs/search?q=$query&page=$page&size=$size',
      ),
    );
    if (response.statusCode == 200) {
      return FootballClubListResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to search football clubs');
    }
  }

  Future<FootballClub> getFootballClubDetail(int id) async {
    final response = await http.get(Uri.parse('$baseUrl/football-clubs/$id'));
    if (response.statusCode == 200) {
      return FootballClub.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load football club details');
    }
  }

  Future<List<FootballClub>> getFootballTopClubs({int limit = 50}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/football-clubs/top?limit=$limit'),
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((i) => FootballClub.fromJson(i)).toList();
    } else {
      throw Exception('Failed to load top football clubs');
    }
  }

  // ── Basketball ───────────────────────────────────────────────────────────

  Future<BasketballPlayerListResponse> searchBasketballPlayers(
    String query, {
    int page = 1,
    int size = 20,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/basketball-players/search?q=$query&page=$page&size=$size',
      ),
    );
    if (response.statusCode == 200) {
      return BasketballPlayerListResponse.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to search basketball players');
    }
  }

  Future<BasketballPlayer> getBasketballPlayerDetail(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/basketball-players/$id'),
    );
    if (response.statusCode == 200) {
      return BasketballPlayer.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load basketball player details');
    }
  }

  Future<List<BasketballPlayer>> getBasketballTopPlayers({
    int limit = 50,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/basketball-players/top?limit=$limit'),
    );
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((i) => BasketballPlayer.fromJson(i)).toList();
    } else {
      throw Exception('Failed to load top basketball players');
    }
  }
}
