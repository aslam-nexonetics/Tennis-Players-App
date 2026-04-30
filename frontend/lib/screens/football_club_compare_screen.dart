import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/football_club.dart';
import '../services/api_service.dart';
import '../widgets/glass_widgets.dart';

class FootballClubCompareScreen extends StatefulWidget {
  final FootballClub? clubA;
  const FootballClubCompareScreen({super.key, this.clubA});

  @override
  State<FootballClubCompareScreen> createState() => _FootballClubCompareScreenState();
}

class _FootballClubCompareScreenState extends State<FootballClubCompareScreen>
    with TickerProviderStateMixin {
  FootballClub? _clubA;
  FootballClub? _clubB;
  
  bool _searchingA = false;
  bool _searchingB = false;
  
  List<FootballClub> _resultsA = [];
  List<FootballClub> _resultsB = [];
  
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
    _clubA = widget.clubA;
    if (_clubA != null) {
      _ctrlA.text = _clubA!.name;
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
      if (isA) {
        _searchingA = true;
      } else {
        _searchingB = true;
      }
    });
    try {
      final res = await ApiService().searchFootballClubs(q, size: 5);
      setState(() {
        if (isA) {
          _resultsA = res.items.where((c) => c.id != _clubB?.id).toList();
          _noResultsA = _resultsA.isEmpty;
        } else {
          _resultsB = res.items.where((c) => c.id != _clubA?.id).toList();
          _noResultsB = _resultsB.isEmpty;
        }
      });
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        if (isA) {
          _searchingA = false;
        } else {
          _searchingB = false;
        }
      });
    }
  }

  void _selectA(FootballClub c) {
    setState(() {
      _clubA = c;
      _resultsA = [];
      _noResultsA = false;
      _ctrlA.text = c.name;
      _showComparison = false;
    });
    FocusScope.of(context).unfocus();
  }

  void _selectB(FootballClub c) {
    setState(() {
      _clubB = c;
      _resultsB = [];
      _noResultsB = false;
      _ctrlB.text = c.name;
      _showComparison = false;
    });
    FocusScope.of(context).unfocus();
  }

  void _compare() {
    if (_clubA != null && _clubB != null) {
      setState(() {
        _showComparison = true;
      });
      _fadeCtrl.forward(from: 0);
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
                      'Club Comparison',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: Color(0xFF1D1D1F),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Analyze football giants side-by-side',
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
              Expanded(child: _buildSearchBox(_ctrlA, _onSearchA, _clubA, true)),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('VS',
                    style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
              ),
              Expanded(child: _buildSearchBox(_ctrlB, _onSearchB, _clubB, false)),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: (_clubA != null && _clubB != null) ? _compare : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE4405F),
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
      FootballClub? selected, bool isA) {
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
              accent: const Color(0xFFE4405F),
            ),
          ),
          Expanded(
            child: TextField(
              controller: ctrl,
              onChanged: onChanged,
              style: const TextStyle(color: Color(0xFF1D1D1F), fontSize: 14),
              decoration: InputDecoration(
                hintText: isA ? 'Search Club 1' : 'Search Club 2',
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
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFE4405F)),
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

  Widget _buildResultList(List<FootballClub> results, Function(FootballClub) onSelect) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        children: results
            .map((c) => ListTile(
                  dense: true,
                  leading: _Avatar(imageUrl: c.imageUrl, name: c.name, size: 24, accent: const Color(0xFFE4405F)),
                  title: Text(c.name,
                      style: const TextStyle(color: Color(0xFF1D1D1F), fontSize: 12)),
                  subtitle: Text(c.league ?? 'Unknown',
                      style: const TextStyle(color: Colors.grey, fontSize: 10)),
                  onTap: () => onSelect(c),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildComparisonResults() {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Column(
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 20),
          _buildStatsComparison(),
          const SizedBox(height: 20),
          _buildExtraInfo(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return GlassContainer(
      borderRadius: 20,
      opacity: 0.1,
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildClubHeader(_clubA!, true),
          Column(
            children: [
              Text('VS',
                  style: TextStyle(color: Colors.grey.withOpacity(0.2), fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
          _buildClubHeader(_clubB!, false),
        ],
      ),
    );
  }

  Widget _buildClubHeader(FootballClub c, bool isLeft) {
    return Expanded(
      child: Column(
        crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          _Avatar(
              imageUrl: c.imageUrl,
              name: c.name,
              size: 80,
              accent: const Color(0xFFE4405F)),
          const SizedBox(height: 12),
          Text(c.name,
              style: const TextStyle(
                  color: Color(0xFF1D1D1F), fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: isLeft ? TextAlign.left : TextAlign.right),
          Text(c.country ?? "N/A", style: const TextStyle(color: Colors.grey)),
          Text(c.league ?? "N/A",
              style: const TextStyle(color: Color(0xFFE4405F), fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStatsComparison() {
    return GlassContainer(
      borderRadius: 20,
      opacity: 0.1,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text('CORE STATISTICS', 
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12, letterSpacing: 1.2)),
          const SizedBox(height: 20),
          _buildStatRow('World Rank', '#${_clubA!.ranking}', '#${_clubB!.ranking}', isLowerBetter: true),
          _buildStatRow('Total Trophies', '${_clubA!.totalTrophies}', '${_clubB!.totalTrophies}'),
          _buildStatRow('Market Value', _clubA!.marketValue ?? 'TBD', _clubB!.marketValue ?? 'TBD', isNumeric: false),
          _buildStatRow('League Pos', '${_clubA!.leaguePosition}', '${_clubB!.leaguePosition}', isLowerBetter: true),
          _buildStatRow('Stadium Capacity', _formatNum(_clubA!.capacity), _formatNum(_clubB!.capacity)),
          _buildStatRow('Avg Attendance', _formatNum(_clubA!.averageAttendance), _formatNum(_clubB!.averageAttendance)),
          _buildStatRow('Founded', '${_clubA!.foundedYear}', '${_clubB!.foundedYear}', isNumeric: false),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String aVal, String bVal, {bool isLowerBetter = false, bool isNumeric = true}) {
    bool aWins = false;
    bool bWins = false;

    if (isNumeric) {
      num? nvA = num.tryParse(aVal.replaceAll(RegExp(r'[^0-9.]'), ''));
      num? nvB = num.tryParse(bVal.replaceAll(RegExp(r'[^0-9.]'), ''));
      
      if (nvA != null && nvB != null) {
        if (isLowerBetter) {
          aWins = nvA < nvB;
          bWins = nvB < nvA;
        } else {
          aWins = nvA > nvB;
          bWins = nvB > nvA;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(aVal, 
                  style: TextStyle(
                    fontWeight: aWins ? FontWeight.bold : FontWeight.normal,
                    color: aWins ? const Color(0xFFE4405F) : Colors.black87,
                    fontSize: 16
                  )
                ),
              ),
              Expanded(
                child: Text(label, 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)
                ),
              ),
              Expanded(
                child: Text(bVal, 
                  textAlign: TextAlign.right, 
                  style: TextStyle(
                    fontWeight: bWins ? FontWeight.bold : FontWeight.normal,
                    color: bWins ? const Color(0xFFE4405F) : Colors.black87,
                    fontSize: 16
                  )
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildComparisonBar(aVal, bVal, isLowerBetter),
        ],
      ),
    );
  }

  Widget _buildComparisonBar(String aVal, String bVal, bool isLowerBetter) {
    num? nvA = num.tryParse(aVal.replaceAll(RegExp(r'[^0-9.]'), ''));
    num? nvB = num.tryParse(bVal.replaceAll(RegExp(r'[^0-9.]'), ''));

    if (nvA == null || nvB == null || (nvA == 0 && nvB == 0)) {
      return Container(height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2)));
    }

    double total = nvA.toDouble() + nvB.toDouble();
    double ratioA = nvA / total;
    
    // Reverse ratio for lower better stats (like ranking)
    if (isLowerBetter) {
       ratioA = 1 - ratioA;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Row(
        children: [
          Expanded(flex: (ratioA * 100).toInt(), child: Container(height: 4, color: const Color(0xFFE4405F))),
          Expanded(flex: ((1 - ratioA) * 100).toInt(), child: Container(height: 4, color: Colors.black12)),
        ],
      ),
    );
  }

  Widget _buildExtraInfo() {
    return Row(
      children: [
        Expanded(child: _buildInfoCard('Manager', _clubA!.manager, _clubB!.manager, Icons.sports_rounded)),
        const SizedBox(width: 16),
        Expanded(child: _buildInfoCard('Captain', _clubA!.captain, _clubB!.captain, Icons.person_pin)),
      ],
    );
  }

  Widget _buildInfoCard(String label, String? a, String? b, IconData icon) {
    return GlassContainer(
      borderRadius: 20,
      opacity: 0.1,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFFE4405F), size: 24),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text(a ?? 'TBD', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
          const Divider(height: 20),
          Text(b ?? 'TBD', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center),
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
          Text('Select two clubs and press COMPARE\nto see the side-by-side analysis',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.withOpacity(0.5))),
        ],
      ),
    );
  }

  String _formatNum(int? num) {
    if (num == null) return '0';
    return num.toString();
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
