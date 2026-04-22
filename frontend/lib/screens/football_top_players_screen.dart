import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/football_player_provider.dart';
import '../widgets/glass_widgets.dart';
import 'football_player_detail_screen.dart';

class FootballTopPlayersScreen extends StatefulWidget {
  const FootballTopPlayersScreen({super.key});

  @override
  State<FootballTopPlayersScreen> createState() => _FootballTopPlayersScreenState();
}

class _FootballTopPlayersScreenState extends State<FootballTopPlayersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FootballPlayerProvider>(context, listen: false).fetchTopPlayers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FootballPlayerProvider>(context);

    return Column(
      children: [
        const SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stars, color: Color(0xFFE4405F), size: 26),
            const SizedBox(width: 8),
            const Text(
              'Top Footballers',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
                color: Color(0xFF1D1D1F),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        const Text(
          'World rankings based on performance',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: provider.isLoading && provider.topPlayers.isEmpty
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE4405F)))
              : provider.error != null && provider.topPlayers.isEmpty
                  ? Center(child: Text('Error: ${provider.error}'))
                  : RefreshIndicator(
                      color: const Color(0xFFE4405F),
                      onRefresh: provider.fetchTopPlayers,
                      child: ListView.builder(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: MediaQuery.of(context).padding.bottom + 100,
                        ),
                        itemCount: provider.topPlayers.length,
                        itemBuilder: (context, index) {
                          final player = provider.topPlayers[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: GlassContainer(
                              borderRadius: 20,
                              child: ListTile(
                                leading: Text(
                                  '#${player.ranking}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE4405F),
                                  ),
                                ),
                                title: Text(
                                  player.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('${player.currentClub} • ${player.country}'),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          FootballPlayerDetailScreen(player: player),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }
}
