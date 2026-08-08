// Fetches tournament (series) stats like top run-scorers and wicket-takers
// from the backend /api/tournament-stats endpoint (powered by cricbuzz).

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class TournamentStats {
  final String type; // mostRuns | mostWickets | mostSixes
  final List<List<String>> values; // rows: [playerId, name, M, I, runs, SR] etc.

  TournamentStats(this.type, this.values);

  String? get topName => values.isNotEmpty && values.first.length > 1
      ? values.first[1]
      : null;

  String? get topValue {
    if (values.isEmpty || values.first.length < 5) return null;
    final v = values.first;
    return v[4]; // runs / wickets / sixes
  }

  factory TournamentStats.fromJson(Map<String, dynamic> j) {
    final list = (j['values'] as List?) ?? [];
    return TournamentStats(
      j['type']?.toString() ?? '',
      list.map((row) => (row as List).map((e) => e.toString()).toList()).toList(),
    );
  }
}

class TournamentStatsService {
  static final Map<String, Map<String, TournamentStats>> _cache = {};
  static const Duration cacheTtl = Duration(minutes: 15);

  static Future<Map<String, TournamentStats>?> fetchStats(
    String seriesIdOrTitle, {
    String? title,
  }) async {
    final key = title ?? seriesIdOrTitle;
    if (key.isEmpty) return null;
    final cached = _cache[key];
    if (cached != null) return cached;

    try {
      final uri = Uri.parse('$apiBaseUrl/api/tournament-stats').replace(
        queryParameters: {
          if (title != null) 'title': title,
          if (title == null) 'seriesId': seriesIdOrTitle,
        },
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final stats = (json['stats'] as List?) ?? [];
      final map = <String, TournamentStats>{};
      for (final s in stats) {
        final t = TournamentStats.fromJson(s as Map<String, dynamic>);
        if (t.type.isNotEmpty) map[t.type] = t;
      }
      _cache[key] = map;
      return map;
    } catch (e) {
      return null;
    }
  }
}
