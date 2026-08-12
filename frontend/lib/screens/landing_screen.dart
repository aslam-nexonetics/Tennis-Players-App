import 'dart:ui';
import 'package:flutter/material.dart';
import '../widgets/glass_widgets.dart';
import 'auth_screen.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // Dynamic Background Glowing Orbs
          Positioned(
            top: -120,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x776366F1), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 450,
              height: 450,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x7706B6D4), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.4,
            left: MediaQuery.of(context).size.width * 0.3,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x44818CF8), Colors.transparent],
                ),
              ),
            ),
          ),

          // Main Layout Content
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 850;
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isWide ? 48 : 20,
                    vertical: 24,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1200),
                      child: Column(
                        children: [
                          // Responsive Hero + Auth Body
                          isWide
                              ? Column(
                                  children: [
                                    _buildHeaderBar(context),
                                    const SizedBox(height: 40),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 6,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 40, top: 20),
                                            child: _buildHeroSection(context),
                                          ),
                                        ),
                                        const Expanded(
                                          flex: 5,
                                          child: AuthCardWidget(),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 40),
                                    _buildFooter(),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const SizedBox(height: 10),
                                    const AuthCardWidget(),
                                    const SizedBox(height: 24),
                                    _buildFooter(),
                                  ],
                                ),

                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Landing Top Header ──────────────────────────────────────────────────────
  Widget _buildHeaderBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF06B6D4)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.4),
                    blurRadius: 12,
                  )
                ],
              ),
              child: const Icon(Icons.sports_tennis_rounded, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Sports Analytics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, color: Colors.greenAccent, size: 16),
              SizedBox(width: 6),
              Text(
                'OAuth2 Encrypted',
                style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Hero Section (Presentation for Web) ──────────────────────────────────
  Widget _buildHeroSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        // Tagline Pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bolt_rounded, color: Color(0xFF818CF8), size: 16),
              SizedBox(width: 6),
              Text(
                'Real-Time Sports Intelligence Platform',
                style: TextStyle(color: Color(0xFF818CF8), fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Main Headline
        const Text(
          'Explore Tennis, Football & Basketball Analytics',
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            height: 1.2,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 16),

        // Subtitle
        Text(
          'Access comprehensive player profiles, ATP/WTA rankings, historical performance trends, and head-to-head statistics in a unified glassmorphic platform.',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.7),
            height: 1.5,
          ),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 28),

        // Sport Badges Wrap
        Wrap(
          alignment: WrapAlignment.start,
          spacing: 10,
          runSpacing: 10,
          children: [
            _buildFeaturePill('🎾 ATP & WTA Tennis', const Color(0xFF6366F1)),
            _buildFeaturePill('🏓 Table Tennis', const Color(0xFF06B6D4)),
            _buildFeaturePill('⚽ Football Teams', const Color(0xFF10B981)),
            _buildFeaturePill('🏀 Basketball Clubs', const Color(0xFFF59E0B)),
            _buildFeaturePill('📊 Head-to-Head Stats', const Color(0xFFEC4899)),
          ],
        ),

        const SizedBox(height: 32),

        // Statistics Highlight Card
        GlassContainer(
          opacity: 0.1,
          borderRadius: 24,
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('10,000+', 'Active Players'),
              _buildStatDivider(),
              _buildStatItem('30+ Yrs', 'Historical Data'),
              _buildStatDivider(),
              _buildStatItem('Instant', 'H2H Comparison'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturePill(String text, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.6)),
        ),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 30,
      width: 1,
      color: Colors.white.withOpacity(0.15),
    );
  }

  Widget _buildFooter() {
    return Text(
      '© 2026 Sports Data Engine • All Rights Reserved',
      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
    );
  }
}
