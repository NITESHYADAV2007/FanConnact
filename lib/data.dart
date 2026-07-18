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

class MatchItem {
  final String sport;
  final String sportEmoji;
  final String series;
  final String teamA;
  final String teamB;
  final String? scoreA;
  final String? scoreB;
  final String status; // "LIVE", "UPCOMING", "COMPLETED"
  final String time;

  const MatchItem({
    required this.sport,
    required this.sportEmoji,
    required this.series,
    required this.teamA,
    required this.teamB,
    this.scoreA,
    this.scoreB,
    required this.status,
    required this.time,
  });
}

class NewsItem {
  final String sport;
  final String sportEmoji;
  final String title;
  final String source;
  final String timeAgo;
  final String tag;

  const NewsItem({
    required this.sport,
    required this.sportEmoji,
    required this.title,
    required this.source,
    required this.timeAgo,
    required this.tag,
  });
}

// ─── Mock matches ───────────────────────────────────────────────
const List<MatchItem> matches = [
  MatchItem(
    sport: 'cricket',
    sportEmoji: '🏏',
    series: 'IND vs AUS • 3rd T20I',
    teamA: 'India',
    teamB: 'Australia',
    scoreA: '182/4',
    scoreB: '176/9',
    status: 'LIVE',
    time: '16.2 ov',
  ),
  MatchItem(
    sport: 'football',
    sportEmoji: '⚽',
    series: 'Premier League • Matchday 12',
    teamA: 'Arsenal',
    teamB: 'Chelsea',
    scoreA: '2',
    scoreB: '1',
    status: 'LIVE',
    time: '67\'',
  ),
  MatchItem(
    sport: 'basketball',
    sportEmoji: '🏀',
    series: 'NBA • Regular Season',
    teamA: 'Lakers',
    teamB: 'Celtics',
    status: 'UPCOMING',
    time: 'Tonight 8:30 PM',
  ),
  MatchItem(
    sport: 'tennis',
    sportEmoji: '🎾',
    series: 'Wimbledon • Quarter Final',
    teamA: 'Djokovic',
    teamB: 'Alcaraz',
    status: 'UPCOMING',
    time: 'Tomorrow 3:00 PM',
  ),
  MatchItem(
    sport: 'kabaddi',
    sportEmoji: '🤼',
    series: 'Pro Kabaddi • Match 45',
    teamA: 'Bengaluru Bulls',
    teamB: 'Patna Pirates',
    scoreA: '34',
    scoreB: '31',
    status: 'COMPLETED',
    time: 'FT',
  ),
  MatchItem(
    sport: 'hockey',
    sportEmoji: '🏑',
    series: 'Hockey WC • Pool A',
    teamA: 'India',
    teamB: 'Germany',
    status: 'UPCOMING',
    time: 'Sun 6:00 PM',
  ),
];

// ─── Mock news feed (replaces "reels" from Crex-style layout) ────
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
