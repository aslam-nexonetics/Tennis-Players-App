import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/tt_player.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/ranking_graph.dart';

class TtPlayerDetailScreen extends StatelessWidget {
  final TableTennisPlayer player;

  const TtPlayerDetailScreen({super.key, required this.player});

  List<RankingPoint> _generateRankingTrend() {
    final current = player.ranking ?? 100;
    final highest = player.highestRanking ?? current - 5;
    final highestDate =
        player.highestRankingDate ??
        DateTime.now().subtract(const Duration(days: 365 * 2));

    return [
      RankingPoint(
        ranking: highest + 5,
        date: highestDate.subtract(const Duration(days: 180)),
      ),
      RankingPoint(ranking: highest, date: highestDate),
      RankingPoint(
        ranking: (highest + current) ~/ 2,
        date: highestDate.add(const Duration(days: 180)),
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
      body: Stack(
        children: [
          // Teal gradient background (no player photo for TT)
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
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _initials(player.name),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
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
                      Row(
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                player.country!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 40, thickness: 1),

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
                          Icon(
                            Icons.query_stats_rounded,
                            color: Color(0xFF0F9D58),
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      RankingGraph(
                        points: _generateRankingTrend(),
                        color: const Color(0xFF0F9D58),
                      ),

                      const SizedBox(height: 30),
                      _buildStatGrid(context),

                      const SizedBox(height: 32),
                      const Text(
                        'Career Performance',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSimpleStat(
                              'WINS',
                              player.wins.toString(),
                              Colors.green[400]!,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSimpleStat(
                              'LOSSES',
                              player.losses.toString(),
                              Colors.red[400]!,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      if (player.source != null)
                        Text(
                          'Verified by ${player.source}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
    final highestRankLabel = player.highestRankingDate != null
        ? '#${player.highestRanking ?? 'N/A'} (${DateFormat('MMM yyyy').format(player.highestRankingDate!)})'
        : '#${player.highestRanking ?? 'N/A'}';

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
              'Career High',
              highestRankLabel,
              Icons.stars_rounded,
            ),
            _buildStatCard(
              cardWidth,
              'Playing Style',
              player.playingStyle ?? 'N/A',
              Icons.sports_tennis,
            ),
            _buildStatCard(
              cardWidth,
              'Height',
              player.height ?? 'N/A',
              Icons.height,
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

  Widget _buildSimpleStat(String label, String value, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      opacity: 0.1,
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
