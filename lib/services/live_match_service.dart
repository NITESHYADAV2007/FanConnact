// Fetches real live match scorecards from the backend (/api/live-matches)
// powered by allsportsapi2 + cricbuzz. Filterable by sport.

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../data.dart';

class LiveMatchService {
  static const Duration cacheTtl = Duration(seconds: 15);
  static const String _prefsKey = 'cache_lm';

  static final Map<String, List<MatchItem>> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static final Map<String, Future<List<MatchItem>>> _inflight = {};

  // Load persisted cache from disk into memory (called at app startup).
  static Future<void> hydrateFromDisk() async {
    if (_cache.containsKey('all')) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final matches = (json['matches'] as List?) ?? [];
      if (matches.isEmpty) return;
      final parsed = matches.map<MatchItem>((m) {
        return MatchItem.fromApi(m as Map<String, dynamic>, sportKey: 'all');
      }).toList();
      _cache['all'] = parsed;
      _cacheTime['all'] = DateTime.now();
    } catch (_) {}
  }

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

  static Future<List<MatchItem>> fetchLiveMatches({
    String sport = 'all',
    bool force = false,
  }) async {
    if (!force && _fresh(sport)) return _cache[sport]!;
    if (!force && _inflight.containsKey(sport)) return _inflight[sport]!;
    // On cold cache (no in-memory data), try disk before firing network.
    if (!_cache.containsKey(sport) && !force) {
      await hydrateFromDisk();
      if (_cache.containsKey(sport)) return _cache[sport]!;
    }
    if (force) {
      _cache.remove(sport);
      _cacheTime.remove(sport);
    }

    final future = _doFetch(sport);
    _inflight[sport] = future;
    try {
      return await future;
    } finally {
      _inflight.remove(sport);
    }
  }

  static Future<List<MatchItem>> _doFetch(String sport) async {
    for (int attempt = 0; attempt < 3; attempt++) {
      try {
        final uri = Uri.parse('$apiBaseUrl/api/live-matches').replace(
          queryParameters: {'sport': sport},
        );
        final res = await http.get(uri).timeout(const Duration(seconds: 30));
        if (res.statusCode == 200) {
          final rawBody = res.body;
          final json = jsonDecode(rawBody) as Map<String, dynamic>;
          final matches = (json['matches'] as List?) ?? [];
          if (matches.isNotEmpty) {
            final parsed = matches.map<MatchItem>((m) {
              final map = m as Map<String, dynamic>;
              return MatchItem.fromApi(map, sportKey: sport);
            }).toList();
            _cache[sport] = parsed;
            _cacheTime[sport] = DateTime.now();
            // Persist to disk so next cold start sees data immediately.
            if (sport == 'all') {
              SharedPreferences.getInstance().then((prefs) =>
                  prefs.setString(_prefsKey, rawBody));
            }
            return parsed;
          }
        }
      } catch (e) {
        debugPrint('LiveMatchService: attempt $attempt failed ($e)');
        if (attempt < 2) await Future.delayed(Duration(seconds: 2 * (attempt + 1)));
      }
    }
    if (_cache.containsKey(sport)) return _cache[sport]!;
    return [];
  }

  // Fetch a single match's live detail (used by the match detail screen for
  // real-time score updates). For cricket this hits the free /match/:id
  // endpoint so it costs no API quota.
  static Future<MatchItem?> fetchMatchDetail({
    required String matchId,
    String sport = 'cricket',
  }) async {
    try {
      final uri = Uri.parse('$apiBaseUrl/api/live-matches/$matchId').replace(
        queryParameters: {'sport': sport},
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 9));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final m = json['match'] as Map<String, dynamic>?;
        if (m != null) {
          return MatchItem.fromApi(m, sportKey: sport);
        }
      }
    } catch (e) {
      debugPrint('LiveMatchService: detail fetch failed ($e)');
    }
    return null;
  }
}
