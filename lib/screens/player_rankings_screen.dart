// Player rankings screen — shows real player rankings for a sport, fetched
// from the backend /api/rankings/:sport/:category endpoint. Crex-style table
// with filter chips and a responsive column layout.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../data.dart';
import '../theme.dart';
import '../services/player_ranking_service.dart';
import 'player_detail_screen.dart';
import 'team_matches_screen.dart';

// Sports with REAL ranking data (ICC / FIFA / ESPN / allsportsapi2). Every
// other sport previously served generated/mock numbers and is hidden now.
const Set<String> realRankingSports = {
  'cricket', 'football', 'basketball', 'baseball', 'hockey', 'tennis',
};

class PlayerRankingsScreen extends StatefulWidget {
  final String sportKey;
  final String? initialCategory;
  const PlayerRankingsScreen({
    super.key,
    required this.sportKey,
    this.initialCategory,
  });

  @override
  State<PlayerRankingsScreen> createState() => _PlayerRankingsScreenState();
}

class _PlayerRankingsScreenState extends State<PlayerRankingsScreen> {
  PlayerRankingResponse? _data;
  bool _loading = true;
  String? _error;
  bool _stale = false;
  final Map<String, String> _selectedFilters = {};
  String _rankType = 'players';

  // Cricket-specific filters
  String _cricketFormat = '1'; // 1=test, 2=odi, 3=t20
  String _cricketGender = 'men';
  String _cricketCategory = '1'; // 1=batsmen, 2=bowlers, 3=all-rounders

  static const _formats = ['Test', 'ODI', 'T20'];
  static const _genders = ['Men', 'Women'];
  static const _playerCategories = ['Batsmen', 'Bowlers', 'All-rounders'];

  @override
  void initState() {
    super.initState();
    if (realRankingSports.contains(widget.sportKey)) {
      _load();
    } else {
      _loading = false;
    }
  }

  String get _sportEmoji {
    const map = {
      'cricket': '🏏',
      'football': '⚽',
      'basketball': '🏀',
      'tennis': '🎾',
      'hockey': '🏑',
      'baseball': '⚾',
      'volleyball': '🏐',
      'kabaddi': '🤼',
      'tabletennis': '🏓',
      'esports': '🎮',

    };
    return map[widget.sportKey] ?? '🏟️';
  }

  String get _sportName {
    final s = sports.firstWhere(
      (s) => s.key == widget.sportKey,
      orElse: () => const Sport(key: 'all', name: 'Sports', emoji: '🏟️'),
    );
    return s.name;
  }

  String get _currentCategory {
    if (_data == null) return widget.initialCategory ?? '';
    // Build category string from selected filters in group order.
    final parts = <String>[];
    for (final g in _data!.filters) {
      parts.add(_selectedFilters[g.group] ?? '');
    }
    final joined = parts.where((p) => p.isNotEmpty).join('_');
    return joined.isNotEmpty ? joined : _data!.defaultCategory;
  }

  Future<void> _load({bool keepFilters = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    PlayerRankingResponse? resp;
    if (widget.sportKey == 'cricket' && _rankType == 'teams') {
      resp = await _loadCricketTeamsDirect();
    } else if (widget.sportKey == 'cricket') {
      resp = await _loadCricketDirect();
    } else {
      resp = await PlayerRankingService.fetchRankings(
        sport: widget.sportKey,
        category: keepFilters ? _currentCategory : widget.initialCategory,
      );
    }
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (resp == null) {
        final cached = widget.sportKey == 'cricket'
            ? (_rankType == 'teams' ? _lastGoodCricketTeams : _lastGoodCricket)
            : PlayerRankingService.lastGood(
                widget.sportKey,
                keepFilters ? _currentCategory : widget.initialCategory,
              );
        if (cached != null) {
          _data = cached;
          _error = null;
          _stale = true;
          if (!keepFilters) {
            _selectedFilters.clear();
            for (final g in cached.filters) {
              if (g.options.isNotEmpty) {
                _selectedFilters[g.group] = g.options.first.value;
              }
            }
          }
        } else {
          _error = 'Could not load rankings';
        }
      } else {
        _data = resp;
        _stale = false;
        if (!keepFilters) {
          _selectedFilters.clear();
          for (final g in resp.filters) {
            if (g.options.isNotEmpty) {
              _selectedFilters[g.group] = g.options.first.value;
            }
          }
        }
      }
    });
  }

  PlayerRankingResponse? _lastGoodCricket;
  PlayerRankingResponse? _lastGoodCricketTeams;

  // Real ICC rankings from the backend (synced from advance /iccranks):
  // every format (Test/ODI/T20I) × role (bat/bowl/all) × gender (men/women)
  // combination is available in data/player-rankings.json.
  static const _backendFormats = ['test', 'odi', 't20i'];
  static const _backendRoles = ['bat', 'bowl', 'all'];

  Future<PlayerRankingResponse?> _loadCricketDirect() async {
    try {
      final fmtIdx = ((int.tryParse(_cricketFormat) ?? 1) - 1).clamp(0, 2);
      final roleIdx = ((int.tryParse(_cricketCategory) ?? 1) - 1).clamp(0, 2);
      final fmt = _backendFormats[fmtIdx];
      final role = _backendRoles[roleIdx];
      final gender = _cricketGender;
      // ICC publishes no women's Test rankings — fall back to last good.
      if (fmt == 'test' && gender == 'women') return _lastGoodCricket;
      final resp = await PlayerRankingService.fetchRankings(
        sport: 'cricket',
        category: '${fmt}_${role}_$gender',
      );
      if (resp == null) return _lastGoodCricket;
      _lastGoodCricket = resp;
      return resp;
    } catch (e) {
      debugPrint('PlayerRankingsScreen: ICC players failed ($e)');
      return _lastGoodCricket;
    }
  }

  Future<PlayerRankingResponse?> _loadCricketTeamsDirect() async {
    try {
      final fmtIdx = ((int.tryParse(_cricketFormat) ?? 1) - 1).clamp(0, 2);
      final fmt = _backendFormats[fmtIdx];
      final gender = _cricketGender;
      // ICC publishes no women's Test team rankings — fall back to last good.
      if (fmt == 'test' && gender == 'women') return _lastGoodCricketTeams;
      final raw = await _fetchTeamRankingsBackend(gender, fmt);
      if (raw == null || raw.isEmpty) return _lastGoodCricketTeams;
      final players = <PlayerRanking>[];
      final formatLabel = _formats[fmtIdx];
      for (var i = 0; i < raw.length; i++) {
        final r = raw[i];
        players.add(PlayerRanking(
          rank: i + 1,
          name: r['team']?.toString() ?? r['name']?.toString() ?? 'Unknown',
          country: r['code']?.toString() ?? r['country']?.toString() ?? '',
          extra: {
            'rating': r['rating']?.toString() ?? '',
            'points': r['points']?.toString() ?? '',
            'image': r['logo']?.toString() ?? r['flag']?.toString() ?? '',
            'format': formatLabel,
          },
        ));
      }
      final resp = PlayerRankingResponse(
        sport: 'cricket',
        label: 'Cricket',
        title: 'ICC Team Rankings ($formatLabel)',
        subtitle: 'ICC team rankings — ${gender.toUpperCase()} — $formatLabel format',
        category: 'all',
        defaultCategory: 'all',
        filters: const [],
        columns: const [
          RankingColumn(key: 'rank', label: '#'),
          RankingColumn(key: 'name', label: 'Team'),
          RankingColumn(key: 'country', label: 'Code'),
          RankingColumn(key: 'rating', label: 'Rating', align: 'center'),
        ],
        source: 'ICC (advance /iccranks)',
        players: players,
      );
      _lastGoodCricketTeams = resp;
      return resp;
    } catch (e) {
      debugPrint('PlayerRankingsScreen: ICC teams failed ($e)');
      return _lastGoodCricketTeams;
    }
  }

  // Teams come from the backend's leaderboard data (synced ICC team ranks):
  // /api/leaderboard/cricket/:Gender/:Category — e.g. Men/ODI, Women/T20I.
  Future<List<Map<String, dynamic>>?> _fetchTeamRankingsBackend(
      String gender, String fmt) async {
    final genderLabel = gender == 'women' ? 'Women' : 'Men';
    final fmtLabel = switch (fmt) {
      'test' => 'Test',
      'odi' => 'ODI',
      _ => 'T20I',
    };
    final uri = Uri.parse(
        '$apiBaseUrl/api/leaderboard/cricket/$genderLabel/$fmtLabel');
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) return null;
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    return (json['rankings'] as List? ?? [])
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text('$_sportEmoji  $_sportName Rankings',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _load(keepFilters: true),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Text(_error!,
                      style: const TextStyle(color: Colors.grey)),
                )
              : !realRankingSports.contains(widget.sportKey) ||
                      (_data != null && _data!.players.isEmpty)
                  ? _NoDataView(sportName: _sportName, emoji: _sportEmoji)
                  : Column(
                  children: [
                    if (widget.sportKey == 'cricket')
                      Column(
                        children: [
                          // Players / Teams toggle
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(value: 'players', label: Text('Players'), icon: Icon(Icons.people, size: 16)),
                                ButtonSegment(value: 'teams', label: Text('Teams'), icon: Icon(Icons.groups, size: 16)),
                              ],
                              selected: {_rankType},
                              onSelectionChanged: (set) {
                                setState(() => _rankType = set.first);
                                _load();
                              },
                              style: ButtonStyle(
                                visualDensity: VisualDensity.compact,
                                backgroundColor: WidgetStateProperty.resolveWith((states) =>
                                    states.contains(WidgetState.selected) ? AppColors.brandBlue.withValues(alpha: 0.15) : null),
                              ),
                            ),
                          ),
                          // Format selector
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                            child: SegmentedButton<String>(
                              segments: _formats.map((f) => ButtonSegment(value: '${_formats.indexOf(f) + 1}', label: Text(f))).toList(),
                              selected: {_cricketFormat},
                              onSelectionChanged: (set) {
                                setState(() => _cricketFormat = set.first);
                                _load();
                              },
                              style: ButtonStyle(
                                visualDensity: VisualDensity.compact,
                                backgroundColor: WidgetStateProperty.resolveWith((states) =>
                                    states.contains(WidgetState.selected) ? AppColors.brandBlue.withValues(alpha: 0.12) : null),
                              ),
                            ),
                          ),
                          // Category selector (players only) + Gender row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                            child: Row(
                              children: [
                                if (_rankType == 'players')
                                  Expanded(
                                    child: SegmentedButton<String>(
                                      segments: _playerCategories.map((c) => ButtonSegment(value: '${_playerCategories.indexOf(c) + 1}', label: Text(c))).toList(),
                                      selected: {_cricketCategory},
                                      onSelectionChanged: (set) {
                                        setState(() => _cricketCategory = set.first);
                                        _load();
                                      },
                                      style: ButtonStyle(
                                        visualDensity: VisualDensity.compact,
                                        backgroundColor: WidgetStateProperty.resolveWith((states) =>
                                            states.contains(WidgetState.selected) ? AppColors.brandBlue.withValues(alpha: 0.12) : null),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 8),
                                SegmentedButton<String>(
                                  segments: _genders.map((g) => ButtonSegment(value: g.toLowerCase(), label: Text(g))).toList(),
                                  selected: {_cricketGender},
                                  onSelectionChanged: (set) {
                                    setState(() => _cricketGender = set.first);
                                    _load();
                                  },
                                  style: ButtonStyle(
                                    visualDensity: VisualDensity.compact,
                                    backgroundColor: WidgetStateProperty.resolveWith((states) =>
                                        states.contains(WidgetState.selected) ? AppColors.brandBlue.withValues(alpha: 0.12) : null),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    // Filter chips (Crex-style)
                    if (_data!.filters.isNotEmpty)
                      Container(
                        color: isDark
                            ? AppColors.darkSurface
                            : Colors.grey.shade50,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _data!.filters.expand((g) {
                              return [
                                Padding(
                                  padding:
                                      const EdgeInsets.only(right: 6, left: 4),
                                  child: Text(g.label,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey)),
                                ),
                                ...g.options.map((o) {
                                  final selected =
                                      _selectedFilters[g.group] == o.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text(o.label),
                                      selected: selected,
                                      onSelected: (_) {
                                        setState(() =>
                                            _selectedFilters[g.group] =
                                                o.value);
                                        _load(keepFilters: true);
                                      },
                                      selectedColor: AppColors.brandBlue,
                                      labelStyle: TextStyle(
                                        color: selected
                                            ? Colors.white
                                            : null,
                                        fontSize: 12,
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  );
                                }),
                              ];
                            }).toList(),
                          ),
                        ),
                      ),
                    // Source badge
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.brandBlue.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _data!.source.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: AppColors.brandBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _data!.subtitle,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Stale-data banner: shown when the fresh fetch failed and
                    // we are displaying the last successfully fetched data.
                    if (_stale)
                      Container(
                        margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.upcomingAmber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.upcomingAmber.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.history,
                                size: 14, color: AppColors.upcomingAmber),
                            const SizedBox(width: 6),
                            const Expanded(
                              child: Text(
                                'Showing last fetched data (live update unavailable)',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.upcomingAmber),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Table header
                    _TableHeader(columns: _data!.columns, isDark: isDark),
                    const Divider(height: 1),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => _load(keepFilters: true),
                        child: ListView.separated(
                          padding: const EdgeInsets.only(bottom: 16),
                          itemCount: _data!.players.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final p = _data!.players[i];
                             return InkWell(
                               onTap: () {
                                 if (widget.sportKey == 'cricket' && _rankType == 'teams') {
                                   Navigator.of(context).push(
                                     MaterialPageRoute(
                                       builder: (_) => TeamMatchesScreen(
                                         sportKey: widget.sportKey,
                                         teamName: p.name,
                                         teamLogo: p.extra['image']?.toString(),
                                       ),
                                     ),
                                   );
                                 } else {
                                   Navigator.of(context).push(
                                     MaterialPageRoute(
                                       builder: (_) => PlayerDetailScreen(
                                         sportKey: widget.sportKey,
                                         name: p.name,
                                         country: p.country,
                                         extra: p.extra,
                                       ),
                                     ),
                                   );
                                 }
                               },
                              child: _PlayerRow(
                                player: p,
                                columns: _data!.columns,
                                isDark: isDark,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final List<RankingColumn> columns;
  final bool isDark;
  const _TableHeader({required this.columns, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      color: isDark ? AppColors.darkSurface : Colors.grey.shade100,
      child: Row(
        children: columns.map((c) {
          return Expanded(
            flex: c.key == 'name' ? 3 : 1,
            child: Text(
              c.label,
              textAlign:
                  c.align == 'center' ? TextAlign.center : TextAlign.left,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white70 : Colors.black54,
                letterSpacing: 0.3,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  final PlayerRanking player;
  final List<RankingColumn> columns;
  final bool isDark;
  const _PlayerRow({
    required this.player,
    required this.columns,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: isDark ? AppColors.darkCard : Colors.white,
      child: Row(
        children: columns.map((c) {
          final value = c.key == 'name'
              ? player.name
              : c.key == 'country'
                  ? (player.country ?? '')
                  : player.extra[c.key]?.toString() ?? '';
          if (c.key == 'name') {
            final img = player.extra['image']?.toString() ?? '';
            return Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: player.rank <= 3
                          ? AppColors.brandBlue
                          : Colors.grey.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${player.rank}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: player.rank <= 3
                            ? Colors.white
                          : (isDark ? Colors.white : Colors.black87),  // ignore: deprecated_member_use
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (img.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          img,
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          value,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (player.country != null)
                          Text(
                            player.country!,
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        if (player.extra['category'] != null &&
                            player.extra['category'].toString().isNotEmpty)
                          Text(
                            player.extra['category'].toString(),
                            style: const TextStyle(
                                fontSize: 10,
                                color: AppColors.brandBlue,
                                fontWeight: FontWeight.w700),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return Expanded(
            flex: 1,
            child: Text(
              value,
              textAlign:
                  c.align == 'center' ? TextAlign.center : TextAlign.left,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NoDataView extends StatelessWidget {
  final String sportName;
  final String emoji;
  const _NoDataView({required this.sportName, required this.emoji});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(
              'No real rankings available for $sportName yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'We only show real rankings sourced from official APIs. '
              'Volleyball, kabaddi, esports, table tennis, rugby, golf and '
              'MMA have no reliable ranking source yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
