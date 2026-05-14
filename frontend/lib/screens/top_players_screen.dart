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
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(
      () =>
          Provider.of<PlayerProvider>(context, listen: false).fetchTopPlayers(),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      Provider.of<PlayerProvider>(context, listen: false)
          .fetchTopPlayers(loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'World Rankings',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    Text(
                      'Top Tennis Pros',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _GenderFilterChips(provider: playerProvider),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: playerProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : playerProvider.error != null
                  ? Center(child: Text('Error: ${playerProvider.error}'))
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: MediaQuery.of(context).padding.bottom + 100,
                      ),
                      itemCount: playerProvider.topPlayers.length +
                          (playerProvider.topPlayersHasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == playerProvider.topPlayers.length) {
                          return Opacity(
                            opacity: playerProvider.isFetchingMore ? 1.0 : 0.0,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          );
                        }
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
                                          color: Colors.indigo.withOpacity(0.3),
                                          width: 2,
                                        ),
                                        color: Colors.indigo.withOpacity(0.12),
                                      ),
                                      child: ClipOval(
                                        child: player.imageUrl != null
                                            ? Image(
                                                image:
                                                    CachedNetworkImageProvider(
                                                  player.imageUrl!,
                                                ),
                                                fit: BoxFit.cover,
                                                alignment: Alignment.topCenter,
                                                errorBuilder: (_, __, ___) =>
                                                    _initialsWidget(
                                                        player.name, 18),
                                              )
                                            : _initialsWidget(player.name, 18),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.indigo,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${player.ranking ?? index + 1}',
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
                                '${player.country ?? 'Unknown'} • ${player.gender == 'M' ? 'ATP' : player.gender == 'F' ? 'WTA' : ''}',
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
      ],
    );
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
          color: Colors.indigo,
          fontWeight: FontWeight.bold,
          fontSize: fontSize,
        ),
      ),
    );
  }
}

class _GenderFilterChips extends StatelessWidget {
  final PlayerProvider provider;
  const _GenderFilterChips({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _chip(context, 'M', 'ATP (Men)'),
        const SizedBox(width: 12),
        _chip(context, 'F', 'WTA (Women)'),
      ],
    );
  }

  Widget _chip(BuildContext context, String value, String label) {
    final selected = provider.selectedGender == value;
    return GestureDetector(
      onTap: () => provider.setGender(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? Colors.indigo.withOpacity(0.15)
              : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? Colors.indigo : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.indigo : Colors.grey[600],
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

