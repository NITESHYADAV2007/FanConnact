// Fetches real live match scorecards from the backend (/api/live-matches)
// powered by allsportsapi2 + cricbuzz. Filterable by sport.

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../data.dart';

class LiveMatchService {
  // Short TTL: live scores change often, but we still avoid hammering the API.
  static const Duration cacheTtl = Duration(seconds: 30);

  static final Map<String, List<MatchItem>> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static final Map<String, Future<List<MatchItem>>> _inflight = {};

  // Force a fresh fetch (used by periodic real-time refresh + pull-to-refresh).
  static void invalidate({String sport = 'all'}) {
    _cache.remove(sport);
    _cacheTime.remove(sport);
    _inflight.remove(sport);
  }

  static bool _fresh(String sport) {
    final t = _cacheTime[sport];
    return t != null &&
        _cache.containsKey(sport) &&
        DateTime.now().difference(t) < cacheTtl;
  }

  static Future<List<MatchItem>> fetchLiveMatches({String sport = 'all'}) async {
    if (_fresh(sport)) return _cache[sport]!;
    if (_inflight.containsKey(sport)) return _inflight[sport]!;

    final future = _doFetch(sport);
    _inflight[sport] = future;
    try {
      return await future;
    } finally {
      _inflight.remove(sport);
    }
  }

  static Future<List<MatchItem>> _doFetch(String sport) async {
    try {
      final uri = Uri.parse('$apiBaseUrl/api/live-matches').replace(
        queryParameters: {'sport': sport},
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 9));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final matches = (json['matches'] as List?) ?? [];
        if (matches.isNotEmpty) {
          final parsed = matches.map<MatchItem>((m) {
            final map = m as Map<String, dynamic>;
            return MatchItem.fromApi(map, sportKey: sport);
          }).toList();
          _cache[sport] = parsed;
          _cacheTime[sport] = DateTime.now();
          return parsed;
        }
      }
    } catch (e) {
      debugPrint('LiveMatchService: failed ($e)');
    }
    if (_cache.containsKey(sport)) return _cache[sport]!;
    return [];
  }
}
