import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/football_club_provider.dart';
import '../widgets/glass_widgets.dart';
import 'football_club_detail_screen.dart';

class FootballSearchScreen extends StatefulWidget {
  const FootballSearchScreen({super.key});

  @override
  State<FootballSearchScreen> createState() => _FootballSearchScreenState();
}

class _FootballSearchScreenState extends State<FootballSearchScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FootballClubProvider>(context);

    // Sync controller with provider if provider was cleared externally
    if (provider.lastQuery.isEmpty && _controller.text.isNotEmpty) {
      _controller.clear();
    }

    return Column(
      children: [
        const SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sports_soccer, color: Color(0xFFE4405F), size: 26),
            const SizedBox(width: 8),
            const Text(
              'Football Clubs',
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
          'Explore football clubs globally',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
        const SizedBox(height: 20),
        // Category Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => provider.setCategory('men'),
                  child: GlassContainer(
                    opacity: provider.selectedCategory == 'men' ? 0.3 : 0.05,
                    borderRadius: 15,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'Men',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: provider.selectedCategory == 'men'
                              ? const Color(0xFFE4405F)
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => provider.setCategory('women'),
                  child: GlassContainer(
                    opacity: provider.selectedCategory == 'women' ? 0.3 : 0.05,
                    borderRadius: 15,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        'Women',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: provider.selectedCategory == 'women'
                              ? const Color(0xFFE4405F)
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: GlassContainer(
            borderRadius: 30,
            opacity: 0.1,
            child: TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Search football clubs...',
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
          child: provider.clubs.isEmpty && !provider.isLoading
              ? Center(
                  child: Opacity(
                    opacity: 0.5,
                    child: Text(provider.lastQuery.isEmpty
                        ? 'Search for football clubs!'
                        : 'No results found for "${provider.lastQuery}"'),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 100,
                  ),
                  itemCount: provider.clubs.length,
                  itemBuilder: (context, index) {
                    final club = provider.clubs[index];
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
                              child: club.imageUrl != null
                                  ? Image.network(
                                      club.imageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => _initialsWidget(club.name, 18),
                                    )
                                  : _initialsWidget(club.name, 18),
                            ),
                          ),
                          title: Text(
                            club.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${club.country ?? 'Unknown'} • ${club.league ?? 'No League'}',
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'World Rank',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                '#${club.ranking ?? 'N/A'}',
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
                                    FootballClubDetailScreen(club: club),
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
