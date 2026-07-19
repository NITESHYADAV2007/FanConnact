import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../l10n.dart';
import '../services/live_match_service.dart';
import '../widgets/sport_selector.dart';
import '../widgets/match_card.dart';

class SportsScreen extends StatefulWidget {
  final Locale locale;
  final bool isDark;

  const SportsScreen({super.key, required this.locale, required this.isDark});

  @override
  State<SportsScreen> createState() => _SportsScreenState();
}

class _SportsScreenState extends State<SportsScreen> {
  String _selectedSport = 'all';
  String _filter = 'all'; // 'all' | 'live' | 'upcoming' | 'finished'
  List<MatchItem> _matches = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final fetched = await LiveMatchService.fetchLiveMatches(sport: _selectedSport);
    if (mounted) {
      setState(() {
        _matches = fetched;
        _loading = false;
      });
    }
  }

  List<MatchItem> get _filtered {
    if (_filter == 'all') return _matches;
    return _matches.where((m) {
      final s = m.status.toUpperCase();
      if (_filter == 'live') return s == 'LIVE';
      if (_filter == 'upcoming') return s == 'UPCOMING';
      if (_filter == 'finished') return s == 'COMPLETED';
      return true;
    }).toList();
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
          t('matches'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          SportSelector(
            selectedKey: _selectedSport,
            onSelected: (key) {
              setState(() => _selectedSport = key);
              _load();
            },
            locale: widget.locale,
          ),
          // Live / Upcoming / Finished segmented filter
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'all',
                  label: Text(t('all')),
                  icon: const Icon(Icons.grid_view, size: 16),
                ),
                ButtonSegment(
                  value: 'live',
                  label: Text(t('live')),
                  icon: const Icon(Icons.fiber_manual_record, size: 14, color: AppColors.liveRed),
                ),
                ButtonSegment(
                  value: 'upcoming',
                  label: Text(t('upcoming')),
                  icon: const Icon(Icons.schedule, size: 16),
                ),
                ButtonSegment(
                  value: 'finished',
                  label: Text(t('completed')),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (set) => setState(() => _filter = set.first),
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                backgroundColor: WidgetStateProperty.resolveWith((states) =>
                    states.contains(WidgetState.selected)
                        ? AppColors.brandBlue.withValues(alpha: 0.15)
                        : null),
                foregroundColor: WidgetStateProperty.all(
                    isDark ? Colors.white : Colors.black87),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.only(top: 8, bottom: 16),
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text(t('noMatches'),
                            style: const TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ..._filtered.map((m) => MatchCard(match: m)),
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
