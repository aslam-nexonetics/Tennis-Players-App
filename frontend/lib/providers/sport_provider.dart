import 'package:flutter/material.dart';

enum SportType { tennis, tableTennis, football }

class Sport {
  final SportType type;
  final String name;
  final IconData icon;
  final Color accentColor;

  const Sport({
    required this.type,
    required this.name,
    required this.icon,
    required this.accentColor,
  });
}

class SportProvider with ChangeNotifier {
  static const List<Sport> allSports = [
    Sport(
      type: SportType.tennis,
      name: 'Tennis',
      icon: Icons.sports_tennis,
      accentColor: Colors.indigo,
    ),
    Sport(
      type: SportType.tableTennis,
      name: 'Table Tennis',
      icon: Icons.sports_tennis_rounded,
      accentColor: Color(0xFF0F9D58),
    ),
    Sport(
      type: SportType.football,
      name: 'Football',
      icon: Icons.sports_soccer,
      accentColor: Color(0xFFE4405F),
    ),
  ];

  Sport _currentSport = allSports[0];

  Sport get currentSport => _currentSport;

  void setSport(Sport sport) {
    if (_currentSport.type != sport.type) {
      _currentSport = sport;
      notifyListeners();
    }
  }
}
