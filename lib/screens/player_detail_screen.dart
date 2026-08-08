// Player detail screen — shows real player info fetched from the RapidAPI
// cricket endpoint (cricket-live-line-advance). For other sports we show the
// basic info we have from the rankings payload.

import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/rapid_api_service.dart';

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
  bool _loading = true;

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
      final pid = int.tryParse(widget.extra?['pid']?.toString() ??
          widget.extra?['playerId']?.toString() ?? '');
      if (pid != null) {
        // Rich Crex-style profile from cricket-live-line-advance
        // /players/{pid}/stats (real API, no backend). Falls back to
        // cricket-live-line1 /player/{pid} if the advance endpoint fails.
        try {
          _player = await RapidApiService.fetchCricketPlayerStats(pid);
        } catch (_) {
          _player = null;
        }
        if (_player == null) {
          try {
            _player = await RapidApiService.fetchCricketPlayerDetail(pid);
          } catch (_) {
            _player = null;
          }
        }
      }
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // The new /players/{pid}/stats endpoint returns the full response directly
    final p = _player as Map<String, dynamic>?;
    // The API returns {player:{...}, batting:{...}, bowling:{...}, bio, ...}
    final playerData = p?['player'] as Map<String, dynamic>?;
    final name = widget.name.isNotEmpty
        ? widget.name
        : (playerData?['name']?.toString() ?? playerData?['title']?.toString() ?? 'Player');

    // Resolve display fields from whichever source has data.
    final imageUrl = (p?['profile_image']?.toString().isNotEmpty == true
            ? p!['profile_image'].toString()
            : (p?['image']?.toString().isNotEmpty == true
                ? p!['image'].toString()
                : (widget.extra?['image']?.toString() ??
                    widget.extra?['img']?.toString() ??
                    '')))
        .toString();
    final country = widget.country ??
        (p?['nationality']?.toString()) ??
        (p?['country'] != null ? p!['country'].toString().toUpperCase() : null) ??
        (widget.extra?['country']?.toString()) ??
        (p?['birth_place'] != null ? p!['birth_place'].toString() : null);
    final role = (p?['playing_role']?.toString()) ??
        (widget.extra?['category']?.toString()) ??
        (widget.extra?['role']?.toString());

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

                // ── Cricket-specific info + career ──
                if (widget.sportKey == 'cricket') ...[
                  _InfoTile('Batting Style',
                      p?['batting_style']?.toString() ?? '—'),
                  _InfoTile('Bowling Style',
                      p?['bowling_style']?.toString() ?? '—'),
                  _InfoTile('Born', p?['birthdate']?.toString() ?? '—'),
                  _InfoTile('Birth Place',
                      p?['birthplace']?.toString() ?? '—'),
                  if (p?['bio'] != null && p!['bio'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _stripHtml(p['bio'].toString()),
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white70 : Colors.black54,
                          height: 1.5,
                        ),
                      ),
                    ),
                  // Career stats from /players/{pid}/stats (batting + bowling)
                  if (_player?['batting'] is Map)
                    _buildFormatStats('Batting Career',
                        _player!['batting'] as Map, isDark),
                  if (_player?['bowling'] is Map)
                    _buildFormatStats('Bowling Career',
                        _player!['bowling'] as Map, isDark),
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
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 2.6,
                      children: statEntries
                          .map((e) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color:
                                      isDark ? AppColors.darkCard : Colors.white,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      e.key,
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.grey),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      e.value,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                    ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'No additional stats available for this player.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                ],
              ],
            ),
    );
  }

  Widget _buildFormatStats(String title, Map stats, bool isDark) {
    // stats: {test:{...}, odi:{...}, t20i:{...}, t20:{...}, lista:{...}}
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

