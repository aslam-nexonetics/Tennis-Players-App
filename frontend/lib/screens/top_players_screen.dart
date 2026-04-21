import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../widgets/glass_widgets.dart';
import 'player_detail_screen.dart';
import 'player_compare_screen.dart';

class TopPlayersScreen extends StatefulWidget {
  const TopPlayersScreen({super.key});

  @override
  State<TopPlayersScreen> createState() => _TopPlayersScreenState();
}

class _TopPlayersScreenState extends State<TopPlayersScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () =>
          Provider.of<PlayerProvider>(context, listen: false).fetchTopPlayers(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);

    return Column(
      children: [
        const SizedBox(height: 50),
        const Text(
          'World Rankings',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: Color(0xFF1D1D1F),
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Top 50 Tennis Pros',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: playerProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : playerProvider.error != null
              ? Center(child: Text('Error: ${playerProvider.error}'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: playerProvider.topPlayers.length,
                  itemBuilder: (context, index) {
                    final player = playerProvider.topPlayers[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GlassContainer(
                        blur: 0,
                        borderRadius: 20,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Hero(
                                tag: 'top-player-${player.id}',
                                child: Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.5),
                                      width: 2,
                                    ),
                                    image: player.imageUrl != null
                                        ? DecorationImage(
                                            image: CachedNetworkImageProvider(
                                              player.imageUrl!,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: player.imageUrl == null
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.indigo,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          title: Text(
                            player.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            player.country ?? 'Unknown',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Colors.grey,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PlayerDetailScreen(player: player),
                              ),
                            );
                          },
                          onLongPress: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    PlayerCompareScreen(playerA: player),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }
}
