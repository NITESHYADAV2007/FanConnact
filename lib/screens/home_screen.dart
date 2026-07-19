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
import '../screens/reels_viewer_screen.dart';

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

  List<MatchItem> _matches = [];
  List<NewsItem> _news = news;
  List<ReelItem> _reels = [];
  bool _loadingMatches = true;
  bool _loadingNews = true;
  bool _loadingReels = true;

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
    NewsService.invalidate(sport: 'all', language: _langOverride ?? widget.locale.languageCode);
    ReelsService.invalidate(sport: 'all');
    _loadMatches();
    _loadNews();
    _loadReels();
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

  Future<void> _loadNews() async {
    setState(() => _loadingNews = true);
    final fetched = await NewsService.fetchNews(
      sport: 'all',
      language: _langOverride ?? widget.locale.languageCode,
    );
    if (mounted) {
      setState(() {
        _news = fetched;
        _loadingNews = false;
      });
    }
  }

  Future<void> _loadReels() async {
    setState(() => _loadingReels = true);
    final fetched = await ReelsService.fetchReels(sport: 'all');
    if (mounted) {
      setState(() {
        _reels = fetched;
        _loadingReels = false;
      });
    }
  }

  // Live matches section shown at the top of Home with real-time scores.
  Widget _buildLiveMatches(String Function(String) t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
          child: Row(
            children: [
              const Icon(Icons.sports_cricket, size: 18, color: AppColors.brandBlue),
              const SizedBox(width: 8),
              Text(
                t('matches'),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (_loadingMatches && _matches.isEmpty)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Text(
                  'LIVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.liveRed,
                  ),
                ),
            ],
          ),
        ),
        if (_matches.isEmpty && !_loadingMatches)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
            child: Text(t('noMatches'),
                style: const TextStyle(color: Colors.grey)),
          )
        else
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _matches.length,
              separatorBuilder: (_, _) => const SizedBox(width: 4),
              itemBuilder: (_, i) => LiveScoreCard(match: _matches[i]),
            ),
          ),
        const SizedBox(height: 8),
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
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.locale.languageCode;
    String t(String k) => AppStrings.get(lang, k);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'assets/fancoin/fanconnactlogo.png',
              height: 30,
              width: 30,
            ),
            const SizedBox(width: 8),
            Text(
              t('appName'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ],
        ),
        actions: [
          // Language selector (quick preview; full switch in Settings)
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            tooltip: t('language'),
            onSelected: (code) {
              // Reload news in the chosen language immediately.
              setState(() => _langOverride = code);
              _loadNews();
            },
            itemBuilder: (_) => AppStrings.languages
                .map((l) => PopupMenuItem<String>(
                      value: l['code'],
                      child: Text(l['name']!),
                    ))
                .toList(),
          ),
          // FanCoin badge
          Container(
            margin: const EdgeInsets.only(right: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/fancoin/fancoin.png',
                  height: 18,
                  width: 18,
                ),
                const SizedBox(width: 4),
                const Text(
                  '120',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: AppColors.brandBlue,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              widget.isDark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: widget.onToggleTheme,
            tooltip: t('darkMode'),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
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
                  // ── Mixed reels + news feed ──
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
