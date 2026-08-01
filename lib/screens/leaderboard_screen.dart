import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme.dart';
import '../config.dart';
import '../data.dart';
import 'user_profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  final Locale locale;
  final bool isDark;

  const LeaderboardScreen({super.key, required this.locale, required this.isDark});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _mode = 'fans';
  String _sport = 'cricket';
  String _format = 'all';
  String _period = 'all';
  bool _showAll = false;

  // Cricket ICC rankings (from backend â€” real ICC data)
  String _rankType = 'teams'; // 'players' | 'teams'
  String _cricketFormat = '2'; // 1=test, 2=odi, 3=t20
  String _cricketRole = '1'; // 1=batsmen, 2=bowlers, 3=all-rounders
  String _cricketGender = 'men'; // 'men' | 'women'
  List<Map<String, dynamic>> _cricketRanks = [];
  bool _loadingCricket = false;

  List<Map<String, dynamic>> _teams = [];
  List<Map<String, dynamic>> _fans = [];
  bool _loadingTeams = false;
  bool _loadingFans = false;
  String? _error;

  static const _sportFormats = {
    'cricket': ['all', 't20', 'odi', 'test'],
    'football': ['all', 'fifa', 'premier-league', 'la-liga', 'serie-a', 'bundesliga', 'ligue-1'],
    'tennis': ['all', 'atp', 'wta'],
    'basketball': ['all', 'nba', 'euroleague'],
    'hockey': ['all', 'nhl'],
    'baseball': ['all', 'mlb'],
    'volleyball': ['all'],
    'kabaddi': ['all', 'pro-kabaddi'],
    'tabletennis': ['all'],
    'esports': ['all'],
  };

  @override
  void initState() {
    super.initState();
    _loadTeams();
    _loadFans();
  }

  List<String> get _formats => _sportFormats[_sport] ?? ['all'];

  // Maps leaderboard screen format keys to real team-ranking categories.
  static const _teamCategories = {
    'football': {'fifa': 'FIFA', 'premier-league': 'EPL', 'la-liga': 'La Liga'},
    'basketball': {'nba': 'NBA', 'euroleague': 'EuroLeague'},
    'hockey': {'nhl': 'NHL'},
    'baseball': {'mlb': 'MLB'},
    'tennis': {'atp': 'ATP', 'wta': 'WTA'},
  };

  Future<void> _loadTeams() async {
    if (_sport == 'cricket') {
      await _loadCricketRanks();
      return;
    }
    setState(() => _loadingTeams = true);
    try {
      if (_rankType == 'players') {
        // Player rankings via /api/rankings (returns `players`).
        final uri = Uri.parse('$apiBaseUrl/api/rankings/$_sport');
        final res = await http.get(uri).timeout(const Duration(seconds: 12));
        if (res.statusCode == 200) {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          _teams = (json['players'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _error = null;
        } else {
          _error = 'Server returned ${res.statusCode}';
        }
        if (mounted) setState(() => _loadingTeams = false);
        return;
      }
      // Real team rankings from /api/leaderboard (synced FIFA/ESPN/ICC data).
      final cat = _teamCategories[_sport]?[_format];
      if (cat != null) {
        final uri =
            Uri.parse('$apiBaseUrl/api/leaderboard/$_sport/Men/$cat');
        final res = await http.get(uri).timeout(const Duration(seconds: 12));
        if (res.statusCode == 200) {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          _teams = (json['rankings'] as List? ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _error = null;
          if (mounted) setState(() => _loadingTeams = false);
          return;
        }
      }
      // Fallback: player rankings via /api/rankings (returns `players`).
      final uri = Uri.parse('$apiBaseUrl/api/rankings/$_sport');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        _teams = (json['players'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _error = null;
      } else {
        _error = 'Server returned ${res.statusCode}';
      }
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loadingTeams = false);
  }

  // Real ICC rankings from the backend: every format (Test/ODI/T20I) Ã—
  // role (bat/bowl/all) Ã— gender (men/women) combination is available.
  static const _iccFormats = ['test', 'odi', 't20i'];
  static const _iccRoles = ['bat', 'bowl', 'all'];

  Future<void> _loadCricketRanks() async {
    setState(() => _loadingCricket = true);
    try {
      final fmtIdx = ((int.tryParse(_cricketFormat) ?? 2) - 1).clamp(0, 2);
      final fmt = _iccFormats[fmtIdx];
      final gender = _cricketGender;
      // ICC publishes no women's Test rankings.
      if (fmt == 'test' && gender == 'women') {
        _cricketRanks = [];
        _error = null;
        if (mounted) setState(() => _loadingCricket = false);
        return;
      }
      if (_rankType == 'players') {
        final role = _iccRoles[((int.tryParse(_cricketRole) ?? 1) - 1).clamp(0, 2)];
        final uri = Uri.parse(
            '$apiBaseUrl/api/rankings/cricket/${fmt}_${role}_$gender');
        final res = await http.get(uri).timeout(const Duration(seconds: 12));
        if (res.statusCode != 200) {
          _error = 'Server returned ${res.statusCode}';
          if (mounted) setState(() => _loadingCricket = false);
          return;
        }
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        _cricketRanks = (json['players'] as List? ?? [])
            .asMap()
            .entries
            .map((e) {
              final r = Map<String, dynamic>.from(e.value as Map);
              r['rank'] = e.key + 1;
              return r;
            })
            .toList();
      } else {
        final genderLabel = gender == 'women' ? 'Women' : 'Men';
        final fmtLabel = ['Test', 'ODI', 'T20I'][fmtIdx];
        final uri = Uri.parse(
            '$apiBaseUrl/api/leaderboard/cricket/$genderLabel/$fmtLabel');
        final res = await http.get(uri).timeout(const Duration(seconds: 12));
        if (res.statusCode != 200) {
          _error = 'Server returned ${res.statusCode}';
          if (mounted) setState(() => _loadingCricket = false);
          return;
        }
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        _cricketRanks = (json['rankings'] as List? ?? [])
            .asMap()
            .entries
            .map((e) {
              final r = Map<String, dynamic>.from(e.value as Map);
              r['rank'] = e.key + 1;
              return r;
            })
            .toList();
      }
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loadingCricket = false);
  }

  Future<void> _loadFans() async {
    setState(() => _loadingFans = true);
    try {
      final snap = await FirebaseFirestore.instance.collection('users').get();
      final list = snap.docs.map((e) {
        final d = e.data();
        final xp = int.tryParse('${d['xp'] ?? 0}') ?? 0;
        final coins = int.tryParse('${d['coins'] ?? 100}') ?? 100;
        final followers = (d['followers'] as List?)?.length ?? 0;
        return {
          'uid': e.id,
          'name': d['username'] ?? d['fullName'] ?? d['email'] ?? 'Fan',
          'xp': xp,
          'coins': coins,
          'level': (xp / 500).floor() + 1,
          'img': d['photoURL'] ?? '',
          'followers': followers,
        };
      }).toList();
      list.sort((a, b) {
        if (a['xp'] != b['xp']) return (b['xp'] as int).compareTo(a['xp'] as int);
        if (a['coins'] != b['coins']) return (b['coins'] as int).compareTo(a['coins'] as int);
        return (a['name'] as String).compareTo(b['name'] as String);
      });
      for (var i = 0; i < list.length; i++) list[i]['rank'] = i + 1;
      _fans = list;
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    if (mounted) setState(() => _loadingFans = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Leaderboard',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () { _loadTeams(); _loadFans(); },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                _ModeBtn(label: 'Teams', selected: _mode == 'teams', onTap: () => setState(() => _mode = 'teams')),
                const SizedBox(width: 8),
                _ModeBtn(label: 'Fans', selected: _mode == 'fans', onTap: () {
                  setState(() { _mode = 'fans'; _showAll = false; });
                }),
              ],
            ),
          ),
          if (_mode == 'teams')
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                  child: Row(
                    children: [
                      Expanded(child: _buildSportDropdown(isDark)),
                      const SizedBox(width: 8),
                      if (_sport != 'cricket' &&
                          _rankType == 'teams' &&
                          _formats.length > 1)
                        Expanded(child: _buildFormatDropdown(isDark)),
                    ],
                  ),
                ),
                // Players / Teams toggle — available for every sport.
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                  child: Row(
                    children: [
                      _CricketRankToggle(
                        rankType: _rankType,
                        onChanged: (v) {
                          setState(() => _rankType = v);
                          _loadTeams();
                        },
                      ),
                      const Spacer(),
                      if (_sport == 'cricket')
                        _CricketFormatChips(
                          format: _cricketFormat,
                          onChanged: (v) {
                            setState(() => _cricketFormat = v);
                            _loadCricketRanks();
                          },
                        ),
                    ],
                  ),
                ),
                if (_sport == 'cricket' && _rankType == 'players')
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
                    child: Row(
                      children: [
                        _CricketRoleChips(
                          role: _cricketRole,
                          onChanged: (v) {
                            setState(() => _cricketRole = v);
                            _loadCricketRanks();
                          },
                        ),
                        const Spacer(),
                        _CricketGenderChips(
                          gender: _cricketGender,
                          onChanged: (v) {
                            setState(() => _cricketGender = v);
                            _loadCricketRanks();
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          if (_mode == 'fans')
            _PeriodBar(period: _period, onChanged: (p) => setState(() => _period = p)),
          const Divider(height: 1),
          Expanded(
            child: _mode == 'teams' ? _buildTeamsView(isDark) : _buildFansView(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSportDropdown(bool isDark) {
    return DropdownButtonFormField<String>(
      value: _sport,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: isDark ? AppColors.darkCard : Colors.white,
      ),
      items: sports.where((s) => s.key != 'all').map((s) {
        return DropdownMenuItem(value: s.key, child: Text('${s.emoji} ${s.name}', style: const TextStyle(fontWeight: FontWeight.w600)));
      }).toList(),
      onChanged: (v) {
        if (v == null) return;
        setState(() { _sport = v; _format = 'all'; });
        _loadTeams();
      },
    );
  }

  Widget _buildFormatDropdown(bool isDark) {
    return DropdownButtonFormField<String>(
      value: _format,
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: isDark ? AppColors.darkCard : Colors.white,
      ),
      items: _formats.map((f) {
        final label = f == 'all' ? 'All Formats' : f.replaceAll('-', ' ').toUpperCase();
        return DropdownMenuItem(value: f, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)));
      }).toList(),
      onChanged: (v) {
        if (v == null) return;
        setState(() => _format = v);
        _loadTeams();
      },
    );
  }

  Widget _buildTeamsView(bool isDark) {
    if (_sport == 'cricket') {
      return _buildCricketRanksView(isDark);
    }
    if (_loadingTeams) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Could not load rankings', style: TextStyle(color: AppColors.liveRed, fontSize: 14)),
        ),
      );
    }
    if (_teams.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text('No rankings available for $_sport', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _teams.length,
      itemBuilder: (_, i) {
        final t = _teams[i];
        final rank = t['rank'] ?? t['position'] ?? i + 1;
        final name = t['name'] ?? t['team'] ?? t['country'] ?? 'Unknown';
        final rating = t['rating']?.toString() ?? t['points']?.toString() ?? t['score']?.toString() ?? '';
        final change = t['change'] ?? t['positionChange'] ?? 0;
        final isTop3 = rank is int && rank <= 3;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isTop3 ? AppColors.brandBlue.withValues(alpha: 0.08) : (isDark ? AppColors.darkCard : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isTop3 ? AppColors.brandBlue.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.15),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Text('#$rank',
                    style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16,
                      color: rank <= 3 ? AppColors.brandBlue : (isDark ? Colors.white60 : Colors.black45),
                    )),
              ),
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.emoji_events, color: AppColors.brandBlue, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    overflow: TextOverflow.ellipsis),
              ),
              if (rating.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(rating,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.brandBlue)),
                ),
              if (change is int && change != 0)
                Icon(
                  change > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16, color: change > 0 ? Colors.green : AppColors.liveRed,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFansView(bool isDark) {
    if (_loadingFans) return const Center(child: CircularProgressIndicator());
    if (_fans.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No fans yet', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    final displayFans = _showAll ? _fans : _fans.take(10).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _LeaderboardHeader(total: _fans.length, isDark: isDark),
        const SizedBox(height: 16),
        if (_fans.length >= 3)
          _WebsitePodium(fans: _fans.take(3).toList(), isDark: isDark, onTap: _openProfile),
        if (_fans.length > 3) ...[
          const SizedBox(height: 20),
          _RankingsTable(
            fans: displayFans.skip(3).toList(),
            isDark: isDark,
            onTap: _openProfile,
          ),
          if (!_showAll && _fans.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: AppColors.brandBlue.withValues(alpha: 0.4)),
                  ),
                  onPressed: () => setState(() => _showAll = true),
                  child: Text('See Full Rankings (${_fans.length})',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          if (_showAll && _fans.length > 10)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  onPressed: () => setState(() => _showAll = false),
                  child: const Text('Show Less', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
        ],
        const SizedBox(height: 16),
        _LeaderboardFooter(isDark: isDark),
      ],
    );
  }

  Widget _buildCricketRanksView(bool isDark) {
    if (_loadingCricket) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text('Could not load ICC rankings',
              style: TextStyle(color: AppColors.liveRed, fontSize: 14)),
        ),
      );
    }
    if (_cricketRanks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text('No ICC rankings available', style: TextStyle(color: Colors.grey, fontSize: 14)),
          ],
        ),
      );
    }

    final formats = ['Test', 'ODI', 'T20'];
    final formatIdx = int.tryParse(_cricketFormat)! - 1;
    final formatName = formatIdx >= 0 && formatIdx < 3 ? formats[formatIdx] : 'ODI';

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.brandBlue.withValues(alpha: 0.1), AppColors.brandBlue.withValues(alpha: 0.03)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.brandBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_rankType == 'players' ? Icons.people : Icons.groups,
                    color: AppColors.brandBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ICC ${_rankType == 'players' ? 'Player' : 'Team'} Rankings',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                    Text('$formatName format  â€¢  ICC',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black45)),
                  ],
                ),
              ),
              Icon(Icons.emoji_events, color: AppColors.brandBlue.withValues(alpha: 0.4), size: 28),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.brandBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const SizedBox(width: 28, child: Text('#', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.brandBlue))),
              const SizedBox(width: 8),
              Expanded(child: Text(_rankType == 'players' ? 'Player' : 'Team',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.brandBlue))),
              if (_rankType == 'players') ...[
                const SizedBox(width: 60, child: Text('Country', textAlign: TextAlign.right,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.brandBlue))),
              ],
              const SizedBox(width: 50, child: Text('Rating', textAlign: TextAlign.right,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: AppColors.brandBlue))),
            ],
          ),
        ),
        const SizedBox(height: 6),
        ..._cricketRanks.map((r) {
          final rank = r['rank'] ?? 0;
          final isTeams = _rankType == 'teams';
          final name = isTeams
              ? (r['team']?.toString() ?? r['name']?.toString() ?? 'Unknown')
              : (r['name']?.toString() ?? 'Unknown');
          final country = isTeams
              ? (r['code']?.toString() ?? r['country']?.toString() ?? '')
              : (r['country']?.toString() ?? r['nationality']?.toString() ?? '');
          final rating = r['rating']?.toString() ?? r['points']?.toString() ?? '-';
          final img = isTeams
              ? (r['logo']?.toString() ?? r['flag']?.toString() ?? '')
              : (r['image']?.toString() ?? r['thumb_url']?.toString() ?? '');
          final isTop3 = rank is int && rank <= 3;
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isTop3 ? AppColors.brandBlue.withValues(alpha: 0.06) : (isDark ? AppColors.darkCard : Colors.white),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isTop3 ? AppColors.brandBlue.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text('$rank',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14,
                          color: isTop3 ? AppColors.brandBlue : (isDark ? Colors.white60 : Colors.black45))),
                ),
                if (img.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(img, width: 28, height: 28, fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => _rankIcon(rank)),
                  )
                else
                  _rankIcon(rank),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ),
                if (_rankType == 'players' && country.isNotEmpty)
                  SizedBox(
                    width: 60,
                    child: Text(country,
                        textAlign: TextAlign.right,
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.black45),
                        overflow: TextOverflow.ellipsis),
                  ),
                SizedBox(
                  width: 50,
                  child: Text(rating,
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.brandBlue)),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 14, color: isDark ? Colors.white54 : Colors.black45),
              const SizedBox(width: 6),
              Text('ICC rankings â€” real-time from ICC',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _rankIcon(int rank) {
    if (rank == 1) return const Icon(Icons.emoji_events, size: 24, color: Color(0xFFFFD700));
    if (rank == 2) return const Icon(Icons.emoji_events, size: 22, color: Color(0xFFC0C0C0));
    if (rank == 3) return const Icon(Icons.emoji_events, size: 20, color: Color(0xFFCD7F32));
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        color: AppColors.brandBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.emoji_events, size: 14, color: AppColors.brandBlue),
    );
  }

  void _openProfile(Map<String, dynamic> u) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => UserProfileScreen(
        uid: u['uid'] as String,
        initialName: u['name'] as String?,
        initialImg: u['img'] as String?,
        initialXp: u['xp'] as int?,
        initialCoins: u['coins'] as int?,
        isDark: Theme.of(context).brightness == Brightness.dark,
      ),
    ));
  }
}

// â”€â”€ Cricket Rank Toggle â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CricketRankToggle extends StatelessWidget {
  final String rankType;
  final ValueChanged<String> onChanged;
  const _CricketRankToggle({required this.rankType, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        _tinyBtn('Players', rankType == 'players', isDark, () => onChanged('players')),
        const SizedBox(width: 4),
        _tinyBtn('Teams', rankType == 'teams', isDark, () => onChanged('teams')),
      ],
    );
  }

  Widget _tinyBtn(String label, bool sel, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: sel ? AppColors.brandBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: sel ? AppColors.brandBlue : Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Text(label,
            style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 11,
              color: sel ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
            )),
      ),
    );
  }
}

// â”€â”€ Cricket Format Chips â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CricketFormatChips extends StatelessWidget {
  final String format;
  final ValueChanged<String> onChanged;
  const _CricketFormatChips({required this.format, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formats = ['1', '2', '3'];
    final labels = ['Test', 'ODI', 'T20'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final sel = format == formats[i];
        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: GestureDetector(
            onTap: () => onChanged(formats[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: sel ? AppColors.brandBlue.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sel ? AppColors.brandBlue.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Text(labels[i],
                  style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 10,
                    color: sel ? AppColors.brandBlue : (isDark ? Colors.white60 : Colors.black45),
                  )),
            ),
          ),
        );
      }),
    );
  }
}

// â”€â”€ Cricket Role Chips (batsmen/bowlers/all-rounders) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CricketRoleChips extends StatelessWidget {
  final String role;
  final ValueChanged<String> onChanged;
  const _CricketRoleChips({required this.role, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final roles = ['1', '2', '3'];
    final labels = ['Batsmen', 'Bowlers', 'All-Rounders'];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final sel = role == roles[i];
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: GestureDetector(
            onTap: () => onChanged(roles[i]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: sel ? AppColors.brandBlue.withValues(alpha: 0.15) : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: sel ? AppColors.brandBlue.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              child: Text(labels[i],
                  style: TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 10,
                    color: sel ? AppColors.brandBlue : (isDark ? Colors.white60 : Colors.black45),
                  )),
            ),
          ),
        );
      }),
    );
  }
}

// â”€â”€ Cricket Gender Chips (men/women) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CricketGenderChips extends StatelessWidget {
  final String gender;
  final ValueChanged<String> onChanged;
  const _CricketGenderChips({required this.gender, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final g in ['men', 'women'])
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: GestureDetector(
              onTap: () => onChanged(g),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: gender == g ? AppColors.brandBlue.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: gender == g ? AppColors.brandBlue.withValues(alpha: 0.4) : Colors.grey.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(g == 'men' ? 'Men' : 'Women',
                    style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 10,
                      color: gender == g ? AppColors.brandBlue : (isDark ? Colors.white60 : Colors.black45),
                    )),
              ),
            ),
          ),
      ],
    );
  }
}

// â”€â”€ Period Filter Bar â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _PeriodBar extends StatelessWidget {
  final String period;
  final ValueChanged<String> onChanged;
  const _PeriodBar({required this.period, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final periods = ['all', 'weekly', 'monthly'];
    final labels = ['All Time', 'Weekly', 'Monthly'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: List.generate(periods.length, (i) {
          final sel = period == periods[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(periods[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: sel ? AppColors.brandBlue : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: sel ? AppColors.brandBlue : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(labels[i],
                    style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12,
                      color: sel ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                    )),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// â”€â”€ Website-Style Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _LeaderboardHeader extends StatelessWidget {
  final int total;
  final bool isDark;
  const _LeaderboardHeader({required this.total, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.brandBlue.withValues(alpha: 0.12), AppColors.brandBlue.withValues(alpha: 0.04)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emoji_events, color: AppColors.brandBlue, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Fan Leaderboard',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                Text('$total fans competing',
                    style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€ Website-Style Footer â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _LeaderboardFooter extends StatelessWidget {
  final bool isDark;
  const _LeaderboardFooter({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 16, color: isDark ? Colors.white54 : Colors.black45),
          const SizedBox(width: 6),
          Text('Rankings update in real-time based on XP earned',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)),
        ],
      ),
    );
  }
}

// â”€â”€ Website-Style Podium â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _WebsitePodium extends StatelessWidget {
  final List<Map<String, dynamic>> fans;
  final bool isDark;
  final void Function(Map<String, dynamic>) onTap;

  const _WebsitePodium({required this.fans, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (fans.length < 3) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withValues(alpha: 0.1),
            const Color(0xFFFFD700).withValues(alpha: 0.02),
          ],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          const Text('ðŸ† TOP FANS',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.2)),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd place
              _PodiumTile(
                fan: fans[1], rank: 2, medal: 'ðŸ¥ˆ',
                barHeight: 80.0, avatarRadius: 22,
                isDark: isDark, onTap: () => onTap(fans[1]),
                accentColor: const Color(0xFFC0C0C0),
                labelColor: const Color(0xFF757575),
              ),
              // 1st place
              _PodiumTile(
                fan: fans[0], rank: 1, medal: 'ðŸ‘‘',
                barHeight: 110.0, avatarRadius: 30,
                isDark: isDark, onTap: () => onTap(fans[0]),
                accentColor: const Color(0xFFFFD700),
                labelColor: const Color(0xFFFF8F00),
                isFirst: true,
              ),
              // 3rd place
              _PodiumTile(
                fan: fans[2], rank: 3, medal: 'ðŸ¥‰',
                barHeight: 60.0, avatarRadius: 20,
                isDark: isDark, onTap: () => onTap(fans[2]),
                accentColor: const Color(0xFFCD7F32),
                labelColor: const Color(0xFFA1887F),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumTile extends StatelessWidget {
  final Map<String, dynamic> fan;
  final int rank;
  final String medal;
  final double barHeight;
  final double avatarRadius;
  final bool isDark;
  final VoidCallback onTap;
  final Color accentColor;
  final Color labelColor;
  final bool isFirst;

  const _PodiumTile({
    required this.fan, required this.rank, required this.medal,
    required this.barHeight, required this.avatarRadius,
    required this.isDark, required this.onTap,
    required this.accentColor, required this.labelColor,
    this.isFirst = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (isFirst) Text(medal, style: const TextStyle(fontSize: 30)),
              Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: avatarRadius * 2,
                  height: avatarRadius * 2,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    image: (fan['img'] as String).isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(fan['img'] as String),
                            onError: (_, __) {},
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: (fan['img'] as String).isEmpty
                      ? Center(
                          child: Text(
                            (fan['name'] as String).isNotEmpty ? (fan['name'] as String)[0].toUpperCase() : '?',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: avatarRadius * 0.8, color: accentColor),
                          ),
                        )
                      : null,
                ),
                if (isFirst)
                  Positioned(
                    right: -2, bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: accentColor, shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.emoji_events, size: 13, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              fan['name'] as String,
              style: TextStyle(
                fontWeight: FontWeight.w800, fontSize: isFirst ? 14 : 12,
                color: isFirst ? accentColor : null,
              ),
              overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
            ),
            const SizedBox(height: 1),
            Text('${fan['xp']} XP',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 10,
                    color: isDark ? Colors.white60 : Colors.black45)),
            const SizedBox(height: 4),
            Text(medal, style: const TextStyle(fontSize: 16)),
            Container(
              height: barHeight,
              width: 44,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.4),
                    accentColor.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(isFirst ? 12 : 8)),
                border: Border.all(color: accentColor.withValues(alpha: 0.4)),
              ),
              child: Center(
                child: Text('#$rank',
                    style: TextStyle(fontWeight: FontWeight.w900,
                        fontSize: isFirst ? 14 : 11, color: accentColor)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€ Website-Style Rankings Table â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _RankingsTable extends StatelessWidget {
  final List<Map<String, dynamic>> fans;
  final bool isDark;
  final void Function(Map<String, dynamic>) onTap;

  const _RankingsTable({required this.fans, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.12))),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8, child: Text('#', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.brandBlue))),
                const SizedBox(width: 46),
                const Expanded(child: Text('Fan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.brandBlue))),
                const SizedBox(width: 4, child: Text('Lv', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.brandBlue))),
                const SizedBox(width: 40, child: Text('XP', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: AppColors.brandBlue))),
                const SizedBox(width: 8),
              ],
            ),
          ),
          // Table rows
          ...fans.asMap().entries.map((entry) {
            final i = entry.key;
            final u = entry.value;
            final rank = u['rank'] as int;
            final isLast = i == fans.length - 1;
            return _TableRow(
              u: u, rank: rank, isDark: isDark,
              isLast: isLast, onTap: () => onTap(u),
            );
          }),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final Map<String, dynamic> u;
  final int rank;
  final bool isDark;
  final bool isLast;
  final VoidCallback onTap;

  const _TableRow({
    required this.u, required this.rank, required this.isDark,
    required this.isLast, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final isMe = currentUid == u['uid'];
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.brandBlue.withValues(alpha: 0.06) : null,
          border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.06))),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text('$rank',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black45)),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.brandBlue.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                image: (u['img'] as String).isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(u['img'] as String),
                        onError: (_, __) {},
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: (u['img'] as String).isEmpty
                  ? Center(
                      child: Text(
                        (u['name'] as String).isNotEmpty ? (u['name'] as String)[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.brandBlue),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(u['name'] as String,
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13,
                            color: isMe ? AppColors.brandBlue : null),
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (isMe)
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.brandBlue.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: const Text('YOU',
                          style: TextStyle(fontSize: 7, fontWeight: FontWeight.w900, color: AppColors.brandBlue)),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Lv.${u['level']}',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11,
                        color: isDark ? Colors.white60 : Colors.black54)),
                Text('${u['xp']} XP',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12,
                        color: AppColors.brandBlue)),
              ],
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${u['coins']}',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFFFF9800))),
                  const Text(' ðŸª™', style: TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _ModeBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? AppColors.brandBlue : Colors.grey.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 14,
              color: selected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
            )),
      ),
    );
  }
}

