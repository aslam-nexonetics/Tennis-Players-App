import 'package:flutter/material.dart';
import '../models/football_club.dart';
import '../widgets/glass_widgets.dart';

class FootballClubDetailScreen extends StatelessWidget {
  final FootballClub club;

  const FootballClubDetailScreen({super.key, required this.club});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4E8),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GlassContainer(
            borderRadius: 12,
            opacity: 0.1,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return _buildWebLayout(context, constraints);
          }
          return _buildMobileLayout(context);
        },
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        Container(
          height: 400,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF5F6D),
                Color(0xFFE4405F),
                Color(0xFF911E3B),
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 80),
                _buildClubLogo(size: 140),
                const SizedBox(height: 16),
                Text(
                  '🏆 ${club.league ?? 'Professional Football'}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (club.ranking != null)
                      _buildRankBadge('World #${club.ranking}', Colors.amber),
                    if (club.domesticRanking != null)
                      _buildRankBadge(
                          'Domestic #${club.domesticRanking}', Colors.blue[400]!),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Scrollable content
        SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 380),
              GlassContainer(
                borderRadius: 40,
                opacity: 0.2,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildHeaderInfo(),
                    const Divider(height: 40, thickness: 1),
                    _buildMainDetails(),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebLayout(BuildContext context, BoxConstraints constraints) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 40),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Profile Card
              SizedBox(
                width: 350,
                child: GlassContainer(
                  borderRadius: 30,
                  opacity: 0.2,
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      Container(
                        height: 300,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(30)),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFF5F6D), Color(0xFFE4405F)],
                          ),
                        ),
                        child: Center(child: _buildClubLogo(size: 160)),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeaderInfo(),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                if (club.ranking != null)
                                  _buildRankBadge(
                                      'World #${club.ranking}', Colors.amber),
                                if (club.domesticRanking != null)
                                  _buildRankBadge(
                                      'Domestic #${club.domesticRanking}',
                                      Colors.blue[400]!),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 40),
              // Right Column: Details
              Expanded(
                child: GlassContainer(
                  borderRadius: 30,
                  opacity: 0.15,
                  padding: const EdgeInsets.all(32),
                  child: _buildMainDetails(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClubLogo({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.2),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 3,
        ),
      ),
      child: ClipOval(
        child: club.imageUrl != null
            ? Image.network(
                club.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialsWidget(club.name, 48),
              )
            : _initialsWidget(club.name, 48),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          club.name,
          style: const TextStyle(
              fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -1),
        ),
        Text(
          '${club.country ?? 'Unknown'} • Founded ${club.foundedYear ?? 'TBD'}',
          style: TextStyle(
              fontSize: 18, color: Colors.grey[700], fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildMainDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildQuickStatsSection(),
        const SizedBox(height: 40),
        if (club.honors != null && club.honors!.isNotEmpty) ...[
          const Text(
            'Major Honors',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE4405F)),
          ),
          const SizedBox(height: 16),
          _buildHonorsGrid(),
          const SizedBox(height: 40),
        ],
        const Text(
          'About the Club',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE4405F)),
        ),
        const SizedBox(height: 12),
        Text(
          club.description ?? 'No information available.',
          style: const TextStyle(
              fontSize: 15, height: 1.6, color: Color(0xFF2D2D2F)),
        ),
        const SizedBox(height: 40),
        const Text(
          'Governance & Financials',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE4405F)),
        ),
        const SizedBox(height: 16),
        _buildGovernanceGrid(),
        const SizedBox(height: 40),
        const Text(
          'Venue & Attendance',
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE4405F)),
        ),
        const SizedBox(height: 16),
        _buildVenueCard(),
        const SizedBox(height: 40),
        if (club.mainRivals != null) ...[
          const Text(
            'Main Rivals',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE4405F)),
          ),
          const SizedBox(height: 12),
          _buildRivalsChips(),
        ],
      ],
    );
  }

  Widget _buildRankBadge(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 8, right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildQuickStatsSection() {
    return Row(
      children: [
        Expanded(
          child: _buildStatBadge('TOTAL TROPHIES', '${club.totalTrophies}', Icons.military_tech_rounded, Colors.amber[800]!),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatBadge('MARKET VALUE', club.marketValue ?? 'TBD', Icons.account_balance_wallet_rounded, Colors.green[700]!),
        ),
      ],
    );
  }

  Widget _buildStatBadge(String label, String value, IconData icon, Color color) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 20),
      borderRadius: 20,
      opacity: 0.1,
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHonorsGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: club.honors!.entries.map((e) => _buildHonorCard(e.key, e.value)).toList(),
    );
  }

  Widget _buildHonorCard(String title, int count) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.4),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE4405F).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFE4405F)),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGovernanceGrid() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildInfoCard('Captain', club.captain ?? 'TBD', Icons.person_pin, 0.45),
        _buildInfoCard('Manager', club.manager ?? 'TBD', Icons.sports_rounded, 0.45),
        _buildInfoCard('Owner/Chairman', club.owner ?? 'TBD', Icons.business_rounded, 1.0),
      ],
    );
  }

  Widget _buildVenueCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: 20,
      opacity: 0.1,
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.stadium, size: 40, color: Color(0xFFE4405F)),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(club.stadium ?? 'Unknown Stadium', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('Capacity: ${_formatNum(club.capacity)}', style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
              ),
            ],
          ),
          if (club.averageAttendance != null) ...[
            const Divider(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Average Attendance', style: TextStyle(fontWeight: FontWeight.w500)),
                Text(_formatNum(club.averageAttendance), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE4405F))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRivalsChips() {
    final rivals = club.mainRivals!.split(',');
    return Wrap(
      spacing: 8,
      children: rivals.map((r) => Chip(
        label: Text(r.trim(), style: const TextStyle(fontSize: 12)),
        backgroundColor: const Color(0xFFE4405F).withOpacity(0.1),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      )).toList(),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, double widthFactor) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GlassContainer(
          width: constraints.maxWidth * widthFactor - (widthFactor < 1.0 ? 6 : 0),
          padding: const EdgeInsets.all(16),
          borderRadius: 15,
          opacity: 0.1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: const Color(0xFFE4405F)),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), overflow: TextOverflow.ellipsis),
            ],
          ),
        );
      }
    );
  }

  String _formatNum(int? num) {
    if (num == null) return 'Unknown';
    return num.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  Widget _initialsWidget(String name, double fontSize) {
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2 ? '${parts[0][0]}${parts[1][0]}'.toUpperCase() : name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Center(child: Text(initials, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: fontSize)));
  }
}
