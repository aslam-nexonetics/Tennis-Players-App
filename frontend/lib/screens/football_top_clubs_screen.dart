import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/football_club_provider.dart';
import '../widgets/glass_widgets.dart';
import 'football_club_detail_screen.dart';

class FootballTopClubsScreen extends StatefulWidget {
  const FootballTopClubsScreen({super.key});

  @override
  State<FootballTopClubsScreen> createState() => _FootballTopClubsScreenState();
}

class _FootballTopClubsScreenState extends State<FootballTopClubsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<FootballClubProvider>(context, listen: false).fetchTopClubs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FootballClubProvider>(context);

    return Column(
      children: [
        const SizedBox(height: 50),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.stars, color: Color(0xFFE4405F), size: 26),
            const SizedBox(width: 8),
            const Text(
              'Top Football Clubs',
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
          'World rankings based on club coefficients',
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
        const SizedBox(height: 10),
        Expanded(
          child: provider.isLoading && provider.topClubs.isEmpty
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE4405F)))
              : provider.error != null && provider.topClubs.isEmpty
                  ? Center(child: Text('Error: ${provider.error}'))
                  : RefreshIndicator(
                      color: const Color(0xFFE4405F),
                      onRefresh: provider.fetchTopClubs,
                      child: ListView.builder(
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          bottom: MediaQuery.of(context).padding.bottom + 100,
                        ),
                        itemCount: provider.topClubs.length,
                        itemBuilder: (context, index) {
                          final club = provider.topClubs[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: GlassContainer(
                              borderRadius: 20,
                              child: ListTile(
                                leading: SizedBox(
                                  width: 75,
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 30,
                                        child: Text(
                                          '#${club.ranking}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFE4405F),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: const Color(0xFFE4405F).withOpacity(0.1),
                                        ),
                                        child: ClipOval(
                                          child: club.imageUrl != null
                                              ? Image.network(
                                                  club.imageUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) => _buildInitials(club.name),
                                                )
                                              : _buildInitials(club.name),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                title: Text(
                                  club.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text('${club.league} • ${club.country}'),
                                trailing: const Icon(Icons.chevron_right),
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
        ),
      ],
    );
  }

  Widget _buildInitials(String name) {
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : '?';
    return Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFFE4405F),
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}
