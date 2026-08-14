// Non-cricket match enrichment via the backend /api/sport-detail proxy.
// The backend routes each sport to allsportsapi2 (basketball, baseball,
// american-football, volleyball) or FlashLive (hockey, kabaddi, esports,
// tabletennis, tennis) and caches 10 min. We never hit the upstream APIs
// directly from the app — the shared RapidAPI key is rate-limited (429s seen).
//
// Endpoints:
//   GET /api/sport-detail/:sport/match/:id/incidents
//   GET /api/sport-detail/:sport/match/:id/lineups
//   GET /api/sport-detail/:sport/match/:id/shotmap?team=:teamId
//   GET /api/sport-detail/:sport/team/:id/players

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class AllSportsApiService {
  static const Duration _ttl = Duration(minutes: 10);
  static final Map<String, _CacheEntry> _cache = {};

  static Future<dynamic> _get(String path) async {
    final cached = _cache[path];
    if (cached != null && DateTime.now().difference(cached.time) < _ttl) {
      return cached.data;
    }
    final uri = Uri.parse('$apiBaseUrl$path');
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _cache[path] = _CacheEntry(data);
        return data;
      }
    } catch (_) {
      if (cached != null) return cached.data; // stale fallback
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> fetchIncidents(
      String sport, String matchId) async {
    final d = await _get('/api/sport-detail/$sport/match/$matchId/incidents');
    if (d is Map && d['incidents'] is List) {
      return (d['incidents'] as List)
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return [];
  }

  static Future<Map<String, dynamic>> fetchLineups(
      String sport, String matchId) async {
    final d = await _get('/api/sport-detail/$sport/match/$matchId/lineups');
    if (d is Map) return Map<String, dynamic>.from(d);
    return {'home': [], 'away': []};
  }

  static Future<List<Map<String, dynamic>>> fetchShotmap(
      String sport, String matchId, String teamId) async {
    final d = await _get(
        '/api/sport-detail/$sport/match/$matchId/shotmap?team=$teamId');
    if (d is Map && d['shotmap'] is List) {
      return (d['shotmap'] as List)
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> fetchTeamPlayers(
      String sport, String teamId) async {
    final d = await _get('/api/sport-detail/$sport/team/$teamId/players');
    if (d is Map && d['players'] is List) {
      return (d['players'] as List)
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return [];
  }
}

class _CacheEntry {
  final DateTime time;
  final dynamic data;
  _CacheEntry(this.data, [DateTime? time]) : time = time ?? DateTime.now();
}
