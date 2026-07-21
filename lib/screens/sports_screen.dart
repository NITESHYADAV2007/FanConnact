import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../l10n.dart';
import '../services/live_match_service.dart';
import '../widgets/sport_selector.dart';
import '../widgets/match_card.dart';
import '../screens/team_matches_screen.dart';
import '../screens/player_rankings_screen.dart';
import '../screens/cricket_hub_screen.dart';

class SportsScreen extends StatefulWidget {
  final Locale locale;
  final bool isDark;

  const SportsScreen({super.key, required this.locale, required this.isDark});

  @override
  State<SportsScreen> createState() => _SportsScreenState();
}

class _SportsScreenState extends State<SportsScreen> {
  String _selectedSport = 'all';
  String _filter = 'all'; // 'all' | 'live' | 'upcoming' | 'finished'
  String _selectedTournament = 'all'; // 'all' or a series name
  List<MatchItem> _matches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final fetched = await LiveMatchService.fetchLiveMatches(sport: _selectedSport);
    if (mounted) {
      setState(() {
        _matches = fetched;
        _loading = false;
        // Reset tournament filter when the sport changes.
        _selectedTournament = 'all';
      });
    }
  }

  List<MatchItem> get _filtered {
    var list = _matches;
    if (_filter != 'all') {
      list = list.where((m) {
        final s = m.status.toUpperCase();
        if (_filter == 'live') return s == 'LIVE';
        if (_filter == 'upcoming') return s == 'UPCOMING';
        if (_filter == 'finished') return s == 'COMPLETED';
        return true;
      }).toList();
    }
    if (_selectedTournament != 'all') {
      list = list
          .where((m) => (m.series.isNotEmpty ? m.series : 'Other') == _selectedTournament)
          .toList();
    }
    return list;
  }

  // Unique tournaments/series present in the current matches (Crex-style).
  // Series containing a LIVE match are listed first.
  List<String> get _tournaments {
    final map = <String, bool>{};
    for (final m in _matches) {
      final key = m.series.isNotEmpty ? m.series : 'Other';
      if (m.status == 'LIVE') {
        map[key] = true;
      } else {
        map.putIfAbsent(key, () => false);
      }
    }
    final entries = map.entries.toList();
    entries.sort((a, b) {
      if (a.value != b.value) return a.value ? 0 : 1; // live first
      return a.key.compareTo(b.key);
    });
    return entries.map((e) => e.key).toList();
  }

  // Group matches by their series / tournament name (Crex-style).
  List<MapEntry<String, List<MatchItem>>> get _grouped {
    final map = <String, List<MatchItem>>{};
    for (final m in _filtered) {
      final key = (m.series.isNotEmpty ? m.series : 'Other');
      map.putIfAbsent(key, () => []).add(m);
    }
    // Put series that contain a LIVE match first.
    final entries = map.entries.toList();
    entries.sort((a, b) {
      final aLive = a.value.any((m) => m.status == 'LIVE') ? 0 : 1;
      final bLive = b.value.any((m) => m.status == 'LIVE') ? 0 : 1;
      if (aLive != bLive) return aLive.compareTo(bLive);
      return a.key.compareTo(b.key);
    });
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.locale.languageCode;
    String t(String k) => AppStrings.get(lang, k);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          t('matches'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          if (_selectedSport != 'all') ...[
            if (_selectedSport == 'cricket')
              TextButton.icon(
                icon: const Icon(Icons.sports_cricket, size: 18),
                label: const Text('Hub'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CricketHubScreen(isDark: isDark),
                    ),
                  );
                },
              ),
            TextButton.icon(
              icon: const Icon(Icons.leaderboard, size: 18),
              label: const Text('Rankings'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PlayerRankingsScreen(
                      sportKey: _selectedSport,
                    ),
                  ),
                );
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          SportSelector(
            selectedKey: _selectedSport,
            onSelected: (key) {
              setState(() => _selectedSport = key);
              _load();
            },
            locale: widget.locale,
          ),
          // Live / Upcoming / Finished segmented filter
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'all',
                  label: Text(t('all')),
                  icon: const Icon(Icons.grid_view, size: 16),
                ),
                ButtonSegment(
                  value: 'live',
                  label: Text(t('live')),
                  icon: const Icon(Icons.fiber_manual_record, size: 14, color: AppColors.liveRed),
                ),
                ButtonSegment(
                  value: 'upcoming',
                  label: Text(t('upcoming')),
                  icon: const Icon(Icons.schedule, size: 16),
                ),
                ButtonSegment(
                  value: 'finished',
                  label: Text(t('completed')),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (set) => setState(() => _filter = set.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                backgroundColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? AppColors.brandBlue.withValues(alpha: 0.15)
                        : null),
                foregroundColor: WidgetStateProperty.all(
                    isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
          const Divider(height: 1),
          // Crex-style tournament filter chips (only when there are series).
          if (_tournaments.isNotEmpty)
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                children: [
                  _TournamentChip(
                    label: t('all'),
                    selected: _selectedTournament == 'all',
                    onTap: () => setState(() => _selectedTournament = 'all'),
                  ),
                  ..._tournaments.map((tn) => _TournamentChip(
                        label: tn,
                        selected: _selectedTournament == tn,
                        live: _matches.any((m) =>
                            (m.series.isNotEmpty ? m.series : 'Other') == tn &&
                            m.status == 'LIVE'),
                        onTap: () => setState(() => _selectedTournament = tn),
                      )),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(t('noMatches'),
                            style: const TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ..._grouped.expand((entry) => [
                          _SeriesHeader(
                            title: entry.key,
                            isLive: entry.value.any((m) => m.status == 'LIVE'),
                          ),
                          ...entry.value.map((m) => MatchCard(
                                match: m,
                                onTeamTap: (teamName, logo) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => TeamMatchesScreen(
                                        teamName: teamName,
                                        teamLogo: logo,
                                        sportKey: _selectedSport,
                                      ),
                                    ),
                                  );
                                },
                              )),
                        ]),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Crex-style series / tournament header shown above each group of matches.
class _SeriesHeader extends StatelessWidget {
  final String title;
  final bool isLive;
  const _SeriesHeader({required this.title, this.isLive = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 2),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: isLive ? AppColors.liveRed : AppColors.brandBlue,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
                color: isDark ? Colors.white : Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.liveRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.liveRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.liveRed,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Crex-style pill chip used in the tournament filter row.
class _TournamentChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool live;
  final VoidCallback onTap;

  const _TournamentChip({
    required this.label,
    required this.selected,
    this.live = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = selected
        ? AppColors.brandBlue
        : (isDark ? AppColors.darkCard : Colors.white);
    final fg = selected
        ? Colors.white
        : (isDark ? Colors.white70 : Colors.black87);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? AppColors.brandBlue
                  : (live ? AppColors.liveRed.withValues(alpha: 0.6) : Colors.grey.withOpacity(0.3)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (live)
                Container(
                  width: 6,
                  height: 6,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: const BoxDecoration(
                    color: AppColors.liveRed,
                    shape: BoxShape.circle,
                  ),
                ),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
