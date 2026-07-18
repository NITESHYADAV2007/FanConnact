import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../l10n.dart';
import '../services/news_service.dart';
import '../services/match_service.dart';
import '../widgets/sport_selector.dart';
import '../widgets/match_card.dart';
import '../widgets/news_card.dart';

// Match status filter tabs (top of matches section).
const List<String> _matchFilters = ['ALL', 'LIVE', 'UPCOMING', 'COMPLETED'];

class HomeScreen extends StatefulWidget {
  final Locale locale;
  const HomeScreen({super.key, required this.locale});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedSport = 'all'; // default = All Sports
  String _matchFilter = 'ALL';

  List<MatchItem> _matches = matches; // static fallback until loaded
  List<NewsItem> _news = news;
  bool _loadingMatches = true;
  bool _loadingNews = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    _loadMatches();
    _loadNews();
  }

  Future<void> _loadMatches() async {
    setState(() => _loadingMatches = true);
    final fetched = await MatchService.fetchMatches(sport: _selectedSport);
    if (mounted) setState(() {
      _matches = fetched;
      _loadingMatches = false;
    });
  }

  Future<void> _loadNews() async {
    setState(() => _loadingNews = true);
    final fetched = await NewsService.fetchNews();
    if (mounted) setState(() {
      _news = fetched;
      _loadingNews = false;
    });
  }

  List<MatchItem> get _filteredMatches {
    if (_matchFilter == 'ALL') return _matches;
    return _matches.where((m) => m.status == _matchFilter).toList();
  }

  List<NewsItem> get _filteredNews {
    if (_selectedSport == 'all') return _news;
    return _news.where((n) => n.sport == _selectedSport).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final lang = widget.locale.languageCode;
    final t = (String k) => AppStrings.get(lang, k);
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/fancoin/fanconnactlogo.png',
              height: 28,
              width: 28,
            ),
            const SizedBox(width: 8),
            Text(
              t('appName'),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Sticky sport selector at top
          SportSelector(
            selectedKey: _selectedSport,
            onSelected: (key) {
              setState(() => _selectedSport = key);
              _loadAll();
            },
            locale: widget.locale,
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView(
                children: [
                  // ─── Matches section ───────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                    child: Row(
                      children: [
                        const Text(
                          'MATCHES',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const Spacer(),
                        if (_loadingMatches)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),
                  // Live / Upcoming / Finished filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: _matchFilters.map((f) {
                        final active = _matchFilter == f;
                        final label = {
                          'ALL': t('all'),
                          'LIVE': t('live'),
                          'UPCOMING': t('upcoming'),
                          'COMPLETED': t('completed'),
                        }[f]!;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: active,
                            onSelected: (_) =>
                                setState(() => _matchFilter = f),
                            selectedColor: AppColors.brandBlue,
                            labelStyle: TextStyle(
                              color: active ? Colors.white : Colors.grey,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                            backgroundColor: isDark
                                ? AppColors.darkCard
                                : Colors.grey.shade100,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (_loadingMatches && _matches.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_filteredMatches.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(t('noMatches'),
                            style: const TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ..._filteredMatches
                        .map((m) => MatchCard(match: m))
                        .toList(),

                  // ─── News feed section ─────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
                    child: Row(
                      children: [
                        Text(
                          t('newsFeed'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const Spacer(),
                        if (_loadingNews)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),
                  if (_loadingNews && _news.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_filteredNews.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(t('noNews'),
                            style: const TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ..._filteredNews.map((n) => NewsCard(item: n)).toList(),
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
