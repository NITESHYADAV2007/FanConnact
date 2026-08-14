// Series screen — top game selector, then tournaments for the selected game
// (with the live tournament highlighted). Each tournament expands to show its
// matches, quick stats, and news of that specific tournament. Crex-style.

import 'package:flutter/material.dart';
import '../theme.dart';
import '../l10n.dart';
import '../services/rapid_api_service.dart';
import '../widgets/sport_selector.dart';


class SeriesScreen extends StatefulWidget {
  final Locale locale;
  final bool isDark;

  const SeriesScreen({super.key, required this.locale, required this.isDark});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  String _selectedSport = 'cricket';
  List<Map<String, dynamic>> _apiTournaments = [];
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
      // Cricket: real tournaments (with logos) from the API. Show ALL
      // tournaments, not just the ones with a live match right now.
      List<Map<String, dynamic>> apiTournaments = [];
      if (_selectedSport == 'cricket') {
        try {
          apiTournaments = await RapidApiService.fetchCricketTournaments();
        } catch (_) {
          apiTournaments = [];
        }
      }
      if (mounted) {
        setState(() {
          _apiTournaments = apiTournaments;
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
        actions: const [],
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
          else
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // ── Tournaments slider (Crex-style, live only, logos) ──
                  if (_selectedSport == 'cricket' &&
                      _apiTournaments.isNotEmpty)
                    _TournamentsSlider(
                      tournaments: _apiTournaments,
                      isDark: isDark,
                      onTap: (tournament) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TournamentDetailScreen(
                              tournament: tournament,
                              isDark: isDark,
                            ),
                          ),
                        );
                      },
                    ),
                  if (_apiTournaments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(t('noMatches'),
                            style: const TextStyle(color: Colors.grey)),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Crex-style horizontal tournaments slider (active, with logos) ──
class _TournamentsSlider extends StatelessWidget {
  final List<Map<String, dynamic>> tournaments;
  final bool isDark;
  final void Function(Map<String, dynamic>) onTap;
  const _TournamentsSlider({
    required this.tournaments,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(14, 6, 14, 8),
          child: Text(
            'TOURNAMENTS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppColors.brandBlue,
            ),
          ),
        ),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: tournaments.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final t = tournaments[i];
              final logo = (t['logo_url'] ?? '').toString();
              return InkWell(
                onTap: () => onTap(t),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 96,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: isDark ? AppColors.darkCard : Colors.white,
                    border: Border.all(
                      color: isDark
                          ? Colors.white12
                          : Colors.black12,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (logo.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            logo,
                            width: 48,
                            height: 48,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.emoji_events,
                                    size: 40, color: AppColors.brandBlue),
                          ),
                        )
                      else
                        const Icon(Icons.emoji_events,
                            size: 40, color: AppColors.brandBlue),
                      const SizedBox(height: 8),
                      Text(
                        (t['name'] ?? '').toString(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ── Tournament detail: matches + stats of the selected tournament ──
class TournamentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> tournament;
  final bool isDark;
  const TournamentDetailScreen({
    super.key,
    required this.tournament,
    required this.isDark,
  });

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  List<Map<String, dynamic>> _matches = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final id = widget.tournament['tournament_id'].toString();
      final matches =
          await RapidApiService.fetchCricketTournamentMatches(id);
      if (mounted) {
        setState(() {
          _matches = matches;
          _loading = false;
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

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final name = widget.tournament['name']?.toString() ?? 'Tournament';
    final logo = widget.tournament['logo_url']?.toString() ?? '';
    final live = _matches
        .where((m) => (m['status_str'] ?? '').toString().toLowerCase() == 'live')
        .length;
    final upcoming = _matches
        .where((m) =>
            (m['status_str'] ?? '').toString().toLowerCase() == 'scheduled')
        .length;
    final done = _matches.length - live - upcoming;

    return Scaffold(
      appBar: AppBar(
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: Column(
        children: [
          // Header with logo + stats
          Container(
            padding: const EdgeInsets.all(16),
            color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
            child: Row(
              children: [
                if (logo.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(logo,
                        width: 56, height: 56, fit: BoxFit.contain),
                  )
                else
                  const Icon(Icons.emoji_events,
                      size: 56, color: AppColors.brandBlue),
                const SizedBox(width: 16),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _statChip('${_matches.length} matches',
                          AppColors.brandBlue),
                      if (live > 0)
                        _statChip('$live live', AppColors.liveRed),
                      if (upcoming > 0)
                        _statChip('$upcoming upcoming',
                            AppColors.upcomingAmber),
                      if (done > 0)
                        _statChip('$done done', AppColors.completedGrey),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(_error!,
                            style: const TextStyle(color: Colors.grey)))
                    : _matches.isEmpty
                        ? const Center(
                            child: Text('No matches in this tournament yet.',
                                style: TextStyle(color: Colors.grey)))
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _matches.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final m = _matches[i];
                              final teama = m['teama'] ?? {};
                              final teamb = m['teamb'] ?? {};
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: isDark
                                      ? AppColors.darkCard
                                      : Colors.white,
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white12
                                        : Colors.black12,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        _teamLogo(teama['logo_url']),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            teama['name']?.toString() ?? 'TBD',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                        _teamLogo(teamb['logo_url']),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            teamb['name']?.toString() ?? 'TBD',
                                            textAlign: TextAlign.right,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${m['format_str'] ?? ''} • ${m['status_str'] ?? ''}',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                    if (m['date_start'] != null)
                                      Text(
                                        m['date_start'].toString(),
                                        style: const TextStyle(
                                            fontSize: 11, color: Colors.grey),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _teamLogo(dynamic url) {
    if (url == null || url.toString().isEmpty) {
      return const SizedBox(width: 24, height: 24);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: Image.network(url.toString(),
          width: 24, height: 24, fit: BoxFit.cover),
    );
  }

  Widget _statChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
