import 'package:flutter/material.dart';
import '../theme.dart';
import '../data.dart';
import '../services/cricket_hub_service.dart';
import 'match_detail_screen.dart';
import 'player_detail_screen.dart';
import 'team_matches_screen.dart';

class CricketHubScreen extends StatefulWidget {
  final bool isDark;
  const CricketHubScreen({super.key, required this.isDark});

  @override
  State<CricketHubScreen> createState() => _CricketHubScreenState();
}

class _CricketHubScreenState extends State<CricketHubScreen> {
  String _activeSection = 'matches';
  final Map<String, dynamic> _data = {};
  final Map<String, bool> _loading = {};
  final Map<String, String> _errors = {};
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  static const _sections = [
    {'key': 'matches', 'label': 'Matches', 'icon': Icons.sports_cricket},
    {'key': 'players', 'label': 'Players', 'icon': Icons.people},
    {'key': 'teams', 'label': 'Teams', 'icon': Icons.groups},
    {'key': 'tournaments', 'label': 'Tournaments', 'icon': Icons.emoji_events},
    {'key': 'competitions', 'label': 'Competitions', 'icon': Icons.table_chart},
    {'key': 'iccRanks', 'label': 'ICC Ranks', 'icon': Icons.bar_chart},
    {'key': 'seasons', 'label': 'Seasons', 'icon': Icons.calendar_month},
  ];

  @override
  void initState() {
    super.initState();
    _loadSection('matches');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSection(String key) async {
    if (_data.containsKey(key) && _data[key] != null) return;
    setState(() {
      _loading[key] = true;
      _errors.remove(key);
    });
    try {
      final fetcher = _fetcher(key);
      final result = await fetcher;
      if (mounted) {
        setState(() {
          _data[key] = result;
          _loading[key] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errors[key] = e.toString();
          _loading[key] = false;
        });
      }
    }
  }

  Future<dynamic> _fetcher(String key) async {
    switch (key) {
      case 'matches': return CricketHubService.matches();
      case 'players': return CricketHubService.players();
      case 'teams': return CricketHubService.teams();
      case 'tournaments': return CricketHubService.tournaments();
      case 'competitions': return CricketHubService.competitions();
      case 'iccRanks': return CricketHubService.iccRanks();
      case 'seasons': return CricketHubService.seasons();
      default: return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏏 Cricket Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _data.clear();
                _errors.clear();
              });
              _loadSection(_activeSection);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSectionChips(isDark),
          if (_activeSection != 'iccRanks' && _activeSection != 'seasons')
            _buildSearchBar(isDark),
          Expanded(child: _buildContent(isDark)),
        ],
      ),
    );
  }

  Widget _buildSectionChips(bool isDark) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _sections.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final s = _sections[i];
          final active = s['key'] == _activeSection;
          return GestureDetector(
            onTap: () {
              setState(() => _activeSection = s['key'] as String);
              _loadSection(s['key'] as String);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppColors.brandBlue : (isDark ? AppColors.darkCard : Colors.white),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: active ? AppColors.brandBlue : Colors.grey.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  Icon(s['icon'] as IconData, size: 18, color: active ? Colors.white : null),
                  const SizedBox(width: 6),
                  Text(
                    s['label'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: active ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search $_activeSection...',
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? AppColors.darkCard : Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    final key = _activeSection;
    if (_loading[key] == true) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errors.containsKey(key)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade500),
              const SizedBox(height: 12),
              Text('Failed to load', style: TextStyle(color: Colors.grey.shade500)),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _data.remove(key);
                    _errors.remove(key);
                  });
                  _loadSection(key);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final items = _data[key];
    if (items == null) return const SizedBox.shrink();

    List list = items is List ? items : [];
    if (_searchQuery.isNotEmpty) {
      list = list.where((e) {
        final str = e.toString().toLowerCase();
        return str.contains(_searchQuery);
      }).toList();
    }

    if (list.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isNotEmpty ? 'No matches found' : 'No data available',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: list.length,
      itemBuilder: (ctx, i) => _buildItemCard(list[i], isDark),
    );
  }

  Widget _buildItemCard(dynamic item, bool isDark) {
    final title = _itemTitle(item);
    final subtitle = _itemSubtitle(item);
    final imageUrl = _itemImage(item);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      color: isDark ? AppColors.darkCard : Colors.white,
      child: ListTile(
        leading: imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(imageUrl, width: 40, height: 40,
                    errorBuilder: (_, __, ___) => _iconForSection()),
              )
            : _iconForSection(),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: () => _onItemTap(item),
      ),
    );
  }

  Widget _iconForSection() {
    final s = _sections.firstWhere((e) => e['key'] == _activeSection,
        orElse: () => _sections[0]);
    return Icon(s['icon'] as IconData, size: 28, color: AppColors.brandBlue);
  }

  String _itemTitle(dynamic item) {
    if (item is Map) {
      return item['title']?.toString() ??
          item['name']?.toString() ??
          item['fullname']?.toString() ??
          item['short_title']?.toString() ??
          item['team']?.toString() ??
          item['season_year']?.toString() ??
          item['year']?.toString() ??
          'Item';
    }
    return item.toString();
  }

  String? _itemSubtitle(dynamic item) {
    if (item is! Map) return null;
    final parts = <String>[];
    if (item['country'] != null) parts.add(item['country'].toString());
    if (item['type'] != null) parts.add(item['type'].toString());
    if (item['format'] != null) parts.add(item['format'].toString());
    if (item['format_str'] != null) parts.add(item['format_str'].toString());
    if (item['status'] != null) parts.add(_statusStr(item['status'].toString()));
    if (item['venue'] != null) parts.add(item['venue'].toString());
    if (item['rating'] != null) parts.add('Rating: ${item['rating']}');
    if (item['points'] != null) parts.add('Pts: ${item['points']}');
    if (item['date_start'] != null) parts.add(_dateStr(item['date_start'].toString()));
    return parts.isEmpty ? null : parts.join(' · ');
  }

  String? _itemImage(dynamic item) {
    if (item is! Map) return null;
    return item['image']?.toString() ??
        item['img']?.toString() ??
        item['logo']?.toString() ??
        item['logo_url']?.toString() ??
        item['thumb_url']?.toString();
  }

  void _onItemTap(dynamic item) {
    if (item is! Map) return;
    final section = _activeSection;

    if (section == 'matches') {
      _openMatchDetail(item);
    } else if (section == 'players') {
      _openPlayerDetail(item);
    } else if (section == 'teams') {
      _openTeamDetail(item);
    } else {
      _showDetailSheet(item);
    }
  }

  void _openMatchDetail(Map item) {
    final match = MatchItem(
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
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => MatchDetailScreen(match: match),
    ));
  }

  void _openPlayerDetail(Map item) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PlayerDetailScreen(
        sportKey: 'cricket',
        name: item['title']?.toString() ??
            item['name']?.toString() ??
            item['fullname']?.toString() ??
            'Player',
        country: item['country']?.toString(),
        extra: Map<String, dynamic>.from(item),
      ),
    ));
  }

  void _openTeamDetail(Map item) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => TeamMatchesScreen(
        teamName: item['name']?.toString() ?? item['title']?.toString() ?? 'Team',
        teamLogo: _itemImage(item),
        sportKey: 'cricket',
      ),
    ));
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
                        child: Text(
                          '${e.value}',
                          style: const TextStyle(fontSize: 13),
                        ),
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

  String _statusStr(String s) {
    switch (s.toUpperCase()) {
      case 'LIVE': return '🔴 LIVE';
      case 'COMPLETED': return '✅ Done';
      case 'UPCOMING': return '⏳ Upcoming';
      default: return s;
    }
  }

  String _dateStr(String d) {
    try {
      final dt = DateTime.parse(d);
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return d.length > 10 ? d.substring(0, 10) : d;
    }
  }
}
