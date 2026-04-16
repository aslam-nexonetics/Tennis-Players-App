import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import 'player_detail_screen.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Top Players')),
      body: playerProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : playerProvider.error != null
          ? Center(child: Text('Error: ${playerProvider.error}'))
          : ListView.builder(
              itemCount: playerProvider.topPlayers.length,
              itemBuilder: (context, index) {
                final player = playerProvider.topPlayers[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: player.imageUrl != null
                          ? CachedNetworkImageProvider(player.imageUrl!)
                          : null,
                      child: player.imageUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text('${index + 1}. ${player.name}'),
                    subtitle: Text(player.country ?? 'Unknown'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PlayerDetailScreen(player: player),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
