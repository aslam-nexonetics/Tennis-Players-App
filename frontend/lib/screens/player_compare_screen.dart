import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/player.dart';
import '../services/api_service.dart';
import '../widgets/glass_widgets.dart';

class PlayerCompareScreen extends StatefulWidget {
  final Player playerA;
  const PlayerCompareScreen({super.key, required this.playerA});

  @override
  State<PlayerCompareScreen> createState() => _PlayerCompareScreenState();
}

class _PlayerCompareScreenState extends State<PlayerCompareScreen>
    with TickerProviderStateMixin {
  Player? _playerB;
  bool _searching = false;
  String? _searchError;
  List<Player> _searchResults = [];
  final TextEditingController _searchCtrl = TextEditingController();
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
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String q) {
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
      final res = await ApiService().searchPlayers(q, size: 10);
      setState(() => _searchResults =
          res.items.where((p) => p.id != widget.playerA.id).toList());
    } catch (e) {
      setState(() => _searchError = e.toString());
    } finally {
      setState(() => _searching = false);
    }
  }

  void _selectPlayerB(Player p) {
    FocusScope.of(context).unfocus();
    setState(() {
      _playerB = p;
      _searchResults = [];
      _searchCtrl.clear();
    });
    _fadeCtrl.forward(from: 0);
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  String _winRate(Player p) {
    final total = p.wins + p.losses;
    if (total == 0) return '0%';
    return '${((p.wins / total) * 100).toStringAsFixed(1)}%';
  }

  // Returns -1 (A wins), 0 (tie), 1 (B wins) for a stat where LOWER is better
  int _cmpLower(num? a, num? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    if (a < b) return -1;
    if (a > b) return 1;
    return 0;
  }

  // Returns -1 (A wins), 0 (tie), 1 (B wins) for a stat where HIGHER is better
  int _cmpHigher(num? a, num? b) => _cmpLower(b, a);

  @override
  Widget build(BuildContext context) {
    final a = widget.playerA;
    return Scaffold(
      backgroundColor: const Color(0xFFCFDEF3),
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
              icon:
                  const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
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
              // ── Player cards row ──────────────────────────────────────
              Row(
                children: [
                  Expanded(child: _PlayerCard(player: a, accent: Colors.indigo)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.indigo.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('VS',
                            style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                                color: Colors.indigo)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _playerB == null
                        ? _PickPlayerCard(accent: Colors.purple)
                        : _PlayerCard(
                            player: _playerB!, accent: Colors.purple),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Search box for player B ───────────────────────────────
              GlassContainer(
                borderRadius: 30,
                opacity: 0.1,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: _playerB == null
                        ? 'Search opponent...'
                        : 'Change opponent...',
                    prefixIcon:
                        const Icon(Icons.search, color: Colors.indigo),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),

              if (_searching)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: LinearProgressIndicator(
                      backgroundColor: Colors.transparent,
                      minHeight: 2),
                ),

              if (_searchResults.isNotEmpty)
                GlassContainer(
                  borderRadius: 16,
                  opacity: 0.08,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    children: _searchResults
                        .map((p) => ListTile(
                              dense: true,
                              leading: _Avatar(
                                  imageUrl: p.imageUrl,
                                  name: p.name,
                                  size: 36,
                                  accent: Colors.indigo),
                              title: Text(p.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14)),
                              subtitle: Text(
                                  '#${p.ranking ?? 'N/A'} • ${p.country ?? ''}',
                                  style: const TextStyle(fontSize: 12)),
                              onTap: () => _selectPlayerB(p),
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

              // ── Comparison table ──────────────────────────────────────
              if (_playerB != null) ...[
                FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    children: [
                      _SectionLabel(label: 'Rankings'),
                      _CompareRow(
                        label: 'Current Rank',
                        aVal: '#${a.ranking ?? 'N/A'}',
                        bVal: '#${_playerB!.ranking ?? 'N/A'}',
                        winner: _cmpLower(a.ranking, _playerB!.ranking),
                      ),
                      _CompareRow(
                        label: 'Career High',
                        aVal: '#${a.highestRanking ?? 'N/A'}',
                        bVal: '#${_playerB!.highestRanking ?? 'N/A'}',
                        winner: _cmpLower(
                            a.highestRanking, _playerB!.highestRanking),
                      ),
                      const SizedBox(height: 12),
                      _SectionLabel(label: 'Performance'),
                      _CompareRow(
                        label: 'Wins',
                        aVal: '${a.wins}',
                        bVal: '${_playerB!.wins}',
                        winner: _cmpHigher(a.wins, _playerB!.wins),
                      ),
                      _CompareRow(
                        label: 'Losses',
                        aVal: '${a.losses}',
                        bVal: '${_playerB!.losses}',
                        winner: _cmpLower(a.losses, _playerB!.losses),
                      ),
                      _CompareRow(
                        label: 'Win Rate',
                        aVal: _winRate(a),
                        bVal: _winRate(_playerB!),
                        winner: _cmpHigher(
                          a.wins + a.losses == 0
                              ? null
                              : a.wins / (a.wins + a.losses),
                          _playerB!.wins + _playerB!.losses == 0
                              ? null
                              : _playerB!.wins /
                                  (_playerB!.wins + _playerB!.losses),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionLabel(label: 'Profile'),
                      _CompareRow(
                        label: 'Country',
                        aVal: a.country ?? 'N/A',
                        bVal: _playerB!.country ?? 'N/A',
                        winner: 0,
                        noHighlight: true,
                      ),
                      _CompareRow(
                        label: 'Age',
                        aVal: a.age != null ? '${a.age} yrs' : 'N/A',
                        bVal: _playerB!.age != null
                            ? '${_playerB!.age} yrs'
                            : 'N/A',
                        winner: 0,
                        noHighlight: true,
                      ),
                      _CompareRow(
                        label: 'Height',
                        aVal: a.height ?? 'N/A',
                        bVal: _playerB!.height ?? 'N/A',
                        winner: 0,
                        noHighlight: true,
                      ),
                      _CompareRow(
                        label: 'Playing Style',
                        aVal: a.playingStyle ?? 'N/A',
                        bVal: _playerB!.playingStyle ?? 'N/A',
                        winner: 0,
                        noHighlight: true,
                      ),
                      const SizedBox(height: 24),
                      _OverallWinner(a: a, b: _playerB!),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ] else ...[
                const SizedBox(height: 40),
                const Opacity(
                  opacity: 0.4,
                  child: Column(
                    children: [
                      Icon(Icons.compare_arrows_rounded,
                          size: 64, color: Colors.indigo),
                      SizedBox(height: 12),
                      Text('Search for an opponent above\nto start the comparison',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, height: 1.5)),
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

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _PlayerCard extends StatelessWidget {
  final Player player;
  final Color accent;
  const _PlayerCard({required this.player, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      opacity: 0.12,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          _Avatar(
              imageUrl: player.imageUrl,
              name: player.name,
              size: 56,
              accent: accent),
          const SizedBox(height: 8),
          Text(
            player.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text('#${player.ranking ?? 'N/A'}',
              style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ],
      ),
    );
  }
}

class _PickPlayerCard extends StatelessWidget {
  final Color accent;
  const _PickPlayerCard({required this.accent});

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
              border: Border.all(
                  color: accent.withOpacity(0.3), width: 2),
              color: accent.withOpacity(0.07),
            ),
            child: Icon(Icons.add, color: accent, size: 26),
          ),
          const SizedBox(height: 8),
          Text('Pick Opponent',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double size;
  final Color accent;
  const _Avatar(
      {required this.imageUrl,
      required this.name,
      required this.size,
      required this.accent});

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

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
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Center(
                    child: Text(_initials,
                        style: TextStyle(
                            color: accent,
                            fontWeight: FontWeight.bold,
                            fontSize: size * 0.32))),
              )
            : Center(
                child: Text(_initials,
                    style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.bold,
                        fontSize: size * 0.32))),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

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
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.indigo)),
        ],
      ),
    );
  }
}

class _CompareRow extends StatelessWidget {
  final String label;
  final String aVal;
  final String bVal;
  final int winner; // -1 = A, 0 = tie, 1 = B
  final bool noHighlight;

  const _CompareRow({
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: aWins
                      ? Colors.indigo.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (aWins)
                      const Icon(Icons.emoji_events_rounded,
                          size: 14, color: Colors.indigo),
                    if (aWins) const SizedBox(width: 4),
                    Flexible(
                      child: Text(aVal,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: aWins ? Colors.indigo : Colors.black87),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: bWins
                      ? Colors.purple.withOpacity(0.15)
                      : Colors.transparent,
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
                              color:
                                  bWins ? Colors.purple : Colors.black87),
                          overflow: TextOverflow.ellipsis),
                    ),
                    if (bWins) const SizedBox(width: 4),
                    if (bWins)
                      const Icon(Icons.emoji_events_rounded,
                          size: 14, color: Colors.purple),
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

class _OverallWinner extends StatelessWidget {
  final Player a;
  final Player b;
  const _OverallWinner({required this.a, required this.b});

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
    check(a.highestRanking, b.highestRanking, lowerBetter: true);
    check(a.wins, b.wins);
    check(
      a.wins + a.losses > 0 ? a.wins / (a.wins + a.losses) : null,
      b.wins + b.losses > 0 ? b.wins / (b.wins + b.losses) : null,
    );

    final String winnerName;
    final Color winnerColor;
    final IconData winnerIcon;

    if (aScore > bScore) {
      winnerName = a.name;
      winnerColor = Colors.indigo;
      winnerIcon = Icons.emoji_events_rounded;
    } else if (bScore > aScore) {
      winnerName = b.name;
      winnerColor = Colors.purple;
      winnerIcon = Icons.emoji_events_rounded;
    } else {
      winnerName = 'Even Match!';
      winnerColor = Colors.orange;
      winnerIcon = Icons.handshake_rounded;
    }

    return GlassContainer(
      borderRadius: 20,
      opacity: 0.12,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(winnerIcon, color: winnerColor, size: 36),
          const SizedBox(height: 8),
          const Text('Overall Edge',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(winnerName,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: winnerColor)),
          if (aScore != bScore)
            Text('($aScore vs $bScore categories won)',
                style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }
}
