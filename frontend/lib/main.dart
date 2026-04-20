import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/player_provider.dart';
import 'providers/tt_player_provider.dart';
import 'screens/search_screen.dart';
import 'screens/top_players_screen.dart';
import 'screens/tt_search_screen.dart';
import 'screens/tt_top_players_screen.dart';
import 'widgets/glass_widgets.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PlayerProvider()),
        ChangeNotifierProvider(create: (_) => TtPlayerProvider()),
      ],
      child: const TennisApp(),
    ),
  );
}

class TennisApp extends StatelessWidget {
  const TennisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sports Player Search',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5D5FEF),
          secondary: const Color(0xFFE0EAFC),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF1D1D1F),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static const List<Widget> _screens = [
    SearchScreen(),
    TopPlayersScreen(),
    TtSearchScreen(),
    TtTopPlayersScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return LiquidBackground(
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(index: _selectedIndex, children: _screens),
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24),
          child: GlassContainer(
            borderRadius: 30,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavBarItem(
                  icon: Icons.search_rounded,
                  label: 'Search',
                  isSelected: _selectedIndex == 0,
                  accentColor: Colors.indigo,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _NavBarItem(
                  icon: Icons.leaderboard_rounded,
                  label: 'Rankings',
                  isSelected: _selectedIndex == 1,
                  accentColor: Colors.indigo,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                _NavBarItem(
                  icon: Icons.sports_tennis,
                  label: 'TT Search',
                  isSelected: _selectedIndex == 2,
                  accentColor: const Color(0xFF0F9D58),
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
                _NavBarItem(
                  icon: Icons.emoji_events,
                  label: 'TT Ranks',
                  isSelected: _selectedIndex == 3,
                  accentColor: const Color(0xFF0F9D58),
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? accentColor : Colors.grey[600],
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? accentColor : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
