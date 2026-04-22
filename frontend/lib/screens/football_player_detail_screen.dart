import 'package:flutter/material.dart';
import '../models/football_player.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/ranking_graph.dart';
import 'football_player_compare_screen.dart';

class FootballPlayerDetailScreen extends StatelessWidget {
  final FootballPlayer player;

  const FootballPlayerDetailScreen({super.key, required this.player});

  List<RankingPoint> _generateRankingTrend() {
    final current = player.ranking ?? 50;
    
    return [
      RankingPoint(
        ranking: current + 10,
        date: DateTime.now().subtract(const Duration(days: 365)),
      ),
      RankingPoint(
        ranking: current + 5,
        date: DateTime.now().subtract(const Duration(days: 180)),
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
          heroTag: 'compare-fb-${player.id}',
          backgroundColor: const Color(0xFFE4405F),
          icon: const Icon(Icons.compare_arrows_rounded, color: Colors.white),
          label: const Text('Compare',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FootballPlayerCompareScreen(playerA: player),
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFFE4E8), // Pinkish-tinted glass theme
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
          // Gradient background
          Container(
            height: 400,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF5F6D),
                  Color(0xFFE4405F),
                  Color(0xFF911E3B),
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
                    child: ClipOval(
                      child: player.imageUrl != null
                          ? Image.network(
                              player.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  _initials(player.name),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          : Center(
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
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '⚽ ${player.position ?? 'Footballer'}',
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
                                  '${player.currentClub ?? 'Free Agent'} • ${player.country ?? 'International'}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
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
                              color: Color(0xFFE4405F),
                            ),
                          ),
                          Icon(
                            Icons.query_stats_rounded,
                            color: Color(0xFFE4405F),
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      RankingGraph(
                        points: _generateRankingTrend(),
                        color: const Color(0xFFE4405F),
                      ),

                      const SizedBox(height: 30),
                      _buildStatGrid(context),

                      const SizedBox(height: 32),
                      const Text(
                        'Season Stats',
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
                              'GOALS',
                              player.goals.toString(),
                              const Color(0xFFE4405F),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSimpleStat(
                              'ASSISTS',
                              player.assists.toString(),
                              Colors.blue[400]!,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      if (player.source != null)
                        Text(
                          'Data source: ${player.source}',
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildStatCard(
              cardWidth,
              'World Ranking',
              '#${player.ranking ?? 'N/A'}',
              Icons.military_tech,
            ),
            _buildStatCard(
              cardWidth,
              'Market Value',
              player.marketValue ?? 'N/A',
              Icons.monetization_on_rounded,
            ),
            _buildStatCard(
              cardWidth,
              'Age',
              player.age != null ? '${player.age} yrs' : 'N/A',
              Icons.calendar_today,
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
          Icon(icon, size: 20, color: const Color(0xFFE4405F)),
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
