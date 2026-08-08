import 'package:flutter/material.dart';
import '../data.dart';


// ── Sport-Specific Score Header ──────────────────────────────────────────────
class SportScoreHeader extends StatelessWidget {
  final MatchItem match;
  final bool isDark;
  final bool live;
  final Color statusColor;

  const SportScoreHeader({
    super.key,
    required this.match,
    required this.isDark,
    required this.live,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    switch (match.sport) {
      case 'football':
        return _FootballScoreHeader(match: match, isDark: isDark, live: live, statusColor: statusColor);
      case 'tennis':
        return _TennisScoreHeader(match: match, isDark: isDark, live: live, statusColor: statusColor);
      case 'tabletennis':
        return _TableTennisScoreHeader(match: match, isDark: isDark, live: live, statusColor: statusColor);
      case 'volleyball':
        return _VolleyballScoreHeader(match: match, isDark: isDark, live: live, statusColor: statusColor);
      case 'kabaddi':
        return _KabaddiScoreHeader(match: match, isDark: isDark, live: live, statusColor: statusColor);
      case 'hockey':
        return _HockeyScoreHeader(match: match, isDark: isDark, live: live, statusColor: statusColor);
      case 'baseball':
        return _BaseballScoreHeader(match: match, isDark: isDark, live: live, statusColor: statusColor);
      case 'esports':
        return _EsportsScoreHeader(match: match, isDark: isDark, live: live, statusColor: statusColor);
      default:
        return _GenericScoreHeader(match: match, isDark: isDark, live: live, statusColor: statusColor);
    }
  }
}

// ── Football Score Header ────────────────────────────────────────────────────
class _FootballScoreHeader extends StatelessWidget {
  final MatchItem match;
  final bool isDark;
  final bool live;
  final Color statusColor;
  const _FootballScoreHeader({required this.match, required this.isDark, required this.live, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StatusBar(match: match, live: live, statusColor: statusColor, icon: Icons.sports_soccer),
          const SizedBox(height: 12),
          Row(
            children: [
              _TeamScoreBlock(name: match.teamA, abbr: match.abbrA, logo: match.logoA, score: match.scoreA ?? '0', alignLeft: true),
              Column(
                children: [
                  Text('FT', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                    child: const Text('⚽', style: TextStyle(fontSize: 20)),
                  ),
                ],
              ),
              _TeamScoreBlock(name: match.teamB, abbr: match.abbrB, logo: match.logoB, score: match.scoreB ?? '0', alignLeft: false),
            ],
          ),
          if (match.result != null && match.result!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
              child: Text(match.result!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12), textAlign: TextAlign.center, maxLines: 2),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Tennis Score Header ──────────────────────────────────────────────────────
class _TennisScoreHeader extends StatelessWidget {
  final MatchItem match;
  final bool isDark;
  final bool live;
  final Color statusColor;
  const _TennisScoreHeader({required this.match, required this.isDark, required this.live, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    final sets = _parseTennisSets(match.scoreA, match.scoreB);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1A237E), const Color(0xFF283593)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StatusBar(match: match, live: live, statusColor: statusColor, icon: Icons.sports_tennis),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(match.teamA, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14), textAlign: TextAlign.left, overflow: TextOverflow.ellipsis)),
              Row(
                children: sets.map((s) => Container(
                  width: 28, margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                  child: Text('$s', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                )).toList(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: Text(match.teamB, style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w700, fontSize: 14), textAlign: TextAlign.left, overflow: TextOverflow.ellipsis)),
              Row(
                children: sets.map((s) => Container(
                  width: 28, margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                  child: const Text('-', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700, fontSize: 13)),
                )).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<int> _parseTennisSets(String? a, String? b) {
    if (a == null || b == null) return [0, 0, 0];
    final setA = a.split('-').map((s) => int.tryParse(s.trim()) ?? 0).toList();
    final setB = b.split('-').map((s) => int.tryParse(s.trim()) ?? 0).toList();
    final maxLen = setA.length > setB.length ? setA.length : setB.length;
    final sets = <int>[];
    for (int i = 0; i < maxLen; i++) {
      final sa = i < setA.length ? setA[i] : 0;
      sets.add(sa);
    }
    while (sets.length < 3) sets.add(0);
    return sets;
  }
}

// ── Table Tennis Score Header ────────────────────────────────────────────────
class _TableTennisScoreHeader extends StatelessWidget {
  final MatchItem match;
  final bool isDark;
  final bool live;
  final Color statusColor;
  const _TableTennisScoreHeader({required this.match, required this.isDark, required this.live, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF004D40), const Color(0xFF00695C)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StatusBar(match: match, live: live, statusColor: statusColor, icon: Icons.sports_tennis),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _PlayerRound(name: match.teamA, abbr: match.abbrA, label: 'Player 1'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(match.scoreA ?? '0', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28)),
              ),
              const Text('VS', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w800)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Text(match.scoreB ?? '0', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28)),
              ),
              _PlayerRound(name: match.teamB, abbr: match.abbrB, label: 'Player 2'),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Volleyball Score Header ──────────────────────────────────────────────────
class _VolleyballScoreHeader extends StatelessWidget {
  final MatchItem match;
  final bool isDark;
  final bool live;
  final Color statusColor;
  const _VolleyballScoreHeader({required this.match, required this.isDark, required this.live, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFE65100), const Color(0xFFFF6F00)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StatusBar(match: match, live: live, statusColor: statusColor, icon: Icons.sports_volleyball),
          const SizedBox(height: 12),
          Row(
            children: [
              _TeamScoreBlock(name: match.teamA, abbr: match.abbrA, logo: match.logoA, score: match.scoreA ?? '0', alignLeft: true),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                child: Text('SETS', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              _TeamScoreBlock(name: match.teamB, abbr: match.abbrB, logo: match.logoB, score: match.scoreB ?? '0', alignLeft: false),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Kabaddi Score Header ─────────────────────────────────────────────────────
class _KabaddiScoreHeader extends StatelessWidget {
  final MatchItem match;
  final bool isDark;
  final bool live;
  final Color statusColor;
  const _KabaddiScoreHeader({required this.match, required this.isDark, required this.live, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFBF360C), const Color(0xFFD84315)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StatusBar(match: match, live: live, statusColor: statusColor, icon: Icons.sports_kabaddi),
          const SizedBox(height: 12),
          Row(
            children: [
              _TeamScoreBlock(name: match.teamA, abbr: match.abbrA, logo: match.logoA, score: match.scoreA ?? '0', alignLeft: true),
              Column(
                children: [
                  Text('🤼', style: TextStyle(fontSize: 28)),
                  Text('KABADDI', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ],
              ),
              _TeamScoreBlock(name: match.teamB, abbr: match.abbrB, logo: match.logoB, score: match.scoreB ?? '0', alignLeft: false),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Hockey Score Header ──────────────────────────────────────────────────────
class _HockeyScoreHeader extends StatelessWidget {
  final MatchItem match;
  final bool isDark;
  final bool live;
  final Color statusColor;
  const _HockeyScoreHeader({required this.match, required this.isDark, required this.live, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF00695C), const Color(0xFF00897B)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StatusBar(match: match, live: live, statusColor: statusColor, icon: Icons.sports_hockey),
          const SizedBox(height: 12),
          Row(
            children: [
              _TeamScoreBlock(name: match.teamA, abbr: match.abbrA, logo: match.logoA, score: match.scoreA ?? '0', alignLeft: true),
              Column(
                children: [
                  Text('🏑', style: TextStyle(fontSize: 28)),
                  Text('HOCKEY', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ],
              ),
              _TeamScoreBlock(name: match.teamB, abbr: match.abbrB, logo: match.logoB, score: match.scoreB ?? '0', alignLeft: false),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Baseball Score Header ────────────────────────────────────────────────────
class _BaseballScoreHeader extends StatelessWidget {
  final MatchItem match;
  final bool isDark;
  final bool live;
  final Color statusColor;
  const _BaseballScoreHeader({required this.match, required this.isDark, required this.live, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1A237E), const Color(0xFFB71C1C)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StatusBar(match: match, live: live, statusColor: statusColor, icon: Icons.sports_baseball),
          const SizedBox(height: 12),
          Row(
            children: [
              _TeamScoreBlock(name: match.teamA, abbr: match.abbrA, logo: match.logoA, score: match.scoreA ?? '0', alignLeft: true),
              Column(
                children: [
                  Text('⚾', style: TextStyle(fontSize: 28)),
                  Text('INN ${match.matchType ?? ''}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w700)),
                ],
              ),
              _TeamScoreBlock(name: match.teamB, abbr: match.abbrB, logo: match.logoB, score: match.scoreB ?? '0', alignLeft: false),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Esports Score Header ─────────────────────────────────────────────────────
class _EsportsScoreHeader extends StatelessWidget {
  final MatchItem match;
  final bool isDark;
  final bool live;
  final Color statusColor;
  const _EsportsScoreHeader({required this.match, required this.isDark, required this.live, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF4A148C), const Color(0xFF6A1B9A)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StatusBar(match: match, live: live, statusColor: statusColor, icon: Icons.videogame_asset),
          const SizedBox(height: 12),
          Row(
            children: [
              _TeamScoreBlock(name: match.teamA, abbr: match.abbrA, logo: match.logoA, score: match.scoreA ?? '0', alignLeft: true),
              Column(
                children: [
                  Text('🎮', style: TextStyle(fontSize: 28)),
                  Text('BO${match.matchType ?? '3'}', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.w700)),
                ],
              ),
              _TeamScoreBlock(name: match.teamB, abbr: match.abbrB, logo: match.logoB, score: match.scoreB ?? '0', alignLeft: false),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Generic Score Header (fallback) ──────────────────────────────────────────
class _GenericScoreHeader extends StatelessWidget {
  final MatchItem match;
  final bool isDark;
  final bool live;
  final Color statusColor;
  const _GenericScoreHeader({required this.match, required this.isDark, required this.live, required this.statusColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1a1a2e), const Color(0xFF16213e)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _StatusBar(match: match, live: live, statusColor: statusColor, icon: Icons.sports),
          Row(
            children: [
              _TeamScoreBlock(name: match.teamA, abbr: match.abbrA, logo: match.logoA, score: match.scoreA ?? '-', alignLeft: true),
              const Text('VS', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w800)),
              _TeamScoreBlock(name: match.teamB, abbr: match.abbrB, logo: match.logoB, score: match.scoreB ?? '-', alignLeft: false),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared Sub-Widgets ──────────────────────────────────────────────────────
class _StatusBar extends StatelessWidget {
  final MatchItem match;
  final bool live;
  final Color statusColor;
  final IconData icon;
  const _StatusBar({required this.match, required this.live, required this.statusColor, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.white.withOpacity(0.6)),
        const SizedBox(width: 6),
        if (live)
          Container(
            width: 8, height: 8, margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(color: const Color(0xFFE53935), shape: BoxShape.circle, boxShadow: [BoxShadow(color: const Color(0xFFE53935).withOpacity(0.7), blurRadius: 6, spreadRadius: 1)]),
          ),
        Text(match.status, style: TextStyle(color: statusColor, fontWeight: FontWeight.w800, fontSize: 12, letterSpacing: 0.5)),
        const Spacer(),
        if (match.matchType != null && match.matchType!.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
            child: Text(match.matchType!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white70)),
          ),
      ],
    );
  }
}

class _TeamScoreBlock extends StatelessWidget {
  final String name;
  final String? abbr;
  final String? logo;
  final String score;
  final bool alignLeft;
  const _TeamScoreBlock({required this.name, this.abbr, this.logo, required this.score, required this.alignLeft});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: alignLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          if (logo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(logo!, width: 44, height: 44, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Icon(Icons.sports, size: 32, color: Colors.white.withOpacity(0.5))),
            ),
          const SizedBox(height: 6),
          Text(
            abbr ?? name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
            overflow: TextOverflow.ellipsis, textAlign: alignLeft ? TextAlign.left : TextAlign.right,
          ),
          Text(
            score,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24),
            textAlign: alignLeft ? TextAlign.left : TextAlign.right,
          ),
          Text(
            name,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
            overflow: TextOverflow.ellipsis, textAlign: alignLeft ? TextAlign.left : TextAlign.right,
          ),
        ],
      ),
    );
  }
}

class _PlayerRound extends StatelessWidget {
  final String name;
  final String? abbr;
  final String label;
  const _PlayerRound({required this.name, this.abbr, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(Icons.person, color: Colors.white, size: 22),
        ),
        const SizedBox(height: 4),
        Text(abbr ?? name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12), overflow: TextOverflow.ellipsis),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 9)),
      ],
    );
  }
}

// ── Sport-Specific Scorecard Tab ──────────────────────────────────────────────
class SportScorecardTab extends StatelessWidget {
  final MatchItem match;
  final bool isDark;

  const SportScorecardTab({super.key, required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    switch (match.sport) {
      case 'football':
        return _FootballScorecard(match: match, isDark: isDark);
      case 'tennis':
        return _TennisScorecard(match: match, isDark: isDark);
      case 'volleyball':
        return _VolleyballScorecard(match: match, isDark: isDark);
      case 'kabaddi':
        return _KabaddiScorecard(match: match, isDark: isDark);
      case 'baseball':
        return _BaseballScorecard(match: match, isDark: isDark);
      default:
        return _GenericScorecard(match: match, isDark: isDark);
    }
  }
}

class _FootballScorecard extends StatelessWidget {
  final MatchItem match;
  final bool isDark;
  const _FootballScorecard({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _StatCard(title: 'Match Stats', rows: [
          _StatRow('Possession', '52%', '48%'),
          _StatRow('Shots on Target', '4', '3'),
          _StatRow('Total Shots', '12', '9'),
          _StatRow('Corners', '6', '4'),
          _StatRow('Fouls', '8', '11'),
          _StatRow('Yellow Cards', '1', '2'),
          _StatRow('Offsides', '2', '3'),
        ], isDark: isDark),
        const SizedBox(height: 12),
        _StatCard(title: '${match.teamA} Lineup', rows: [
          _StatRow('Formation', '4-3-3', ''),
          _StatRow('Goalkeeper', '#1 Player', ''),
          _StatRow('Goals', match.scoreA ?? '0', ''),
        ], isDark: isDark),
        const SizedBox(height: 12),
        _StatCard(title: '${match.teamB} Lineup', rows: [
          _StatRow('Formation', '4-4-2', ''),
          _StatRow('Goalkeeper', '#1 Player', ''),
          _StatRow('Goals', match.scoreB ?? '0', ''),
        ], isDark: isDark),
      ],
    );
  }
}

class _TennisScorecard extends StatelessWidget {
  final MatchItem match;
  final bool isDark;
  const _TennisScorecard({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _StatCard(title: 'Match Summary', rows: [
          _StatRow('Sets Won', '0', '0'),
          _StatRow('Aces', '5', '3'),
          _StatRow('Double Faults', '2', '4'),
          _StatRow('1st Serve %', '68%', '62%'),
          _StatRow('Break Points', '3/7', '1/4'),
          _StatRow('Winners', '22', '18'),
          _StatRow('Unforced Errors', '15', '21'),
        ], isDark: isDark),
        const SizedBox(height: 12),
        _StatCard(title: 'Service Stats', rows: [
          _StatRow('Fastest Serve', '135 mph', '128 mph'),
          _StatRow('1st Serve Won', '78%', '72%'),
          _StatRow('2nd Serve Won', '52%', '48%'),
        ], isDark: isDark),
      ],
    );
  }
}

class _VolleyballScorecard extends StatelessWidget {
  final MatchItem match;
  final bool isDark;
  const _VolleyballScorecard({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _StatCard(title: 'Match Stats', rows: [
          _StatRow('Kills', '38', '35'),
          _StatRow('Blocks', '8', '6'),
          _StatRow('Aces', '5', '3'),
          _StatRow('Digs', '42', '39'),
          _StatRow('Assists', '36', '33'),
          _StatRow('Errors', '14', '18'),
        ], isDark: isDark),
      ],
    );
  }
}

class _KabaddiScorecard extends StatelessWidget {
  final MatchItem match;
  final bool isDark;
  const _KabaddiScorecard({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _StatCard(title: 'Match Stats', rows: [
          _StatRow('Total Points', match.scoreA ?? '0', match.scoreB ?? '0'),
          _StatRow('Raid Points', '12', '10'),
          _StatRow('Tackle Points', '8', '6'),
          _StatRow('ALL OUT', '2', '1'),
          _StatRow('Super Raids', '1', '0'),
          _StatRow('Super Tackles', '2', '1'),
        ], isDark: isDark),
      ],
    );
  }
}

class _BaseballScorecard extends StatelessWidget {
  final MatchItem match;
  final bool isDark;
  const _BaseballScorecard({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _StatCard(title: 'Box Score', rows: [
          _StatRow('Runs', match.scoreA ?? '0', match.scoreB ?? '0'),
          _StatRow('Hits', '9', '7'),
          _StatRow('Errors', '1', '2'),
          _StatRow('Home Runs', '2', '1'),
          _StatRow('Strikeouts', '8', '10'),
          _StatRow('Walks', '4', '3'),
          _StatRow('ERA', '3.50', '4.20'),
        ], isDark: isDark),
      ],
    );
  }
}

class _GenericScorecard extends StatelessWidget {
  final MatchItem match;
  final bool isDark;
  const _GenericScorecard({required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _StatCard(title: 'Score Summary', rows: [
          _StatRow(match.teamA, match.scoreA ?? '-', ''),
          _StatRow(match.teamB, match.scoreB ?? '-', ''),
        ], isDark: isDark),
      ],
    );
  }
}

// ── Sport-Specific Commentary Tab ────────────────────────────────────────────
class SportCommentaryTab extends StatelessWidget {
  final MatchItem match;
  final bool isDark;

  const SportCommentaryTab({super.key, required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final events = _mockEvents();
    if (events.isEmpty) {
      return Center(
        child: Text('Commentary not available yet.', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: events.length,
      itemBuilder: (_, i) {
        final e = events[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C2230) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: (e['color'] as Color).withOpacity(0.3)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: e['color'] as Color, borderRadius: BorderRadius.circular(4)),
                child: Text(e['time'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(e['text'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    if (e['detail'] != null)
                      Text(e['detail'] as String, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45)),
                  ],
                ),
              ),
              if (e['icon'] != null)
                Text(e['icon'] as String, style: const TextStyle(fontSize: 20)),
            ],
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _mockEvents() {
    final live = match.status == 'LIVE';
    if (!live && match.status != 'COMPLETED') return [];

    switch (match.sport) {
      case 'football':
        return [
          {'time': "90+3'", 'text': 'Full Time! ${match.result ?? "Match over"}', 'color': Colors.green, 'detail': 'Referee blows the final whistle', 'icon': '⚽'},
          {'time': "78'", 'text': 'GOAL! ${match.teamA} scores!', 'color': Colors.green, 'detail': 'Beautiful strike from outside the box', 'icon': '⚽'},
          {'time': "65'", 'text': 'Yellow Card - Player ${match.teamB}', 'color': const Color(0xFFFF9800), 'detail': 'Late challenge', 'icon': '🟡'},
          {'time': "55'", 'text': 'Corner kick for ${match.teamA}', 'color': const Color(0xFF2196F3), 'detail': 'Good delivery into the box', 'icon': '🚩'},
          {'time': "HT", 'text': 'Half Time', 'color': Colors.grey, 'detail': '${match.scoreA ?? "0"} - ${match.scoreB ?? "0"}', 'icon': '⏸️'},
        ];
      case 'tennis':
        return [
          {'time': 'GM 5', 'text': 'Ace! ${match.teamA} serving', 'color': const Color(0xFF2196F3), 'detail': 'Unreturnable serve down the T', 'icon': '🎾'},
          {'time': 'GM 4', 'text': 'Break Point saved by ${match.teamB}', 'color': const Color(0xFFFF9800), 'detail': 'Great serve under pressure', 'icon': '🎾'},
          {'time': 'SET 1', 'text': '${match.teamA} wins Set 1 6-4', 'color': Colors.green, 'detail': 'One set away from victory', 'icon': '🎾'},
        ];
      case 'volleyball':
        return [
          {'time': 'PT 22', 'text': 'Spike! Point ${match.teamA}', 'color': Colors.green, 'detail': 'Powerful spike down the line', 'icon': '🏐'},
          {'time': 'PT 20', 'text': 'Block! ${match.teamB} blocks', 'color': const Color(0xFF2196F3), 'detail': 'Excellent timing at the net', 'icon': '🏐'},
          {'time': 'SET 1', 'text': '${match.teamA} takes Set 1', 'color': Colors.green, 'detail': 'Close set 25-23', 'icon': '🏐'},
        ];
      case 'kabaddi':
        return [
          {'time': 'MIN 32', 'text': 'ALL OUT! ${match.teamA}', 'color': const Color(0xFFE53935), 'detail': 'Entire defense tackled', 'icon': '🤼'},
          {'time': 'MIN 28', 'text': 'Super Raid! +3 points', 'color': const Color(0xFFFF9800), 'detail': 'Raider touches 3 defenders', 'icon': '🤼'},
          {'time': 'MIN 25', 'text': 'Successful Raid - 1 point', 'color': const Color(0xFF2196F3), 'detail': 'Quick touch and return', 'icon': '🤼'},
        ];
      case 'hockey':
        return [
          {'time': 'Q3 5m', 'text': 'GOAL! ${match.teamA} scores', 'color': Colors.green, 'detail': 'Drag flick into the top corner', 'icon': '🏑'},
          {'time': 'Q2 10m', 'text': 'Penalty Corner for ${match.teamB}', 'color': const Color(0xFFFF9800), 'detail': 'Dangerous play', 'icon': '🏑'},
        ];
      case 'baseball':
        return [
          {'time': 'TOP 7', 'text': 'HOME RUN! ${match.teamA}', 'color': const Color(0xFFE53935), 'detail': 'Solo shot to left field', 'icon': '⚾'},
          {'time': 'BOT 6', 'text': 'Strikeout - Pitcher dominates', 'color': const Color(0xFF2196F3), 'detail': 'Swings and misses', 'icon': '⚾'},
          {'time': 'TOP 5', 'text': 'Double play! Inning over', 'color': const Color(0xFFFF9800), 'detail': '6-4-3 around the horn', 'icon': '⚾'},
        ];
      default:
        return [
          {'time': 'LIVE', 'text': '${match.teamA} vs ${match.teamB}', 'color': const Color(0xFF2196F3), 'detail': match.status},
        ];
    }
  }
}

// ── Sport-Specific Squads Tab ─────────────────────────────────────────────────
class SportSquadsTab extends StatelessWidget {
  final MatchItem match;
  final bool isDark;

  const SportSquadsTab({super.key, required this.match, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _SquadCard(teamName: match.teamA, players: _mockLineupA(), isDark: isDark),
        const SizedBox(height: 12),
        _SquadCard(teamName: match.teamB, players: _mockLineupB(), isDark: isDark),
      ],
    );
  }

  List<Map<String, String>> _mockLineupA() {
    switch (match.sport) {
      case 'football':
        return [for (int i = 1; i <= 11; i++) {'name': '${match.teamA} Player $i', 'role': i == 1 ? 'GK' : (i <= 4 ? 'DEF' : (i <= 8 ? 'MID' : 'FWD'))}];
      case 'tennis':
        return [{'name': match.teamA, 'role': 'Singles Player'}, {'name': 'Coach', 'role': 'Coach'}];
      case 'volleyball':
        return [for (int i = 1; i <= 6; i++) {'name': '${match.teamA} Player $i', 'role': i == 1 ? 'Setter' : (i <= 3 ? 'Spiker' : 'Libero')}];
      case 'kabaddi':
        return [for (int i = 1; i <= 7; i++) {'name': '${match.teamA} Player $i', 'role': i == 1 ? 'Raider' : 'Defender'}];
      case 'hockey':
        return [for (int i = 1; i <= 11; i++) {'name': '${match.teamA} Player $i', 'role': i == 1 ? 'GK' : (i <= 4 ? 'DEF' : (i <= 8 ? 'MID' : 'FWD'))}];
      case 'baseball':
        return [for (int i = 1; i <= 9; i++) {'name': '${match.teamA} Player $i', 'role': ['P', 'C', '1B', '2B', 'SS', '3B', 'LF', 'CF', 'RF'][i - 1]}];
      default:
        return [{'name': 'Player 1', 'role': 'Player'}];
    }
  }

  List<Map<String, String>> _mockLineupB() {
    switch (match.sport) {
      case 'football':
        return [for (int i = 1; i <= 11; i++) {'name': '${match.teamB} Player $i', 'role': i == 1 ? 'GK' : (i <= 4 ? 'DEF' : (i <= 8 ? 'MID' : 'FWD'))}];
      case 'tennis':
        return [{'name': match.teamB, 'role': 'Singles Player'}];
      case 'volleyball':
        return [for (int i = 1; i <= 6; i++) {'name': '${match.teamB} Player $i', 'role': i == 1 ? 'Setter' : (i <= 3 ? 'Spiker' : 'Libero')}];
      case 'kabaddi':
        return [for (int i = 1; i <= 7; i++) {'name': '${match.teamB} Player $i', 'role': i == 1 ? 'Raider' : 'Defender'}];
      case 'hockey':
        return [for (int i = 1; i <= 11; i++) {'name': '${match.teamB} Player $i', 'role': i == 1 ? 'GK' : (i <= 4 ? 'DEF' : (i <= 8 ? 'MID' : 'FWD'))}];
      case 'baseball':
        return [for (int i = 1; i <= 9; i++) {'name': '${match.teamB} Player $i', 'role': ['P', 'C', '1B', '2B', 'SS', '3B', 'LF', 'CF', 'RF'][i - 1]}];
      default:
        return [{'name': 'Player 2', 'role': 'Player'}];
    }
  }
}

class _SquadCard extends StatelessWidget {
  final String teamName;
  final List<Map<String, String>> players;
  final bool isDark;
  const _SquadCard({required this.teamName, required this.players, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2230) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF2196F3).withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.group, color: Color(0xFF2196F3), size: 18)),
              const SizedBox(width: 10),
              Text(teamName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const Spacer(),
              Text('${players.length} players', style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black45)),
            ],
          ),
          const SizedBox(height: 10),
          ...players.map((p) => Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.08)))),
            child: Row(
              children: [
                CircleAvatar(radius: 14, child: Text((p['name'] ?? '?')[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12))),
                const SizedBox(width: 10),
                Expanded(child: Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF2196F3).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text(p['role'] ?? '', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: Color(0xFF2196F3))),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

// ── Shared UI Components ─────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String title;
  final List<_StatRow> rows;
  final bool isDark;
  const _StatCard({required this.title, required this.rows, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C2230) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: isDark ? Colors.white60 : Colors.black45, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          ...rows.map((r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(width: 60, child: Text(r.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.black54))),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(r.left, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF2196F3))),
                      if (r.right.isNotEmpty) Text('-', style: TextStyle(color: isDark ? Colors.white38 : Colors.black26)),
                      if (r.right.isNotEmpty) Text(r.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFE53935))),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class _StatRow {
  final String label;
  final String left;
  final String right;
  const _StatRow(this.label, this.left, this.right);
}
