import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/player.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/ranking_graph.dart';
import 'player_compare_screen.dart';

class PlayerDetailScreen extends StatelessWidget {
  final Player player;

  const PlayerDetailScreen({super.key, required this.player});

  // Helper to generate ranking path for graph
  List<RankingPoint> _generateRankingTrend() {
    final current = player.ranking ?? 100;
    final highest = player.highestRanking ?? current - 10;
    final highestDate =
        player.highestRankingDate ??
        DateTime.now().subtract(const Duration(days: 365 * 2));

    // Generate 4-5 points to show a trend
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          heroTag: 'compare-tennis-${player.id}',
          backgroundColor: Colors.indigo,
          icon: const Icon(Icons.compare_arrows_rounded, color: Colors.white),
          label: const Text('Compare',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PlayerCompareScreen(playerA: player),
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFCFDEF3), // Matches liquid theme
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
        // Splash background
        if (player.imageUrl != null)
          Hero(
            tag: 'player-${player.id}',
            child: CachedNetworkImage(
              imageUrl: player.imageUrl!,
              height: 400,
              width: double.infinity,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          )
        else
          Container(
            height: 400,
            width: double.infinity,
            color: Colors.indigo.withOpacity(0.1),
            child: const Icon(Icons.person, size: 100, color: Colors.blue),
          ),

        // Content
        SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 350), // Overlap trigger
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
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(30)),
                        child: player.imageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: player.imageUrl!,
                                height: 350,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                alignment: Alignment.topCenter,
                              )
                            : Container(
                                height: 350,
                                color: Colors.indigo.withOpacity(0.1),
                                child: const Icon(Icons.person,
                                    size: 100, color: Colors.blue),
                              ),
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
                              '${player.country ?? "N/A"} • ${player.age != null ? "${player.age} years" : "Pro Athlete"}',
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
                                    builder: (_) => PlayerCompareScreen(
                                        playerA: player),
                                  ),
                                ),
                                icon: const Icon(Icons.compare_arrows_rounded),
                                label: const Text('Compare Player'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.indigo,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 16),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
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
                          color: Colors.indigo,
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
                '${player.country ?? "N/A"} • ${player.age != null ? "${player.age} years" : "Pro Athlete"}',
                style: TextStyle(
                  fontSize: 18,
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
                color: Colors.indigo,
              ),
            ),
            Icon(Icons.query_stats_rounded, color: Colors.indigo, size: 20),
          ],
        ),
        const SizedBox(height: 10),
        RankingGraph(points: _generateRankingTrend()),
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
      ],
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
            _buildStatCard(
              cardWidth,
              'Weight',
              player.weight ?? 'N/A',
              Icons.monitor_weight_outlined,
            ),
            _buildStatCard(
              cardWidth,
              'Turned Pro',
              player.turnedPro ?? 'N/A',
              Icons.event_available,
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
          Icon(icon, size: 20, color: Colors.indigo),
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
