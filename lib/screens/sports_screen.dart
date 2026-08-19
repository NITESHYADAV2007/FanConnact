import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../l10n.dart';
import '../services/live_match_service.dart';
import '../services/tournament_stats_service.dart';
import '../services/cricket_hub_service.dart';
import '../widgets/sport_selector.dart';
import '../widgets/match_card.dart';
import '../screens/team_matches_screen.dart';

import '../screens/player_detail_screen.dart';
import '../screens/match_detail_screen.dart';
import '../screens/tournament_stats_screen.dart';

class SportsScreen extends StatefulWidget {
  final Locale locale;
  final bool isDark;

  const SportsScreen({super.key, required this.locale, required this.isDark});

  @override
  State<SportsScreen> createState() => _SportsScreenState();
}

class _SportsScreenState extends State<SportsScreen> with WidgetsBindingObserver {
  String _selectedSport = 'all';
  String _filter = 'all';
  String _selectedTournament = 'all';
  List<MatchItem> _matches = [];
  bool _loading = true;

  Map<String, List<dynamic>> _cricketData = {};
  Map<String, bool> _cricketLoading = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App reopened: silently refresh so data is always current.
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    // Silent refresh when data already on screen (no flash); spinner only
    // on a cold load.
    if (_matches.isEmpty) setState(() => _loading = true);
    final fetched = await LiveMatchService.fetchLiveMatches(sport: _selectedSport);
    if (mounted) {
      setState(() {
        _matches = fetched;
        _loading = false;
        _selectedTournament = 'all';
      });
      if (_selectedSport == 'cricket') {
        _loadCricketSections();
      }
    }
  }

  Future<void> _loadCricketSections() async {
    for (final key in ['players', 'teams']) {
      if (_cricketData.containsKey(key)) continue;
      setState(() => _cricketLoading[key] = true);
      try {
        List<dynamic> items;
        switch (key) {
          case 'players': items = await CricketHubService.players(); break;
          case 'teams': items = await CricketHubService.teams(); break;
          case 'tournaments': items = await CricketHubService.tournaments(); break;
          case 'competitions': items = await CricketHubService.competitions(); break;
          case 'iccRanks': items = await CricketHubService.iccRanks(); break;
          default: items = [];
        }
        if (mounted) {
          setState(() {
            _cricketData[key] = items;
            _cricketLoading[key] = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _cricketLoading[key] = false);
      }
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

  List<String> get _tournaments {
    final map = <String, bool>{};
    for (final m in _matches) {
      if (m.status == 'COMPLETED') continue;
      final key = m.series.isNotEmpty ? m.series : 'Other';
      if (m.status == 'LIVE') {
        map[key] = true;
      } else {
        map.putIfAbsent(key, () => false);
      }
    }
    final entries = map.entries.toList();
    entries.sort((a, b) {
      if (a.value != b.value) return a.value ? 0 : 1;
      return a.key.compareTo(b.key);
    });
    return entries.map((e) => e.key).toList();
  }

  List<MapEntry<String, List<MatchItem>>> get _grouped {
    final map = <String, List<MatchItem>>{};
    for (final m in _filtered) {
      final key = (m.series.isNotEmpty ? m.series : 'Other');
      map.putIfAbsent(key, () => []).add(m);
    }
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
              setState(() {
                _selectedSport = key;
                _cricketData.clear();
                _cricketLoading.clear();
              });
              _load();
            },
            locale: widget.locale,
          ),
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
                        onTap: () {
                          setState(() => _selectedTournament = tn);
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => TournamentStatsScreen(
                              tournament: tn,
                              sportKey: _selectedSport,
                              allMatches: _matches,
                            ),
                          ));
                        },
                      )),
                ],
              ),
            ),
          if (_selectedTournament != 'all')
            TournamentStatsPanel(
              tournament: _selectedTournament,
              sportKey: _selectedSport,
              allMatches: _matches,
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
                          _SectionHeader(
                            title: entry.key,
                            isLive: entry.value.any((m) => m.status == 'LIVE'),
                            matchCount: entry.value.length,
                            liveCount: entry.value.where((m) => m.status == 'LIVE').length,
                            tournament:
                                entry.value.every((m) => m.sport == 'cricket') ? entry.key : null,
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
                  if (_selectedSport == 'cricket') ..._buildCricketSections(isDark),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCricketSections(bool isDark) {
    final widgets = <Widget>[];
    for (final entry in _cricketSectionsConfig) {
      final key = entry['key'] as String;
      final label = entry['label'] as String;
      final icon = entry['icon'] as IconData;
      final gradient = entry['gradient'] as List<Color>;
      final items = _cricketData[key];
      final loading = _cricketLoading[key] == true;

      widgets.add(Padding(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 4),
        child: Row(
          children: [
            Container(
              width: 4, height: 20,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.3,
                color: isDark ? Colors.white : Colors.black87,
              )),
            ),
            if (items != null && items.length > 6)
              GestureDetector(
                onTap: () => _showDetailSheetAll(items, label),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('See all', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                ),
              ),
          ],
        ),
      ));
      if (loading) {
        widgets.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(gradient.first),
              ),
            ),
          ),
        ));
      } else if (items != null && items.isNotEmpty) {
        widgets.add(_buildCricketScroll(key, items, isDark, gradient));
      }
    }
    return widgets;
  }

  static const _cricketSectionsConfig = [
    {'key': 'players', 'label': 'Players', 'icon': Icons.people, 'gradient': [Color(0xFF667EEA), Color(0xFF764BA2)]},
    {'key': 'teams', 'label': 'Teams', 'icon': Icons.groups, 'gradient': [Color(0xFFF093FB), Color(0xFFF5576C)]},
  ];

  Widget _buildCricketScroll(String key, List<dynamic> items, bool isDark, List<Color> gradient) {
    return SizedBox(
      height: 118,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: items.length > 12 ? 12 : items.length,
        itemBuilder: (ctx, i) {
          final item = items[i];
          return _buildCricketCard(item, key, isDark, gradient);
        },
      ),
    );
  }

  Widget _buildCricketCard(dynamic item, String section, bool isDark, List<Color> gradient) {
    if (item is! Map) return const SizedBox.shrink();
    final title = _itemTitle(item);
    final img = _itemImage(item);
    final hasImage = img != null;
    final isRank = section == 'iccRanks';

    return GestureDetector(
      onTap: () => _onCricketTap(item, section),
      child: Container(
        width: 92,
        margin: const EdgeInsets.only(right: 8, top: 4, bottom: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                isDark ? (gradient.first.withValues(alpha: 0.15)) : Colors.white,
                isDark ? (gradient.last.withValues(alpha: 0.08)) : Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: gradient.first.withValues(alpha: isDark ? 0.3 : 0.2),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -8, top: -8,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      gradient.first.withValues(alpha: 0.08),
                      gradient.last.withValues(alpha: 0.08),
                    ]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isRank)
                      Container(
                        width: 22, height: 22,
                        margin: const EdgeInsets.only(bottom: 4),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradient),
                          shape: BoxShape.circle,
                        ),
                        child: Text('${(item['rank'] ?? item['position'] ?? '—')}',
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white)),
                      ),
                    if (hasImage)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Image.network(img, width: 40, height: 40, fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(_sectionIcon(section), size: 24, color: gradient.first)),
                        ),
                      )
                    else
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: gradient).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_sectionIcon(section), size: 24, color: gradient.first),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      title.length > 14 ? '${title.substring(0, 12)}…' : title,
                      textAlign: TextAlign.center, maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1A1F2B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetailSheetAll(List<dynamic> items, String label) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (ctx, scrollCtrl) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Container(
                        width: 4, height: 18,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [AppColors.brandBlue, AppColors.brandGreen]),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(label, style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      )),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.black12,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      final title = item is Map ? _itemTitle(item) : item.toString();
                      return ListTile(
                        leading: item is Map && _itemImage(item) != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(_itemImage(item)!, width: 36, height: 36,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.circle, size: 28)),
                              )
                            : null,
                        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () { Navigator.pop(ctx); _onCricketTap(item is Map ? item : {}, label.toLowerCase()); },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _onCricketTap(Map item, String section) {
    switch (section) {
      case 'players':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => PlayerDetailScreen(
            sportKey: 'cricket',
            name: _itemTitle(item),
            country: item['country']?.toString(),
            extra: Map<String, dynamic>.from(item),
          ),
        ));
        break;
      case 'teams':
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => TeamMatchesScreen(
            teamName: _itemTitle(item),
            teamLogo: _itemImage(item),
            sportKey: 'cricket',
          ),
        ));
        break;
      case 'matches':
        final match = _buildMatchItem(item);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => MatchDetailScreen(match: match),
        ));
        break;
      default:
        _showDetailSheet(item);
    }
  }

  MatchItem _buildMatchItem(Map item) {
    return MatchItem(
      sport: 'cricket',
      sportEmoji: '🏏',
      series: item['competition'] is Map
          ? (item['competition']['name'] ?? '').toString()
          : (item['competition']?.toString() ?? ''),
      teamA: item['teama'] is Map
          ? (item['teama']['name'] ?? item['teama']['short_name'] ?? 'Team A').toString()
          : (item['teama']?.toString() ?? 'Team A'),
      teamB: item['teamb'] is Map
          ? (item['teamb']['name'] ?? item['teamb']['short_name'] ?? 'Team B').toString()
          : (item['teamb']?.toString() ?? 'Team B'),
      logoA: item['teama'] is Map ? item['teama']['logo_url']?.toString() : null,
      logoB: item['teamb'] is Map ? item['teamb']['logo_url']?.toString() : null,
      abbrA: item['teama'] is Map ? item['teama']['short_name']?.toString() : null,
      abbrB: item['teamb'] is Map ? item['teamb']['short_name']?.toString() : null,
      status: (item['status'] ?? 'UPCOMING').toString(),
      time: item['date_start']?.toString() ?? item['subtitle']?.toString() ?? '',
      matchId: item['match_id']?.toString(),
      venue: item['venue']?.toString(),
      matchType: item['format_str']?.toString(),
    );
  }

  IconData _sectionIcon(String section) {
    for (final s in _cricketSectionsConfig) {
      if (s['key'] == section) return s['icon'] as IconData;
    }
    return Icons.circle;
  }

  String _itemTitle(dynamic item) {
    if (item is! Map) return item.toString();
    return item['title']?.toString() ??
        item['name']?.toString() ??
        item['fullname']?.toString() ??
        item['short_title']?.toString() ??
        item['team']?.toString() ??
        item['season_year']?.toString() ??
        item['year']?.toString() ??
        'Item';
  }

  String? _itemImage(dynamic item) {
    if (item is! Map) return null;
    return item['image']?.toString() ??
        item['img']?.toString() ??
        item['logo']?.toString() ??
        item['logo_url']?.toString() ??
        item['thumb_url']?.toString();
  }

  void _showDetailSheet(Map item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (ctx, scrollCtrl) {
            return ListView(
              controller: scrollCtrl,
              padding: const EdgeInsets.all(20),
              children: item.entries.map((e) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(
                          e.key.replaceAll('_', ' '),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text('${e.value}', style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

class _SectionHeader extends StatefulWidget {
  final String title;
  final bool isLive;
  final int matchCount;
  final int liveCount;
  final String? tournament;
  const _SectionHeader({
    required this.title,
    this.isLive = false,
    this.matchCount = 0,
    this.liveCount = 0,
    this.tournament,
  });

  @override
  State<_SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<_SectionHeader> {
  Map<String, TournamentStats>? _stats;

  @override
  void initState() {
    super.initState();
    final t = widget.tournament;
    if (t != null && t.isNotEmpty && t.toLowerCase() != 'other') {
      TournamentStatsService.fetchStats(t, title: t).then((s) {
        if (mounted && s != null && s.isNotEmpty) setState(() => _stats = s);
      });
    }
  }

  static final List<_TourneyTheme> _themes = [
    _TourneyTheme(const Color(0xFF0d1b3e), const Color(0xFF1a3a6e), Icons.emoji_events),
    _TourneyTheme(const Color(0xFF1a3a1a), const Color(0xFF0d5e2e), Icons.emoji_nature),
    _TourneyTheme(const Color(0xFF2d1b4e), const Color(0xFF4a2d7a), Icons.shield),
    _TourneyTheme(const Color(0xFF3e1a1a), const Color(0xFF6e2a2a), Icons.local_fire_department),
    _TourneyTheme(const Color(0xFF0d2a3e), const Color(0xFF1a4a6e), Icons.waves),
    _TourneyTheme(const Color(0xFF2a1a3e), const Color(0xFF4a2d6e), Icons.diamond),
    _TourneyTheme(const Color(0xFF1a2a1a), const Color(0xFF2d5e2d), Icons.eco),
    _TourneyTheme(const Color(0xFF3e2a1a), const Color(0xFF6e4a1a), Icons.whatshot),
  ];

  _TourneyTheme get _theme => _themes[widget.title.hashCode.abs() % _themes.length];

  @override
  Widget build(BuildContext context) {
    final theme = _theme;
    final stats = _stats;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
        height: 80,
        child: Stack(
          children: [
            // Background gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.color1, theme.color2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: theme.color2.withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
            ),
            // Decorative circles (Crex-style)
            Positioned(
              right: -20, top: -20,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              right: 30, bottom: -30,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            Positioned(
              left: -10, bottom: -10,
              child: Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            // Content
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Trophy icon
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(theme.icon, size: 18, color: widget.isLive ? AppColors.liveRed : Colors.amber.shade300),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.3,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.matchCount > 0) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.liveCount > 0 ? '${widget.matchCount} matches • ${widget.liveCount} live' : '${widget.matchCount} matches',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.6),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (widget.isLive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.liveRed,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.fiber_manual_record, size: 8, color: Colors.white),
                                SizedBox(width: 4),
                                Text('LIVE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
          if (stats != null && stats.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _StatsStrip(stats: stats),
            ),
        ],
      ),
    );
  }
}

class _StatsStrip extends StatelessWidget {
  final Map<String, TournamentStats> stats;
  const _StatsStrip({required this.stats});

  String _label(String type) {
    switch (type) {
      case 'mostRuns':
        return 'Highest Runs';
      case 'mostWickets':
        return 'Wicket Taker';
      case 'mostSixes':
        return 'Most Sixes';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final entries = stats.entries.where((e) => e.value.topName != null).take(3).toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    return Row(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.grey.shade300,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _label(entries[i].key),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandBlue,
                      letterSpacing: 0.4,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    entries[i].value.topName!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entries[i].value.topValue != null) ...[
                    const SizedBox(height: 1),
                    Text(
                      entries[i].value.topValue!,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.6)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TourneyTheme {
  final Color color1;
  final Color color2;
  final IconData icon;
  const _TourneyTheme(this.color1, this.color2, this.icon);
}

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
                  width: 6, height: 6,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: const BoxDecoration(color: AppColors.liveRed, shape: BoxShape.circle),
                ),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
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
