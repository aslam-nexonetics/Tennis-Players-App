import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/football_player_provider.dart';
import '../widgets/glass_widgets.dart';
import 'football_player_detail_screen.dart';
import 'football_player_compare_screen.dart';

class FootballSearchScreen extends StatelessWidget {
  const FootballSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FootballPlayerProvider>(context);

    return Column(
      children: [
        const SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_soccer, color: Color(0xFFE4405F), size: 26),
            const SizedBox(width: 8),
            const Text(
              'Football Search',
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
          'Find world class footballers',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: GlassContainer(
            borderRadius: 30,
            opacity: 0.1,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search football players...',
                prefixIcon: Icon(Icons.search, color: Color(0xFFE4405F)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 15),
              ),
              onChanged: provider.onSearchChanged,
            ),
          ),
        ),
        if (provider.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: LinearProgressIndicator(
              backgroundColor: Colors.transparent,
              color: Color(0xFFE4405F),
              minHeight: 2,
            ),
          ),
        if (provider.error != null)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GlassContainer(
              padding: const EdgeInsets.all(12),
              opacity: 0.05,
              child: Text(
                'Error: ${provider.error}',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
          ),
        Expanded(
          child: provider.players.isEmpty && !provider.isLoading
              ? const Center(
                  child: Opacity(
                    opacity: 0.5,
                    child: Text('Search for football players!'),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 100,
                  ),
                  itemCount: provider.players.length,
                  itemBuilder: (context, index) {
                    final player = provider.players[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: GlassContainer(
                        blur: 0,
                        borderRadius: 20,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(8),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFE4405F).withOpacity(0.12),
                              border: Border.all(
                                color: const Color(0xFFE4405F).withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: ClipOval(
                              child: player.imageUrl != null
                                  ? Image.network(
                                      player.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _initialsWidget(player.name, 18),
                                    )
                                  : _initialsWidget(player.name, 18),
                            ),
                          ),
                          title: Text(
                            player.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${player.country ?? 'Unknown'} • ${player.currentClub ?? 'No Club'}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Rank',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '#${player.ranking ?? 'N/A'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE4405F),
                                ),
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    FootballPlayerDetailScreen(player: player),
                              ),
                            );
                          },
                          onLongPress: () {
                             Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FootballPlayerCompareScreen(playerA: player),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

Widget _initialsWidget(String name, double fontSize) {
  final parts = name.trim().split(' ');
  final initials = parts.length >= 2
      ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
      : name.isNotEmpty
          ? name[0].toUpperCase()
          : '?';
  return Center(
    child: Text(
      initials,
      style: TextStyle(
        color: const Color(0xFFE4405F),
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
      ),
    ),
  );
}
