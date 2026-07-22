// Player rankings screen — shows real player rankings for a sport, fetched
// from the backend /api/rankings/:sport/:category endpoint. Crex-style table
// with filter chips and a responsive column layout.

import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../services/player_ranking_service.dart';
import '../services/rapid_api_service.dart';
import 'player_detail_screen.dart';

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
  final Map<String, String> _selectedFilters = {};

  @override
  void initState() {
    super.initState();
    _load();
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
      'rugby': '🏉',
      'golf': '⛳',
      'mma': '🥊',
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

    // Cricket: fetch REAL player data directly from the RapidAPI cricket
    // endpoint (cricket-live-line-advance /players) instead of the backend.
    if (widget.sportKey == 'cricket') {
      try {
        final players = await RapidApiService.fetchCricketPlayers();
        if (!mounted) return;
        if (players.isEmpty) {
          setState(() {
            _loading = false;
            _error = 'No cricket players returned';
          });
          return;
        }
        final rankingPlayers = players.asMap().entries.map((e) {
          final p = e.value;
          final rating =
              double.tryParse('${p['fantasy_player_rating'] ?? 0}') ?? 0;
          return PlayerRanking(
            rank: e.key + 1,
            name: (p['title'] ?? p['short_name'] ?? 'Unknown').toString(),
            country: _countryName(p['country']?.toString()),
            extra: {
              'team': (p['primary_team'] is List &&
                      (p['primary_team'] as List).isNotEmpty)
                  ? (p['primary_team'][0]['title'] ?? '').toString()
                  : '',
              'role': (p['playing_role'] ?? '').toString(),
              'rating': rating.toStringAsFixed(1),
              'pid': p['pid']?.toString() ?? '',
            },
          );
        }).toList();

        final resp = PlayerRankingResponse(
          sport: 'cricket',
          label: 'Cricket',
          title: '$_sportEmoji  Cricket Players',
          subtitle: 'Live from cricket-live-line-advance API',
          category: 'all',
          defaultCategory: 'all',
          filters: const [],
          columns: const [
            RankingColumn(key: 'name', label: 'Player'),
            RankingColumn(key: 'role', label: 'Role', align: 'center'),
            RankingColumn(key: 'rating', label: 'Rating', align: 'center'),
          ],
          source: 'RapidAPI · Cricket',
          players: rankingPlayers,
          lastSync: null,
        );
        setState(() {
          _loading = false;
          _data = resp;
        });
        return;
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _error = 'Cricket API error: $e';
        });
        return;
      }
    }

    // Other sports: use the backend aggregation (real + fallback).
    final resp = await PlayerRankingService.fetchRankings(
      sport: widget.sportKey,
      category: keepFilters ? _currentCategory : widget.initialCategory,
    );
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (resp == null) {
        _error = 'Could not load rankings';
      } else {
        _data = resp;
        if (!keepFilters) {
          _selectedFilters.clear();
          for (final g in resp.filters) {
            // pick first option as default
            if (g.options.isNotEmpty) {
              _selectedFilters[g.group] = g.options.first.value;
            }
          }
        }
      }
    });
  }

  String? _countryName(String? code) {
    if (code == null || code.isEmpty) return null;
    const map = {
      'lk': 'Sri Lanka',
      'ae': 'UAE',
      'in': 'India',
      'au': 'Australia',
      'en': 'England',
      'za': 'South Africa',
      'pk': 'Pakistan',
      'bd': 'Bangladesh',
      'nz': 'New Zealand',
      'us': 'USA',
      'ca': 'Canada',
    };
    return map[code.toLowerCase()] ?? code.toUpperCase();
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
              : Column(
                  children: [
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
                          : Colors.grey.withOpacity(0.2),
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
