import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/basketball_club_provider.dart';
import 'basketball_club_detail_screen.dart';

class BasketballTopClubsScreen extends StatefulWidget {
  const BasketballTopClubsScreen({super.key});

  @override
  State<BasketballTopClubsScreen> createState() => _BasketballTopClubsScreenState();
}

class _BasketballTopClubsScreenState extends State<BasketballTopClubsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BasketballClubProvider>().fetchTopClubs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Consumer<BasketballClubProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading && provider.topClubs.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: Colors.orange));
          }
          if (provider.error.isNotEmpty && provider.topClubs.isEmpty) {
            return Center(child: Text('Error: ${provider.error}', style: const TextStyle(color: Colors.white)));
          }
          return RefreshIndicator(
            onRefresh: () => provider.fetchTopClubs(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.topClubs.length,
              itemBuilder: (context, index) {
                final club = provider.topClubs[index];
                return Card(
                  color: Colors.white.withOpacity(0.1),
                  margin: const EdgeInsets.only(bottom: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => BasketballClubDetailScreen(club: club)),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Text(
                            '${index + 1}',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                          const SizedBox(width: 20),
                          club.imageUrl != null
                              ? CircleAvatar(radius: 25, backgroundImage: NetworkImage(club.imageUrl!))
                              : const CircleAvatar(radius: 25, backgroundColor: Colors.white12, child: Icon(Icons.sports_basketball, color: Colors.white)),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(club.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                Text('${club.league} • ${club.conference}', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Icon(Icons.emoji_events, color: Colors.orange, size: 16),
                              Text('${club.titles} Titles', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    );
  }
}
