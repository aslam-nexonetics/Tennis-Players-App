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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BasketballClubProvider>(context);

    // Sync controller with provider if provider was cleared externally
    if (provider.lastQuery.isEmpty && _controller.text.isNotEmpty) {
      _controller.clear();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Category Toggle
            Row(
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
                                ? Colors.orange
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
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
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              onChanged: (value) => provider.searchClubs(value),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search NBA, WNBA & Global Clubs...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Consumer<BasketballClubProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator(color: Colors.orange));
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
                    itemCount: provider.searchResults.length,
                    itemBuilder: (context, index) {
                      final club = provider.searchResults[index];
                      return Card(
                        color: Colors.white.withOpacity(0.1),
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
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
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${club.league} • ${club.category.toUpperCase()}',
                            style: TextStyle(color: Colors.white.withOpacity(0.7)),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BasketballClubDetailScreen(club: club),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
