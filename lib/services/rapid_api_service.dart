// Real-API client for player rankings + player details.
//
// The Flutter app calls OUR backend proxy routes (one origin, one key, quota
// guarded on the server). The backend fans out to the exact RapidAPI sources
// the user specified:
//
//   • Cricket      → cricket-live-line-advance  (/players, /matches)
//   • Football     → free-api-live-football-data (/football-players-search)
//   • Table Tennis→ tabletennisapi             (/api/table-tennis/team/:id,
//                                                /api/table-tennis/event/:id)
//   • Tennis       → tennis-api-atp-wta-itf    (prediction endpoint 404s →
//                                                  backend falls back)
//   • Other sports→ allsportsapi2              (no /rankings endpoint exists,
//                                                  backend serves synced data)
//
// All responses are cached client-side for 10 min to avoid hammering the
// backend (which itself guards the 100/day upstream quota).

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class RapidApiService {
  // 10-minute client cache to protect the daily quota.
  static const Duration _ttl = Duration(minutes: 10);
  static final Map<String, _CacheEntry> _cache = {};

  static Future<dynamic> _getJson(String path) async {
    final key = path;
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.time) < _ttl) {
      return cached.data;
    }
    final uri = Uri.parse('$apiBaseUrl$path');
    try {
      final res = await http
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _cache[key] = _CacheEntry(DateTime.now(), data);
        return data;
      }
      debugPrint('RapidApiService: $path -> ${res.statusCode}');
    } catch (e) {
      debugPrint('RapidApiService: $path failed ($e)');
    }
    if (cached != null) return cached.data; // stale cache fallback
    return null;
  }

  // ───────────────────────── Cricket ─────────────────────────
  // Real cricket players from cricket-live-line-advance (via backend proxy).
  static Future<List<Map<String, dynamic>>> fetchCricketPlayers() async {
    final data = await _getJson('/api/real/cricket/players');
    if (data is Map && data['players'] is List) {
      return (data['players'] as List)
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return [];
  }

  // Cricket matches (used for series/tournament discovery).
  static Future<List<Map<String, dynamic>>> fetchCricketMatches() async {
    final data = await _getJson('/api/real/cricket/matches');
    if (data is Map && data['matches'] is List) {
      return (data['matches'] as List)
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return [];
  }

  // Fetch a single cricket player's full detail by pid (from /players list).
  static Future<Map<String, dynamic>?> fetchCricketPlayer(int pid) async {
    final all = await fetchCricketPlayers();
    try {
      return all.firstWhere((p) => p['pid'] == pid);
    } catch (_) {
      return null;
    }
  }

  // ───────────────────────── Football ─────────────────────────
  // Search football players by name → list of {id,name,teamName,...}.
  static Future<List<Map<String, dynamic>>> searchFootballPlayers(
      String query) async {
    final data = await _getJson(
        '/api/real/football/players?search=${Uri.encodeComponent(query)}');
    if (data is Map && data['players'] is List) {
      return (data['players'] as List)
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return [];
  }

  // ───────────────────────── Table Tennis ─────────────────────────
  // Team detail (name, category, country) from tabletennisapi.
  static Future<Map<String, dynamic>?> fetchTableTennisTeam(int teamId) async {
    final data = await _getJson('/api/real/table-tennis/team/$teamId');
    if (data is Map && data['team'] is Map) {
      return Map<String, dynamic>.from(data['team'] as Map);
    }
    return null;
  }

  // Table-tennis event detail (tournament + teams) from tabletennisapi.
  static Future<Map<String, dynamic>?> fetchTableTennisEvent(int eventId) async {
    final data = await _getJson('/api/real/table-tennis/event/$eventId');
    if (data is Map && data['event'] is Map) {
      return Map<String, dynamic>.from(data['event'] as Map);
    }
    return null;
  }
}

class _CacheEntry {
  final DateTime time;
  final dynamic data;
  _CacheEntry(this.time, this.data);
}
