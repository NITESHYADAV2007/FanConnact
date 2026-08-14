import 'package:cloud_firestore/cloud_firestore.dart';
import 'prediction_enums.dart';

class PredictionGame {
  final String id;
  final String sportKey;
  final String teamA;
  final String teamB;
  final String? logoA;
  final String? logoB;
  final String? series;
  final String venue;
  final DateTime startTime;
  final String status;
  final List<PredictionMarket> markets;
  final bool isTrending;
  final int totalPredictions;
  final String? scoreA;
  final String? scoreB;
  final String? overA;
  final String? overB;

  PredictionGame({
    required this.id,
    required this.sportKey,
    required this.teamA,
    required this.teamB,
    this.logoA,
    this.logoB,
    this.series,
    required this.venue,
    required this.startTime,
    required this.status,
    required this.markets,
    this.isTrending = false,
    this.totalPredictions = 0,
    this.scoreA,
    this.scoreB,
    this.overA,
    this.overB,
  });

  factory PredictionGame.fromJson(Map<String, dynamic> json) => PredictionGame(
    id: json['id'] as String,
    sportKey: json['sportKey'] as String,
    teamA: json['teamA'] as String,
    teamB: json['teamB'] as String,
    logoA: json['logoA'] as String?,
    logoB: json['logoB'] as String?,
    series: json['series'] as String?,
    venue: json['venue'] as String,
    startTime: DateTime.parse(json['startTime'] as String),
    status: json['status'] as String,
    markets: (json['markets'] as List).map((e) => PredictionMarket.fromJson(e as Map<String, dynamic>)).toList(),
    isTrending: json['isTrending'] as bool? ?? false,
    totalPredictions: json['totalPredictions'] as int? ?? 0,
    scoreA: json['scoreA'] as String?,
    scoreB: json['scoreB'] as String?,
    overA: json['overA'] as String?,
    overB: json['overB'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'sportKey': sportKey,
    'teamA': teamA,
    'teamB': teamB,
    'logoA': logoA,
    'logoB': logoB,
    'series': series,
    'venue': venue,
    'startTime': startTime.toIso8601String(),
    'status': status,
    'markets': markets.map((e) => e.toJson()).toList(),
    'isTrending': isTrending,
    'totalPredictions': totalPredictions,
    'scoreA': scoreA,
    'scoreB': scoreB,
    'overA': overA,
    'overB': overB,
  };

  bool get isLive => status == 'live';
  bool get isUpcoming => status == 'upcoming';
  bool get isCompleted => status == 'completed';
}

class PredictionMarket {
  final String id;
  final String gameId;
  final String question;
  final MarketType type;
  final List<PredictionOption> options;
  final DateTime? closesAt;
  final bool isActive;

  PredictionMarket({
    required this.id,
    required this.gameId,
    required this.question,
    required this.type,
    required this.options,
    this.closesAt,
    this.isActive = true,
  });

  factory PredictionMarket.fromJson(Map<String, dynamic> json) => PredictionMarket(
    id: json['id'] as String,
    gameId: json['gameId'] as String,
    question: json['question'] as String,
    type: MarketType.values.firstWhere((e) => e.name == json['type'], orElse: () => MarketType.custom),
    options: (json['options'] as List).map((e) => PredictionOption.fromJson(e as Map<String, dynamic>)).toList(),
    closesAt: json['closesAt'] != null ? DateTime.parse(json['closesAt'] as String) : null,
    isActive: json['isActive'] as bool? ?? true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'gameId': gameId,
    'question': question,
    'type': type.name,
    'options': options.map((e) => e.toJson()).toList(),
    'closesAt': closesAt?.toIso8601String(),
    'isActive': isActive,
  };

  PredictionOption? getSelectedOption(String? pickedOptionId) {
    if (pickedOptionId == null) return null;
    try {
      return options.firstWhere((o) => o.id == pickedOptionId);
    } catch (_) {
      return null;
    }
  }
}

class PredictionOption {
  final String id;
  final String label;
  final double odds;
  final double probability;
  final int totalPicks;
  final bool isCorrect;

  PredictionOption({
    required this.id,
    required this.label,
    required this.odds,
    required this.probability,
    this.totalPicks = 0,
    this.isCorrect = false,
  });

  factory PredictionOption.fromJson(Map<String, dynamic> json) => PredictionOption(
    id: json['id'] as String,
    label: json['label'] as String,
    odds: (json['odds'] as num).toDouble(),
    probability: (json['probability'] as num).toDouble(),
    totalPicks: json['totalPicks'] as int? ?? 0,
    isCorrect: json['isCorrect'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'odds': odds,
    'probability': probability,
    'totalPicks': totalPicks,
    'isCorrect': isCorrect,
  };

  String get formattedOdds => odds.toStringAsFixed(2);
  String get formattedProbability => '${(probability * 100).toStringAsFixed(1)}%';
}

class UserPrediction {
  final String id;
  final String userId;
  final String gameId;
  final String marketId;
  final String optionId;
  final double oddsAtPick;
  final int coinsStaked;
  final int potentialWin;
  final PredictionStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  UserPrediction({
    required this.id,
    required this.userId,
    required this.gameId,
    required this.marketId,
    required this.optionId,
    required this.oddsAtPick,
    required this.coinsStaked,
    required this.potentialWin,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  factory UserPrediction.fromJson(Map<String, dynamic> json) => UserPrediction(
    id: (json['id'] ?? '').toString(),
    userId: (json['userId'] ?? json['uid'] ?? '').toString(),
    gameId: (json['gameId'] ?? '').toString(),
    marketId: (json['marketId'] ?? '').toString(),
    optionId: (json['optionId'] ?? '').toString(),
    oddsAtPick: (json['oddsAtPick'] as num?)?.toDouble() ?? 1.0,
    coinsStaked: (json['coinsStaked'] as num?)?.toInt() ?? 0,
    potentialWin: (json['potentialWin'] as num?)?.toInt() ?? 0,
    status: PredictionStatus.values.firstWhere((e) => e.name == json['status'], orElse: () => PredictionStatus.pending),
    createdAt: parseFirebaseDate(json['createdAt']) ?? DateTime.now(),
    resolvedAt: parseFirebaseDate(json['resolvedAt']),
  );

  static DateTime? parseFirebaseDate(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'gameId': gameId,
    'marketId': marketId,
    'optionId': optionId,
    'oddsAtPick': oddsAtPick,
    'coinsStaked': coinsStaked,
    'potentialWin': potentialWin,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'resolvedAt': resolvedAt?.toIso8601String(),
  };
}