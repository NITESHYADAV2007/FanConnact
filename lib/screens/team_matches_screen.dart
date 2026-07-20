// Crex-style "team clicked → all matches" screen. When a user taps a team
// name/logo inside a MatchCard, this screen shows every match involving that
// team (across the currently selected sport), fetched live from the backend.

import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../l10n.dart';
import '../services/live_match_service.dart';
import '../widgets/match_card.dart';

class TeamMatchesScreen extends StatefulWidget {
  final String teamName;
  final String? teamLogo;
  final String sportKey;
  const TeamMatchesScreen({
    super.key,
    required this.teamName,
    this.teamLogo,
    required this.sportKey,
  });

  @override
  State<TeamMatchesScreen> createState() => _TeamMatchesScreenState();
}

class _TeamMatchesScreenState extends State<TeamMatchesScreen> {
  List<MatchItem> _matches = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final all = await LiveMatchService.fetchLiveMatches(sport: widget.sportKey);
    if (!mounted) return;
    final teamMatches = all.where((m) {
      final a = m.teamA.toLowerCase();
      final b = m.teamB.toLowerCase();
      final t = widget.teamName.toLowerCase();
      return a.contains(t) || b.contains(t) || t.contains(a) || t.contains(b);
    }).toList();
    setState(() {
      _matches = teamMatches;
      _loading = false;
    });
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
    final lang = Localizations.localeOf(context).languageCode;
    String t(String k) => AppStrings.get(lang, k);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.teamLogo != null && widget.teamLogo!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    widget.teamLogo!,
                    width: 28,
                    height: 28,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.sports, size: 22),
                  ),
                ),
              ),
            Expanded(
              child: Text(
                widget.teamName,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
                  icon: const Icon(Icons.fiber_manual_record,
                      size: 14, color: AppColors.liveRed),
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
              onSelectionChanged: (set) =>
                  setState(() => _filter = set.first),
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
