import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/basketball_club_provider.dart';
import '../widgets/glass_widgets.dart';
import 'basketball_club_detail_screen.dart';

class BasketballTopClubsScreen extends StatefulWidget {
  const BasketballTopClubsScreen({super.key});

  @override
  State<BasketballTopClubsScreen> createState() =>
      _BasketballTopClubsScreenState();
}

class _BasketballTopClubsScreenState extends State<BasketballTopClubsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BasketballClubProvider>().fetchTopClubs();
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
      context.read<BasketballClubProvider>().fetchTopClubs(loadMore: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BasketballClubProvider>(context);

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
                        Icon(Icons.sports_basketball,
                            color: Colors.orange, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Club Rankings',
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
                      'Global Basketball Giants',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Category Toggle
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => provider.setCategory('men'),
                  child: GlassContainer(
                    opacity: provider.selectedCategory == 'men' ? 0.3 : 0.05,
                    borderRadius: 12,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Text(
                        'Men',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: provider.selectedCategory == 'men'
                              ? Colors.orange
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
                    borderRadius: 12,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: Text(
                        'Women',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: provider.selectedCategory == 'women'
                              ? Colors.orange
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
        const SizedBox(height: 8),
        Expanded(
          child: Consumer<BasketballClubProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading && provider.topClubs.isEmpty) {
                return const Center(
                    child: CircularProgressIndicator(color: Colors.orange));
              }
              if (provider.error.isNotEmpty && provider.topClubs.isEmpty) {
                return Center(
                    child: Text('Error: ${provider.error}',
                        style: const TextStyle(color: Colors.redAccent)));
              }
              return RefreshIndicator(
                onRefresh: () => provider.fetchTopClubs(),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).padding.bottom + 100,
                  ),
                  itemCount: provider.topClubs.length +
                      (provider.topClubsHasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.topClubs.length) {
                      return Opacity(
                        opacity: provider.isFetchingMore ? 1.0 : 0.0,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                              child: CircularProgressIndicator(
                                  color: Colors.orange)),
                        ),
                      );
                    }
                    final club = provider.topClubs[index];
                    return Card(
                      color: Colors.white.withOpacity(0.1),
                      margin: const EdgeInsets.only(bottom: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    BasketballClubDetailScreen(club: club)),
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Text(
                                '${club.ranking ?? index + 1}',
                                style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange),
                              ),
                              const SizedBox(width: 20),
                              club.imageUrl != null
                                  ? CircleAvatar(
                                      radius: 25,
                                      backgroundImage:
                                          NetworkImage(club.imageUrl!))
                                  : const CircleAvatar(
                                      radius: 25,
                                      backgroundColor: Colors.white12,
                                      child: Icon(Icons.sports_basketball,
                                          color: Colors.white)),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(club.name,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                                    Text(
                                        '${club.league} • ${club.category.toUpperCase()}',
                                        style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.7))),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Icon(Icons.emoji_events,
                                      color: Colors.orange, size: 16),
                                  Text('${club.titles} Titles',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
