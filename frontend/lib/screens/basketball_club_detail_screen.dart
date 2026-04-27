import 'package:flutter/material.dart';
import '../models/basketball_club.dart';

class BasketballClubDetailScreen extends StatelessWidget {
  final BasketballClub club;

  const BasketballClubDetailScreen({super.key, required this.club});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(club.name),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.orange.shade900,
              Colors.black87,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 100),
              // Header Section
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: club.imageUrl != null
                            ? Image.network(club.imageUrl!, fit: BoxFit.cover)
                            : Container(
                                color: Colors.white24,
                                child: const Icon(Icons.sports_basketball, size: 60, color: Colors.white),
                              ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            club.name,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '${club.city}, ${club.country}',
                            style: TextStyle(fontSize: 18, color: Colors.white.withOpacity(0.8)),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${club.league} • ${club.conference}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Stats Overview Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatItem('Titles', '${club.titles}', Icons.emoji_events),
                    _buildStatItem('Playoffs', '${club.playoffAppearances}', Icons.trending_up),
                    _buildStatItem('Rank', '#${club.ranking}', Icons.bar_chart),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Detailed Sections
              _buildGlassCard(
                title: 'Team Personnel',
                icon: Icons.groups,
                child: Column(
                  children: [
                    _buildDetailRow('Head Coach', club.headCoach ?? 'N/A'),
                    _buildDetailRow('Star Player', club.starPlayer ?? 'N/A'),
                    _buildDetailRow('General Manager', club.generalManager ?? 'N/A'),
                    _buildDetailRow('Owner', club.owner ?? 'N/A'),
                  ],
                ),
              ),

              _buildGlassCard(
                title: 'Arena & Market',
                icon: Icons.business,
                child: Column(
                  children: [
                    _buildDetailRow('Home Arena', club.arena ?? 'N/A'),
                    _buildDetailRow('Capacity', club.capacity?.toString() ?? 'N/A'),
                    _buildDetailRow('Market Value', club.marketValue ?? 'N/A'),
                    _buildDetailRow('Current Record', club.currentSeasonRecord ?? 'N/A'),
                  ],
                ),
              ),

              if (club.honors != null && club.honors!.isNotEmpty)
                _buildGlassCard(
                  title: 'Club Honors',
                  icon: Icons.military_tech,
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: club.honors!.entries.map((e) {
                      return Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              e.value.toString(),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                            Text(
                              e.key,
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),

              _buildGlassCard(
                title: 'Description',
                icon: Icons.info_outline,
                child: Text(
                  club.description ?? 'No description available.',
                  style: const TextStyle(color: Colors.white70, height: 1.5),
                ),
              ),

              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.orange, size: 28),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }

  Widget _buildGlassCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.orange, size: 24),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          const Divider(color: Colors.white24, height: 25),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
