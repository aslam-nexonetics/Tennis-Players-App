import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../models/player.dart';

class PlayerDetailScreen extends StatelessWidget {
  final Player player;

  const PlayerDetailScreen({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(player.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: player.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: player.imageUrl!,
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const SizedBox(
                          height: 250,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 250,
                          color: Colors.grey[300],
                          child: const Icon(Icons.person, size: 100),
                        ),
                      )
                    : Container(
                        height: 250,
                        width: double.infinity,
                        color: Colors.grey[300],
                        child: const Icon(Icons.person, size: 100),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              player.name,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              player.country ?? 'Unknown Country',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: Colors.grey[600]),
            ),
            const Divider(height: 32),
            _buildStatRow('Ranking', '#${player.ranking ?? 'N/A'}'),
            _buildStatRow(
              'Highest Ranking',
              '#${player.highestRanking ?? 'N/A'}',
            ),
            _buildStatRow(
              'Birth Date',
              player.birthDate != null
                  ? DateFormat('MMM dd, yyyy').format(player.birthDate!)
                  : 'N/A',
            ),
            _buildStatRow('Height', player.height ?? 'N/A'),
            _buildStatRow('Weight', player.weight ?? 'N/A'),
            _buildStatRow('Style', player.playingStyle ?? 'N/A'),
            const SizedBox(height: 16),
            const Text(
              'Career Stats',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildSimpleStat('Wins', player.wins.toString(), Colors.green),
                const SizedBox(width: 16),
                _buildSimpleStat(
                  'Losses',
                  player.losses.toString(),
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Data Source: ${player.source ?? 'Unknown'}',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          Text(value, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
