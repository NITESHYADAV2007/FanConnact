import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data.dart';
import '../theme.dart';
import '../services/live_match_service.dart';
import '../services/match_chat_service.dart';
import '../services/news_service.dart';
import '../services/cricket_hub_service.dart';
import '../services/rapid_api_service.dart';
import '../widgets/glow_wrapper.dart';
import '../widgets/match_games.dart';
import '../widgets/sports_animation_overlay.dart';
import '../widgets/sport_match_center.dart';

// Crex-style match center: opens when a match is tapped. Shows a live
// scorecard header + tabbed sections (Info, Live Chat, Summary/Graph,
// Series Stats, Games). Live scores auto-refresh; chat is real-time WS.
class MatchDetailScreen extends StatefulWidget {
  final MatchItem match;

  const MatchDetailScreen({super.key, required this.match});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen>
    with SingleTickerProviderStateMixin {
  late MatchItem _match;
  Timer? _timer;
  bool _loading = false;

  late TabController _tabController;
  bool get _loggedIn => FirebaseAuth.instance.currentUser != null;
  List<String> get _tabs {
    if (_match.sport == 'cricket') {
      final base = ['Scorecard', 'Commentary', 'Live', 'Info', 'Squads', 'Graphs', 'Series'];
      if (_loggedIn) return [...base, 'Live Chat', 'Games'];
      return base;
    }
    final base = ['Scorecard', 'Commentary', 'Live', 'Info', 'Squads', 'Graphs', 'Series', 'News'];
    if (_loggedIn) return [...base, 'Live Chat', 'Games'];
    return base;
  }

  MatchChatService? _chat;

  // Animation overlay
  String _lastEventType = '';
  String _lastEventText = '';
  String? _lastEventPlayer;
  bool _showAnimation = false;
  int _animationKey = 0;

  // Cricket data
  Map<String, dynamic>? _cricketAdvance;
  bool _cricketLoading = false;
  int _selectedInning = 0;

  // Poll every 3s for live matches so scores feel real-time (the backend
  // cache is now 20s, so this stays well within quota while feeling snappy).
  static const Duration _poll = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    _match = widget.match;
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _startPolling();
    _initChat();
    if (_match.sport == 'cricket') _loadCricketAdvance();
  }

  void _initChat() {
    if (_match.matchId == null) return;
    _chat = MatchChatService(matchId: _match.matchId!);
    _chat!.connect();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    _chat?.dispose();
    super.dispose();
  }

  void _startPolling() {
    if (_match.matchId == null) return;
    _refresh();
    _timer = Timer.periodic(_poll, (_) => _refresh());
  }

  Future<void> _refresh() async {
    if (_match.matchId == null) return;
    if (mounted) setState(() => _loading = true);
    final updated = await LiveMatchService.fetchMatchDetail(
      matchId: _match.matchId!,
      sport: _match.sport,
    );
    if (mounted) {
      setState(() {
        if (updated != null) _match = updated;
        _loading = false;
      });
    }
  }

  void _triggerAnimation(String eventType, String eventText, {String? playerName}) {
    setState(() {
      _lastEventType = eventType;
      _lastEventText = eventText;
      _lastEventPlayer = playerName;
      _showAnimation = true;
      _animationKey++;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showAnimation = false);
    });
  }

  Future<void> _loadCricketAdvance() async {
    if (_match.matchId == null) return;
    setState(() => _cricketLoading = true);
    try {
      _cricketAdvance = await CricketHubService.matchAdvance(_match.matchId!);
    } catch (_) {}
    if (mounted) setState(() => _cricketLoading = false);
  }

  Color _statusColor() {
    switch (_match.status) {
      case 'LIVE':
        return AppColors.liveRed;
      case 'UPCOMING':
        return AppColors.upcomingAmber;
      default:
        return AppColors.completedGrey;
    }
  }

  Widget _teamLogo(String? logo, {double size = 52}) {
    if (logo != null && logo.isNotEmpty) {
      return GlowWrapper(
        glowColor: AppColors.brandBlue,
        glowBlur: 12,
        glowSpread: 1,
        borderRadius: BorderRadius.circular(10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            logo,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => Icon(Icons.sports, size: size * 0.7),
          ),
        ),
      );
    }
    return Icon(Icons.sports, size: size * 0.7);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final live = _match.status == 'LIVE';
    final isCricket = _match.sport == 'cricket';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: Text(
          _match.series.isNotEmpty ? _match.series : 'Match Center',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(right: 14),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _refresh,
              tooltip: 'Refresh',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          labelColor: AppColors.brandBlue,
          indicatorColor: AppColors.brandBlue,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
        ),
      ),
      body: Column(
        children: [
          Stack(
            children: [
              if (isCricket)
                _CricketScoreHeader(
                  isDark: isDark,
                  match: _match,
                  live: live,
                  statusColor: _statusColor(),
                  teamLogo: _teamLogo,
                )
              else
                SportScoreHeader(
                  isDark: isDark,
                  match: _match,
                  live: live,
                  statusColor: _statusColor(),
                ),
              if (_showAnimation)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: SportEventOverlay(
                        key: ValueKey('anim_$_animationKey'),
                        sport: _match.sport,
                        eventType: _lastEventType,
                        eventText: _lastEventText,
                        playerName: _lastEventPlayer,
                        visible: _showAnimation,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Expanded(
            child: isCricket
                ? _buildCricketTabs(isDark)
                : TabBarView(
                    controller: _tabController,
                    children: [
                      SportScorecardTab(match: _match, isDark: isDark),
                      SportCommentaryTab(match: _match, isDark: isDark),
                      _LiveAnimationTab(match: _match, isDark: isDark),
                      _InfoTab(match: _match, isDark: isDark),
                      SportSquadsTab(match: _match, isDark: isDark),
                      GraphsView(isDark: isDark, sport: _match.sport, teamA: _match.teamA, teamB: _match.teamB, scoreA: _match.scoreA, scoreB: _match.scoreB),
                      _SeriesTab(match: _match, isDark: isDark),
                      _NewsTab(match: _match, isDark: isDark),
                      if (_loggedIn) _ChatTab(chat: _chat, isDark: isDark, match: _match),
                      if (_loggedIn) MatchGames(isDark: isDark, sport: _match.sport),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCricketTabs(bool isDark) {
    return TabBarView(
      controller: _tabController,
      children: [
        _CricketScorecardTab(
          match: _match,
          isDark: isDark,
          advance: _cricketAdvance,
          loading: _cricketLoading,
          selectedInning: _selectedInning,
          onInningChanged: (i) => setState(() => _selectedInning = i),
        ),
        _CricketCommentaryTab(
          matchId: _match.matchId ?? '',
          isDark: isDark,
          onEvent: _triggerAnimation,
        ),
        _LiveAnimationTab(match: _match, isDark: isDark),
        _InfoTab(match: _match, isDark: isDark),
        _CricketSquadsTab(
          matchId: _match.matchId ?? '',
          isDark: isDark,
        ),
        GraphsView(isDark: isDark, sport: _match.sport, teamA: _match.teamA, teamB: _match.teamB, scoreA: _match.scoreA, scoreB: _match.scoreB),
        _SeriesTab(match: _match, isDark: isDark),
        if (_loggedIn) _ChatTab(chat: _chat, isDark: isDark, match: _match),
        if (_loggedIn) MatchGames(isDark: isDark, sport: _match.sport),
      ],
    );
  }
}

// ── Cricket score header (Crex-style dark gradient) ─────────────────────────
class _CricketScoreHeader extends StatelessWidget {
  final bool isDark;
  final MatchItem match;
  final bool live;
  final Color statusColor;
  final Widget Function(String?, {double size}) teamLogo;

  const _CricketScoreHeader({
    required this.isDark,
    required this.match,
    required this.live,
    required this.statusColor,
    required this.teamLogo,
  });

  void _share(BuildContext context) {
    final text = '${match.teamA} vs ${match.teamB}\n'
        '${match.scoreA ?? '-'} : ${match.scoreB ?? '-'}\n'
        '${match.series.isNotEmpty ? match.series + '\n' : ''}'
        '${match.status}'
        '${match.result != null && match.result!.isNotEmpty ? ' • ' + match.result! : ''}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Match summary copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)]
              : [const Color(0xFF0f0c29), const Color(0xFF1a1a3e)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          // Status bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (live)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: AppColors.liveRed,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.liveRed.withValues(alpha: 0.7),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                Text(
                  match.status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(width: 8),
                if (match.matchType != null && match.matchType!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      match.matchType!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.share_outlined, size: 16, color: Colors.white60),
                  onPressed: () => _share(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Share',
                ),
              ],
            ),
          ),
          // Team scores side by side
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Expanded(child: _CricketTeamScore(match: match, side: true, teamLogo: teamLogo)),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    children: [
                      Text('VS',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.3))),
                    ],
                  ),
                ),
                Expanded(child: _CricketTeamScore(match: match, side: false, teamLogo: teamLogo)),
              ],
            ),
          ),
          // Result banner
          if (match.result != null && match.result!.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.brandBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                match.result!,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 12, color: Colors.white),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          // Venue + time
          if ((match.venue != null && match.venue!.isNotEmpty) || match.time.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (match.venue != null && match.venue!.isNotEmpty) ...[
                    Icon(Icons.location_on_outlined, size: 12, color: Colors.white.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(match.venue!,
                          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5)),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  if (match.time.isNotEmpty) ...[
                    if (match.venue != null && match.venue!.isNotEmpty) const SizedBox(width: 12),
                    Icon(Icons.access_time, size: 12, color: Colors.white.withValues(alpha: 0.5)),
                    const SizedBox(width: 4),
                    Text(match.time,
                        style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.5))),
                  ],
                ],
              ),
            ),
          // Live indicator
          if (live)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 4),
              color: AppColors.liveRed.withValues(alpha: 0.15),
              child: const Text(
                'Auto-updating live • refreshes every 3s',
                style: TextStyle(fontSize: 10, color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _CricketTeamScore extends StatelessWidget {
  final MatchItem match;
  final bool side;
  final Widget Function(String?, {double size}) teamLogo;
  const _CricketTeamScore({required this.match, required this.side, required this.teamLogo});

  @override
  Widget build(BuildContext context) {
    final name = side ? match.teamA : match.teamB;
    final abbr = side ? match.abbrA : match.abbrB;
    final logo = side ? match.logoA : match.logoB;
    final score = side ? match.scoreA : match.scoreB;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        teamLogo(logo, size: 56),
        const SizedBox(height: 6),
        Text(
          abbr != null && abbr.isNotEmpty ? abbr : name,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          score ?? '-',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.5)),
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Cricket Scorecard tab (Crex-style innings batting/bowling card) ─────────
class _CricketScorecardTab extends StatefulWidget {
  final MatchItem match;
  final bool isDark;
  final Map<String, dynamic>? advance;
  final bool loading;
  final int selectedInning;
  final ValueChanged<int> onInningChanged;

  const _CricketScorecardTab({
    required this.match,
    required this.isDark,
    required this.advance,
    required this.loading,
    required this.selectedInning,
    required this.onInningChanged,
  });

  @override
  State<_CricketScorecardTab> createState() => _CricketScorecardTabState();
}

class _CricketScorecardTabState extends State<_CricketScorecardTab> {
  @override
  Widget build(BuildContext context) {
    if (widget.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    final innings = _getInnings();
    if (innings.isEmpty) {
      return Center(
        child: Text('Scorecard not available yet.',
            style: TextStyle(color: widget.isDark ? Colors.white54 : Colors.black45)),
      );
    }

    final inningIdx = widget.selectedInning < innings.length ? widget.selectedInning : 0;
    final inning = innings[inningIdx];
    final batting = _getBatting(inning);
    final bowling = _getBowling(inning);
    final extras = _getExtras(inning);
    final total = _getTotal(inning);

    return Column(
      children: [
        // Innings selector
        SizedBox(
          height: 42,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: innings.length,
            itemBuilder: (_, i) {
              final inn = innings[i];
              final selected = i == inningIdx;
              final label = inn['name']?.toString() ?? 'Innings ${i + 1}';
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => widget.onInningChanged(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.brandBlue : Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : (widget.isDark ? Colors.white70 : Colors.black54),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              // Total score header
              if (total != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.brandBlue.withValues(alpha: 0.2),
                        AppColors.brandBlue.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        total['runs']?.toString() ?? '',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.brandBlue),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Overs: ${_fmt(total['overs'])}',
                              style: TextStyle(fontSize: 13, color: widget.isDark ? Colors.white70 : Colors.black54)),
                          if (extras != null)
                            Text('Extras: ${extras['total'] ?? extras['extras'] ?? 0}',
                                style: TextStyle(fontSize: 12, color: widget.isDark ? Colors.white54 : Colors.black45)),
                        ],
                      ),
                    ],
                  ),
                ),
              // Batting table
              const Text('BATTING',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 6),
              _BattingTable(batting: batting, isDark: widget.isDark),
              const SizedBox(height: 16),
              // Bowling table
              const Text('BOWLING',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
              const SizedBox(height: 6),
              _BowlingTable(bowling: bowling, isDark: widget.isDark),
              const SizedBox(height: 12),
              // Fall of wickets
              _FallOfWickets(inning: inning, isDark: widget.isDark),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }

  List<dynamic> _getInnings() {
    if (widget.advance == null) return [];
    final data = widget.advance!;
    if (data['innings'] is List) return data['innings'] as List<dynamic>;
    if (data['response'] is Map && data['response']['innings'] is List) {
      return data['response']['innings'] as List<dynamic>;
    }
    if (data['scorecard'] is List) return data['scorecard'] as List<dynamic>;
    return [];
  }

  List<dynamic> _getBatting(Map inning) {
    if (inning['batting'] is List) return inning['batting'] as List<dynamic>;
    if (inning['batsmen'] is List) return inning['batsmen'] as List<dynamic>;
    if (inning['battingCard'] is List) return inning['battingCard'] as List<dynamic>;
    return [];
  }

  List<dynamic> _getBowling(Map inning) {
    if (inning['bowling'] is List) return inning['bowling'] as List<dynamic>;
    if (inning['bowlers'] is List) return inning['bowlers'] as List<dynamic>;
    if (inning['bowlingCard'] is List) return inning['bowlingCard'] as List<dynamic>;
    return [];
  }

  Map? _getExtras(Map inning) {
    if (inning['extras'] is Map) return inning['extras'] as Map;
    return null;
  }

  Map? _getTotal(Map inning) {
    if (inning['total'] is Map) return inning['total'] as Map;
    if (inning['score'] is Map) return inning['score'] as Map;
    return null;
  }

  String _fmt(dynamic v) {
    if (v == null) return '-';
    if (v is double) return v.toStringAsFixed(1);
    return v.toString();
  }
}

class _BattingTable extends StatelessWidget {
  final List<dynamic> batting;
  final bool isDark;
  const _BattingTable({required this.batting, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                const Expanded(flex: 3, child: Text('Batter', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                const Expanded(flex: 1, child: Text('R', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                const Expanded(flex: 1, child: Text('B', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                const Expanded(flex: 1, child: Text('4s', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                const Expanded(flex: 1, child: Text('6s', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                const Expanded(flex: 1, child: Text('SR', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
              ],
            ),
          ),
          // Rows
          for (final b in batting)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.08))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b['name']?.toString() ?? b['batter']?.toString() ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (b['out_desc'] != null || b['dismissal'] != null)
                          Text(
                            b['out_desc']?.toString() ?? b['dismissal']?.toString() ?? '',
                            style: TextStyle(fontSize: 9, color: isDark ? Colors.white54 : Colors.black45),
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (_isOut(b))
                          Text('OUT',
                              style: TextStyle(fontSize: 9, color: AppColors.liveRed, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  _cell(b['runs']?.toString() ?? '0'),
                  _cell(b['balls']?.toString() ?? b['ball']?.toString() ?? '0'),
                  _cell(b['fours']?.toString() ?? b['4s']?.toString() ?? '0'),
                  _cell(b['sixes']?.toString() ?? b['6s']?.toString() ?? '0'),
                  _cell(b['strike_rate']?.toString() ?? b['sr']?.toString() ?? '-'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  bool _isOut(Map b) {
    if (b['out'] == true || b['out'] == 1) return true;
    if (b['dismissal'] != null && b['dismissal'].toString().isNotEmpty && b['dismissal'].toString() != 'batting') return true;
    if (b['out_desc'] != null && b['out_desc'].toString().isNotEmpty) return true;
    return false;
  }

  Widget _cell(String v) {
    return Expanded(
      flex: 1,
      child: Text(v, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _BowlingTable extends StatelessWidget {
  final List<dynamic> bowling;
  final bool isDark;
  const _BowlingTable({required this.bowling, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                const Expanded(flex: 3, child: Text('Bowler', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                const Expanded(flex: 1, child: Text('O', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                const Expanded(flex: 1, child: Text('M', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                const Expanded(flex: 1, child: Text('R', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                const Expanded(flex: 1, child: Text('W', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
                const Expanded(flex: 1, child: Text('Eco', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11))),
              ],
            ),
          ),
          for (final b in bowling)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.08))),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      b['name']?.toString() ?? b['bowler']?.toString() ?? 'Unknown',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _cell(b['overs']?.toString() ?? '0'),
                  _cell(b['maidens']?.toString() ?? b['medens']?.toString() ?? '0'),
                  _cell(b['runs']?.toString() ?? b['conceded']?.toString() ?? '0'),
                  _cell(b['wickets']?.toString() ?? b['w']?.toString() ?? '0'),
                  _cell(b['economy']?.toString() ?? b['economy_rate']?.toString() ?? '-'),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(String v) {
    return Expanded(
      flex: 1,
      child: Text(v, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class _FallOfWickets extends StatelessWidget {
  final Map inning;
  final bool isDark;
  const _FallOfWickets({required this.inning, required this.isDark});

  @override
  Widget build(BuildContext context) {
    List<dynamic>? fow;
    if (inning['fall_of_wickets'] is List) fow = inning['fall_of_wickets'] as List<dynamic>;
    if (inning['fow'] is List) fow = inning['fow'] as List<dynamic>;
    if (fow == null || fow.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text('FALL OF WICKETS',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: fow.asMap().entries.map((e) {
              final w = e.value is Map ? e.value as Map : <dynamic, dynamic>{};
              final score = w['score']?.toString() ?? '';
              final overs = w['overs']?.toString() ?? '';
              final name = w['name']?.toString() ?? '';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.liveRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${e.key + 1}. $score${overs.isNotEmpty ? ' ($overs)' : ''}${name.isNotEmpty ? ' - $name' : ''}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ── Cricket Commentary tab (ball-by-ball from API) ─────────────────────────
class _CricketCommentaryTab extends StatefulWidget {
  final String matchId;
  final bool isDark;
  final void Function(String eventType, String eventText, {String? playerName})? onEvent;
  const _CricketCommentaryTab({required this.matchId, required this.isDark, this.onEvent});

  @override
  State<_CricketCommentaryTab> createState() => _CricketCommentaryTabState();
}

class _CricketCommentaryTabState extends State<_CricketCommentaryTab> {
  List<Map<String, dynamic>> _commentary = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (widget.matchId.isEmpty) return;
      _commentary = await RapidApiService.fetchCricbuzzCommentary(widget.matchId);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String _cleanText(String raw) {
    return raw
        .replaceAll(RegExp(r'B\d+\$'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String? _extractPlayerName(String text, {bool isWicket = false}) {
    if (isWicket) {
      final m = RegExp(r'(\w+)\s+b\b').firstMatch(text);
      return m?.group(1);
    }
    final m = RegExp(r'^\s*(\w+)\s').firstMatch(text);
    return m?.group(1);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_commentary.isEmpty) {
      return Center(
        child: Text('Commentary not available yet.',
            style: TextStyle(color: widget.isDark ? Colors.white54 : Colors.black45)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _commentary.length,
      itemBuilder: (_, i) {
        final c = _commentary[i];
        final eventType = (c['eventtype'] ?? '').toString();
        final isWicket = eventType == 'WICKET';
        final isSix = eventType == 'SIX';
        final isFour = eventType == 'FOUR' || eventType == 'BOUNDARY';
        final isOverBreak = eventType == 'over-break';
        final over = c['overnum']?.toString() ?? '';
        final raw = c['commtxt']?.toString() ?? '';
        final text = _cleanText(raw);
        final boundaryTracker = c['boundarytracker'] == true;

        Color badgeColor;
        Color textColor;
        if (isWicket) {
          badgeColor = AppColors.liveRed;
          textColor = AppColors.liveRed;
        } else if (isSix) {
          badgeColor = AppColors.upcomingAmber;
          textColor = AppColors.upcomingAmber;
        } else if (isFour || boundaryTracker) {
          badgeColor = AppColors.brandBlue;
          textColor = AppColors.brandBlue;
        } else {
          badgeColor = widget.isDark ? Colors.white38 : Colors.black38;
          textColor = widget.isDark ? Colors.white : Colors.black87;
        }

        if (isWicket && widget.onEvent != null) {
        final playerName = _extractPlayerName(text, isWicket: true);
        widget.onEvent!('WICKET', raw, playerName: playerName);
      } else if (isSix && widget.onEvent != null) {
        final playerName = _extractPlayerName(text);
        widget.onEvent!('SIX', raw, playerName: playerName);
      } else if (isFour && widget.onEvent != null) {
        final playerName = _extractPlayerName(text);
        widget.onEvent!('FOUR', raw, playerName: playerName);
      }

      return Container(
          margin: EdgeInsets.only(bottom: isOverBreak ? 12 : 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isWicket
                  ? AppColors.liveRed.withValues(alpha: 0.3)
                  : (isSix ? AppColors.upcomingAmber.withValues(alpha: 0.3)
                      : (isFour ? AppColors.brandBlue.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.12))),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(right: 10, top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  over,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: (isWicket || isSix || isFour) ? Colors.white : badgeColor,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: (isWicket || isSix || isFour) ? FontWeight.w700 : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Cricket Squads tab (playing XI) ────────────────────────────────────────
class _CricketSquadsTab extends StatefulWidget {
  final String matchId;
  final bool isDark;
  const _CricketSquadsTab({required this.matchId, required this.isDark});

  @override
  State<_CricketSquadsTab> createState() => _CricketSquadsTabState();
}

class _CricketSquadsTabState extends State<_CricketSquadsTab> {
  List<dynamic> _squads = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      if (widget.matchId.isEmpty) return;
      _squads = await CricketHubService.matchSquads(widget.matchId);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_squads.isEmpty) {
      return Center(
        child: Text('Squads not available yet.',
            style: TextStyle(color: widget.isDark ? Colors.white54 : Colors.black45)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: _squads.map((s) {
        final squad = s is Map ? s : <dynamic, dynamic>{};
        final teamName = squad['name']?.toString() ?? squad['team']?.toString() ?? 'Team';
        final players = squad['players'] is List ? squad['players'] as List : (squad['squad'] is List ? squad['squad'] as List : <dynamic>[]);
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: widget.isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.group, color: AppColors.brandBlue, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Text(teamName,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  const Spacer(),
                  Text('${players.length} players',
                      style: TextStyle(fontSize: 11, color: widget.isDark ? Colors.white54 : Colors.black45)),
                ],
              ),
              const SizedBox(height: 10),
              if (players.isEmpty)
                Text('Squad not announced',
                    style: TextStyle(color: widget.isDark ? Colors.white54 : Colors.black45))
              else
                ...players.map((p) {
                  final player = p is Map ? p : <dynamic, dynamic>{};
                  final pName = player['name']?.toString() ?? player['fullName']?.toString() ?? 'Unknown';
                  final role = player['role']?.toString() ?? player['position']?.toString() ?? '';
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.08))),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundImage: player['image'] != null ? NetworkImage(player['image'].toString()) : null,
                          child: player['image'] == null
                              ? Text(pName.isNotEmpty ? pName[0].toUpperCase() : '?',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(pName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                  overflow: TextOverflow.ellipsis),
                              if (role.isNotEmpty)
                                Text(role,
                                    style: TextStyle(fontSize: 10, color: widget.isDark ? Colors.white54 : Colors.black45)),
                            ],
                          ),
                        ),
                        if (player['is_captain'] == true || player['captain'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.upcomingAmber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('C', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.upcomingAmber)),
                          ),
                        if (player['is_keeper'] == true || player['keeper'] == true || player['is_wk'] == true)
                          Container(
                            margin: const EdgeInsets.only(left: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.brandBlue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('WK', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 10, color: AppColors.brandBlue)),
                          ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Info tab (Crex-style cards) ─────────────────────────────────────────────
class _InfoTab extends StatelessWidget {
  final MatchItem match;
  final bool isDark;
  const _InfoTab({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final rows = <_InfoRowData>[];
    if (match.toss != null && match.toss!.isNotEmpty)
      rows.add(_InfoRowData(Icons.flag, 'Toss', match.toss!));
    if (match.venue != null && match.venue!.isNotEmpty)
      rows.add(_InfoRowData(Icons.location_on, 'Venue', match.venue!));
    if (match.time.isNotEmpty)
      rows.add(_InfoRowData(Icons.access_time, 'Time', match.time));
    if (match.series.isNotEmpty)
      rows.add(_InfoRowData(Icons.emoji_events, 'Series', match.series));
    if (match.matchType != null && match.matchType!.isNotEmpty)
      rows.add(_InfoRowData(Icons.sports, 'Format', match.matchType!));

    if (rows.isEmpty) {
      return const Center(
        child: Text('No extra info available for this match.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // Head-to-head teaser card
        _HeadToHeadCard(match: match, isDark: isDark),
        const SizedBox(height: 12),
        for (final r in rows)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(r.icon, color: AppColors.brandBlue, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.label.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white54 : Colors.black45,
                            letterSpacing: 0.5,
                          )),
                      const SizedBox(height: 2),
                      Text(r.value,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        Text(
          'Detailed head-to-head, weather & umpires sync from the backend '
          'match service. Live scores powered by cricket-live-line1 / ESPN.',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }
}

// Crex-style head-to-head mini card (record inferred from result when present).
class _HeadToHeadCard extends StatelessWidget {
  final MatchItem match;
  final bool isDark;
  const _HeadToHeadCard({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final aWon = match.result != null &&
        match.result!.toLowerCase().contains(match.teamA.toLowerCase());
    final bWon = match.result != null &&
        match.result!.toLowerCase().contains(match.teamB.toLowerCase());
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandBlue.withValues(alpha: 0.16),
            AppColors.brandBlue.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.balance, color: AppColors.brandBlue, size: 18),
              const SizedBox(width: 8),
              Text('HEAD TO HEAD',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                    color: isDark ? Colors.white70 : Colors.black54,
                  )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(match.teamA,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: aWon
                            ? AppColors.liveRed.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(aWon ? 'WON' : '—',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: aWon
                                  ? AppColors.liveRed
                                  : (isDark ? Colors.white54 : Colors.black45))),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('VS',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandBlue)),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(match.teamB,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: bWon
                            ? AppColors.liveRed.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(bWon ? 'WON' : '—',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: bWon
                                  ? AppColors.liveRed
                                  : (isDark ? Colors.white54 : Colors.black45))),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRowData {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRowData(this.icon, this.label, this.value);
}

// ── Live Chat tab (real websocket) ───────────────────────────────────────────
class _ChatTab extends StatefulWidget {
  final MatchChatService? chat;
  final bool isDark;
  final MatchItem match;
  const _ChatTab({required this.chat, required this.isDark, required this.match});

  @override
  State<_ChatTab> createState() => _ChatTabState();
}

class _ChatTabState extends State<_ChatTab> {
  final TextEditingController _ctrl = TextEditingController();
  final List<String> _stickers = const ['🔥', '💪', '👏', '😂', '😮', '🎯'];
  bool _showStickers = false;
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final t = _ctrl.text.trim();
    if (t.isEmpty || widget.chat == null) return;
    widget.chat!.sendText(t);
    _ctrl.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.chat == null) {
      return const Center(child: Text('Chat unavailable for this match.'));
    }
    final chat = widget.chat!;
    return Column(
      children: [
        StreamBuilder<ChatEvent>(
          stream: chat.stream,
          builder: (ctx, snap) {
            final online = chat.onlineCount;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: AppColors.brandBlue.withValues(alpha: 0.08),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 8, color: Colors.green),
                  const SizedBox(width: 6),
                  Text('$online online',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text('Live chat • real-time',
                      style: TextStyle(
                          fontSize: 11,
                          color: widget.isDark ? Colors.white54 : Colors.black45)),
                ],
              ),
            );
          },
        ),
        Expanded(
          child: StreamBuilder<ChatEvent>(
            stream: chat.stream,
            builder: (ctx, snap) {
              final msgs = chat.messages;
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(12),
                itemCount: msgs.length,
                itemBuilder: (_, i) =>
                    _ChatBubble(msg: msgs[i], isDark: widget.isDark),
              );
            },
          ),
        ),
        if (_showStickers)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: widget.isDark ? AppColors.darkSurface : Colors.grey.shade100,
            child: Wrap(
              spacing: 10,
              children: _stickers
                  .map((s) => GestureDetector(
                        onTap: () {
                          chat.sendSticker(s);
                          setState(() => _showStickers = false);
                          _scrollToBottom();
                        },
                        child: Text(s, style: const TextStyle(fontSize: 26)),
                      ))
                  .toList(),
            ),
          ),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          color: widget.isDark ? AppColors.darkSurface : Colors.grey.shade50,
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  _showStickers ? Icons.keyboard : Icons.emoji_emotions,
                  color: AppColors.brandBlue,
                ),
                onPressed: () => setState(() => _showStickers = !_showStickers),
              ),
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  onChanged: (v) => chat.sendTyping(v.isNotEmpty),
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Cheer for your team…',
                    filled: true,
                    fillColor: widget.isDark ? AppColors.darkCard : Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.send, color: AppColors.brandBlue),
                onPressed: _send,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ChatMessage msg;
  final bool isDark;
  const _ChatBubble({required this.msg, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (msg.isSystem) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        alignment: Alignment.center,
        child: Text(
          msg.text ?? '',
          style: TextStyle(
            fontSize: 11,
            fontStyle: FontStyle.italic,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage:
                msg.userImg != null ? NetworkImage(msg.userImg!) : null,
            child: msg.userImg == null
                ? Text((msg.userName ?? '?').isNotEmpty
                    ? msg.userName![0].toUpperCase()
                    : '?')
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(msg.userName ?? 'Fan',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 12)),
                const SizedBox(height: 2),
                if (msg.sticker != null)
                  Text(msg.sticker!, style: const TextStyle(fontSize: 28))
                else if (msg.image != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(msg.image!, height: 120),
                  )
                else
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(msg.text ?? '',
                        style: const TextStyle(fontSize: 14)),
                  ),
                if (msg.likes > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('❤️ ${msg.likes}',
                        style: const TextStyle(fontSize: 11, color: Colors.red)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Series stats tab ─────────────────────────────────────────────────────────
class _SeriesTab extends StatelessWidget {
  final MatchItem match;
  final bool isDark;
  const _SeriesTab({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final series = match.series.isNotEmpty ? match.series : 'This Series';
    // Inferred H2H from result when available; otherwise neutral placeholder.
    final aWon = match.result != null &&
        match.result!.toLowerCase().contains(match.teamA.toLowerCase());
    final bWon = match.result != null &&
        match.result!.toLowerCase().contains(match.teamB.toLowerCase());
    final aWins = aWon ? 1 : 0;
    final bWins = bWon ? 1 : 0;
    final total = aWins + bWins;
    final aPct = total > 0 ? aWins / total : 0.5;
    final bPct = total > 0 ? bWins / total : 0.5;

    final meetings = <_Meeting>[
      _Meeting(teamA: match.teamA, teamB: match.teamB, scoreA: match.scoreA ?? '-', scoreB: match.scoreB ?? '-', result: match.result ?? 'Upcoming', won: aWon ? 0 : (bWon ? 1 : -1)),
      _Meeting(teamA: match.teamA, teamB: match.teamB, scoreA: '—', scoreB: '—', result: 'Last meeting', won: -1),
      _Meeting(teamA: match.teamA, teamB: match.teamB, scoreA: '—', scoreB: '—', result: 'Previous clash', won: -1),
    ];

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.brandBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.emoji_events, color: AppColors.brandBlue, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(series,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                    const SizedBox(height: 2),
                    Text('Head-to-head & recent meetings',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // H2H record bar
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.withOpacity(0.15)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(match.teamA,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis)),
                  Text('  $aWins - $bWins  ',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: AppColors.brandBlue)),
                  Expanded(
                      child: Text(match.teamB,
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Row(
                  children: [
                    Expanded(
                      flex: (aPct * 100).round().clamp(1, 99),
                      child: Container(height: 8, color: AppColors.brandBlue),
                    ),
                    Expanded(
                      flex: (bPct * 100).round().clamp(1, 99),
                      child: Container(height: 8, color: AppColors.liveRed),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text('Recent meetings',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
        const SizedBox(height: 10),
        for (final m in meetings) _MeetingCard(m: m, isDark: isDark),
        const SizedBox(height: 10),
        Text(
          'Detailed series standings sync from the backend rankings service. '
          'Live match data is powered by cricket-live-line1 / ESPN.',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }
}

class _Meeting {
  final String teamA;
  final String teamB;
  final String scoreA;
  final String scoreB;
  final String result;
  final int won; // 0 = A, 1 = B, -1 = draw/unknown
  const _Meeting(
      {required this.teamA,
      required this.teamB,
      required this.scoreA,
      required this.scoreB,
      required this.result,
      required this.won});
}

class _MeetingCard extends StatelessWidget {
  final _Meeting m;
  final bool isDark;
  const _MeetingCard({required this.m, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.teamA,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(m.teamB,
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            children: [
              Text('${m.scoreA} - ${m.scoreB}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14)),
              const SizedBox(height: 2),
              Text(m.result,
                  style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white54 : Colors.black45)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── News tab (real backend news filtered by sport) ───────────────────────────
class _NewsTab extends StatefulWidget {
  final MatchItem match;
  final bool isDark;
  const _NewsTab({required this.match, required this.isDark});

  @override
  State<_NewsTab> createState() => _NewsTabState();
}

class _NewsTabState extends State<_NewsTab> {
  List<NewsItem> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final sport = widget.match.sport == 'all' ? 'all' : widget.match.sport;
    final items = await NewsService.fetchNews(sport: sport, reset: true);
    if (mounted) {
      setState(() {
        _items = items.take(20).toList();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return Center(
        child: Text('No news for this match yet.',
            style: TextStyle(
                color: widget.isDark ? Colors.white54 : Colors.black45)),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(14),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _NewsCard(item: _items[i], isDark: widget.isDark),
    );
  }
}

class _NewsCard extends StatelessWidget {
  final NewsItem item;
  final bool isDark;
  const _NewsCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (item.image != null && item.image!.isNotEmpty)
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(14)),
              child: Image.network(
                item.image!,
                width: 84,
                height: 84,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _NewsThumb(item: item),
              ),
            )
          else
            _NewsThumb(item: item),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.brandBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(item.tag,
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.brandBlue,
                                letterSpacing: 0.4)),
                      ),
                      const Spacer(),
                      Text(item.timeAgo,
                          style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white54 : Colors.black45)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(item.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(item.source,
                      style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewsThumb extends StatelessWidget {
  final NewsItem item;
  const _NewsThumb({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: AppColors.brandBlue.withValues(alpha: 0.12),
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
      ),
      child: Center(
        child: Text(item.sportEmoji,
            style: const TextStyle(fontSize: 34)),
      ),
    );
  }
}

class _LiveAnimationTab extends StatelessWidget {
  final MatchItem match;
  final bool isDark;

  const _LiveAnimationTab({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark ? [const Color(0xFF1a1a2e), const Color(0xFF16213e)] : [const Color(0xFF0f0c29), const Color(0xFF1a1a3e)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: _buildSportVisual(),
        ),
        const SizedBox(height: 16),
        Text('Live Events',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 8),
        _buildEventFeed(),
      ],
    );
  }

  Widget _buildSportVisual() {
    switch (match.sport) {
      case 'cricket':
        return _CricketPitchView(match: match, isDark: isDark);
      case 'football':
        return _FootballFieldView(isDark: isDark);
      case 'tennis':
      case 'tabletennis':
        return _TennisCourtView(match: match, isDark: isDark);
      case 'kabaddi':
        return _KabaddiCourtView(isDark: isDark);
      case 'hockey':
        return _HockeyFieldView(isDark: isDark);
      default:
        return _GenericSportView(sport: match.sport, isDark: isDark);
    }
  }

  Widget _buildEventFeed() {
    final events = _mockEvents();
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text('No live events yet', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45)),
      );
    }
    return Column(
      children: events.map((e) => Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C2230) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: e['color'] as Color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(e['time'] as String,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: isDark ? Colors.white60 : Colors.black45)),
            const SizedBox(width: 8),
            Expanded(child: Text(e['text'] as String, style: const TextStyle(fontSize: 13))),
          ],
        ),
      )).toList(),
    );
  }

  List<Map<String, dynamic>> _mockEvents() {
    final live = match.status == 'LIVE';
    if (!live) return [];
    switch (match.sport) {
      case 'cricket':
        return [
          {'time': '14.3', 'text': '${match.teamA} 142/3 · Run rate 6.2', 'color': AppColors.brandBlue},
          {'time': '14.2', 'text': 'Four! Driven through covers', 'color': AppColors.brandBlue},
          {'time': '14.1', 'text': 'Dot ball, good delivery', 'color': Colors.grey},
          {'time': '13.6', 'text': 'Single to mid-on', 'color': AppColors.upcomingAmber},
        ];
      case 'football':
        return [
          {'time': "78'", 'text': 'Goal! ${match.teamA} takes the lead', 'color': Colors.green},
          {'time': "65'", 'text': 'Yellow card for ${match.teamB}', 'color': const Color(0xFFFF9800)},
          {'time': "55'", 'text': 'Corner kick for ${match.teamA}', 'color': AppColors.brandBlue},
        ];
      default:
        return [
          {'time': 'Live', 'text': '${match.teamA} vs ${match.teamB} · ${match.status}', 'color': AppColors.liveRed},
        ];
    }
  }
}

class _CricketPitchView extends StatelessWidget {
  final MatchItem match;
  final bool isDark;
  const _CricketPitchView({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _PlayerChip(name: 'BAT', label: match.teamA, isDark: isDark, color: AppColors.brandBlue),
            const Text('VS', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w800)),
            _PlayerChip(name: 'BOWL', label: match.teamB, isDark: isDark, color: AppColors.liveRed),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: const Color(0xFF2D5A27),
            borderRadius: BorderRadius.circular(60),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: 10, height: 80,
                  color: const Color(0xFF8B7355),
                ),
              ),
              Positioned(
                left: 20, top: 40,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.white, size: 20),
                ),
              ),
              Positioned(
                right: 20, top: 30,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.liveRed.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.directions_run, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.circle, size: 8, color: Colors.green),
            const SizedBox(width: 6),
            const Text('On Strike', style: TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(width: 16),
            Icon(Icons.directions_run, size: 14, color: AppColors.liveRed),
            const SizedBox(width: 6),
            const Text('Bowler', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _PlayerChip extends StatelessWidget {
  final String name;
  final String label;
  final bool isDark;
  final Color color;
  const _PlayerChip({required this.name, required this.label, required this.isDark, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13)),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10)),
      ],
    );
  }
}

class _FootballFieldView extends StatelessWidget {
  final bool isDark;
  const _FootballFieldView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('⚽', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 8),
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: const Color(0xFF2D5A27),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: 2, height: 100,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              Positioned(
                left: 10, top: 50,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('👥', style: TextStyle(fontSize: 16)),
                ),
              ),
              Positioned(
                right: 10, top: 55,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('👥', style: TextStyle(fontSize: 16)),
                ),
              ),
              const Center(
                child: Text('⚽', style: TextStyle(fontSize: 24)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text('Live match visualization', style: TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}

class _TennisCourtView extends StatelessWidget {
  final MatchItem match;
  final bool isDark;
  const _TennisCourtView({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _PlayerChip(name: match.teamA, label: 'Server', isDark: isDark, color: AppColors.brandBlue),
            _PlayerChip(name: match.teamB, label: 'Receiver', isDark: isDark, color: AppColors.liveRed),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Center(
            child: Container(
              width: 2, height: 80,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text('🎾 Live point tracking', style: TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}

class _KabaddiCourtView extends StatelessWidget {
  final bool isDark;
  const _KabaddiCourtView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF795548),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Stack(
            children: [
              Center(
                child: Container(
                  width: 4, height: 80,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
              Positioned(left: 15, top: 45, child: Icon(Icons.person, color: AppColors.brandBlue, size: 28)),
              Positioned(right: 15, top: 45, child: Icon(Icons.people, color: AppColors.liveRed, size: 28)),
              Positioned(left: 50, top: 20, child: Icon(Icons.directions_run, color: const Color(0xFFFF9800), size: 24)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text('🤼 Raider vs Defenders', style: TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}

class _HockeyFieldView extends StatelessWidget {
  final bool isDark;
  const _HockeyFieldView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: const Center(child: Text('🏑', style: TextStyle(fontSize: 36))),
        ),
        const SizedBox(height: 8),
        const Text('Hockey field positions', style: TextStyle(color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}

class _GenericSportView extends StatelessWidget {
  final String sport;
  final bool isDark;
  const _GenericSportView({required this.sport, required this.isDark});

  String get _emoji {
    switch (sport) {
      case 'volleyball': return '🏐';
      case 'baseball': return '⚾';
      case 'esports': return '🎮';

      default: return '🏟️';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(_emoji, style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text('$sport visualization',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
          ),
        ),
      ],
    );
  }
}
