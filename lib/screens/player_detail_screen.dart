// Player detail screen — real player data via the BACKEND proxy:
//   cricket: /api/players/resolve/:name + /api/players/:id/profile (cricbuzz)
//   NBA/MLB/NHL: /api/players/espn/:league/:athleteId (ESPN core API)

import 'package:flutter/material.dart';
import '../theme.dart';
import '../data.dart';
import '../services/player_detail_service.dart';
import '../services/news_service.dart';

class PlayerDetailScreen extends StatefulWidget {
  final String sportKey;
  final String name;
  final String? country;
  final Map<String, dynamic>? extra; // ranking extra map (may hold pid/team/role)

  const PlayerDetailScreen({
    super.key,
    required this.sportKey,
    required this.name,
    this.country,
    this.extra,
  });

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  Map<String, dynamic>? _player;
  Map<String, dynamic>? _espnProfile;
  List<NewsItem> _news = [];
  bool _loading = true;
  bool _bioExpanded = false;

  // Keys we never want to show as a "stat" tile.
  static const Set<String> _skipKeys = {
    'image',
    'img',
    'photo',
    'logo',
    'flag',
    'pid',
    'playerId',
    'player_id',
    'teamId',
    'team_id',
    'id',
    'category',
    'name',
    'country',
    'rank',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.sportKey == 'cricket') {
      int? pid = int.tryParse(widget.extra?['pid']?.toString() ??
          widget.extra?['playerId']?.toString() ??
          widget.extra?['player_id']?.toString() ??
          '');
      // No pid was passed (e.g. tapped from a scorecard/squad row or a
      // rankings row). Resolve it by name so we can still show the full
      // Crex-style profile.
      if (pid == null && widget.name.isNotEmpty) {
        pid = await PlayerDetailService.resolveCricketPlayerId(widget.name);
      }
      if (pid != null) {
        // Full Crex-style profile from the backend cricbuzz proxy
        // (/api/players/:id/profile → info + batting + bowling + career).
        _player = await PlayerDetailService.fetchCricketProfile(pid);
      }
    } else if (widget.sportKey == 'basketball' ||
        widget.sportKey == 'baseball' ||
        widget.sportKey == 'hockey') {
      final league = widget.sportKey == 'basketball'
          ? 'nba'
          : widget.sportKey == 'baseball'
              ? 'mlb'
              : 'nhl';
      final athleteId =
          (widget.extra?['athleteId'] ?? widget.extra?['id'] ?? '').toString();
      if (athleteId.isNotEmpty) {
        _espnProfile =
            await PlayerDetailService.fetchEspnProfile(league, athleteId);
      }
    }
    // Real news about this player from the backend news feed.
    try {
      final sport = widget.sportKey == 'cricket' ? 'cricket' : widget.sportKey;
      final items = await NewsService.fetchNews(sport: sport);
      final tokens = widget.name
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 2)
          .toList();
      _news = items.where((n) {
        final hay = '${n.title} ${n.source}'.toLowerCase();
        return tokens.any((t) => hay.contains(t));
      }).take(6).toList();
    } catch (_) {
      _news = [];
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // The new /players/{pid}/stats endpoint returns the full response directly
    final p = _player;
    final basic = p?['basic'] as Map<String, dynamic>?;
    final espn = _espnProfile;
    final name = widget.name.isNotEmpty
        ? widget.name
        : (basic?['name']?.toString() ??
            espn?['name']?.toString() ??
            (p?['player'] is Map
                ? (p!['player'] as Map)['name']?.toString()
                : null) ??
            'Player');

    // Resolve display fields from whichever source has data.
    // Priority: ESPN headshot (real, per-athlete) → ranking-row image
    // (entitysport for cricket / ESPN CDN for NBA-MLB-NHL — both live) →
    // cricbuzz basic image (dead host, last resort).
    final imageUrl = (espn?['image']?.toString().isNotEmpty == true)
        ? espn!['image'].toString()
        : (widget.extra?['image']?.toString().isNotEmpty == true)
            ? widget.extra!['image'].toString()
            : (widget.extra?['img']?.toString().isNotEmpty == true)
                ? widget.extra!['img'].toString()
                : (basic?['image']?.toString().isNotEmpty == true)
                    ? basic!['image'].toString()
                    : (p?['profile_image']?.toString().isNotEmpty == true)
                        ? p!['profile_image'].toString()
                        : (p?['image']?.toString().isNotEmpty == true)
                            ? p!['image'].toString()
                            : '';
    final country = widget.country ??
        basic?['country']?.toString() ??
        espn?['country']?.toString() ??
        widget.extra?['country']?.toString() ??
        (p?['nationality']?.toString());
    final role = basic?['role']?.toString() ??
        espn?['position']?.toString() ??
        widget.extra?['category']?.toString() ??
        widget.extra?['role']?.toString();

    // Stat fields for non-cricket sports (everything in extra minus skips).
    final statEntries = <MapEntry<String, String>>[];
    widget.extra?.forEach((k, v) {
      if (_skipKeys.contains(k)) return;
      if (v == null) return;
      final s = v.toString();
      if (s.isEmpty) return;
      final pretty = k
          .replaceAll('_', ' ')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim()
          .split(' ')
          .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
          .join(' ');
      statEntries.add(MapEntry(pretty, s));
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile link copied')),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark ? AppColors.darkCard : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: AppColors.brandBlue,
                        backgroundImage: imageUrl.isNotEmpty
                            ? NetworkImage(imageUrl)
                            : null,
                        child: imageUrl.isEmpty
                            ? Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 28, color: Colors.white),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (country != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  country,
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.grey),
                                ),
                              ),
                            if (role != null && role.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandBlue
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    role.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.brandBlue,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Cricket: full Crex-style profile from backend cricbuzz ──
                if (widget.sportKey == 'cricket') ...[
                  if (_player != null) ...[
                    _InfoTile('Batting Style',
                        (basic?['battingStyle'] ?? '—').toString()),
                    _InfoTile('Bowling Style',
                        (basic?['bowlingStyle'] ?? '—').toString()),
                    if (basic?['team'] != null &&
                        basic!['team'].toString().isNotEmpty)
                      _InfoTile('Team', basic['team'].toString()),
                    if (basic?['jersey'] != null &&
                        basic!['jersey'].toString().isNotEmpty)
                      _InfoTile('Jersey', basic['jersey'].toString()),
                    _InfoTile('Born', (basic?['born'] ?? '—').toString()),
                    if (p?['profile'] is Map &&
                        _profileBio(p!['profile'] as Map).isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text('ABOUT',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.brandBlue)),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _stripHtml(_profileBio(p['profile'] as Map)),
                          maxLines: _bioExpanded ? null : 4,
                          overflow: _bioExpanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black54,
                            height: 1.5,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () =>
                              setState(() => _bioExpanded = !_bioExpanded),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                          ),
                          icon: Icon(
                            _bioExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 15,
                            color: AppColors.brandBlue,
                          ),
                          label: Text(
                            _bioExpanded ? 'Show Less' : 'View All',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brandBlue,
                            ),
                          ),
                        ),
                      ),
                    ],
                    // Recent matches (real cricbuzz data, merged bat+bowl)
                    if (p?['recent'] is List &&
                        (p?['recent'] as List).isNotEmpty)
                      _buildRecentMatches(
                          p?['recent'] as List, isDark),
                    // Career stats from the backend proxy (batting + bowling)
                    if (p?['batting'] is Map)
                      _buildCricbuzzTable('Batting Career',
                          p!['batting'] as Map, isDark),
                    if (p?['bowling'] is Map)
                      _buildCricbuzzTable('Bowling Career',
                          p!['bowling'] as Map, isDark),
                  ] else ...[
                    // No linked profile yet — show the real ICC ranking data
                    // we already have (rating / points / format / rank).
                    _buildRankingSnapshot(isDark),
                  ],
                ] else if (espn != null) ...[
                  // ── NBA / MLB / NHL: real ESPN bio + season stats ──
                  _buildEspnSection(espn, statEntries, isDark),
                ] else ...[
                  // ── Generic Crex-style stat grid for all other sports ──
                  if (statEntries.isNotEmpty) ...[
                    const Text(
                      'STATS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStatGrid(statEntries, isDark),
                  ] else
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'No additional stats available for this player.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  // ── Latest news about this player (real backend news) ──
                  if (_news.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    const Text(
                      'LATEST NEWS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._news.map((n) => _NewsCard(item: n, isDark: isDark)),
                  ],
                ],
              ],
            ),
    );
  }

  Widget _buildFormatStats(String title, Map stats, bool isDark) {
    // Legacy shape: {test:{...}, odi:{...}, t20i:{...}, t20:{...}, lista:{...}}
    // (handled here) — cricbuzz {headers, values} shape is handled by
    // _buildCricbuzzTable below.
    final order = ['test', 'odi', 't20i', 't20', 'lista'];
    final formats = order
        .where((f) => stats[f] is Map && (stats[f] as Map).isNotEmpty)
        .toList();
    if (formats.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppColors.brandBlue,
          ),
        ),
        const SizedBox(height: 8),
        ...formats.map((f) {
          final m = Map<String, dynamic>.from(stats[f] as Map);
          final rows = <String, String>{};
          m.forEach((k, v) {
            if (v == null) return;
            final s = v.toString();
            if (s.isEmpty) return;
            rows[k] = s;
          });
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDark ? AppColors.darkCard : Colors.white,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.toUpperCase(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: rows.entries.take(10).map((e) {
                    final label = e.key
                        .replaceAll('_', ' ')
                        .replaceAll(RegExp(r'\s+'), ' ')
                        .trim()
                        .split(' ')
                        .map((w) =>
                            w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
                        .join(' ');
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: const TextStyle(
                                fontSize: 10, color: Colors.grey)),
                        Text(e.value,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                      ],
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // Recent matches — real cricbuzz data: {id, batting, bowling, opponent,
  // format, date} — rendered Crex-style (date chip + format + scores).
  Widget _buildRecentMatches(List recent, bool isDark) {
    final cellBg = isDark ? AppColors.darkCard : Colors.white;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('RECENT MATCHES',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.brandBlue)),
        const SizedBox(height: 8),
        for (var i = 0; i < recent.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          _recentMatchCard(recent[i], cellBg, isDark),
        ],
      ],
    );
  }

  Widget _recentMatchCard(dynamic m, Color cellBg, bool isDark) {
    final batting = m is Map ? (m['batting']?.toString() ?? '') : '';
    final bowling = m is Map ? (m['bowling']?.toString() ?? '') : '';
    final opponent = m is Map ? (m['opponent']?.toString() ?? '') : '';
    final format = m is Map ? (m['format']?.toString() ?? '') : '';
    final date = m is Map ? (m['date']?.toString() ?? '') : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: cellBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(format.isNotEmpty ? format : '—',
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandBlue)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  batting.isNotEmpty ? batting : '—',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (bowling.isNotEmpty)
                  Text(
                    'Bowling: $bowling',
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('vs $opponent',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black54)),
              const SizedBox(height: 2),
              Text(date,
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

// Cricbuzz career table: {headers:['ROWHEADER','Test','ODI',...],
  // values:[{values:['Matches','123','314',...]}, ...]} — falls back to the
  // legacy per-format map renderer when the shape doesn't match.
  Widget _buildCricbuzzTable(String title, Map stats, bool isDark) {
    final headers = stats['headers'];
    final values = stats['values'];
    if (headers is! List || values is! List || values.isEmpty) {
      return _buildFormatStats(title, stats, isDark);
    }
    final cols = headers.map((h) => h?.toString() ?? '').toList();
    final data = <List<String>>[];
    for (final row in values) {
      final v = row is Map ? row['values'] : null;
      if (v is List && v.isNotEmpty) {
        data.add(v.map((x) => x?.toString() ?? '').toList());
      }
    }
    if (data.isEmpty) return const SizedBox.shrink();
    final labelCol = cols.isNotEmpty ? cols[0] : '';
    final fmtCols = cols.length > 1 ? cols.sublist(1) : <String>[];
    final cellBg = isDark ? AppColors.darkCard : Colors.white;
    final labelStyle = TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white54 : Colors.grey.shade600);
    final valStyle = TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : Colors.black87);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.brandBlue)),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
              color: cellBg,
            ),
            child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStatePropertyAll(
                  AppColors.brandBlue.withValues(alpha: 0.08)),
              columnSpacing: 16,
              horizontalMargin: 12,
              dataRowMinHeight: 32,
              columns: [
                DataColumn(label: Text(labelCol, style: labelStyle)),
                ...fmtCols.map((c) => DataColumn(
                    label: Text(c, style: labelStyle),
                    numeric: true)),
              ],
              rows: data.map((r) {
                return DataRow(cells: [
                  for (var i = 0; i < cols.length; i++)
                    DataCell(Text(
                      i < r.length ? r[i] : '',
                      style: i == 0 ? labelStyle : valStyle,
                      textAlign: i == 0 ? TextAlign.left : TextAlign.right,
                    )),
                ]);
              }).toList(),
            ),
          ),
        ),
        ),
      ],
    );
  }

  String _profileBio(Map profile) {
    for (final k in ['bio', 'description', 'about', 'longBio', 'introduction']) {
      final v = profile[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString();
    }
    return '';
  }

  Widget _buildStatGrid(List<MapEntry<String, String>> entries, bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 2.6,
      children: entries
          .map((e) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isDark ? AppColors.darkCard : Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      e.key,
                      style:
                          const TextStyle(fontSize: 10, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      e.value,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w800),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }

  // NBA / MLB / NHL — real ESPN athlete bio + season stats from rankings.
  Widget _buildEspnSection(Map espn, List<MapEntry<String, String>> statEntries,
      bool isDark) {
    final league = (espn['league'] ?? '').toString().toUpperCase();
    final team = widget.extra?['team']?.toString() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$league PLAYER',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.brandBlue)),
        const SizedBox(height: 8),
        _InfoTile('Position', (espn['position'] ?? '—').toString()),
        _InfoTile('Team', team.isNotEmpty ? team : '—'),
        _InfoTile('Height', (espn['height'] ?? '—').toString()),
        _InfoTile('Weight', (espn['weight'] ?? '—').toString()),
        if (espn['age'] != null) _InfoTile('Age', espn['age'].toString()),
        if (espn['jersey'] != null && espn['jersey'].toString().isNotEmpty)
          _InfoTile('Jersey', espn['jersey'].toString()),
        if (espn['experience'] != null &&
            espn['experience'].toString().isNotEmpty)
          _InfoTile('Experience', espn['experience'].toString()),
        if (espn['debutYear'] != null &&
            espn['debutYear'].toString().isNotEmpty)
          _InfoTile('Debut Year', espn['debutYear'].toString()),
        if (espn['draft'] != null && espn['draft'].toString().isNotEmpty)
          _InfoTile('Draft', espn['draft'].toString()),
        if (espn['birthPlace'] != null &&
            espn['birthPlace'].toString().isNotEmpty)
          _InfoTile('Birth Place', espn['birthPlace'].toString()),
        if (statEntries.isNotEmpty) ...[
          const SizedBox(height: 14),
          const Text('SEASON STATS',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brandBlue)),
          const SizedBox(height: 8),
          _buildStatGrid(statEntries, isDark),
        ],
      ],
    );
  }

  String _stripHtml(String s) {
    return s
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&rsquo;', "'")
        .replaceAll('&ndash;', '-')
        .replaceAll('&mdash;', '-')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('\\/', '/')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // Real ICC ranking snapshot shown when no linked full-career profile
  // (pid) is available. Uses the genuine ranking data we already have.
  Widget _buildRankingSnapshot(bool isDark) {
    final extra = widget.extra ?? <String, dynamic>{};
    final stats = <MapEntry<String, String>>[];
    String? val(String k) {
      final v = extra[k];
      if (v == null) return null;
      final s = v.toString().trim();
      if (s.isEmpty || s == '0') return null;
      return s;
    }

    final rank = extra['rank']?.toString();
    if (rank != null && rank.isNotEmpty && rank != '0') {
      stats.add(MapEntry('ICC Rank', '#$rank'));
    }
    final rating = val('rating');
    if (rating != null) stats.add(MapEntry('Rating', rating));
    final points = val('points');
    if (points != null) stats.add(MapEntry('Points', points));
    final matches = val('matches');
    if (matches != null) stats.add(MapEntry('Matches', matches));
    final runs = val('runs');
    if (runs != null) stats.add(MapEntry('Runs', runs));
    final wkts = val('wkts');
    if (wkts != null) stats.add(MapEntry('Wickets', wkts));
    final avg = val('avg');
    if (avg != null) stats.add(MapEntry('Average', avg));
    final econ = val('econ');
    if (econ != null) stats.add(MapEntry('Economy', econ));
    final format = extra['format']?.toString();
    if (format != null && format.isNotEmpty) {
      stats.add(MapEntry('Format', format));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('ICC RANKING',
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.brandBlue)),
        const SizedBox(height: 8),
        if (stats.isEmpty)
          const Text('No ranking stats available for this player.',
              style: TextStyle(color: Colors.grey))
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.6,
            children: stats
                .map((e) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isDark ? AppColors.darkCard : Colors.white,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(e.key,
                              style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          const SizedBox(height: 2),
                          Text(e.value,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ))
                .toList(),
          ),
        const SizedBox(height: 8),
        Text(
          'Full career stats, recent matches and bio load automatically when a '
          'player profile is linked. Tap a player from a live match scorecard '
          'to open the complete Crex-style breakdown.',
          style: TextStyle(
              fontSize: 11, color: isDark ? Colors.white54 : Colors.black45),
        ),
      ],
    );
  }

  Widget _NewsCard({required NewsItem item, required bool isDark}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          if (item.image != null && item.image!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(item.image!,
                  width: 64, height: 64, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _newsThumb(item)),
            )
          else
            _newsThumb(item),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                        color: isDark ? Colors.white60 : Colors.black45)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _newsThumb(NewsItem item) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.brandBlue.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(item.sportEmoji, style: const TextStyle(fontSize: 26)),
      ),
    );
  }


  Widget _InfoTile(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? AppColors.darkCard : Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

