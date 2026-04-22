import 'dart:async';
import 'package:flutter/material.dart';
import '../models/football_player.dart';
import '../services/api_service.dart';
import '../widgets/glass_widgets.dart';

const _kPink = Color(0xFFE4405F);
const _kBlue = Color(0xFF3897F0);

class FootballPlayerCompareScreen extends StatefulWidget {
  final FootballPlayer playerA;
  const FootballPlayerCompareScreen({super.key, required this.playerA});

  @override
  State<FootballPlayerCompareScreen> createState() => _FootballPlayerCompareScreenState();
}

class _FootballPlayerCompareScreenState extends State<FootballPlayerCompareScreen>
    with SingleTickerProviderStateMixin {
  FootballPlayer? _playerB;
  bool _searching = false;
  String? _searchError;
  List<FootballPlayer> _results = [];
  final TextEditingController _ctrl = TextEditingController();
  Timer? _debounce;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _ctrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearch(String q) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (q.trim().isNotEmpty) _doSearch(q.trim());
    });
  }

  Future<void> _doSearch(String q) async {
    setState(() {
      _searching = true;
      _searchError = null;
    });
    try {
      final res = await ApiService().searchFootballPlayers(q);
      setState(() => _results =
          res.items.where((p) => p.id != widget.playerA.id).toList());
    } catch (e) {
      setState(() => _searchError = e.toString());
    } finally {
      setState(() => _searching = false);
    }
  }

  void _pick(FootballPlayer p) {
    FocusScope.of(context).unfocus();
    setState(() {
      _playerB = p;
      _results = [];
      _ctrl.clear();
    });
    _fadeCtrl.forward(from: 0);
  }

  int _cmpLower(num? a, num? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    if (a < b) return -1;
    if (a > b) return 1;
    return 0;
  }

  int _cmpHigher(num? a, num? b) => _cmpLower(b, a);

  @override
  Widget build(BuildContext context) {
    final a = widget.playerA;
    return Scaffold(
      backgroundColor: const Color(0xFFFFE4E8),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: GlassContainer(
            borderRadius: 12,
            opacity: 0.1,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          'Head-to-Head',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF1D1D1F)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // ── Player cards ──────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                      child: _FootballPlayerCard(player: a, accent: _kPink)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _kPink.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('VS',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                color: _kPink)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _playerB == null
                        ? _FootballPickCard()
                        : _FootballPlayerCard(
                            player: _playerB!, accent: _kBlue),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Search ───────────────────────────────────────────────
              GlassContainer(
                borderRadius: 30,
                opacity: 0.1,
                child: TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    hintText: _playerB == null
                        ? 'Search opponent...'
                        : 'Change opponent...',
                    prefixIcon: const Icon(Icons.search, color: _kPink),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: _onSearch,
                ),
              ),

              if (_searching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: LinearProgressIndicator(
                      color: _kPink,
                      backgroundColor: Colors.transparent,
                      minHeight: 2),
                ),

              if (_results.isNotEmpty)
                GlassContainer(
                  borderRadius: 16,
                  opacity: 0.08,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: _results
                        .map((p) => ListTile(
                              dense: true,
                              leading: _FootballAvatar(
                                  player: p, size: 36, accent: _kPink),
                              title: Text(p.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              subtitle: Text(
                                  '#${p.ranking ?? 'N/A'} • ${p.currentClub ?? ''}',
                                  style: const TextStyle(fontSize: 12)),
                              onTap: () => _pick(p),
                            ))
                        .toList(),
                  ),
                ),

              if (_searchError != null)
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(_searchError!,
                      style: const TextStyle(color: Colors.red)),
                ),

              const SizedBox(height: 20),

              // ── Comparison ────────────────────────────────────────────
              if (_playerB != null) ...[
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      _FootballSection(label: 'Rankings'),
                      _FootballRow(
                        label: 'World Rank',
                        aVal: '#${a.ranking ?? 'N/A'}',
                        bVal: '#${_playerB!.ranking ?? 'N/A'}',
                        winner: _cmpLower(a.ranking, _playerB!.ranking),
                      ),
                      const SizedBox(height: 12),
                      _FootballSection(label: 'Season Stats'),
                      _FootballRow(
                        label: 'Goals',
                        aVal: '${a.goals}',
                        bVal: '${_playerB!.goals}',
                        winner: _cmpHigher(a.goals, _playerB!.goals),
                      ),
                      _FootballRow(
                        label: 'Assists',
                        aVal: '${a.assists}',
                        bVal: '${_playerB!.assists}',
                        winner: _cmpHigher(a.assists, _playerB!.assists),
                      ),
                      const SizedBox(height: 12),
                      _FootballSection(label: 'Profile'),
                      _FootballRow(
                          label: 'Club',
                          aVal: a.currentClub ?? 'N/A',
                          bVal: _playerB!.currentClub ?? 'N/A',
                          winner: 0,
                          noHighlight: true),
                      _FootballRow(
                          label: 'Country',
                          aVal: a.country ?? 'N/A',
                          bVal: _playerB!.country ?? 'N/A',
                          winner: 0,
                          noHighlight: true),
                      _FootballRow(
                          label: 'Position',
                          aVal: a.position ?? 'N/A',
                          bVal: _playerB!.position ?? 'N/A',
                          winner: 0,
                          noHighlight: true),
                      _FootballRow(
                          label: 'Market Value',
                          aVal: a.marketValue ?? 'N/A',
                          bVal: _playerB!.marketValue ?? 'N/A',
                          winner: 0,
                          noHighlight: true),
                      const SizedBox(height: 24),
                      _FootballOverallWinner(a: a, b: _playerB!),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FootballAvatar extends StatelessWidget {
  final FootballPlayer player;
  final double size;
  final Color accent;
  const _FootballAvatar(
      {required this.player, required this.size, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent.withOpacity(0.3), width: 2),
        color: accent.withOpacity(0.1),
      ),
      child: ClipOval(
        child: player.imageUrl != null
            ? Image.network(
                player.imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                    child: Text(_initials(player.name),
                        style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.bold,
                            fontSize: size * 0.32))),
              )
            : Center(
                child: Text(_initials(player.name),
                    style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.bold,
                        fontSize: size * 0.32))),
      ),
    );
  }

  String _initials(String name) {
    final p = name.trim().split(' ');
    if (p.length >= 2) return '${p[0][0]}${p[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}

class _FootballPlayerCard extends StatelessWidget {
  final FootballPlayer player;
  final Color accent;
  const _FootballPlayerCard({required this.player, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      opacity: 0.12,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _FootballAvatar(player: player, size: 56, accent: accent),
          const SizedBox(height: 8),
          Text(player.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text('#${player.ranking ?? 'N/A'}',
              style: TextStyle(
                  color: accent, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

class _FootballPickCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      opacity: 0.07,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _kBlue.withOpacity(0.3), width: 2),
              color: _kBlue.withOpacity(0.07),
            ),
            child: const Icon(Icons.add, color: _kBlue, size: 26),
          ),
          const SizedBox(height: 8),
          const Text('Pick Opponent',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: _kBlue, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
}

class _FootballSection extends StatelessWidget {
  final String label;
  const _FootballSection({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                  color: _kPink, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: _kPink)),
        ],
      ),
    );
  }
}

class _FootballRow extends StatelessWidget {
  final String label;
  final String aVal;
  final String bVal;
  final int winner;
  final bool noHighlight;
  const _FootballRow({
    required this.label,
    required this.aVal,
    required this.bVal,
    required this.winner,
    this.noHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final aWins = !noHighlight && winner == -1;
    final bWins = !noHighlight && winner == 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassContainer(
        borderRadius: 14,
        opacity: 0.08,
        blur: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: aWins ? _kPink.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (aWins)
                      const Icon(Icons.emoji_events_rounded,
                          size: 14, color: _kPink),
                    if (aWins) const SizedBox(width: 4),
                    Flexible(
                      child: Text(aVal,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: aWins ? _kPink : Colors.black87),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 90,
              child: Center(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500)),
              ),
            ),
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: bWins ? _kBlue.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(bVal,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: bWins ? _kBlue : Colors.black87),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (bWins) const SizedBox(width: 4),
                    if (bWins)
                      const Icon(Icons.emoji_events_rounded,
                          size: 14, color: _kBlue),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FootballOverallWinner extends StatelessWidget {
  final FootballPlayer a;
  final FootballPlayer b;
  const _FootballOverallWinner({required this.a, required this.b});

  @override
  Widget build(BuildContext context) {
    int aScore = 0, bScore = 0;

    void check(num? aV, num? bV, {bool lowerBetter = false}) {
      if (aV == null || bV == null) return;
      if (lowerBetter) {
        if (aV < bV) aScore++;
        if (bV < aV) bScore++;
      } else {
        if (aV > bV) aScore++;
        if (bV > aV) bScore++;
      }
    }

    check(a.ranking, b.ranking, lowerBetter: true);
    check(a.goals, b.goals);
    check(a.assists, b.assists);

    final String wName;
    final Color wColor;
    final IconData wIcon;

    if (aScore > bScore) {
      wName = a.name;
      wColor = _kPink;
      wIcon = Icons.emoji_events_rounded;
    } else if (bScore > aScore) {
      wName = b.name;
      wColor = _kBlue;
      wIcon = Icons.emoji_events_rounded;
    } else {
      wName = 'Even Match!';
      wColor = Colors.orange;
      wIcon = Icons.handshake_rounded;
    }

    return GlassContainer(
      borderRadius: 20,
      opacity: 0.12,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(wIcon, color: wColor, size: 36),
          const SizedBox(height: 8),
          const Text('Overall Edge',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(wName,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: wColor)),
          if (aScore != bScore)
            Text('($aScore vs $bScore categories won)',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
