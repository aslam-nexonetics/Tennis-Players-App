import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/basketball_club_provider.dart';
import '../widgets/glass_widgets.dart';
import 'basketball_club_detail_screen.dart';

class BasketballSearchScreen extends StatefulWidget {
  const BasketballSearchScreen({super.key});

  @override
  State<BasketballSearchScreen> createState() => _BasketballSearchScreenState();
}

class _BasketballSearchScreenState extends State<BasketballSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        _controller.text.isNotEmpty) {
      context
          .read<BasketballClubProvider>()
          .searchClubsCall(_controller.text, loadMore: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BasketballClubProvider>(context);

    // Sync controller with provider if provider was cleared externally
    if (provider.lastQuery.isEmpty && _controller.text.isNotEmpty) {
      _controller.clear();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              const Icon(Icons.sports_basketball, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoops Search',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    Text(
                      'Analyze basketball giants',
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: GlassContainer(
            borderRadius: 20,
            opacity: 0.1,
            child: TextField(
              controller: _controller,
              onChanged: provider.searchClubs,
              decoration: const InputDecoration(
                hintText: 'Search NBA, WNBA & Global Clubs...',
                hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                prefixIcon: Icon(Icons.search, color: Colors.orange, size: 20),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),
            Expanded(
              child: Consumer<BasketballClubProvider>(
                builder: (context, provider, child) {
                  if (provider.isSearching && provider.searchResults.isEmpty) {
                    return const Center(
                        child: CircularProgressIndicator(color: Colors.orange));
                  }
                  if (provider.searchResults.isEmpty) {
                    return Center(
                      child: Text(
                        provider.lastQuery.isEmpty
                            ? 'Enter a club name to start'
                            : 'No results found for "${provider.lastQuery}"',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: MediaQuery.of(context).padding.bottom + 140,
                    ),
                    itemCount: provider.searchResults.length +
                        (provider.searchHasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == provider.searchResults.length) {
                        return Opacity(
                          opacity: provider.isFetchingMore ? 1.0 : 0.0,
                          child: const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: CircularProgressIndicator(
                                  color: Colors.orange),
                            ),
                          ),
                        );
                      }
                      final club = provider.searchResults[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: GlassContainer(
                          blur: 0,
                          borderRadius: 20,
                        child: ListTile(
                          leading: club.imageUrl != null
                              ? CircleAvatar(
                                  backgroundImage: NetworkImage(club.imageUrl!),
                                )
                              : const CircleAvatar(
                                  backgroundColor: Colors.orange,
                                  child: Icon(Icons.sports_basketball, color: Colors.white),
                                ),
                          title: Text(
                            club.name,
                            style: const TextStyle(color: Color(0xFF1D1D1F), fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${club.league} • ${club.category.toUpperCase()}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BasketballClubDetailScreen(club: club),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                    },
                  );
                },
              ),
            ),
      ],
    );
  }
}
