// Sports list + mock match & news data for the Fanconnact app.
// Later this will be replaced by the real backend API.

class Sport {
  final String key;
  final String name;
  final String emoji;

  const Sport({required this.key, required this.name, required this.emoji});
}

// "all" is the default selection — shows every sport's content.
const List<Sport> sports = [
  Sport(key: 'all', name: 'All Sports', emoji: '🏟️'),
  Sport(key: 'cricket', name: 'Cricket', emoji: '🏏'),
  Sport(key: 'football', name: 'Football', emoji: '⚽'),
  Sport(key: 'basketball', name: 'Basketball', emoji: '🏀'),
  Sport(key: 'tennis', name: 'Tennis', emoji: '🎾'),
  Sport(key: 'hockey', name: 'Hockey', emoji: '🏑'),
  Sport(key: 'kabaddi', name: 'Kabaddi', emoji: '🤼'),
  Sport(key: 'baseball', name: 'Baseball', emoji: '⚾'),
  Sport(key: 'volleyball', name: 'Volleyball', emoji: '🏐'),
  Sport(key: 'tabletennis', name: 'Table Tennis', emoji: '🏓'),
  Sport(key: 'esports', name: 'E-Sports', emoji: '🎮'),

];

String? _overFromScore(String s) {
  final re = RegExp(r'\((\d+(?:\.\d+)?)\)');
  final match = re.firstMatch(s);
  return match?.group(1);
}

class MatchItem {
  final String sport;
  final String sportEmoji;
  final String series;
  final String teamA;
  final String teamB;
  final String? logoA;
  final String? logoB;
  final String? abbrA;
  final String? abbrB;
  final String? scoreA;
  final String? scoreB;
  final String? overA;
  final String? overB;
  final String status; // "LIVE", "UPCOMING", "COMPLETED"
  final String time;
  final String? matchId;
  final String? result;
  final String? toss;
  final String? matchType;
  final String? venue;
  final String? seriesId;
  final String? teamIdA;
  final String? teamIdB;

  const MatchItem({
    required this.sport,
    required this.sportEmoji,
    required this.series,
    required this.teamA,
    required this.teamB,
    this.logoA,
    this.logoB,
    this.abbrA,
    this.abbrB,
    this.scoreA,
    this.scoreB,
    this.overA,
    this.overB,
    required this.status,
    required this.time,
    this.matchId,
    this.result,
    this.toss,
    this.matchType,
    this.venue,
    this.seriesId,
    this.teamIdA,
    this.teamIdB,
  });

  // Build from cricket-live-line-advance /matches endpoint.
  factory MatchItem.fromCricketAdvance(Map<String, dynamic> m) {
    final teama = m['teama'] is Map ? Map<String, dynamic>.from(m['teama']) : <String, dynamic>{};
    final teamb = m['teamb'] is Map ? Map<String, dynamic>.from(m['teamb']) : <String, dynamic>{};
    final comp = m['competition'] is Map ? Map<String, dynamic>.from(m['competition']) : <String, dynamic>{};
    final statusRaw = (m['status_str'] ?? '').toString().toUpperCase();
    final status = statusRaw == 'LIVE' ? 'LIVE' : (statusRaw == 'COMPLETED' ? 'COMPLETED' : 'UPCOMING');
    final scoreA = (teama['scores_full'] ?? '').toString().isNotEmpty
        ? teama['scores_full'].toString()
        : (teama['scores']?.toString() ?? '');
    final scoreB = (teamb['scores_full'] ?? '').toString().isNotEmpty
        ? teamb['scores_full'].toString()
        : (teamb['scores']?.toString() ?? '');

    final format = comp['match_format']?.toString() ?? m['format_str']?.toString() ?? '';
    return MatchItem(
      sport: 'cricket',
      sportEmoji: '🏏',
      series: comp['title']?.toString() ?? '',
      teamA: teama['name']?.toString() ?? m['title']?.toString() ?? 'Team A',
      teamB: teamb['name']?.toString() ?? m['title']?.toString() ?? 'Team B',
      logoA: teama['logo_url']?.toString(),
      logoB: teamb['logo_url']?.toString(),
      abbrA: teama['short_name']?.toString(),
      abbrB: teamb['short_name']?.toString(),
      scoreA: scoreA.isNotEmpty ? scoreA : null,
      scoreB: scoreB.isNotEmpty ? scoreB : null,
      overA: scoreA.isNotEmpty ? _overFromScore(scoreA) : null,
      overB: scoreB.isNotEmpty ? _overFromScore(scoreB) : null,
      status: status,
      time: m['date_start_ist']?.toString() ?? m['timestamp_start']?.toString() ?? '',
      matchId: m['match_id']?.toString(),
      result: m['result']?.toString(),
      toss: m['toss'] is Map ? m['toss']['text']?.toString() : null,
      matchType: format.isNotEmpty ? format : null,
      venue: m['venue'] is Map ? m['venue']['name']?.toString() : (m['venue']?.toString()),
    );
  }

  // Build from the backend /api/matches payload (ESPN real data).
  factory MatchItem.fromApi(Map<String, dynamic> m, {String sportKey = 'all'}) {
    const emojiMap = {
      'football': '⚽',
      'basketball': '🏀',
      'hockey': '🏑',
      'baseball': '⚾',
      'tennis': '🎾',
      'cricket': '🏏',
      'volleyball': '🏐',
      'tabletennis': '🏓',
      'kabaddi': '🤼',
      'esports': '🎮',

    };
    return MatchItem(
      sport: sportKey,
      sportEmoji: emojiMap[sportKey] ?? '🏟️',
      series: (m['league'] ?? '').toString(),
      teamA: (m['homeName'] ?? 'TBD').toString(),
      teamB: (m['awayName'] ?? 'TBD').toString(),
      logoA: (m['homeLogo'] ?? '').toString().isNotEmpty
          ? m['homeLogo'].toString()
          : null,
      logoB: (m['awayLogo'] ?? '').toString().isNotEmpty
          ? m['awayLogo'].toString()
          : null,
      abbrA: (m['homeAbbr'] ?? '').toString().isNotEmpty
          ? m['homeAbbr'].toString()
          : null,
      abbrB: (m['awayAbbr'] ?? '').toString().isNotEmpty
          ? m['awayAbbr'].toString()
          : null,
      scoreA: (m['homeScore'] ?? '').toString().isNotEmpty
          ? m['homeScore'].toString()
          : null,
      scoreB: (m['awayScore'] ?? '').toString().isNotEmpty
          ? m['awayScore'].toString()
          : null,
      overA: (m['homeOver'] ?? '').toString().isNotEmpty
          ? m['homeOver'].toString()
          : (m['homeScore'] ?? '').toString().isNotEmpty
              ? _overFromScore(m['homeScore'].toString())
              : null,
      overB: (m['awayOver'] ?? '').toString().isNotEmpty
          ? m['awayOver'].toString()
          : (m['awayScore'] ?? '').toString().isNotEmpty
              ? _overFromScore(m['awayScore'].toString())
              : null,
      status: (m['status'] ?? 'UPCOMING').toString(),
      time: (m['time'] ?? '').toString(),
      matchId: ((m['matchId'] ?? m['match_id'] ?? '').toString()).isNotEmpty
          ? (m['matchId'] ?? m['match_id']).toString()
          : null,
      teamIdA: ((m['teamIdA'] ?? m['homeId'] ?? '').toString()).isNotEmpty
          ? (m['teamIdA'] ?? m['homeId']).toString()
          : null,
      teamIdB: ((m['teamIdB'] ?? m['awayId'] ?? '').toString()).isNotEmpty
          ? (m['teamIdB'] ?? m['awayId']).toString()
          : null,
      result: (m['result'] ?? '').toString().isNotEmpty
          ? m['result'].toString()
          : null,
      toss: (m['toss'] ?? '').toString().isNotEmpty
          ? m['toss'].toString()
          : null,
      matchType: (m['matchType'] ?? '').toString().isNotEmpty
          ? m['matchType'].toString()
          : null,
      venue: (m['venue'] ?? '').toString().isNotEmpty
          ? m['venue'].toString()
          : null,
      seriesId: (m['seriesId'] ?? '').toString().isNotEmpty
          ? m['seriesId'].toString()
          : null,
    );
  }
}

class NewsItem {
  final String sport;
  final String sportEmoji;
  final String title;
  final String source;
  final String timeAgo;
  final String tag;
  final String? image;
  final String? description;
  final String? link;

  const NewsItem({
    required this.sport,
    required this.sportEmoji,
    required this.title,
    required this.source,
    required this.timeAgo,
    required this.tag,
    this.image,
    this.description,
    this.link,
  });
}

// ─── Mock news feed (replaces "reels" from Crex-style layout) ────
// NOTE: This is only used as the initial empty-state placeholder in
// HomeScreen before real API data loads. The app never renders static
// match data — all matches come from LiveMatchService (backend API).
const List<NewsItem> news = [
  NewsItem(
    sport: 'cricket',
    sportEmoji: '🏏',
    title: 'Kohli smashes 71* as India dominate the powerplay',
    source: 'Fanconnact Sports',
    timeAgo: '12m ago',
    tag: 'MATCH REPORT',
  ),
  NewsItem(
    sport: 'football',
    sportEmoji: '⚽',
    title: 'Late winner sends Arsenal top of the table',
    source: 'Fanconnact Sports',
    timeAgo: '34m ago',
    tag: 'GOAL',
  ),
  NewsItem(
    sport: 'basketball',
    sportEmoji: '🏀',
    title: 'LeBron drops 38 as Lakers edge closer to playoffs',
    source: 'Court Side',
    timeAgo: '1h ago',
    tag: 'HIGHLIGHTS',
  ),
  NewsItem(
    sport: 'tennis',
    sportEmoji: '🎾',
    title: 'Alcaraz saves 3 match points in epic comeback',
    source: 'Net News',
    timeAgo: '2h ago',
    tag: 'FEATURE',
  ),
  NewsItem(
    sport: 'kabaddi',
    sportEmoji: '🤼',
    title: 'Bulls clinch thriller in the final raid of the match',
    source: 'Mat Pulse',
    timeAgo: '3h ago',
    tag: 'REPORT',
  ),
];
