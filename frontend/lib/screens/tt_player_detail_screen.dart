import 'package:flutter/material.dart';
import '../models/tt_player.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/ranking_graph.dart';
import 'tt_player_compare_screen.dart';

class TtPlayerDetailScreen extends StatelessWidget {
  final TableTennisPlayer player;

  const TtPlayerDetailScreen({super.key, required this.player});

  List<RankingPoint> _generateRankingTrend() {
    final current = player.ranking ?? 100;
    
    // Generate simulated points to show a trend based on current rank
    return [
      RankingPoint(
        ranking: current + 10,
        date: DateTime.now().subtract(const Duration(days: 180)),
      ),
      RankingPoint(
        ranking: current + 5,
        date: DateTime.now().subtract(const Duration(days: 90)),
      ),
      RankingPoint(
        ranking: current + 2,
        date: DateTime.now().subtract(const Duration(days: 30)),
      ),
      RankingPoint(ranking: current, date: DateTime.now()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          heroTag: 'compare-tt-${player.id}',
          backgroundColor: const Color(0xFF0F9D58),
          icon: const Icon(Icons.compare_arrows_rounded, color: Colors.white),
          label: const Text('Compare',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TtPlayerCompareScreen(playerA: player),
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFCEF0DE), // Teal-tinted glass theme
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GlassContainer(
            borderRadius: 12,
            opacity: 0.1,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return _buildWebLayout(context, constraints);
          }
          return _buildMobileLayout(context);
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Stack(
      children: [
        // Teal gradient background
        Container(
          height: 400,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF34A853),
                Color(0xFF0F9D58),
                Color(0xFF006837),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                _buildProfileAvatar(size: 120),
                const SizedBox(height: 12),
                Text(
                  player.gender == 'M'
                      ? '🏓 Men\'s Singles'
                      : player.gender == 'F'
                      ? '🏓 Women\'s Singles'
                      : '🏓 Table Tennis',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Scrollable content
        SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 350),
              GlassContainer(
                borderRadius: 40,
                opacity: 0.2,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildHeader(),
                    const Divider(height: 40, thickness: 1),
                    _buildRankingSection(),
                    const SizedBox(height: 30),
                    _buildStatGrid(context),
                    const SizedBox(height: 32),
                    _buildPerformanceSection(),
                    const SizedBox(height: 30),
                    _buildSourceFooter(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebLayout(BuildContext context, BoxConstraints constraints) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Profile Card
              SizedBox(
                width: 350,
                child: GlassContainer(
                  borderRadius: 30,
                  opacity: 0.2,
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      Container(
                        height: 300,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(30)),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF34A853), Color(0xFF0F9D58)],
                          ),
                        ),
                        child: Center(child: _buildProfileAvatar(size: 150)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player.name,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${player.country ?? 'N/A'} • ${player.age != null ? '${player.age} years' : 'Pro Athlete'}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        TtPlayerCompareScreen(playerA: player),
                                  ),
                                ),
                                icon: const Icon(Icons.compare_arrows_rounded),
                                label: const Text('Compare Player'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0F9D58),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 40),
              // Right Column: Details
              Expanded(
                child: GlassContainer(
                  borderRadius: 30,
                  opacity: 0.15,
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRankingSection(),
                      const SizedBox(height: 40),
                      const Text(
                        'Player Statistics',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F9D58),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatGrid(context),
                      const SizedBox(height: 40),
                      _buildPerformanceSection(),
                      const SizedBox(height: 40),
                      _buildSourceFooter(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 3,
        ),
      ),
      child: ClipOval(
        child: player.imageUrl != null
            ? Image.network(
                player.imageUrl!,
                fit: BoxFit.cover,
                                                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) => Center(
                  child: Text(
                    _initials(player.name),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.33,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              )
            : Center(
                child: Text(
                  _initials(player.name),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: size * 0.33,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                player.name,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
              Text(
                '${player.country ?? 'N/A'} • ${player.age != null ? '${player.age} years' : 'Pro Athlete'}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (player.country != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              player.country!,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildRankingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ranking Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F9D58),
              ),
            ),
            Icon(Icons.query_stats_rounded, color: Color(0xFF0F9D58), size: 20),
          ],
        ),
        const SizedBox(height: 10),
        RankingGraph(
          points: _generateRankingTrend(),
          color: const Color(0xFF0F9D58),
        ),
      ],
    );
  }

  Widget _buildPerformanceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Career Performance',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _buildWinPercentageBanner(),
      ],
    );
  }

  Widget _buildWinPercentageBanner() {
    final percentage = player.winPercentage ?? 0.0;
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      borderRadius: 20,
      opacity: 0.1,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'WIN RATE',
                  style: TextStyle(
                    color: Color(0xFF0F9D58),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 80,
            height: 80,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0F9D58).withOpacity(0.1),
            ),
            child: CircularProgressIndicator(
              value: percentage / 100,
              strokeWidth: 8,
              backgroundColor: Colors.white.withOpacity(0.2),
              color: const Color(0xFF0F9D58),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSourceFooter() {
    if (player.source == null) return const SizedBox();
    return Text(
      'Verified by ${player.source}',
      style: const TextStyle(
        fontSize: 12,
        fontStyle: FontStyle.italic,
        color: Colors.grey,
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Widget _buildStatGrid(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatCard(
              cardWidth,
              'Current Rank',
              '#${player.ranking ?? 'N/A'}',
              Icons.military_tech,
            ),
            _buildStatCard(
              cardWidth,
              'Playing Style',
              player.playingStyle ?? 'N/A',
              Icons.sports_tennis,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    double width,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF0F9D58)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


}
