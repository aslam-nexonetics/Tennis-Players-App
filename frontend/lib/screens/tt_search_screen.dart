import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/tt_player_provider.dart';
import '../widgets/glass_widgets.dart';
import 'tt_player_detail_screen.dart';

class TtSearchScreen extends StatelessWidget {
  const TtSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TtPlayerProvider>(context);

    return Column(
      children: [
        const SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_tennis, color: Color(0xFF0F9D58), size: 26),
            const SizedBox(width: 8),
            const Text(
              'TT Search',
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
          'Find table tennis athletes',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 12),
        // Gender filter chips
        _GenderFilterChips(provider: provider),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: GlassContainer(
            borderRadius: 30,
            opacity: 0.1,
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search table tennis players...',
                prefixIcon: Icon(Icons.search, color: Color(0xFF0F9D58)),
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
              color: Color(0xFF0F9D58),
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
                    child: Text('Search for table tennis players!'),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 120,
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
                              color: const Color(0xFF0F9D58).withOpacity(0.12),
                              border: Border.all(
                                color: const Color(0xFF0F9D58).withOpacity(0.3),
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
                            '${player.country ?? 'Unknown'} • ${player.gender == 'M'
                                ? 'Men'
                                : player.gender == 'F'
                                ? 'Women'
                                : ''}',
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
                                  color: Color(0xFF0F9D58),
                                ),
                              ),
                            ],
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
        color: const Color(0xFF0F9D58),
        fontWeight: FontWeight.bold,
        fontSize: fontSize,
      ),
    ),
  );
}

class _GenderFilterChips extends StatelessWidget {
  final TtPlayerProvider provider;
  const _GenderFilterChips({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _chip(context, null, 'All'),
        const SizedBox(width: 8),
        _chip(context, 'M', 'Men'),
        const SizedBox(width: 8),
        _chip(context, 'F', 'Women'),
      ],
    );
  }

  Widget _chip(BuildContext context, String? value, String label) {
    final selected = provider.genderFilter == value;
    return GestureDetector(
      onTap: () => provider.setGenderFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
