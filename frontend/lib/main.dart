import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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

// ── Breakpoints ──────────────────────────────────────────────────────────────
const double _kCompactBreakpoint = 600; // below = mobile bottom nav

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

  static const List<_NavDef> _navItems = [
    _NavDef(Icons.search_rounded, 'Tennis Search', Colors.indigo),
    _NavDef(Icons.leaderboard_rounded, 'Rankings', Colors.indigo),
    _NavDef(Icons.sports_tennis, 'TT Search', Color(0xFF0F9D58)),
    _NavDef(Icons.emoji_events, 'TT Rankings', Color(0xFF0F9D58)),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _kCompactBreakpoint;
        return isWide ? _wideLayout(context) : _compactLayout(context);
      },
    );
  }

  // ── Wide layout (web / tablet) ─────────────────────────────────────────────
  Widget _wideLayout(BuildContext context) {
    return LiquidBackground(
      child: Scaffold(
        body: Row(
          children: [
            // Side rail
            _SideRail(
              selectedIndex: _selectedIndex,
              navItems: _navItems,
              onTap: (i) => setState(() => _selectedIndex = i),
            ),
            const VerticalDivider(width: 1, thickness: 1),
            // Content — constrained to a sensible max width, centred
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _screens,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Compact layout (mobile) ────────────────────────────────────────────────
  Widget _compactLayout(BuildContext context) {
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
              children: List.generate(
                _navItems.length,
                (i) => _BottomNavItem(
                  def: _navItems[i],
                  isSelected: _selectedIndex == i,
                  onTap: () => setState(() => _selectedIndex = i),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Data holder ───────────────────────────────────────────────────────────────
class _NavDef {
  final IconData icon;
  final String label;
  final Color accent;
  const _NavDef(this.icon, this.label, this.accent);
}

// ── Side rail for wide screens ────────────────────────────────────────────────
class _SideRail extends StatelessWidget {
  final int selectedIndex;
  final List<_NavDef> navItems;
  final ValueChanged<int> onTap;

  const _SideRail({
    required this.selectedIndex,
    required this.navItems,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.35),
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.sports_tennis,
                      color: Colors.indigo.shade400, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'SportsSearch',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.indigo.shade700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            ...List.generate(
              navItems.length,
              (i) => _SideRailItem(
                def: navItems[i],
                isSelected: selectedIndex == i,
                onTap: () => onTap(i),
              ),
            ),
            const Spacer(),
            if (kIsWeb)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Text(
                  'Sports Player Search\nWeb Edition',
                  style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[500],
                      height: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SideRailItem extends StatelessWidget {
  final _NavDef def;
  final bool isSelected;
  final VoidCallback onTap;

  const _SideRailItem({
    required this.def,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? def.accent.withOpacity(0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              def.icon,
              size: 20,
              color: isSelected ? def.accent : Colors.grey[600],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                def.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? def.accent : Colors.grey[700],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom nav item (mobile) ───────────────────────────────────────────────────
class _BottomNavItem extends StatelessWidget {
  final _NavDef def;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.def,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? def.accent.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              def.icon,
              color: isSelected ? def.accent : Colors.grey[600],
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              def.label.length > 8
                  ? '${def.label.substring(0, 7)}…'
                  : def.label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? def.accent : Colors.grey[600],
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
