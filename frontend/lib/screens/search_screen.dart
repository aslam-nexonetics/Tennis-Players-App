import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import 'player_detail_screen.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tennis Player Search'), elevation: 0),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search players (e.g. Djokovic, Nadal)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onChanged: playerProvider.onSearchChanged,
            ),
          ),
          if (playerProvider.isLoading) const LinearProgressIndicator(),
          if (playerProvider.error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error: ${playerProvider.error}',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Expanded(
            child: playerProvider.players.isEmpty && !playerProvider.isLoading
                ? const Center(child: Text('Start searching for players!'))
                : ListView.builder(
                    itemCount: playerProvider.players.length,
                    itemBuilder: (context, index) {
                      final player = playerProvider.players[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: player.imageUrl != null
                              ? CachedNetworkImageProvider(player.imageUrl!)
                              : null,
                          child: player.imageUrl == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(player.name),
                        subtitle: Text(player.country ?? 'Unknown'),
                        trailing: Text('Rank: ${player.ranking ?? 'N/A'}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PlayerDetailScreen(player: player),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
