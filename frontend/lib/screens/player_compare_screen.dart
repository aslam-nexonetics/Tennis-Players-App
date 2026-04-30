import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
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
  H2HResponse? _h2hData;
  
  bool _searchingA = false;
  bool _searchingB = false;
  bool _loadingH2H = false;
  
  List<Player> _resultsA = [];
  List<Player> _resultsB = [];
  
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
      final res = await ApiService().searchPlayers(q, size: 5);
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

  void _selectA(Player p) {
    setState(() {
      _playerA = p;
      _resultsA = [];
      _noResultsA = false;
      _ctrlA.text = p.name;
      _showComparison = false;
      _h2hData = null;
    });
    FocusScope.of(context).unfocus();
  }

  void _selectB(Player p) {
    setState(() {
      _playerB = p;
      _resultsB = [];
      _noResultsB = false;
      _ctrlB.text = p.name;
      _showComparison = false;
      _h2hData = null;
    });
    FocusScope.of(context).unfocus();
  }

  Future<void> _compare() async {
    if (_playerA != null && _playerB != null) {
      setState(() {
        _loadingH2H = true;
        _showComparison = true;
      });
      _fadeCtrl.forward(from: 0);
      
      try {
        final data = await ApiService().getH2H(_playerA!.id, _playerB!.id);
        setState(() {
          _h2hData = data;
          _loadingH2H = false;
        });
      } catch (e) {
        setState(() => _loadingH2H = false);
      }
    }
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
                    const SizedBox(height: 30),
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
                    if (_showComparison)
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
                  backgroundColor: const Color(0xFF2C3E50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('COMPARE',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (_resultsA.isNotEmpty || _resultsB.isNotEmpty || _noResultsA || _noResultsB)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _resultsA.isNotEmpty
                      ? _buildResultList(_resultsA, _selectA)
                      : (_noResultsA && _ctrlA.text.isNotEmpty ? _buildNoResults() : const SizedBox()),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _resultsB.isNotEmpty
                      ? _buildResultList(_resultsB, _selectB)
                      : (_noResultsB && _ctrlB.text.isNotEmpty ? _buildNoResults() : const SizedBox()),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: const Text('No results found', 
        style: TextStyle(color: Colors.grey, fontSize: 12),
        textAlign: TextAlign.center),
    );
  }

  Widget _buildResultList(List<Player> results, Function(Player) onSelect) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
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
    if (_loadingH2H) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(50.0),
          child: CircularProgressIndicator(color: Colors.indigo),
        ),
      );
    }
    
    if (_h2hData == null) return const SizedBox();

    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 20),
          _buildLastMatchInfo(),
          const SizedBox(height: 20),
          _buildStatsAndCharts(),
          const SizedBox(height: 20),
          _buildMatchHistory(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final a = _h2hData!.player1;
    final b = _h2hData!.player2;
    final stats = _h2hData!.stats;

    return GlassContainer(
      borderRadius: 20,
      opacity: 0.1,
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildPlayerProfile(a, true),
          Column(
            children: [
              const Text('HEAD TO HEAD',
                  style: TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 1.2)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('${stats.player1Wins}',
                      style: const TextStyle(
                          color: Colors.indigo,
                          fontSize: 42,
                          fontWeight: FontWeight.bold)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(width: 12, height: 2, color: Colors.grey.withOpacity(0.3)),
                  ),
                  Text('${stats.player2Wins}',
                      style: const TextStyle(
                          color: Colors.pink,
                          fontSize: 42,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              Text('Wins', style: TextStyle(color: Colors.grey[400], fontSize: 12)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Total ${stats.matchesPlayed}', 
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ),
            ],
          ),
          _buildPlayerProfile(b, false),
        ],
      ),
    );
  }

  Widget _buildPlayerProfile(Player p, bool isLeft) {
    return Expanded(
      child: Column(
        crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          _Avatar(
              imageUrl: p.imageUrl,
              name: p.name,
              size: 70,
              accent: isLeft ? Colors.indigo : Colors.pink),
          const SizedBox(height: 12),
          Text(p.name,
              style: const TextStyle(
                  color: Color(0xFF1D1D1F), fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: isLeft ? TextAlign.left : TextAlign.right),
          Text(p.country ?? "N/A", style: const TextStyle(color: Colors.grey)),
          Text('Age ${p.age ?? "??"} | ${p.playingStyle ?? "R-Handed"}',
              style: const TextStyle(color: Colors.grey, fontSize: 11)),
          const SizedBox(height: 4),
          Text('Rank ${p.ranking ?? "N/A"}',
              style: TextStyle(
                  color: isLeft ? Colors.indigo : Colors.pink,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLastMatchInfo() {
    final last = _h2hData!.stats.lastMatch;
    if (last == null) return const SizedBox();

    return GlassContainer(
      borderRadius: 16,
      opacity: 0.05,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('LAST MATCH', 
            style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('${last.event} ${last.year}, ${last.round}', 
            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          Text('${last.winnerName} won', style: const TextStyle(color: Colors.indigo, fontSize: 12)),
          const SizedBox(height: 5),
          Text(last.score, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }

  Widget _buildStatsAndCharts() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildStatsTable()),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: _buildSurfaceBreakdown()),
      ],
    );
  }

  Widget _buildStatsTable() {
    final stats = _h2hData!.stats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('STATS SUMMARY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        GlassContainer(
          borderRadius: 12,
          opacity: 0.1,
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              _buildStatRow('Matches', '${stats.matchesPlayed}', '${stats.matchesPlayed}'),
              _buildStatRow('Wins', '${stats.player1Wins}', '${stats.player2Wins}'),
              _buildStatRow('Win %', '${stats.player1WinPct}%', '${stats.player2WinPct}%'),
              _buildStatRow('Hard Wins', '${stats.hardCourtWins[_playerA!.id]}', '${stats.hardCourtWins[_playerB!.id]}'),
              _buildStatRow('Clay Wins', '${stats.clayCourtWins[_playerA!.id]}', '${stats.clayCourtWins[_playerB!.id]}'),
              _buildStatRow('Grass Wins', '${stats.grassCourtWins[_playerA!.id]}', '${stats.grassCourtWins[_playerB!.id]}'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String aVal, String bVal) {
    num? nvA = num.tryParse(aVal.replaceAll('%', ''));
    num? nvB = num.tryParse(bVal.replaceAll('%', ''));
    bool aWins = (nvA ?? 0) > (nvB ?? 0);
    bool bWins = (nvB ?? 0) > (nvA ?? 0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(aVal, style: TextStyle(fontWeight: aWins ? FontWeight.bold : FontWeight.normal, color: aWins ? Colors.indigo : Colors.black87))),
          Expanded(child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 11))),
          Expanded(child: Text(bVal, textAlign: TextAlign.right, style: TextStyle(fontWeight: bWins ? FontWeight.bold : FontWeight.normal, color: bWins ? Colors.pink : Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildSurfaceBreakdown() {
    final stats = _h2hData!.stats;
    final total = stats.matchesPlayed;
    
    // Calculate percentages for pie chart
    double hard = stats.hardCourtWins.values.reduce((a, b) => a + b) / total;
    double clay = stats.clayCourtWins.values.reduce((a, b) => a + b) / total;
    double grass = stats.grassCourtWins.values.reduce((a, b) => a + b) / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SURFACES', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        SizedBox(
          height: 120,
          child: PieChart(
            PieChartData(
              sections: [
                PieChartSectionData(value: hard * 100, color: Colors.blue, radius: 40, title: 'H'),
                PieChartSectionData(value: clay * 100, color: Colors.orange, radius: 40, title: 'C'),
                PieChartSectionData(value: grass * 100, color: Colors.green, radius: 40, title: 'G'),
              ],
              centerSpaceRadius: 20,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildLegendItem('Hard', Colors.blue),
        _buildLegendItem('Clay', Colors.orange),
        _buildLegendItem('Grass', Colors.green),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildMatchHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('HEAD TO HEAD MATCH HISTORY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 10),
        GlassContainer(
          borderRadius: 16,
          opacity: 0.1,
          padding: const EdgeInsets.all(0),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.black.withOpacity(0.05),
                child: const Row(
                  children: [
                    Expanded(flex: 1, child: Text('Year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(flex: 3, child: Text('Winner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(flex: 3, child: Text('Event', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    Expanded(flex: 2, child: Text('Score', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                ),
              ),
              ..._h2hData!.history.map((m) => _buildHistoryRow(m)).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryRow(H2HMatch m) {
    bool p1Won = m.winnerId == _playerA!.id;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(flex: 1, child: Text('${m.year}', style: const TextStyle(fontSize: 11))),
          Expanded(flex: 3, child: Text(m.winnerName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: p1Won ? Colors.indigo : Colors.pink))),
          Expanded(flex: 3, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(m.event, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              Text('${m.round} • ${m.surface}', style: const TextStyle(fontSize: 9, color: Colors.grey)),
            ],
          )),
          Expanded(flex: 2, child: Text(m.score, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500))),
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
                placeholder: (context, url) => Container(color: Colors.grey[200]),
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
