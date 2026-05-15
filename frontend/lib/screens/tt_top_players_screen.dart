import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tt_player_provider.dart';
import '../widgets/glass_widgets.dart';
import 'tt_player_detail_screen.dart';
import 'tt_player_compare_screen.dart';

class TtTopPlayersScreen extends StatefulWidget {
  const TtTopPlayersScreen({super.key});

  @override
  State<TtTopPlayersScreen> createState() => _TtTopPlayersScreenState();
}

class _TtTopPlayersScreenState extends State<TtTopPlayersScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      if (!mounted) return;
      Provider.of<TtPlayerProvider>(context, listen: false).fetchTopPlayers();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      Provider.of<TtPlayerProvider>(context, listen: false)
          .fetchTopPlayers(loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TtPlayerProvider>(context);

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
                    Row(
                      children: [
                        Icon(Icons.emoji_events, color: Color(0xFF0F9D58), size: 18),
                        SizedBox(width: 6),
                        Text(
                          'TT Rankings',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                            color: Color(0xFF1D1D1F),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'World Pro Rankings',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _GenderFilterBar(provider: provider),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: provider.isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: const Color(0xFF0F9D58),
                  ),
                )
              : provider.error != null
              ? Center(child: Text('Error: ${provider.error}'))
              : provider.topPlayers.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text(
                      'No table tennis players found.\nTap the refresh button or run the TT scraper.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 140,
                  ),
                  itemCount: provider.topPlayers.length +
                      (provider.topPlayersHasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.topPlayers.length) {
                      return Opacity(
                        opacity: provider.isFetchingMore ? 1.0 : 0.0,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }
                    final player = provider.topPlayers[index];
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
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(
                                    0xFF0F9D58,
                                  ).withOpacity(0.1),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF0F9D58,
                                    ).withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: ClipOval(
                                  child: player.imageUrl != null
                                      ? Image.network(
                                          player.imageUrl!,
                                          fit: BoxFit.cover,
                                                alignment: Alignment.topCenter,
                                          errorBuilder: (_, __, ___) =>
                                              _initialsCenter(player.name),
                                        )
                                      : _initialsCenter(player.name),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF0F9D58),
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
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            '${player.country ?? 'Unknown'} • ${player.gender == 'M'
                                ? '♂ Men'
                                : player.gender == 'F'
                                ? '♀ Women'
                                : ''}',
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
                                    TtPlayerDetailScreen(player: player),
                              ),
                            );
                          },
                          /*
                          onLongPress: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    TtPlayerCompareScreen(playerA: player),
                              ),
                            );
                          },
                          */
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Widget _initialsCenter(String name) {
    return Center(
      child: Text(
        _initials(name),
        style: const TextStyle(
          color: Color(0xFF0F9D58),
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
    );
  }
}

class _GenderFilterBar extends StatelessWidget {
  final TtPlayerProvider provider;
  const _GenderFilterBar({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _chip('M', '♂ Men'),
        const SizedBox(width: 12),
        _chip('F', '♀ Women'),
      ],
    );
  }

  Widget _chip(String value, String label) {
    final selected = provider.genderFilter == value;
    return GestureDetector(
      onTap: () => provider.setGenderFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF0F9D58).withOpacity(0.15)
              : Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? const Color(0xFF0F9D58)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF0F9D58) : Colors.grey[600],
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

