import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/tt_player.dart';
import '../services/api_service.dart';
import '../widgets/glass_widgets.dart';

const _kGreen = Color(0xFF0F9D58);
const _kPurple = Color(0xFF7C3AED);

class TtPlayerCompareScreen extends StatefulWidget {
  final TableTennisPlayer? playerA;
  const TtPlayerCompareScreen({super.key, this.playerA});

  @override
  State<TtPlayerCompareScreen> createState() => _TtPlayerCompareScreenState();
}

class _TtPlayerCompareScreenState extends State<TtPlayerCompareScreen>
    with TickerProviderStateMixin {
  TableTennisPlayer? _playerA;
  TableTennisPlayer? _playerB;
  
  bool _searchingA = false;
  bool _searchingB = false;
  
  List<TableTennisPlayer> _resultsA = [];
  List<TableTennisPlayer> _resultsB = [];
  
  bool _noResultsA = false;
  bool _noResultsB = false;
  
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
      if (q.trim().isNotEmpty) {
        _doSearch(q.trim(), true);
      } else {
        setState(() {
          _resultsA = [];
          _noResultsA = false;
        });
      }
    });
  }

  void _onSearchB(String q) {
    if (_debounceB?.isActive ?? false) _debounceB!.cancel();
    _debounceB = Timer(const Duration(milliseconds: 400), () {
      if (q.trim().isNotEmpty) {
        _doSearch(q.trim(), false);
      } else {
        setState(() {
          _resultsB = [];
          _noResultsB = false;
        });
      }
    });
  }

  Future<void> _doSearch(String q, bool isA) async {
    setState(() {
      if (isA) _searchingA = true; else _searchingB = true;
    });
    try {
      final res = await ApiService().searchTtPlayers(q, size: 5);
      setState(() {
        if (isA) {
          _resultsA = res.items.where((p) => p.id != _playerB?.id).toList();
          _noResultsA = _resultsA.isEmpty;
        } else {
          _resultsB = res.items.where((p) => p.id != _playerA?.id).toList();
          _noResultsB = _resultsB.isEmpty;
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

  void _selectA(TableTennisPlayer p) {
    setState(() {
      _playerA = p;
      _resultsA = [];
      _noResultsA = false;
      _ctrlA.text = p.name;
      _showComparison = false;
    });
    FocusScope.of(context).unfocus();
  }

  void _selectB(TableTennisPlayer p) {
    setState(() {
      _playerB = p;
      _resultsB = [];
      _noResultsB = false;
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

  String _winRate(TableTennisPlayer p) {
    return '${(p.winPercentage ?? 0.0).toStringAsFixed(1)}%';
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
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_playerA != null && _playerB != null) ? _compare : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('COMPARE ATHLETES',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
          if (_resultsA.isNotEmpty || _resultsB.isNotEmpty || _noResultsA || _noResultsB)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _resultsA.isNotEmpty
                        ? _buildResultList(_resultsA, _selectA)
                        : (_noResultsA && _ctrlA.text.isNotEmpty ? _buildNoResults() : const SizedBox()),
                  ),
                  const SizedBox(width: 44), // Space for 'VS' alignment
                  Expanded(
                    child: _resultsB.isNotEmpty
                        ? _buildResultList(_resultsB, _selectB)
                        : (_noResultsB && _ctrlB.text.isNotEmpty ? _buildNoResults() : const SizedBox()),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchBox(TextEditingController ctrl, Function(String) onChanged,
      TableTennisPlayer? selected, bool isA) {
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
            child: _TtAvatar(
              player: selected,
              size: 32,
              accent: isA ? _kGreen : _kPurple,
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
              child: CircularProgressIndicator(strokeWidth: 2, color: _kGreen),
            ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: const Text('No results found', 
        style: TextStyle(color: Colors.grey, fontSize: 12),
        textAlign: TextAlign.center),
    );
  }

  Widget _buildResultList(List<TableTennisPlayer> results, Function(TableTennisPlayer) onSelect) {
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
                  leading: _TtAvatar(player: p, size: 24, accent: _kGreen),
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
          const SizedBox(height: 20),
          _buildOverallEdge(a, b),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(TableTennisPlayer a, TableTennisPlayer b) {
    return GlassContainer(
      borderRadius: 20,
      opacity: 0.1,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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

  Widget _buildPlayerSummary(TableTennisPlayer p, bool isLeft) {
    return Expanded(
      child: Column(
        crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          _TtAvatar(
              player: p,
              size: 80,
              accent: isLeft ? _kGreen : _kPurple),
          const SizedBox(height: 12),
          Text(p.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Color(0xFF1D1D1F), fontSize: 16, fontWeight: FontWeight.bold)),
          Text(p.country ?? "N/A", 
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
          Text('Age ${p.age ?? "??"} | ${p.playingStyle ?? "N/A"}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.grey, fontSize: 10)),
          const SizedBox(height: 4),
          Text('Rank ${p.ranking ?? "N/A"}',
              style: TextStyle(
                  color: isLeft ? _kGreen : _kPurple,
                  fontSize: 13,
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
                    color: _kGreen,
                    fontSize: 42,
                    fontWeight: FontWeight.bold)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(width: 12, height: 2, color: Colors.grey.withOpacity(0.3)),
            ),
            const Text('0',
                style: TextStyle(
                    color: _kPurple,
                    fontSize: 42,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSummary(TableTennisPlayer a, TableTennisPlayer b) {
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
                    color: aWins ? _kGreen : Colors.black87,
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
                    color: bWins ? _kPurple : Colors.black87,
                    fontWeight: bWins ? FontWeight.bold : FontWeight.normal)),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallEdge(TableTennisPlayer a, TableTennisPlayer b) {
    int aScore = 0, bScore = 0;
    void check(num? aV, num? bV, {bool lowerBetter = false}) {
      if (aV == null || bV == null) return;
      if (lowerBetter) {
        if (aV < bV) aScore++; if (bV < aV) bScore++;
      } else {
        if (aV > bV) aScore++; if (bV > aV) bScore++;
      }
    }
    check(a.ranking, b.ranking, lowerBetter: true);
    check(a.winPercentage, b.winPercentage);

    String winnerName = aScore > bScore ? a.name : bScore > aScore ? b.name : "Even Match!";
    Color winnerColor = aScore > bScore ? _kGreen : bScore > aScore ? _kPurple : Colors.grey;

    return GlassContainer(
      borderRadius: 16,
      opacity: 0.1,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(Icons.emoji_events, color: winnerColor, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('OVERALL EDGE', style: TextStyle(color: Colors.grey, fontSize: 10)),
                Text(winnerName, style: TextStyle(color: winnerColor, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Text('$aScore - $bScore', style: const TextStyle(color: Color(0xFF1D1D1F), fontSize: 24, fontWeight: FontWeight.bold)),
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

class _TtAvatar extends StatelessWidget {
  final TableTennisPlayer? player;
  final double size;
  final Color accent;
  const _TtAvatar({required this.player, required this.size, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: accent.withOpacity(0.5), width: 2),
        color: accent.withOpacity(0.1),
      ),
      child: ClipOval(
        child: player?.imageUrl != null
            ? CachedNetworkImage(
                imageUrl: player!.imageUrl!,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorWidget: (_, __, ___) => _initials(),
              )
            : _initials(),
      ),
    );
  }

  Widget _initials() {
    final name = player?.name ?? '?';
    final parts = name.trim().split(' ');
    final text = parts.length >= 2 ? '${parts[0][0]}${parts[1][0]}' : name.isNotEmpty ? name[0] : '?';
    return Center(child: Text(text.toUpperCase(), style: TextStyle(color: accent, fontWeight: FontWeight.bold, fontSize: size * 0.4)));
  }
}
