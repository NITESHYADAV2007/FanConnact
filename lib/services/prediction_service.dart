import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prediction_models.dart';
import '../models/prediction_enums.dart';
import '../data.dart';
import 'live_match_service.dart';

class PredictionService {
  static final Random _random = Random();

  static List<PredictionGame> generateGamesFromMatches(List<MatchItem> matches) {
    return matches.map((m) {
      final isLive = m.status == 'LIVE';
      final isUpcoming = m.status == 'UPCOMING' || m.status == 'SCHEDULED';
      final status = isLive ? 'live' : (isUpcoming ? 'upcoming' : 'completed');

      return PredictionGame(
        id: m.matchId ?? 'match_${matches.indexOf(m)}',
        sportKey: m.sport,
        teamA: m.teamA,
        teamB: m.teamB,
        logoA: m.logoA,
        logoB: m.logoB,
        series: m.series,
        venue: m.venue ?? 'TBD',
        startTime: _parseMatchTime(m.time) ?? DateTime.now().add(Duration(hours: _random.nextInt(48))),
        status: status,
        scoreA: m.scoreA,
        scoreB: m.scoreB,
        overA: m.overA,
        overB: m.overB,
        markets: _generateMarketsForSport(m.sport, m.teamA, m.teamB, isLive: isLive, match: m),
        isTrending: _random.nextBool(),
        totalPredictions: _random.nextInt(5000) + 100,
      );
    }).toList();
  }

  static List<PredictionMarket> _generateMarketsForSport(
      String sport, String teamA, String teamB,
      {bool isLive = false, MatchItem? match}) {
    final List<PredictionMarket> markets = switch (sport) {
      'cricket' => _generateCricketMarkets(teamA, teamB),
      'football' => _generateFootballMarkets(teamA, teamB),
      'basketball' => _generateBasketballMarkets(teamA, teamB),
      'tennis' => _generateTennisMarkets(teamA, teamB),
      _ => _generateGenericMarkets(teamA, teamB),
    };
    if (isLive && match != null) {
      markets.addAll(_generateLiveMarkets(sport, match));
    }
    return markets;
  }

  /// Live-only markets generated from the match's current state so the
  /// questions automatically follow what is happening in the real game.
  static List<PredictionMarket> _generateLiveMarkets(String sport, MatchItem m) {
    final markets = <PredictionMarket>[];
    if (sport == 'cricket') {
      final runs = _parseLeadingInt(m.scoreA);
      if (runs != null) {
        final target = (runs ~/ 50) * 50 + 50;
        markets.add(PredictionMarket(
          id: 'market_live_total',
          gameId: '',
          question: 'Will ${m.teamA} reach a total of $target+ runs?',
          type: MarketType.overUnder,
          options: [
            PredictionOption(id: 'live_total_yes', label: 'Yes', odds: 1.85, probability: 0.52, totalPicks: 640),
            PredictionOption(id: 'live_total_no', label: 'No', odds: 1.95, probability: 0.48, totalPicks: 520),
          ],
        ));
      }
      markets.add(PredictionMarket(
        id: 'market_next_wicket',
        gameId: '',
        question: 'Next Wicket Method (Live)',
        type: MarketType.methodDismissal,
        options: [
          PredictionOption(id: 'dismiss_caught', label: 'Caught', odds: 1.65, probability: 0.58, totalPicks: 1240),
          PredictionOption(id: 'dismiss_bowled', label: 'Bowled', odds: 3.2, probability: 0.25, totalPicks: 520),
          PredictionOption(id: 'dismiss_lbw', label: 'LBW', odds: 4.0, probability: 0.15, totalPicks: 280),
          PredictionOption(id: 'dismiss_runout', label: 'Run Out', odds: 8.0, probability: 0.02, totalPicks: 40),
        ],
      ));
    } else if (sport == 'football' || sport == 'hockey') {
      markets.add(PredictionMarket(
        id: 'market_next_goal',
        gameId: '',
        question: 'Will there be another goal this match?',
        type: MarketType.custom,
        options: [
          PredictionOption(id: 'goal_yes', label: 'Yes', odds: 1.75, probability: 0.55, totalPicks: 980),
          PredictionOption(id: 'goal_no', label: 'No', odds: 2.05, probability: 0.45, totalPicks: 760),
        ],
      ));
    }
    return markets;
  }

  static List<PredictionMarket> _generateCricketMarkets(String teamA, String teamB) {
    final markets = <PredictionMarket>[];

    markets.add(PredictionMarket(
      id: 'market_winner',
      gameId: '',
      question: 'Match Winner',
      type: MarketType.winner,
      options: [
        PredictionOption(id: 'opt_a', label: teamA, odds: 1.85, probability: 0.52, totalPicks: 2340),
        PredictionOption(id: 'opt_b', label: teamB, odds: 1.95, probability: 0.48, totalPicks: 1890),
      ],
    ));

    markets.add(PredictionMarket(
      id: 'market_toss',
      gameId: '',
      question: 'Toss Winner',
      type: MarketType.toss,
      options: [
        PredictionOption(id: 'toss_a', label: '$teamA wins toss', odds: 2.0, probability: 0.5, totalPicks: 1100),
        PredictionOption(id: 'toss_b', label: '$teamB wins toss', odds: 2.0, probability: 0.5, totalPicks: 980),
      ],
    ));

    markets.add(PredictionMarket(
      id: 'market_toss_decision',
      gameId: '',
      question: 'Toss Decision',
      type: MarketType.custom,
      options: [
        PredictionOption(id: 'bat_first', label: 'Bat First', odds: 1.75, probability: 0.57, totalPicks: 1450),
        PredictionOption(id: 'bowl_first', label: 'Bowl First', odds: 2.1, probability: 0.43, totalPicks: 890),
      ],
    ));

    markets.add(PredictionMarket(
      id: 'market_top_batter',
      gameId: '',
      question: 'Top Batter',
      type: MarketType.topBatter,
      options: [
        PredictionOption(id: 'bat_1', label: 'Player A ($teamA)', odds: 3.5, probability: 0.25, totalPicks: 560),
        PredictionOption(id: 'bat_2', label: 'Player B ($teamA)', odds: 4.2, probability: 0.21, totalPicks: 420),
        PredictionOption(id: 'bat_3', label: 'Player C ($teamB)', odds: 3.8, probability: 0.23, totalPicks: 480),
        PredictionOption(id: 'bat_4', label: 'Player D ($teamB)', odds: 5.0, probability: 0.18, totalPicks: 310),
        PredictionOption(id: 'bat_5', label: 'Other', odds: 6.5, probability: 0.13, totalPicks: 180),
      ],
    ));

    markets.add(PredictionMarket(
      id: 'market_powerplay',
      gameId: '',
      question: 'Powerplay Runs (0-6 overs)',
      type: MarketType.powerplayRuns,
      options: [
        PredictionOption(id: 'pp_0_30', label: '0-30 runs', odds: 4.5, probability: 0.15, totalPicks: 210),
        PredictionOption(id: 'pp_31_45', label: '31-45 runs', odds: 2.2, probability: 0.38, totalPicks: 890),
        PredictionOption(id: 'pp_46_60', label: '46-60 runs', odds: 2.5, probability: 0.32, totalPicks: 720),
        PredictionOption(id: 'pp_60_plus', label: '60+ runs', odds: 5.5, probability: 0.15, totalPicks: 180),
      ],
    ));

    markets.add(PredictionMarket(
      id: 'market_total_sixes',
      gameId: '',
      question: 'Total Sixes in Match',
      type: MarketType.totalSixes,
      options: [
        PredictionOption(id: 'six_0_5', label: '0-5 sixes', odds: 2.8, probability: 0.30, totalPicks: 560),
        PredictionOption(id: 'six_6_10', label: '6-10 sixes', odds: 2.1, probability: 0.40, totalPicks: 980),
        PredictionOption(id: 'six_11_15', label: '11-15 sixes', odds: 3.2, probability: 0.22, totalPicks: 410),
        PredictionOption(id: 'six_16_plus', label: '16+ sixes', odds: 6.0, probability: 0.08, totalPicks: 120),
      ],
    ));

    markets.add(PredictionMarket(
      id: 'market_first_wicket',
      gameId: '',
      question: 'Method of First Dismissal',
      type: MarketType.methodDismissal,
      options: [
        PredictionOption(id: 'dismiss_caught', label: 'Caught', odds: 1.65, probability: 0.58, totalPicks: 1240),
        PredictionOption(id: 'dismiss_bowled', label: 'Bowled', odds: 3.2, probability: 0.25, totalPicks: 520),
        PredictionOption(id: 'dismiss_lbw', label: 'LBW', odds: 4.0, probability: 0.15, totalPicks: 280),
        PredictionOption(id: 'dismiss_runout', label: 'Run Out', odds: 8.0, probability: 0.02, totalPicks: 40),
      ],
    ));

    return markets;
  }

  static List<PredictionMarket> _generateFootballMarkets(String teamA, String teamB) {
    return [
      PredictionMarket(
        id: 'market_winner',
        gameId: '',
        question: 'Match Winner',
        type: MarketType.winner,
        options: [
          PredictionOption(id: 'opt_a', label: teamA, odds: 2.1, probability: 0.42, totalPicks: 3200),
          PredictionOption(id: 'opt_draw', label: 'Draw', odds: 3.4, probability: 0.26, totalPicks: 1800),
          PredictionOption(id: 'opt_b', label: teamB, odds: 3.2, probability: 0.32, totalPicks: 2100),
        ],
      ),
      PredictionMarket(
        id: 'market_first_goal',
        gameId: '',
        question: 'First Goal Scorer',
        type: MarketType.custom,
        options: [
          PredictionOption(id: 'fg_a1', label: 'Striker A ($teamA)', odds: 4.5, probability: 0.18, totalPicks: 450),
          PredictionOption(id: 'fg_a2', label: 'Midfielder A ($teamA)', odds: 6.0, probability: 0.12, totalPicks: 280),
          PredictionOption(id: 'fg_b1', label: 'Striker B ($teamB)', odds: 5.0, probability: 0.15, totalPicks: 380),
          PredictionOption(id: 'fg_b2', label: 'Midfielder B ($teamB)', odds: 7.5, probability: 0.1, totalPicks: 190),
          PredictionOption(id: 'fg_none', label: 'No Goal', odds: 12.0, probability: 0.05, totalPicks: 80),
        ],
      ),
      PredictionMarket(
        id: 'market_total_goals',
        gameId: '',
        question: 'Total Goals',
        type: MarketType.overUnder,
        options: [
          PredictionOption(id: 'goals_0_1', label: '0-1 goals', odds: 2.8, probability: 0.3, totalPicks: 800),
          PredictionOption(id: 'goals_2_3', label: '2-3 goals', odds: 1.9, probability: 0.45, totalPicks: 1650),
          PredictionOption(id: 'goals_4_plus', label: '4+ goals', odds: 4.2, probability: 0.25, totalPicks: 650),
        ],
      ),
      PredictionMarket(
        id: 'market_both_score',
        gameId: '',
        question: 'Both Teams to Score',
        type: MarketType.custom,
        options: [
          PredictionOption(id: 'btts_yes', label: 'Yes', odds: 1.8, probability: 0.52, totalPicks: 1450),
          PredictionOption(id: 'btts_no', label: 'No', odds: 2.05, probability: 0.48, totalPicks: 1200),
        ],
      ),
    ];
  }

  static List<PredictionMarket> _generateBasketballMarkets(String teamA, String teamB) {
    return [
      PredictionMarket(
        id: 'market_winner',
        gameId: '',
        question: 'Match Winner (incl. OT)',
        type: MarketType.winner,
        options: [
          PredictionOption(id: 'opt_a', label: teamA, odds: 1.75, probability: 0.54, totalPicks: 2800),
          PredictionOption(id: 'opt_b', label: teamB, odds: 2.1, probability: 0.46, totalPicks: 2100),
        ],
      ),
      PredictionMarket(
        id: 'market_total_points',
        gameId: '',
        question: 'Total Points',
        type: MarketType.overUnder,
        options: [
          PredictionOption(id: 'pts_under', label: 'Under 215.5', odds: 1.9, probability: 0.5, totalPicks: 1450),
          PredictionOption(id: 'pts_over', label: 'Over 215.5', odds: 1.9, probability: 0.5, totalPicks: 1450),
        ],
      ),
      PredictionMarket(
        id: 'market_player_points',
        gameId: '',
        question: 'Top Scorer',
        type: MarketType.playerPerformance,
        options: [
          PredictionOption(id: 'ps_a1', label: 'Star A ($teamA) - 25.5+ pts', odds: 1.85, probability: 0.51, totalPicks: 1200),
          PredictionOption(id: 'ps_a2', label: 'Star B ($teamA) - 20.5+ pts', odds: 2.1, probability: 0.44, totalPicks: 980),
          PredictionOption(id: 'ps_b1', label: 'Star C ($teamB) - 28.5+ pts', odds: 1.75, probability: 0.54, totalPicks: 1350),
        ],
      ),
    ];
  }

  static List<PredictionMarket> _generateTennisMarkets(String playerA, String playerB) {
    return [
      PredictionMarket(
        id: 'market_winner',
        gameId: '',
        question: 'Match Winner',
        type: MarketType.winner,
        options: [
          PredictionOption(id: 'opt_a', label: playerA, odds: 1.6, probability: 0.6, totalPicks: 1800),
          PredictionOption(id: 'opt_b', label: playerB, odds: 2.3, probability: 0.4, totalPicks: 1100),
        ],
      ),
      PredictionMarket(
        id: 'market_sets',
        gameId: '',
        question: 'Total Sets',
        type: MarketType.overUnder,
        options: [
          PredictionOption(id: 'sets_2', label: '2 sets (straight)', odds: 2.2, probability: 0.4, totalPicks: 720),
          PredictionOption(id: 'sets_3', label: '3 sets', odds: 1.75, probability: 0.6, totalPicks: 1300),
        ],
      ),
    ];
  }

  static List<PredictionMarket> _generateGenericMarkets(String teamA, String teamB) {
    return [
      PredictionMarket(
        id: 'market_winner',
        gameId: '',
        question: 'Match Winner',
        type: MarketType.winner,
        options: [
          PredictionOption(id: 'opt_a', label: teamA, odds: 1.9, probability: 0.5, totalPicks: 1500),
          PredictionOption(id: 'opt_b', label: teamB, odds: 1.9, probability: 0.5, totalPicks: 1500),
        ],
      ),
    ];
  }

  static List<PredictionGame> getTrendingGames(List<PredictionGame> allGames) {
    final trending = allGames.where((g) => g.isTrending).toList();
    trending.sort((a, b) => b.totalPredictions.compareTo(a.totalPredictions));
    return trending.take(5).toList();
  }

  static List<PredictionGame> getLiveGames(List<PredictionGame> allGames) {
    return allGames.where((g) => g.isLive).toList();
  }

  static List<PredictionGame> getUpcomingGames(List<PredictionGame> allGames) {
    return allGames.where((g) => g.isUpcoming).toList();
  }

  static DateTime? _parseMatchTime(String? timeStr) {
    if (timeStr == null) return null;
    try {
      return DateTime.parse(timeStr);
    } catch (_) {
      return null;
    }
  }

  /// Auto-resolves pending predictions as soon as their match is finished.
  /// Winner markets use the real final score; toss markets use the real toss
  /// result; any other market is voided. Winning picks credit coins.
  static Future<int> resolveDuePredictions(String uid) async {
    try {
      final db = FirebaseFirestore.instance;
      final pendingSnap = await db
          .collection('predictions')
          .where('uid', isEqualTo: uid)
          .limit(200)
          .get();
      final preds = pendingSnap.docs
          .where((d) => (d.data()['status'] ?? 'pending') == 'pending')
          .toList();
      if (preds.isEmpty) return 0;

      final matches = <String, MatchItem>{};
      try {
        final list = await LiveMatchService.fetchLiveMatches(sport: 'all');
        for (final m in list) {
          if (m.matchId != null) matches[m.matchId!] = m;
        }
      } catch (_) {}

      int resolved = 0;
      for (final doc in preds) {
        final p = doc.data();
        final match = matches[(p['gameId'] ?? '').toString()];
        if (match == null || match.status != 'COMPLETED') continue;

        final marketId = (p['marketId'] ?? '').toString();
        try {
          await db.runTransaction((tx) async {
            final ref = db.collection('predictions').doc(doc.id);
            final snap = await tx.get(ref);
            if (!snap.exists) return;
            if ((snap.get('status') ?? 'pending') != 'pending') return;

            final newStatus = _resolveStatus(marketId, p, match);

            tx.update(ref, {
              'status': newStatus.name,
              'resolvedAt': FieldValue.serverTimestamp(),
            });

            if (newStatus == PredictionStatus.won) {
              final potentialWin = (p['potentialWin'] as num?)?.toInt() ?? 0;
              if (potentialWin > 0) {
                tx.update(db.collection('users').doc(uid), {
                  'coins': FieldValue.increment(potentialWin),
                });
                tx.set(db.collection('transactions').doc(), {
                  'userId': uid,
                  'amount': potentialWin,
                  'description': 'Prediction won: ${match.teamA} vs ${match.teamB}',
                  'date': DateTime.now().toIso8601String(),
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }
            }
          });
          resolved++;
        } catch (_) {}
      }
      return resolved;
    } catch (_) {
      return 0;
    }
  }

  static PredictionStatus _resolveStatus(
      String marketId, Map<String, dynamic> p, MatchItem match) {
    if (marketId == 'market_winner') {
      final winner = _deriveWinner(match);
      if (winner == null) return PredictionStatus.voided;
      final picked = _pickedOptionLabel(p, match);
      if (picked == null) return PredictionStatus.voided;
      return picked.toLowerCase().trim() == winner.toLowerCase().trim()
          ? PredictionStatus.won
          : PredictionStatus.lost;
    }
    if (marketId == 'market_toss') {
      final toss = (match.toss ?? '').toLowerCase();
      if (toss.isEmpty) return PredictionStatus.voided;
      final picked = _pickedOptionLabel(p, match);
      if (picked == null) return PredictionStatus.voided;
      final tossWinner = toss.contains(match.teamA.toLowerCase())
          ? match.teamA
          : toss.contains(match.teamB.toLowerCase())
              ? match.teamB
              : null;
      if (tossWinner == null) return PredictionStatus.voided;
      return picked.toLowerCase().contains(tossWinner.toLowerCase())
          ? PredictionStatus.won
          : PredictionStatus.lost;
    }
    return PredictionStatus.voided;
  }

  static String? _deriveWinner(MatchItem m) {
    final scoreA = _parseLeadingInt(m.scoreA);
    final scoreB = _parseLeadingInt(m.scoreB);
    if (scoreA != null && scoreB != null && scoreA != scoreB) {
      return scoreA > scoreB ? m.teamA : m.teamB;
    }
    if (scoreA != null && scoreB != null && scoreA == scoreB) return 'Draw';
    final res = (m.result ?? '').toLowerCase();
    if (res.isNotEmpty) {
      if (res.contains(m.teamA.toLowerCase())) return m.teamA;
      if (res.contains(m.teamB.toLowerCase())) return m.teamB;
    }
    return null;
  }

  static String? _pickedOptionLabel(Map<String, dynamic> p, MatchItem match) {
    final label = (p['optionLabel'] ?? '').toString();
    if (label.isNotEmpty) return label;
    final optId = (p['optionId'] ?? '').toString();
    if (optId == 'opt_a') return match.teamA;
    if (optId == 'opt_b') return match.teamB;
    if (optId == 'opt_draw') return 'Draw';
    return null;
  }

  static int? _parseLeadingInt(String? s) {
    if (s == null || s.isEmpty) return null;
    final m = RegExp(r'^\s*(\d+)').firstMatch(s);
    return m == null ? null : int.tryParse(m.group(1)!);
  }
}