// Player detail screen — matches the website's player profile design:
// hero (portrait, flag, name, role, rank/rating/status cards, follow button),
// info grid (born/age/batting/bowling/height/weight/jersey/debut), tabbed
// Overview / Stats / News / Teams / Achievements with real API data:
//   cricket: /api/players/:id/profile (cricbuzz)
//   NBA/MLB/NHL: /api/players/espn/:league/:athleteId (ESPN core API)
//   other sports: real ranking data + derived stats

import 'package:flutter/material.dart';
import '../theme.dart';
import '../data.dart';
import '../services/player_detail_service.dart';
import '../services/news_service.dart';
import '../services/wikipedia_service.dart';
import '../widgets/team_logo.dart';
import 'match_detail_screen.dart';

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
  bool _following = false;
  String? _wikiPhoto;
  String _format = 'all';

  static const Set<String> _skipKeys = {
    'image', 'img', 'photo', 'logo', 'flag', 'pid', 'playerId', 'player_id',
    'teamId', 'team_id', 'id', 'category', 'name', 'country', 'rank',
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
      if (pid == null && widget.name.isNotEmpty) {
        pid = await PlayerDetailService.resolveCricketPlayerId(widget.name);
      }
      if (pid != null) {
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
    WikipediaService.fetchImage('${widget.name} sports player').then((u) {
      if (mounted && u != null) setState(() => _wikiPhoto = u);
    });
    if (mounted) setState(() => _loading = false);
  }

  // ── Resolvers ────────────────────────────────────────────────────────────
  Map<String, dynamic>? get _basic =>
      _player?['basic'] as Map<String, dynamic>?;

  Map<String, dynamic>? get _profile {
    final p = _player?['profile'];
    return p is Map ? Map<String, dynamic>.from(p) : null;
  }

  String _pick(List<String> keys,
      [Map<String, dynamic>? src, Map<String, dynamic>? src2]) {
    final sources = [
      if (src != null) src,
      if (src2 != null) src2,
      if (src == null && src2 == null) ..._profile == null ? [] : [_profile!],
    ];
    for (final m in sources) {
      for (final k in keys) {
        final v = m[k];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString();
      }
    }
    return '';
  }

  String get _name {
    final basic = _basic;
    final espn = _espnProfile;
    return widget.name.isNotEmpty
        ? widget.name
        : (basic?['name']?.toString() ??
            espn?['name']?.toString() ??
            (widget.extra?['name']?.toString()) ??
            'Player');
  }

  String get _country {
    final c = _pick(['country', 'nationality']);
    if (c.isNotEmpty) return c;
    return widget.country ??
        _basic?['country']?.toString() ??
        _espnProfile?['country']?.toString() ??
        widget.extra?['country']?.toString() ??
        '';
  }

  String get _role {
    final r = _pick(['role', 'playingRole', 'battingStyle']);
    if (r.isNotEmpty) return r;
    return _espnProfile?['position']?.toString() ??
        widget.extra?['category']?.toString() ??
        widget.extra?['role']?.toString() ??
        '';
  }

  String get _imageUrl {
    final espn = _espnProfile;
    if (espn?['image']?.toString().isNotEmpty == true) {
      return espn!['image'].toString();
    }
    for (final k in ['image', 'img']) {
      final v = widget.extra?[k]?.toString();
      if (v != null && v.isNotEmpty) return v;
    }
    final basic = _basic;
    if (basic?['image']?.toString().isNotEmpty == true) {
      return basic!['image'].toString();
    }
    for (final k in ['profile_image', 'image']) {
      final v = _player?[k]?.toString();
      if (v != null && v.isNotEmpty) return v;
    }
    return _wikiPhoto ?? '';
  }

  int? get _rank {
    final r = _player?['rank']?.toString() ??
        _player?['ranking']?['rank']?.toString() ??
        widget.extra?['rank']?.toString();
    final n = int.tryParse(r ?? '');
    return (n != null && n > 0) ? n : null;
  }

  String? get _rating {
    for (final k in ['rating', 'points', 'ratingPoints']) {
      final v = _player?[k]?.toString() ??
          (widget.extra?[k]?.toString() ?? '');
      if (v.isNotEmpty && v != '0') return v;
    }
    return null;
  }

  String get _status {
    if (_rank != null && _rank! <= 3) return 'TOP ${_rank}';
    if (_rank != null) return 'RANKED';
    if (_rating != null) return 'ACTIVE';
    return 'ACTIVE';
  }

  String get _bio => _stripHtml(
      _profile == null
          ? ''
          : _pick(['bio', 'description', 'about', 'longBio', 'introduction'],
              _profile));

  List<MapEntry<String, String>> get _infoGrid {
    final out = <MapEntry<String, String>>[];
    void add(String label, String value) {
      if (value.trim().isNotEmpty) {
        out.add(MapEntry(label, value.trim()));
      }
    }

    add('Born', _pick(['born', 'dateOfBirth', 'birthDate'], _profile));
    add('Age', _pick(['age'], _profile));
    add('Batting',
        _pick(['battingStyle', 'batting', 'battingStyle'], _basic, _profile));
    add('Bowling',
        _pick(['bowlingStyle', 'bowling', 'bowlingStyle'], _basic, _profile));
    add('Height', _pick(['height', 'height2'], _profile, _espnProfile));
    add('Weight', _pick(['weight', 'weight2'], _profile, _espnProfile));
    add('Jersey', _pick(['jersey', 'jersey'], _basic, _espnProfile));
    add('Debut',
        _pick(['debut', 'debutYear', 'debutYear'], _profile, _espnProfile));
    return out;
  }

  Map<String, dynamic>? get _career {
    final c = _player?['career'];
    return c is Map ? Map<String, dynamic>.from(c) : null;
  }

  List<String> get _formats {
    final career = _career;
    if (career == null) return const [];
    const order = ['all', 'test', 'odi', 't20i', 't20', 'lista', 'domestic'];
    return order
        .where((f) => career[f] is Map && (career[f] as Map).isNotEmpty)
        .toList();
  }

  // ── UI ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = _name;

    return Scaffold(
      appBar: AppBar(
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHero(isDark),
                TabBar(
                  indicatorColor: AppColors.brandBlue,
                  labelColor: AppColors.brandBlue,
                  unselectedLabelColor:
                      isDark ? Colors.white54 : Colors.black45,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 12.5),
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Stats'),
                    Tab(text: 'News'),
                    Tab(text: 'Teams'),
                    Tab(text: 'Achievements'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildOverview(isDark),
                      _buildStatsTab(isDark),
                      _buildNewsTab(isDark),
                      _buildTeamsTab(isDark),
                      _buildAchievementsTab(isDark),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  // Hero — portrait, flag, name, role, rank/rating/status cards, follow.
  Widget _buildHero(bool isDark) {
    final name = _name;
    final country = _country;
    final role = _role;
    final image = _imageUrl;
    final flag = country.isEmpty
        ? ''
        : _flagFor(country);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0d1b3e), Color(0xFF3b2a6d)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Portrait
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                clipBehavior: Clip.antiAlias,
                child: image.isNotEmpty
                    ? Image.network(image,
                        width: 88, height: 88, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _initialsBox(name, isDark))
                    : _initialsBox(name, isDark),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  height: 1.15)),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified,
                            size: 16, color: Color(0xFF4FC3F7)),
                      ],
                    ),
                    if (role.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(role.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.amberAccent,
                                letterSpacing: 0.6)),
                      ),
                    if (country.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          flag.isNotEmpty ? '$flag $country' : country,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.white70),
                        ),
                      ),
                    const SizedBox(height: 8),
                    // Follow button
                    GestureDetector(
                      onTap: () {
                        setState(() => _following = !_following);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_following
                                ? 'Following $name'
                                : 'Unfollowed $name'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: _following
                              ? null
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF4FC3F7),
                                    Color(0xFF2196F3),
                                  ],
                                ),
                          color:
                              _following ? Colors.white.withValues(alpha: 0.15) : null,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: _following ? Colors.white54 : Colors.transparent),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(_following ? Icons.check : Icons.person_add,
                                size: 14, color: Colors.white),
                            const SizedBox(width: 5),
                            Text(_following ? 'FOLLOWING' : 'FOLLOW',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Rank / Rating / Status glass cards
          Row(
            children: [
              _glassCard('RANK', _rank != null ? '#$_rank' : '—', Icons.emoji_events),
              const SizedBox(width: 8),
              _glassCard('RATING', _rating ?? '—', Icons.star),
              const SizedBox(width: 8),
              _glassCard('STATUS', _status, Icons.bolt),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glassCard(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 14, color: Colors.amber.shade300),
            const SizedBox(height: 3),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
            Text(label,
                style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: Colors.white.withValues(alpha: 0.6))),
          ],
        ),
      ),
    );
  }

  Widget _initialsBox(String name, bool isDark) {
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    return Container(
      width: 88,
      height: 88,
      color: Colors.white.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Text(
        initials.isNotEmpty ? initials : '?',
        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white),
      ),
    );
  }

  // ── Overview: bio + info grid + recent matches ───────────────────────────
  Widget _buildOverview(bool isDark) {
    final bio = _bio;
    final info = _infoGrid;
    final recent = _player?['recent'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (bio.isNotEmpty) ...[
          _sectionTitle('ABOUT'),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDark ? AppColors.darkCard : Colors.white,
              border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
            ),
            child: Text(bio,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.5,
                )),
          ),
          const SizedBox(height: 16),
        ],
        if (info.isNotEmpty) ...[
          _sectionTitle('PLAYER INFO'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.4,
            children: info.map((e) => _infoCard(e.key, e.value, isDark)).toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (recent is List && recent.isNotEmpty) ...[
          _sectionTitle('RECENT MATCHES'),
          for (var i = 0; i < recent.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _recentMatchCard(recent[i], isDark),
          ],
        ],
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 3.5, height: 16,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.brandBlue, AppColors.brandGreen]),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 7),
          Text(title,
              style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w800, letterSpacing: 0.4)),
        ],
      ),
    );
  }

  Widget _infoCard(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  // ── Stats: format chips + real career stat cards ─────────────────────────
  Widget _buildStatsTab(bool isDark) {
    final career = _career;
    final formats = _formats;
    final espn = _espnProfile;

    if (widget.sportKey == 'cricket' && career != null && formats.isNotEmpty) {
      final selected = _format;
      final data = career[formats.contains(selected) ? selected : formats.first];
      final statCards = _statCardsFor(data, isDark);
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('CAREER STATS'),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: formats.map((f) {
                final on = f == selected;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _format = f),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: on
                            ? const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)])
                            : null,
                        color: on
                            ? null
                            : (isDark ? AppColors.darkCard : Colors.white),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: on
                                ? Colors.transparent
                                : Colors.grey.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        f.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: on ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          if (statCards.isNotEmpty)
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1.15,
              children: statCards,
            )
          else
            const Text('No career stats for this format.',
                style: TextStyle(color: Colors.grey)),
        ],
      );
    }

    // Fallbacks: cricbuzz tables, ESPN stats, or ranking snapshot.
    if (widget.sportKey == 'cricket') {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_player?['batting'] is Map)
            _buildCricbuzzTable('Batting Career', _player!['batting'] as Map, isDark),
          if (_player?['bowling'] is Map)
            _buildCricbuzzTable('Bowling Career', _player!['bowling'] as Map, isDark),
          if (_player?['batting'] is! Map && _player?['bowling'] is! Map)
            _buildRankingSnapshot(isDark),
        ],
      );
    }
    if (espn != null) {
      return _buildEspnSection(espn, isDark);
    }
    return _buildRankingSnapshot(isDark);
  }

  List<Widget> _statCardsFor(dynamic data, bool isDark) {
    if (data is! Map) return const [];
    final m = Map<String, dynamic>.from(data);
    String? v(String key) {
      for (final k in key.split('|')) {
        final x = m[k];
        if (x != null && x.toString().trim().isNotEmpty && x.toString().trim() != '0') {
          return x.toString().trim();
        }
      }
      return null;
    }

    final batting = <MapEntry<String, String>>[];
    void add(String label, String? value) {
      if (value != null && value.isNotEmpty) {
        batting.add(MapEntry(label, value));
      }
    }

    add('Matches', v('matches|mat|match'));
    add('Runs', v('runs'));
    add('Average', v('average|avg'));
    add('Strike Rate', v('strikeRate|strike_rate|sr'));
    add('Highest', v('highest|high|hs'));
    add('100s', v('hundreds|100s|centuries'));
    add('50s', v('fifties|50s'));
    add('4s', v('fours'));
    add('6s', v('sixes'));
    add('Balls', v('balls'));

    final bowling = <MapEntry<String, String>>[];
    add2(String label, String? value) {
      if (value != null && value.isNotEmpty) bowling.add(MapEntry(label, value));
    }

    add2('Wickets', v('wickets|wkts|wicket'));
    add2('Economy', v('economy|econ|economyRate'));
    add2('Best Bowling', v('bestBowling|best|bbi'));
    add2('5W', v('fiveWickets|five_wkts|fiveWkts|fiveWicket'));
    add2('Bowl Avg', v('bowlingAvg|bowlAvg|avg'));

    final cards = <Widget>[];
    for (final e in batting.take(9)) {
      cards.add(_statCard(e.key, e.value, isDark));
    }
    for (final e in bowling.take(4)) {
      cards.add(_statCard(e.key, e.value, isDark));
    }
    return cards;
  }

  Widget _statCard(String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            AppColors.brandBlue.withValues(alpha: isDark ? 0.25 : 0.08),
            AppColors.brandGreen.withValues(alpha: isDark ? 0.15 : 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppColors.brandBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 8.5, color: Colors.grey, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // ── News ──────────────────────────────────────────────────────────────────
  Widget _buildNewsTab(bool isDark) {
    if (_news.isEmpty) {
      return const Center(
        child: Text('No news found for this player.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    // 2-column grid like the website design.
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 0.78,
      ),
      itemCount: _news.length,
      itemBuilder: (ctx, i) => _newsCard(_news[i], isDark),
    );
  }

  Widget _newsCard(NewsItem item, bool isDark) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? AppColors.darkCard : Colors.white,
        border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (item.image != null && item.image!.isNotEmpty)
            Image.network(item.image!,
                height: 78, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                      height: 78,
                      width: double.infinity,
                      color: AppColors.brandBlue.withValues(alpha: 0.12),
                      alignment: Alignment.center,
                      child: Text(item.sportEmoji,
                          style: const TextStyle(fontSize: 26)),
                    ))
          else
            Container(
              height: 78,
              width: double.infinity,
              color: AppColors.brandBlue.withValues(alpha: 0.12),
              alignment: Alignment.center,
              child: Text(item.sportEmoji, style: const TextStyle(fontSize: 26)),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.title,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(item.source,
                    style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white54 : Colors.black45),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Teams ─────────────────────────────────────────────────────────────────
  Widget _buildTeamsTab(bool isDark) {
    final teams = <String>[];
    String team = _pick(['team', 'currentTeam', 'nationalTeam'], _profile);
    if (team.isNotEmpty) teams.add(team);
    team = _pick(['team'], _basic);
    if (team.isNotEmpty && !teams.contains(team)) teams.add(team);
    team = widget.extra?['team']?.toString() ?? '';
    if (team.isNotEmpty && !teams.contains(team)) teams.add(team);
    team = _espnProfile?['team']?.toString() ?? '';
    if (team.isNotEmpty && !teams.contains(team)) teams.add(team);

    if (teams.isEmpty) {
      return const Center(
        child: Text('No team info available.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('CURRENT TEAMS'),
        for (final t in teams)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDark ? AppColors.darkCard : Colors.white,
              border: Border.all(color: Colors.grey.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                TeamLogo(name: t, url: null, size: 38),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(t,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                ),
                const Icon(Icons.chevron_right,
                    size: 18, color: Colors.grey),
              ],
            ),
          ),
      ],
    );
  }

  // ── Achievements: timeline built from real rank + bio milestones ─────────
  Widget _buildAchievementsTab(bool isDark) {
    final milestones = <MapEntry<String, String>>[];
    if (_rank != null) {
      milestones.add(MapEntry(
        'World Rankings',
        'Currently ranked #$_rank in the world'
            '${_rating != null ? ' with rating $_rating' : ''}.',
      ));
    }
    final bio = _bio;
    if (bio.isNotEmpty) {
      // Pull real bio sentences that carry milestone keywords + a year.
      final sentences = bio
          .split(RegExp(r'(?<=[.!?])\s+'))
          .where((s) => RegExp(r'(19|20)\d{2}').hasMatch(s) &&
              RegExp(r'debut|won|named|record|award|selected|first|beat|captain|scored|took', caseSensitive: false)
                  .hasMatch(s))
          .take(4)
          .toList();
      for (final s in sentences) {
        final year = RegExp(r'(19|20)\d{2}').firstMatch(s)?.group(0) ?? '';
        milestones.add(MapEntry(
          year.isNotEmpty ? year : 'Career',
          s.replaceAll(RegExp(r'\s+'), ' ').trim(),
        ));
      }
    }
    if (milestones.isEmpty) {
      return const Center(
        child: Text('No achievement milestones available.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('CAREER HIGHLIGHTS'),
        for (var i = 0; i < milestones.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFF093FB), Color(0xFFF5576C)]),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                        i == 0 ? Icons.emoji_events : Icons.stars,
                        size: 15,
                        color: Colors.white),
                  ),
                  if (i < milestones.length - 1)
                    Container(
                      width: 2,
                      height: 42,
                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: i < milestones.length - 1 ? 22 : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(milestones[i].key.toUpperCase(),
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandBlue,
                              letterSpacing: 0.5)),
                      const SizedBox(height: 3),
                      Text(milestones[i].value,
                          style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: isDark ? Colors.white70 : Colors.black54)),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  // ── Reused helpers (recent matches / tables / espn / ranking) ────────────
  Widget _recentMatchCard(dynamic m, bool isDark) {
    final batting = m is Map ? (m['batting']?.toString() ?? '') : '';
    final bowling = m is Map ? (m['bowling']?.toString() ?? '') : '';
    final opponent = m is Map ? (m['opponent']?.toString() ?? '') : '';
    final format = m is Map ? (m['format']?.toString() ?? '') : '';
    final date = m is Map ? (m['date']?.toString() ?? '') : '';
    final id = m is Map ? (m['id']?.toString() ?? '') : '';
    final url = m is Map ? (m['url']?.toString() ?? '') : '';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: id.isNotEmpty
          ? () => _openRecentMatch(id, url, format, date)
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
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
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('vs $opponent',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black54)),
                  const SizedBox(height: 2),
                  Text(date,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right,
                size: 18, color: isDark ? Colors.white30 : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  static const Set<String> _seriesDropWords = {
    '1st', '2nd', '3rd', '4th', '5th', '6th', '7th',
    'test', 'tests', 'odi', 'odis', 't20', 't20i', 't20is', 't20s',
    'match', 'final', 'semi', 'semi-final', 'qualifier', 'only',
  };

  void _openRecentMatch(String id, String url, String format, String date) {
    var teamA = 'Team A';
    var teamB = 'Team B';
    var series = format.isNotEmpty ? format : 'Match';
    final segments = url.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isNotEmpty) {
      final slug = segments.last;
      final parts = slug.split('-').where((s) => s.isNotEmpty).toList();
      if (parts.length >= 2) {
        teamA = parts[0].toUpperCase();
        teamB = parts[1].toUpperCase();
        final rest = parts
            .sublist(2)
            .where((w) => !_seriesDropWords.contains(w.toLowerCase()))
            .toList();
        if (rest.isNotEmpty) {
          series = rest
              .map((w) => w[0].toUpperCase() + w.substring(1))
              .join(' ');
        }
      }
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MatchDetailScreen(
          match: MatchItem(
            sport: 'cricket',
            sportEmoji: '🏏',
            series: series,
            teamA: teamA,
            teamB: teamB,
            status: 'COMPLETED',
            time: date,
            matchId: id,
            matchType: format.isNotEmpty ? format : null,
          ),
        ),
      ),
    );
  }

  Widget _buildCricbuzzTable(String title, Map stats, bool isDark) {
    final headers = stats['headers'];
    final values = stats['values'];
    if (headers is! List || values is! List || values.isEmpty) {
      return const SizedBox.shrink();
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
        _sectionTitle(title.toUpperCase()),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
              color: isDark ? AppColors.darkCard : Colors.white,
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
                      label: Text(c, style: labelStyle), numeric: true)),
                ],
                rows: data.map((r) {
                  return DataRow(cells: [
                    for (var i = 0; i < cols.length; i++)
                      DataCell(Text(
                        i < r.length ? r[i] : '',
                        style: i == 0 ? labelStyle : valStyle,
                        textAlign:
                            i == 0 ? TextAlign.left : TextAlign.right,
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

  Widget _buildEspnSection(Map espn, bool isDark) {
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('SEASON STATS'),
        if (statEntries.isNotEmpty)
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.15,
            children: statEntries
                .take(12)
                .map((e) => _statCard(e.key, e.value, isDark))
                .toList(),
          )
        else
          const Text('No season stats available.',
              style: TextStyle(color: Colors.grey)),
      ],
    );
  }

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
      stats.add(MapEntry('Rank', '#$rank'));
    }
    for (final k in ['rating', 'points', 'matches', 'runs', 'wkts', 'avg', 'econ']) {
      final v = val(k);
      if (v != null) stats.add(MapEntry(k.toUpperCase(), v));
    }
    if (stats.isEmpty) {
      return const Center(
        child: Text('No ranking stats available for this player.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionTitle('RANKING'),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.15,
          children: stats.map((e) => _statCard(e.key, e.value, isDark)).toList(),
        ),
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

  String _flagFor(String country) {
    const map = {
      'India': '🇮🇳', 'Australia': '🇦🇺', 'England': '🏴󠁧󠁢󠁥󠁮󠁧󠁿',
      'South Africa': '🇿🇦', 'New Zealand': '🇳🇿', 'Pakistan': '🇵🇰',
      'Sri Lanka': '🇱🇰', 'Bangladesh': '🇧🇩', 'Afghanistan': '🇦🇫',
      'West Indies': '🏳️', 'Ireland': '🇮🇪', 'Zimbabwe': '🇿🇼',
      'United States': '🇺🇸', 'USA': '🇺🇸', 'Canada': '🇨🇦',
      'Germany': '🇩🇪', 'France': '🇫🇷', 'Spain': '🇪🇸', 'Italy': '🇮🇹',
      'Brazil': '🇧🇷', 'Argentina': '🇦🇷', 'Japan': '🇯🇵', 'China': '🇨🇳',
      'Netherlands': '🇳🇱', 'Scotland': '🏴󠁧󠁢󠁳󠁣󠁴󠁿',
    };
    return map[country] ?? '';
  }
}
