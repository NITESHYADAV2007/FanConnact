// Tournament Stats Screen — selected tournament shows FULL stats tables,
// a real leaderboard (player rankings for the sport), and its matches.
// Stats are real: cricbuzz tournament stats for cricket, derived standings
// from real completed results for other sports, ICC/ESPN rankings for the
// leaderboard.

import 'package:flutter/material.dart';
import '../theme.dart';
import '../data.dart';
import '../services/tournament_stats_service.dart';
import '../services/player_ranking_service.dart';
import '../widgets/match_card.dart';

class TournamentStatsScreen extends StatefulWidget {
  final String tournament;
  final String sportKey;
  final List<MatchItem> allMatches;

  const TournamentStatsScreen({
    super.key,
    required this.tournament,
    required this.sportKey,
    required this.allMatches,
  });

  @override
  State<TournamentStatsScreen> createState() => _TournamentStatsScreenState();
}

class _TournamentStatsScreenState extends State<TournamentStatsScreen> {
  List<MatchItem> get _matches => widget.allMatches
      .where((m) => (m.series.isNotEmpty ? m.series : 'Other') == widget.tournament)
      .toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.tournament,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          bottom: TabBar(
            indicatorColor: AppColors.brandBlue,
            labelColor: AppColors.brandBlue,
            unselectedLabelColor: isDark ? Colors.white54 : Colors.black45,
            labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
            tabs: const [
              Tab(text: 'Leaderboard'),
              Tab(text: 'Stats'),
              Tab(text: 'Matches'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LeaderboardTab(sportKey: widget.sportKey),
            _StatsTab(
              tournament: widget.tournament,
              sportKey: widget.sportKey,
              matches: _matches,
            ),
            _MatchesTab(matches: _matches),
          ],
        ),
      ),
    );
  }
}

// ─── Leaderboard: real ICC / ESPN / API-Sports player rankings ─────────────
class _LeaderboardTab extends StatefulWidget {
  final String sportKey;
  const _LeaderboardTab({required this.sportKey});

  @override
  State<_LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends State<_LeaderboardTab> {
  PlayerRankingResponse? _resp;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final resp = await PlayerRankingService.fetchRankings(sport: widget.sportKey);
    if (mounted) setState(() {
      _resp = resp;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) return const Center(child: CircularProgressIndicator());
    final resp = _resp;
    if (resp == null || resp.players.isEmpty) {
      return const Center(
        child: Text('No leaderboard data available.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    final players = resp.players.take(50).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  resp.title.isNotEmpty ? resp.title : 'Leaderboard',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  resp.source.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandBlue,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: players.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (ctx, i) {
              final p = players[i];
              final medal = i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDark ? AppColors.darkCard : Colors.white,
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 46,
                      child: Text(
                        medal.isNotEmpty ? medal : '#${p.rank}',
                        style: TextStyle(
                          fontSize: medal.isNotEmpty ? 15 : 13,
                          fontWeight: FontWeight.w800,
                          color: medal.isNotEmpty ? null : AppColors.brandBlue,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(p.name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                    ),
                    if (p.country != null && p.country!.isNotEmpty)
                      Text(p.country!,
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black45)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─── Stats: real tournament stats (cricket) / derived standings ────────────
class _StatsTab extends StatefulWidget {
  final String tournament;
  final String sportKey;
  final List<MatchItem> matches;
  const _StatsTab({
    required this.tournament,
    required this.sportKey,
    required this.matches,
  });

  @override
  State<_StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<_StatsTab> {
  Map<String, TournamentStats>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.sportKey == 'cricket' &&
        widget.tournament.isNotEmpty &&
        widget.tournament.toLowerCase() != 'other') {
      TournamentStatsService.fetchStats(widget.tournament, title: widget.tournament)
          .then((s) {
        if (mounted) setState(() {
          _stats = s;
          _loading = false;
        });
      });
    } else {
      _loading = false;
    }
  }

  String _label(String type) {
    switch (type) {
      case 'mostRuns': return 'Highest Run Scorers';
      case 'mostWickets': return 'Top Wicket Takers';
      case 'mostSixes': return 'Most Sixes';
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) return const Center(child: CircularProgressIndicator());
    final stats = _stats;
    final widgets = <Widget>[];

    if (stats != null && stats.isNotEmpty) {
      stats.forEach((type, s) {
        widgets.add(_StatsCard(
          title: _label(type),
          rows: s.values,
          isDark: isDark,
        ));
      });
    } else {
      widgets.add(_StandingsCard(matches: widget.matches, isDark: isDark));
    }
    if (widgets.isEmpty) {
      return const Center(
        child: Text('No stats available for this tournament.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: widgets,
    );
  }
}

class _StatsCard extends StatelessWidget {
  final String title;
  final List<List<String>> rows;
  final bool isDark;
  const _StatsCard({required this.title, required this.rows, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandBlue)),
          const SizedBox(height: 8),
          for (var i = 0; i < rows.length && i < 12; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 22,
                    child: Text('${i + 1}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brandBlue)),
                  ),
                  Expanded(
                    child: Text(
                      rows[i].length > 1 ? rows[i][1] : '',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (rows[i].length > 4)
                    Text(
                      rows[i][4],
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Derived standings from REAL completed match results (points, wins/losses).
class _StandingsCard extends StatelessWidget {
  final List<MatchItem> matches;
  final bool isDark;
  const _StandingsCard({required this.matches, required this.isDark});

  int _score(String? s) {
    if (s == null || s.isEmpty) return -1;
    final m = RegExp(r'\d+').firstMatch(s);
    return m == null ? -1 : int.parse(m.group(0)!);
  }

  @override
  Widget build(BuildContext context) {
    final done = matches.where((m) => m.status == 'COMPLETED').toList();
    final played = <String, int>{};
    final wins = <String, int>{};
    final losses = <String, int>{};
    for (final m in done) {
      final a = _score(m.scoreA);
      final b = _score(m.scoreB);
      if (a < 0 || b < 0) continue;
      played[m.teamA] = (played[m.teamA] ?? 0) + 1;
      played[m.teamB] = (played[m.teamB] ?? 0) + 1;
      if (a > b) {
        wins[m.teamA] = (wins[m.teamA] ?? 0) + 1;
        losses[m.teamB] = (losses[m.teamB] ?? 0) + 1;
      } else if (b > a) {
        wins[m.teamB] = (wins[m.teamB] ?? 0) + 1;
        losses[m.teamA] = (losses[m.teamA] ?? 0) + 1;
      }
    }
    final teams = played.keys.toList()
      ..sort((x, y) {
        final px = (wins[x] ?? 0) * 2;
        final py = (wins[y] ?? 0) * 2;
        if (px != py) return py.compareTo(px);
        return (played[x] ?? 0).compareTo(played[y] ?? 0);
      });
    if (teams.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: isDark ? AppColors.darkCard : Colors.white,
        ),
        child: const Text(
          'No completed matches in this tournament yet — standings will appear '
          'as matches finish.',
          style: TextStyle(color: Colors.grey, fontSize: 13),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TEAM STANDINGS',
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandBlue)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(flex: 2, child: Text('Team', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w700))),
              for (final h in const ['P', 'W', 'L', 'Pts'])
                SizedBox(
                  width: 34,
                  child: Text(h,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
          const Divider(height: 12),
          for (var i = 0; i < teams.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${i + 1}. ${teams[i]}',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  for (final v in [
                    played[teams[i]] ?? 0,
                    wins[teams[i]] ?? 0,
                    losses[teams[i]] ?? 0,
                    (wins[teams[i]] ?? 0) * 2,
                  ])
                    SizedBox(
                      width: 34,
                      child: Text('$v',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w800)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Matches of this tournament ────────────────────────────────────────────
class _MatchesTab extends StatelessWidget {
  final List<MatchItem> matches;
  const _MatchesTab({required this.matches});

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const Center(
        child: Text('No matches for this tournament.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: matches.length,
      itemBuilder: (ctx, i) => MatchCard(match: matches[i]),
    );
  }
}// ─── Compact full-stats panel (updates when the selected tournament
//     changes) ──────────────────────────────────────────────────────────────
class TournamentStatsPanel extends StatefulWidget {
  final String tournament;
  final String sportKey;
  final List<MatchItem> allMatches;
  const TournamentStatsPanel({
    super.key,
    required this.tournament,
    required this.sportKey,
    required this.allMatches,
  });

  @override
  State<TournamentStatsPanel> createState() => _TournamentStatsPanelState();
}

class _TournamentStatsPanelState extends State<TournamentStatsPanel> {
  Map<String, TournamentStats>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TournamentStatsPanel old) {
    super.didUpdateWidget(old);
    if (old.tournament != widget.tournament || old.sportKey != widget.sportKey) {
      _stats = null;
      _loading = true;
      _load();
    }
  }

  Future<void> _load() async {
    if (widget.sportKey == 'cricket' &&
        widget.tournament.isNotEmpty &&
        widget.tournament.toLowerCase() != 'other') {
      final s = await TournamentStatsService.fetchStats(widget.tournament,
          title: widget.tournament);
      if (mounted) {
        setState(() {
          _stats = s;
          _loading = false;
        });
      }
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  String _label(String type) {
    switch (type) {
      case 'mostRuns': return 'Highest Runs';
      case 'mostWickets': return 'Top Wicket Takers';
      case 'mostSixes': return 'Most Sixes';
      default: return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = _stats;
    final widgets = <Widget>[];
    if (stats != null && stats.isNotEmpty) {
      stats.forEach((type, s) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_label(type),
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandBlue)),
              const SizedBox(height: 4),
              for (var i = 0; i < s.values.length && i < 3; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.brandBlue)),
                      ),
                      Expanded(
                        child: Text(
                          s.values[i].length > 1 ? s.values[i][1] : '',
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (s.values[i].length > 4)
                        Text(
                          s.values[i][4],
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black87),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ));
      });
    }
    if (widgets.isEmpty) {
      widgets.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Text('Full stats load for this tournament…',
            style: TextStyle(fontSize: 12, color: Colors.grey)),
      ));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            colors: [
              AppColors.brandBlue.withValues(alpha: isDark ? 0.18 : 0.08),
              AppColors.brandGreen.withValues(alpha: isDark ? 0.10 : 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, size: 16, color: Colors.amber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${widget.tournament.toUpperCase()} — FULL STATS',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandBlue,
                        letterSpacing: 0.3),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => TournamentStatsScreen(
                      tournament: widget.tournament,
                      sportKey: widget.sportKey,
                      allMatches: widget.allMatches,
                    ),
                  )),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('OPEN',
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(10),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              ...widgets,
          ],
        ),
      ),
    );
  }
}

