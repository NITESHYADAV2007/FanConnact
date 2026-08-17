import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../data.dart';
import '../theme.dart';
import '../l10n.dart';
import '../services/reels_service.dart';
import '../services/live_match_service.dart';
import '../services/currents_service.dart';
import '../widgets/reels_card.dart';
import '../widgets/live_score_card.dart';
import '../screens/match_detail_screen.dart';
import '../screens/reels_viewer_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/news_screen.dart';
import '../screens/login_screen.dart';
import '../screens/fancoin_screen.dart';

class HomeScreen extends StatefulWidget {
  final Locale locale;
  final bool isDark;
  final ThemeType themeType;
  final VoidCallback onToggleTheme;
  final ValueChanged<ThemeType> onThemeChanged;
  final ValueChanged<Locale> onLocaleChanged;
  final Color accentColor;
  final ValueChanged<Color> onAccentColorChanged;

  const HomeScreen({
    super.key,
    required this.locale,
    required this.isDark,
    required this.themeType,
    required this.onToggleTheme,
    required this.onThemeChanged,
    required this.onLocaleChanged,
    this.accentColor = AppColors.brandBlue,
    required this.onAccentColorChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _langOverride;
  String _feedSport = 'all';

  List<MatchItem> _matches = [];
  List<ReelItem> _reels = [];
  List<NewsItem> _headlines = [];
  bool _loadingMatches = true;
  bool _loadingReels = true;
  bool _loadingHeadlines = true;
  bool _loadingMore = false;

  static const Duration _pollInterval = Duration(seconds: 20);
  bool _polling = true;

  Timer? _headlineTimer;
  late PageController _headlineCtrl;

  static final NewsItem _dummyHeadline = NewsItem(
    sport: 'all', sportEmoji: '📰',
    title: 'Loading latest sports news…',
    source: 'Fanconnact', timeAgo: '', tag: 'BREAKING',
    image: null, description: null, link: '',
  );
  static final NewsItem _noNewsHeadline = NewsItem(
    sport: 'all', sportEmoji: '📰',
    title: 'No breaking news right now — pull to refresh',
    source: 'Fanconnact', timeAgo: '', tag: 'BREAKING',
    image: null, description: null, link: '',
  );

  @override
  void initState() {
    super.initState();
    _headlineCtrl = PageController();
    _loadAll();
    _startPolling();
    _startHeadlineTimer();
  }

  @override
  void dispose() {
    _polling = false;
    _headlineTimer?.cancel();
    _headlineCtrl.dispose();
    super.dispose();
  }

  void _startPolling() {
    Future.doWhile(() async {
      if (!_polling || !mounted) return false;
      await Future.delayed(_pollInterval);
      if (!_polling || !mounted) return false;
      // Force a fresh request on each poll so live cards visibly update after
      // launch/reopen instead of reusing the short-lived cache.
      final fetched = await LiveMatchService.fetchLiveMatches(
        sport: 'all',
        force: true,
      );
      if (mounted) {
        setState(() {
          _matches = fetched;
          _loadingMatches = false;
        });
      }
      // Also refresh headlines periodically (only if not real data yet).
      if (_headlines.isEmpty) {
        _loadHeadlines();
      }
      return _polling;
    });
  }

  Future<void> _loadAll() async {
    // Warm up the Render backend (wakes from free-tier sleep).
    try { await http.get(Uri.parse('$apiBaseUrl/api/live-matches?sport=all')).timeout(const Duration(seconds: 5)); } catch (_) {}
    // Hydrate disk caches first so UI shows data immediately on cold start.
    await Future.wait([
      LiveMatchService.hydrateFromDisk(),
      ReelsService.hydrateFromDisk(),
    ]);
    // If disk cache has data, show it right away (stale-while-revalidate).
    if (mounted) {
      final cachedMatches = await LiveMatchService.fetchLiveMatches(sport: 'all', force: false);
      if (cachedMatches.isNotEmpty) {
        setState(() {
          _matches = cachedMatches;
          _loadingMatches = false;
          _loadingReels = false;
        });
      }
    }
    // Fire all fresh network fetches in parallel.
    // Reels load uses current _feedSport so filter takes effect on refresh.
    await Future.wait([
      _loadMatches(),
      _loadReels(reset: true),
      _loadHeadlines(),
    ]);
  }

  Future<void> _loadMatches() async {
    if (!mounted) return;
    setState(() => _loadingMatches = true);
    final fetched = LiveMatchService.fetchLiveMatches(
      sport: 'all',
      force: true,
    );
    // Cricket comes from the backend proxy too (sport=cricket) — the legacy
    // direct-RapidAPI path has no key and always returned empty.
    final cricketFuture = LiveMatchService.fetchLiveMatches(
      sport: 'cricket',
      force: true,
    );

    final results = await Future.wait([
      fetched,
      cricketFuture.then((raw) => raw.toList()).catchError((_) => <MatchItem>[]),
    ]);

    final allMatches = results[0];
    final cricketMatches = results[1];

    final merged = <MatchItem>[];
    final seen = <String>{};
    for (final item in allMatches) {
      final key = item.matchId ?? '${item.teamA}-${item.teamB}-${item.series}';
      if (!seen.contains(key)) {
        merged.add(item);
        seen.add(key);
      }
    }
    for (final item in cricketMatches) {
      final key = item.matchId ?? '${item.teamA}-${item.teamB}-${item.series}';
      final idx = merged.indexWhere((m) =>
          (m.matchId ?? '${m.teamA}-${m.teamB}-${m.series}') == key);
      if (idx >= 0) {
        merged[idx] = item;
      } else {
        merged.add(item);
      }
    }

    if (mounted) {
      setState(() {
        _matches = merged;
        _loadingMatches = false;
      });
    }
  }

  Future<void> _loadReels({bool reset = false}) async {
    if (!mounted) return;
    if (reset) setState(() => _loadingReels = true);
    List<ReelItem> fetched;
    bool first = true;
    do {
      fetched = await ReelsService.fetchReels(sport: _feedSport, reset: reset && first);
      first = false;
      if (mounted) setState(() => _reels = fetched);
    } while (ReelsService.hasMore(_feedSport) && fetched.length < 100);
    if (mounted) setState(() => _loadingReels = false);
  }

  Future<void> _loadHeadlines() async {
    final articles = await CurrentsService.fetchHeadlines(language: _langOverride ?? widget.locale.languageCode);
    if (mounted) {
      setState(() {
        _headlines = articles;
        _loadingHeadlines = false;
      });
    }
  }

  void _startHeadlineTimer() {
    _headlineTimer?.cancel();
    _headlineTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _headlines.isEmpty) return;
      final cur = _headlineCtrl.page?.round() ?? 0;
      final next = cur + 1;
      if (next >= _headlines.length) {
        _headlineCtrl.animateToPage(0,
            duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      } else {
        _headlineCtrl.animateToPage(next,
            duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
      }
    });
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    if (!ReelsService.hasMore(_feedSport)) return;
    setState(() => _loadingMore = true);
    await _loadReels();
    if (mounted) setState(() => _loadingMore = false);
  }

  void _onFeedSportChanged(String sport) {
    setState(() => _feedSport = sport);
    _loadReels(reset: true);
  }

  void _openNotifications(BuildContext context) {
    final lang = widget.locale.languageCode;
    final t = (String k) => AppStrings.get(lang, k);
    final entries = [
      (Icons.sensors, 'Live Match Alerts', 'liveMatchAlerts'),
      (Icons.article_outlined, 'Breaking News', 'breakingNews'),
      (Icons.analytics, 'Prediction Results', 'predictionResults'),
      (Icons.group_outlined, 'Community Updates', 'communityUpdates'),
      (Icons.mail_outline, 'Email Notifications', 'emailNotifications'),
      (Icons.notifications_active, 'Push Notifications', 'pushNotifications'),
      (Icons.alternate_email, 'Mentions & Replies', 'mentionsReplies'),
      (Icons.person_add_alt, 'New Followers', 'newFollowers'),
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          Widget row(IconData icon, String title, String key) {
            return FutureBuilder<bool>(
              future: SharedPreferences.getInstance().then((p) => p.getBool(key) ?? true),
              builder: (ctx, snap) {
                final val = snap.data ?? true;
                return SwitchListTile(
                  secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
                  title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  value: val,
                  onChanged: (v) async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool(key, v);
                    setSheet(() {});
                  },
                );
              },
            );
          }

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 36, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_outlined),
                      const SizedBox(width: 8),
                      Text(t('notifications'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              onToggleTheme: widget.onToggleTheme,
                              isDark: widget.isDark,
                              themeType: widget.themeType,
                              onThemeChanged: widget.onThemeChanged,
                              onLocaleChanged: widget.onLocaleChanged,
                              locale: widget.locale,
                              accentColor: widget.accentColor,
                              onAccentColorChanged: widget.onAccentColorChanged,
                            ),
                          ));
                        },
                        child: Text('Open Settings', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                      ),
                    ],
                  ),
                ),
                Flexible(child: ListView(shrinkWrap: true, children: entries.map((e) => row(e.$1, e.$2, e.$3)).toList())),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Breaking news ticker (auto-scroll carousel) above live matches ──
  void _openNewsScreen() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => NewsScreen(
        themeType: widget.themeType,
        onThemeChanged: widget.onThemeChanged,
        locale: widget.locale,
        onLocaleChanged: widget.onLocaleChanged,
        accentColor: widget.accentColor,
        onAccentColorChanged: widget.onAccentColorChanged,
      ),
    ));
  }

  Widget _buildBreakingNews() {
    final items = _loadingHeadlines
        ? [_dummyHeadline]
        : (_headlines.isEmpty ? [_noNewsHeadline] : _headlines);

    return SizedBox(
      height: 190,
      child: PageView.builder(
        controller: _headlineCtrl,
        itemCount: items.length,
        itemBuilder: (_, i) {
          final h = items[i];
          final hasImage = h.image != null && h.image!.isNotEmpty;
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
            child: GestureDetector(
              onTap: _headlines.isEmpty ? null : _openNewsScreen,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: hasImage
                        ? Image.network(h.image!, width: double.infinity, height: 190, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade900))
                        : Container(color: Colors.grey.shade900),
                  ),
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter, end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 14, left: 14, right: 14,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.liveRed,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('BREAKING',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black26,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(h.source, style: const TextStyle(color: Colors.white70, fontSize: 9)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(h.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Text('View All News', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_forward, size: 12, color: Colors.white70),
                          ],
                        ),
                      ],
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

  // Live matches section shown at the top of Home with real-time scores.
  // ── Live matches: ONLY live matches across all sports, swipeable cards ──
  Widget _buildLiveMatches(String Function(String) t) {
    final liveMatches = _matches
        .where((m) => (m.status).toUpperCase() == 'LIVE')
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.liveRed,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.liveRed.withValues(alpha: 0.6),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${t('live')} ${t('matches')}',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  letterSpacing: 0.5,
                  color: widget.isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              if (_loadingMatches && liveMatches.isEmpty)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.liveRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${liveMatches.length} ${t('live')}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.liveRed,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (_loadingMatches && _matches.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (liveMatches.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: widget.isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.sports_outlined,
                      color: AppColors.liveRed, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No live matches right now. Pull to refresh or check back soon.',
                      style: TextStyle(
                        color: widget.isDark
                            ? Colors.white70
                            : Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 168,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: liveMatches.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => LiveScoreCard(
                match: liveMatches[i],
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MatchDetailScreen(match: liveMatches[i]),
                    ),
                  );
                },
              ),
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  // Build vertical reels feed (no news interleaved).
  List<Widget> get _reelsFeed {
    final List<Widget> items = [];
    for (int i = 0; i < _reels.length; i++) {
      items.add(ReelsCard(
        reel: _reels[i],
        isDark: widget.isDark,
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ReelsViewerScreen(
                reels: _reels,
                initialIndex: i,
              ),
            ),
          );
        },
      ));
    }
    if (_loadingMore) {
      items.add(const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ));
    }
    return items;
  }

  // Horizontal sport filter chips for the news/reels feed.
  Widget _buildFeedFilter(String Function(String) t) {
    const chips = [
      ('all', 'All'),
      ('cricket', '🏏 Cricket'),
      ('football', '⚽ Football'),
      ('basketball', '🏀 NBA'),
      ('tennis', '🎾 Tennis'),
      ('hockey', '🏑 Hockey'),
      ('baseball', '⚾ MLB'),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (key, label) = chips[i];
          final selected = _feedSport == key;
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => _onFeedSportChanged(key),
            selectedColor: AppColors.brandBlue,
            labelStyle: TextStyle(
              color: selected ? Colors.white : null,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }

  // ── Top bar: logo + two-tone "Fanconnact" wordmark + action icons ──
  PreferredSizeWidget _buildAppBar(String Function(String) t) {
    final cfg = themeConfigFor(widget.themeType);
    final isCustom = widget.themeType == ThemeType.custom;
    final fanColor = isCustom ? Colors.white : cfg.fanColor;
    final connactColor = isCustom ? widget.accentColor : cfg.connactColor;

    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: (isCustom || cfg.glassCards)
          ? Colors.transparent
          : (widget.isDark ? AppColors.darkSurface : AppColors.lightSurface),
      titleSpacing: 12,
      title: Row(
        children: [
          // Single brand logo (no duplicate)
          Image.asset(
            'assets/fancoin/fanconnactlogo.png',
            height: 30,
            width: 30,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.sports, color: connactColor, size: 26),
          ),
          const SizedBox(width: 8),
          // Two-tone wordmark — smaller text per request
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Fan',
                  style: TextStyle(
                    color: fanColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'connact',
                  style: TextStyle(
                    color: connactColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Fan Coins balance (live from the signed-in account)
        Builder(
          builder: (ctx) {
            final u = FirebaseAuth.instance.currentUser;
            if (u == null) return const SizedBox.shrink();
            return StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(u.uid)
                  .snapshots(),
              builder: (ctx, snap) {
                final data = snap.data?.data() as Map<String, dynamic>?;
                final coins = (data?['coins'] is num)
                    ? (data!['coins'] as num).toInt()
                    : (data?['coins'] is String
                        ? int.tryParse(data!['coins'] as String) ?? 100
                        : 100);
                return GestureDetector(
                  onTap: () => Navigator.of(ctx).push(
                    MaterialPageRoute(
                      builder: (_) => FanCoinScreen(
                        locale: widget.locale,
                        isDark: widget.isDark,
                      ),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(right: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.brandBlue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.brandBlue.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 13)),
                        const SizedBox(width: 4),
                        Text(
                          '$coins',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isCustom
                                ? widget.accentColor
                                : AppColors.brandBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
        // Notifications
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: t('notifications'),
          onPressed: () => _openNotifications(context),
        ),
        // Theme toggle
        IconButton(
          icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
          tooltip: t('darkMode'),
          onPressed: widget.onToggleTheme,
        ),
        // Settings
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: t('settings'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsScreen(
                  onToggleTheme: widget.onToggleTheme,
                  isDark: widget.isDark,
                  themeType: widget.themeType,
                  onThemeChanged: widget.onThemeChanged,
                  onLocaleChanged: widget.onLocaleChanged,
                  locale: widget.locale,
                  accentColor: widget.accentColor,
                  onAccentColorChanged: widget.onAccentColorChanged,
                ),
              ),
            );
          },
        ),
        // Profile
        Builder(
          builder: (ctx) {
            final u = FirebaseAuth.instance.currentUser;
            return StreamBuilder<DocumentSnapshot>(
              stream: u == null
                  ? null
                  : FirebaseFirestore.instance.collection('users').doc(u.uid).snapshots(),
              builder: (ctx, snap) {
                final doc = snap.data;
                final photo = (doc?.data() as Map<String, dynamic>?)?['photoURL']?.toString() ?? u?.photoURL ?? '';
                return IconButton(
                  icon: photo.isNotEmpty
                      ? Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(photo),
                              onError: (_, __) {},
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : const Icon(Icons.person_outline),
                  tooltip: t('account'),
              onPressed: () async {
                if (FirebaseAuth.instance.currentUser == null) {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LoginScreen(
                        isDark: widget.isDark,
                        onToggleTheme: widget.onToggleTheme,
                        themeType: widget.themeType,
                        onThemeChanged: widget.onThemeChanged,
                        locale: widget.locale,
                        onLocaleChanged: widget.onLocaleChanged,
                        accentColor: widget.accentColor,
                        onAccentColorChanged: widget.onAccentColorChanged,
                      ),
                    ),
                  );
                  return;
                }
                if (!ctx.mounted) return;
                Navigator.of(ctx).push(
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(
                      locale: widget.locale,
                      isDark: widget.isDark,
                      onToggleTheme: widget.onToggleTheme,
                      themeType: widget.themeType,
                      onThemeChanged: widget.onThemeChanged,
                      onLocaleChanged: widget.onLocaleChanged,
                      accentColor: widget.accentColor,
                      onAccentColorChanged: widget.onAccentColorChanged,
                    ),
                  ),
                );
              },
                );
              },
            );
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.locale.languageCode;
    String t(String k) => AppStrings.get(lang, k);

    return Scaffold(
      appBar: _buildAppBar(t),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                children: [
                  // ── Breaking news ticker (auto-scroll) ──
                  _buildBreakingNews(),
                  // ── Live matches (real-time scores) ──
                  _buildLiveMatches(t),
                  const Divider(height: 1),
                  // ── Sport filter for the feed ──
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: _buildFeedFilter(t),
                  ),
                  // ── Reels feed (short-form sports videos) ──
                  if (_loadingReels && _reels.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_reelsFeed.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(t('noReels'),
                            style: const TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ..._reelsFeed,
                  // Endless scroll trigger.
                  if (_reelsFeed.isNotEmpty)
                    SizedBox(
                      height: 1,
                      child: NotificationListener<ScrollEndNotification>(
                        onNotification: (n) {
                          if (n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                            _loadMore();
                          }
                          return false;
                        },
                        child: const SizedBox.shrink(),
                      ),
                    ),
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
