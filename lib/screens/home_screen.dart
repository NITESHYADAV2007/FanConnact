import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../l10n.dart';
import '../services/news_service.dart';
import '../services/reels_service.dart';
import '../services/live_match_service.dart';
import '../widgets/news_post_card.dart';
import '../widgets/reels_card.dart';
import '../widgets/live_score_card.dart';
import '../screens/match_detail_screen.dart';
import '../screens/reels_viewer_screen.dart';
import '../screens/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final Locale locale;
  final bool isDark;
  final VoidCallback onToggleTheme;

  const HomeScreen({
    super.key,
    required this.locale,
    required this.isDark,
    required this.onToggleTheme,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _langOverride; // quick language preview from the top bar
  String _feedSport = 'all'; // sport filter for the news/reels feed

  List<MatchItem> _matches = [];
  List<NewsItem> _news = news;
  List<ReelItem> _reels = [];
  bool _loadingMatches = true;
  bool _loadingNews = true;
  bool _loadingReels = true;
  bool _loadingMore = false;

  // Real-time score updates: poll the backend every 20s.
  static const Duration _pollInterval = Duration(seconds: 20);
  bool _polling = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _startPolling();
  }

  @override
  void dispose() {
    _polling = false;
    super.dispose();
  }

  void _startPolling() {
    Future.doWhile(() async {
      if (!_polling || !mounted) return false;
      await Future.delayed(_pollInterval);
      if (!_polling || !mounted) return false;
      // Silent refresh of live scores (cache TTL 30s keeps it cheap).
      final fetched = await LiveMatchService.fetchLiveMatches(sport: 'all');
      if (mounted) {
        setState(() {
          _matches = fetched;
          _loadingMatches = false;
        });
      }
      return _polling;
    });
  }

  Future<void> _loadAll() async {
    // Pull-to-refresh: bypass the client cache so we fetch fresh data.
    LiveMatchService.invalidate(sport: 'all');
    NewsService.invalidate(sport: _feedSport, language: _langOverride ?? widget.locale.languageCode);
    ReelsService.invalidate(sport: _feedSport);
    _loadMatches();
    _loadNews(reset: true);
    _loadReels(reset: true);
  }

  Future<void> _loadMatches() async {
    setState(() => _loadingMatches = true);
    final fetched = await LiveMatchService.fetchLiveMatches(sport: 'all');
    if (mounted) {
      setState(() {
        _matches = fetched;
        _loadingMatches = false;
      });
    }
  }

  Future<void> _loadNews({bool reset = false}) async {
    if (reset) setState(() => _loadingNews = true);
    final fetched = await NewsService.fetchNews(
      sport: _feedSport,
      language: _langOverride ?? widget.locale.languageCode,
      reset: reset,
    );
    if (mounted) {
      setState(() {
        _news = fetched;
        _loadingNews = false;
      });
    }
  }

  Future<void> _loadReels({bool reset = false}) async {
    if (reset) setState(() => _loadingReels = true);
    final fetched = await ReelsService.fetchReels(sport: _feedSport, reset: reset);
    if (mounted) {
      setState(() {
        _reels = fetched;
        _loadingReels = false;
      });
    }
  }

  // Load the next page of the feed (endless scroll).
  Future<void> _loadMore() async {
    if (_loadingMore) return;
    if (!NewsService.hasMore(_feedSport, _langOverride ?? widget.locale.languageCode) &&
        !ReelsService.hasMore(_feedSport)) {
      return;
    }
    setState(() => _loadingMore = true);
    await Future.wait([
      _loadNews(),
      _loadReels(),
    ]);
    if (mounted) setState(() => _loadingMore = false);
  }

  void _onFeedSportChanged(String sport) {
    setState(() => _feedSport = sport);
    _loadNews(reset: true);
    _loadReels(reset: true);
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
                'LIVE MATCHES',
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
                    '${liveMatches.length} LIVE',
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

  // Build a mixed vertical feed: reels interleaved with news (shorts style).
  List<Widget> get _mixedFeed {
    final List<Widget> items = [];
    final reelCount = _reels.length;
    final newsCount = _news.length;
    final maxLen = reelCount > newsCount ? reelCount : newsCount;

    for (int i = 0; i < maxLen; i++) {
      if (i < reelCount) {
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
      if (i < newsCount) {
        items.add(NewsPostCard(item: _news[i]));
      }
    }
    // Loading-more spinner at the end of the endless feed.
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
    final isDark = widget.isDark;
    // "Fan" is white in dark mode / black in light mode.
    final fanColor = isDark ? Colors.white : Colors.black;
    // "connact" is blue in light mode / green in dark mode.
    final connactColor = isDark ? AppColors.brandGreen : AppColors.brandBlue;

    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
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
        // Notifications
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          tooltip: t('notifications'),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t('notifications'))),
            );
          },
        ),
        // Theme toggle
        IconButton(
          icon: Icon(widget.isDark ? Icons.light_mode : Icons.dark_mode),
          tooltip: t('darkMode'),
          onPressed: widget.onToggleTheme,
        ),
        // Profile
        IconButton(
          icon: const Icon(Icons.person_outline),
          tooltip: t('account'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProfileScreen(
                  locale: widget.locale,
                  isDark: widget.isDark,
                ),
              ),
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
                  // ── Live matches (real-time scores) at the top ──
                  _buildLiveMatches(t),
                  const Divider(height: 1),
                  // ── Sport filter for the feed ──
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 4),
                    child: _buildFeedFilter(t),
                  ),
                  // ── Mixed reels + news feed (endless) ──
                  if (_loadingReels && _reels.isEmpty && _loadingNews && _news.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_mixedFeed.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(t('noNews'),
                            style: const TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ..._mixedFeed,
                  // Endless scroll trigger.
                  if (_mixedFeed.isNotEmpty)
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
