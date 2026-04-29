import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/player.dart';
import '../services/api_service.dart';
import '../widgets/glass_widgets.dart';

class PlayerCompareScreen extends StatefulWidget {
  final Player? playerA;
  const PlayerCompareScreen({super.key, this.playerA});

  @override
  State<PlayerCompareScreen> createState() => _PlayerCompareScreenState();
}

class _PlayerCompareScreenState extends State<PlayerCompareScreen>
    with TickerProviderStateMixin {
  Player? _playerA;
  Player? _playerB;
  
  bool _searchingA = false;
  bool _searchingB = false;
  
  List<Player> _resultsA = [];
  List<Player> _resultsB = [];
  
  final TextEditingController _ctrlA = TextEditingController();
  final TextEditingController _ctrlB = TextEditingController();
  
  Timer? _debounceA;
  Timer? _debounceB;
  
  bool _showComparison = false;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _playerA = widget.playerA;
    if (_playerA != null) {
      _ctrlA.text = _playerA!.name;
    }
    
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    
    if (_playerA != null) {
      _showComparison = false;
    }
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _ctrlA.dispose();
    _ctrlB.dispose();
    _debounceA?.cancel();
    _debounceB?.cancel();
    super.dispose();
  }

  void _onSearchA(String q) {
    if (_debounceA?.isActive ?? false) _debounceA!.cancel();
    _debounceA = Timer(const Duration(milliseconds: 400), () {
      if (q.trim().isNotEmpty) _doSearch(q.trim(), true);
    });
  }

  void _onSearchB(String q) {
    if (_debounceB?.isActive ?? false) _debounceB!.cancel();
    _debounceB = Timer(const Duration(milliseconds: 400), () {
      if (q.trim().isNotEmpty) _doSearch(q.trim(), false);
    });
  }

  Future<void> _doSearch(String q, bool isA) async {
    setState(() {
      if (isA) _searchingA = true; else _searchingB = true;
    });
    try {
      final res = await ApiService().searchPlayers(q, size: 5);
      setState(() {
        if (isA) {
          _resultsA = res.items;
        } else {
          _resultsB = res.items;
        }
      });
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        if (isA) _searchingA = false; else _searchingB = false;
      });
    }
  }

  void _selectA(Player p) {
    setState(() {
      _playerA = p;
      _resultsA = [];
      _ctrlA.text = p.name;
      _showComparison = false;
    });
    FocusScope.of(context).unfocus();
  }

  void _selectB(Player p) {
    setState(() {
      _playerB = p;
      _resultsB = [];
      _ctrlB.text = p.name;
      _showComparison = false;
    });
    FocusScope.of(context).unfocus();
  }

  void _compare() {
    if (_playerA != null && _playerB != null) {
      setState(() => _showComparison = true);
      _fadeCtrl.forward(from: 0);
    }
  }

  String _winRate(Player p) {
    final total = p.wins + p.losses;
    if (total == 0) return '0%';
    return '${((p.wins / total) * 100).toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 50),
                    const Text(
                      'Head to Head',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Compare athletes side-by-side',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    _buildSelectionArea(),
                    const SizedBox(height: 20),
                    if (_showComparison && _playerA != null && _playerB != null)
                      _buildComparisonResults()
                    else
                      _buildPlaceholder(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionArea() {
    return GlassContainer(
      borderRadius: 16,
      opacity: 0.1,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildSearchBox(_ctrlA, _onSearchA, _playerA, true)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('VS',
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
              Expanded(child: _buildSearchBox(_ctrlB, _onSearchB, _playerB, false)),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: (_playerA != null && _playerB != null) ? _compare : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('COMPARE',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (_resultsA.isNotEmpty || _resultsB.isNotEmpty)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _resultsA.isNotEmpty
                      ? _buildResultList(_resultsA, _selectA)
                      : const SizedBox(),
                ),
                const SizedBox(width: 100),
                Expanded(
                  child: _resultsB.isNotEmpty
                      ? _buildResultList(_resultsB, _selectB)
                      : const SizedBox(),
                ),
                const SizedBox(width: 110),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBox(TextEditingController ctrl, Function(String) onChanged,
      Player? selected, bool isA) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: _Avatar(
              imageUrl: selected?.imageUrl,
              name: selected?.name ?? '?',
              size: 32,
              accent: isA ? Colors.indigo : Colors.pink,
            ),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              onChanged: onChanged,
              style: const TextStyle(color: Color(0xFF1D1D1F), fontSize: 14),
              decoration: InputDecoration(
                hintText: isA ? 'Search Player 1' : 'Search Player 2',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if ((isA && _searchingA) || (!isA && _searchingB))
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.indigo),
            ),
          const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildResultList(List<Player> results, Function(Player) onSelect) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: results
            .map((p) => ListTile(
                  dense: true,
                  leading: _Avatar(imageUrl: p.imageUrl, name: p.name, size: 24, accent: Colors.indigo),
                  title: Text(p.name,
                      style: const TextStyle(color: Color(0xFF1D1D1F), fontSize: 12)),
                  subtitle: Text('#${p.ranking ?? "N/A"}',
                      style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  onTap: () => onSelect(p),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildComparisonResults() {
    final a = _playerA!;
    final b = _playerB!;
    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          _buildSummaryCard(a, b),
          const SizedBox(height: 20),
          _buildStatsSummary(a, b),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Player a, Player b) {
    return GlassContainer(
      borderRadius: 20,
      opacity: 0.1,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPlayerSummary(a, true),
              _buildH2HScore(),
              _buildPlayerSummary(b, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerSummary(Player p, bool isLeft) {
    return Expanded(
      child: Column(
        crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          _Avatar(
              imageUrl: p.imageUrl,
              name: p.name,
              size: 80,
              accent: isLeft ? Colors.indigo : Colors.pink),
          const SizedBox(height: 12),
          Text(p.name,
              style: const TextStyle(
                  color: Color(0xFF1D1D1F), fontSize: 18, fontWeight: FontWeight.bold)),
          Text(p.country ?? "N/A", style: const TextStyle(color: Colors.grey)),
          Text('Age ${p.age ?? "??"}',
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text('Rank ${p.ranking ?? "N/A"}',
              style: TextStyle(
                  color: isLeft ? Colors.indigo : Colors.pink,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildH2HScore() {
    return Column(
      children: [
        const Text('HEAD TO HEAD',
            style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('0',
                style: TextStyle(
                    color: Colors.indigo,
                    fontSize: 42,
                    fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(width: 12, height: 2, color: Colors.grey.withOpacity(0.3)),
            ),
            const Text('0',
                style: TextStyle(
                    color: Colors.pink,
                    fontSize: 42,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSummary(Player a, Player b) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('STATS SUMMARY',
            style: TextStyle(
                color: Color(0xFF1D1D1F), fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 12),
        GlassContainer(
          borderRadius: 16,
          opacity: 0.1,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildStatRow('Matches Played', '${a.wins + a.losses}', '${b.wins + b.losses}'),
              _buildStatRow('Wins', '${a.wins}', '${b.wins}'),
              _buildStatRow('Win %', _winRate(a), _winRate(b)),
              _buildStatRow('Current Rank', '#${a.ranking ?? "N/A"}', '#${b.ranking ?? "N/A"}', lowerIsBetter: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String aVal, String bVal, {bool lowerIsBetter = false}) {
    num? nvA = num.tryParse(aVal.replaceAll(RegExp(r'[^0-9.]'), ''));
    num? nvB = num.tryParse(bVal.replaceAll(RegExp(r'[^0-9.]'), ''));
    bool aWins = false;
    bool bWins = false;
    if (nvA != null && nvB != null) {
      if (lowerIsBetter) {
        aWins = nvA < nvB; bWins = nvB < nvA;
      } else {
        aWins = nvA > nvB; bWins = nvB > nvA;
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(aVal,
                textAlign: TextAlign.start,
                style: TextStyle(
                    color: aWins ? Colors.indigo : Colors.black87,
                    fontWeight: aWins ? FontWeight.bold : FontWeight.normal)),
          ),
          Expanded(
            child: Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          Expanded(
            child: Text(bVal,
                textAlign: TextAlign.end,
                style: TextStyle(
                    color: bWins ? Colors.pink : Colors.black87,
                    fontWeight: bWins ? FontWeight.bold : FontWeight.normal)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: 300,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.compare_arrows, color: Colors.grey.withOpacity(0.3), size: 100),
          const SizedBox(height: 20),
          Text('Select two players and press COMPARE\nto see the head-to-head analysis',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.withOpacity(0.5))),
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
  const _Avatar({required this.imageUrl, required this.name, required this.size, required this.accent});

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
                errorWidget: (_, __, ___) => _initials(),
              )
            : _initials(),
      ),
    );
  }

  Widget _initials() {
    final parts = name.trim().split(' ');
    final text = parts.length >= 2 ? '${parts[0][0]}${parts[1][0]}' : name.isNotEmpty ? name[0] : '?';
    return Center(child: Text(text.toUpperCase(), style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: size * 0.4)));
  }
}
