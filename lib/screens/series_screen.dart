// Series screen — top game selector, then tournaments for the selected game
// (with the live tournament highlighted). Each tournament expands to show its
// matches, quick stats, and news of that specific tournament. Crex-style.

import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../l10n.dart';
import '../services/live_match_service.dart';
import '../services/news_service.dart';
import '../widgets/sport_selector.dart';
import '../widgets/match_card.dart';
import 'match_detail_screen.dart';
import 'player_rankings_screen.dart';

class SeriesScreen extends StatefulWidget {
  final Locale locale;
  final bool isDark;

  const SeriesScreen({super.key, required this.locale, required this.isDark});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  String _selectedSport = 'cricket';
  List<MatchItem> _matches = [];
  List<NewsItem> _news = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final fetched =
          await LiveMatchService.fetchLiveMatches(sport: _selectedSport);
      final news = await NewsService.fetchNews(
        sport: _selectedSport,
        reset: true,
      );
      if (mounted) {
        setState(() {
          _matches = fetched;
          _news = news;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  // Unique tournaments/series present in the current matches.
  // Series containing a LIVE match are listed first.
  List<String> get _tournaments {
    final map = <String, bool>{};
    for (final m in _matches) {
      final key = m.series.isNotEmpty ? m.series : 'Other';
      if (m.status == 'LIVE') {
        map[key] = true;
      } else {
        map.putIfAbsent(key, () => false);
      }
    }
    final entries = map.entries.toList();
    entries.sort((a, b) {
      if (a.value != b.value) return a.value ? 0 : 1;
      return a.key.compareTo(b.key);
    });
    return entries.map((e) => e.key).toList();
  }

  List<MatchItem> _matchesFor(String tournament) => _matches
      .where((m) => (m.series.isNotEmpty ? m.series : 'Other') == tournament)
      .toList();

  List<NewsItem> _newsFor(String tournament) {
    if (tournament == 'Other') return _news;
    final lower = tournament.toLowerCase();
    return _news
        .where((n) =>
            n.title.toLowerCase().contains(lower) ||
            (n.description ?? '').toLowerCase().contains(lower))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.locale.languageCode;
    String t(String k) => AppStrings.get(lang, k);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Series',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          if (_selectedSport != 'all')
            TextButton.icon(
              icon: const Icon(Icons.leaderboard, size: 18),
              label: const Text('Rankings'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PlayerRankingsScreen(
                      sportKey: _selectedSport,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Top game selector
          SportSelector(
            selectedKey: _selectedSport,
            onSelected: (key) {
              setState(() => _selectedSport = key);
              _load();
            },
            locale: widget.locale,
          ),
          const Divider(height: 1),
          if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Text('Failed to load: $_error',
                    style: const TextStyle(color: Colors.grey)),
              ),
            )
          else if (_tournaments.isEmpty)
            Expanded(
              child: Center(
                child: Text(t('noMatches'),
                    style: const TextStyle(color: Colors.grey)),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _tournaments.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final tournament = _tournaments[index];
                  final matches = _matchesFor(tournament);
                  final live = matches.any((m) => m.status == 'LIVE');
                  return _TournamentCard(
                    tournament: tournament,
                    matches: matches,
                    news: _newsFor(tournament),
                    live: live,
                    isDark: isDark,
                    onOpenMatch: (m) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => MatchDetailScreen(match: m),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _TournamentCard extends StatefulWidget {
  final String tournament;
  final List<MatchItem> matches;
  final List<NewsItem> news;
  final bool live;
  final bool isDark;
  final void Function(MatchItem) onOpenMatch;

  const _TournamentCard({
    required this.tournament,
    required this.matches,
    required this.news,
    required this.live,
    required this.isDark,
    required this.onOpenMatch,
  });

  @override
  State<_TournamentCard> createState() => _TournamentCardState();
}

class _TournamentCardState extends State<_TournamentCard> {
  bool _expanded = false;

  int get _liveCount => widget.matches.where((m) => m.status == 'LIVE').length;
  int get _upcomingCount =>
      widget.matches.where((m) => m.status == 'UPCOMING').length;
  int get _completedCount =>
      widget.matches.where((m) => m.status == 'COMPLETED').length;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? AppColors.darkCard : Colors.white,
        border: widget.live
            ? Border.all(color: AppColors.liveRed, width: 1.5)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  if (widget.live)
                    Container(
                      width: 9,
                      height: 9,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: AppColors.liveRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tournament,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Quick stats
                        Wrap(
                          spacing: 8,
                          children: [
                            _chip('${widget.matches.length} matches',
                                AppColors.brandBlue),
                            if (_liveCount > 0)
                              _chip('$_liveCount live', AppColors.liveRed),
                            if (_upcomingCount > 0)
                              _chip('$_upcomingCount upcoming',
                                  AppColors.upcomingAmber),
                            if (_completedCount > 0)
                              _chip('$_completedCount done',
                                  AppColors.completedGrey),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            // Matches
            if (widget.matches.isEmpty)
              const Padding(
                padding: EdgeInsets.all(14),
                child: Text('No matches in this tournament yet.',
                    style: TextStyle(color: Colors.grey)),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                itemCount: widget.matches.length,
                separatorBuilder: (_, __) => const SizedBox(height: 6),
                itemBuilder: (context, i) => MatchCard(
                  match: widget.matches[i],
                  onTap: () => widget.onOpenMatch(widget.matches[i]),
                ),
              ),
            // News of this specific tournament
            if (widget.news.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(14, 10, 14, 4),
                child: Text(
                  'News',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: AppColors.brandBlue,
                  ),
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                itemCount: widget.news.length > 4 ? 4 : widget.news.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, i) {
                  final n = widget.news[i];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    leading: n.image != null && n.image!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              n.image!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.article),
                            ),
                          )
                        : const Icon(Icons.article),
                    title: Text(
                      n.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    subtitle: Text(
                      '${n.source} · ${n.timeAgo}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    dense: true,
                  );
                },
              ),
            ],
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
