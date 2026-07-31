// Real-API client — calls RapidAPI DIRECTLY from the Flutter app (no backend
// proxy). One shared key. The exact sources the user specified:
//
//   • Cricket players/matches/tournaments → cricket-live-line-advance
//   • Cricket player + team rankings      → cricket-live-line1 (ICC-style)
//   • Football player search              → free-api-live-football-data
//   • Table Tennis team/event             → tabletennisapi
//
// Responses are cached client-side for 10 min to protect the daily quota.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class RapidApiService {
  static const String _key =
      '31ee070a54mshd6171aacb85b007p1443ccjsnf7c39463a592';

  // 10-minute client cache to protect the daily quota.
  static const Duration _ttl = Duration(minutes: 10);
  static final Map<String, _CacheEntry> _cache = {};

  static Map<String, String> _headersForHost(String host) {
    return {
      'x-rapidapi-host': host,
      'x-rapidapi-key': _key,
    };
  }

  // Direct RapidAPI GET. Returns decoded JSON body on success, or cached
  // (even stale) data on failure so the UI still renders.
  static Future<dynamic> _get(String host, String path,
      {Map<String, String>? query}) async {
    final key = '$host$path${query ?? ''}';
    final cached = _cache[key];
    if (cached != null && DateTime.now().difference(cached.time) < _ttl) {
      return cached.data;
    }
    final uri = Uri.https(host, path, query);
    try {
      final res = await http
          .get(uri, headers: _headersForHost(host))
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _cache[key] = _CacheEntry(DateTime.now(), data);
        return data;
      }
      debugPrint('RapidApiService: $host$path -> ${res.statusCode}');
    } catch (e) {
      debugPrint('RapidApiService: $host$path failed ($e)');
    }
    if (cached != null) return cached.data; // stale cache fallback
    return null;
  }

  // ───────────────────────── Cricket (cricket-live-line-advance) ─────────────────────────
  // Real cricket players.
  static Future<List<Map<String, dynamic>>> fetchCricketPlayers() async {
    final data = await _get('cricket-live-line-advance.p.rapidapi.com', '/players');
    if (data is Map && data['response'] is Map) {
      final items = data['response']['items'] as List? ?? [];
      return items
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return [];
  }

  // Cricket matches (used for series/tournament discovery).
  static Future<List<Map<String, dynamic>>> fetchCricketMatches() async {
    final data = await _get('cricket-live-line-advance.p.rapidapi.com', '/matches');
    if (data is Map && data['response'] is Map) {
      final items = data['response']['items'] as List? ?? [];
      return items
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

  // Rich cricket player profile (Crex-style) from cricket-live-line1.
  // Returns {player:{...}, batting_career:[...], bowling_career:[...], teams}
  // or null on failure.
  static Future<Map<String, dynamic>?> fetchCricketPlayerDetail(
      int pid) async {
    final data =
        await _get('cricket-live-line1.p.rapidapi.com', '/player/$pid');
    if (data is Map && data['data'] is Map) {
      return Map<String, dynamic>.from(data['data'] as Map);
    }
    return null;
  }

  // ── Cricket player STATS (cricket-live-line-advance, DIRECT) ──
  // GET /players/{pid}/stats → {player:{...}, batting:{test,odi,t20i,t20,lista},
  // bowling:{...}, series_stats:[...], bio, debut_data:[...]}.
  // This is the real, quota-friendly endpoint the user wants (no backend).
  // Returns the full `response` map, or null on failure.
  static Future<Map<String, dynamic>?> fetchCricketPlayerStats(int pid) async {
    final data = await _get(
        'cricket-live-line-advance.p.rapidapi.com', '/players/$pid/stats');
    if (data is Map && data['response'] is Map) {
      return Map<String, dynamic>.from(data['response'] as Map);
    }
    return null;
  }

  // ───────────────────────── Football (free-api-live-football-data) ─────────────────────────
  // Search football players by name → list of {id,name,teamName,...}.
  static Future<List<Map<String, dynamic>>> searchFootballPlayers(
      String query) async {
    final data = await _get('free-api-live-football-data.p.rapidapi.com',
        '/football-players-search',
        query: {'search': query});
    if (data is Map && data['response'] is Map) {
      final sugg = data['response']['suggestions'] as List? ?? [];
      return sugg
          .where((s) => s is Map && s['type'] == 'player')
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList();
    }
    return [];
  }

  // ───────────────────────── Table Tennis (tabletennisapi) ─────────────────────────
  // Team detail (name, category, country).
  static Future<Map<String, dynamic>?> fetchTableTennisTeam(int teamId) async {
    final data = await _get('tabletennisapi.p.rapidapi.com',
        '/api/table-tennis/team/$teamId');
    if (data is Map && data['team'] is Map) {
      return Map<String, dynamic>.from(data['team'] as Map);
    }
    return null;
  }

  // Table-tennis event detail (tournament + teams).
  static Future<Map<String, dynamic>?> fetchTableTennisEvent(int eventId) async {
    final data = await _get('tabletennisapi.p.rapidapi.com',
        '/api/table-tennis/event/$eventId');
    if (data is Map && data['event'] is Map) {
      return Map<String, dynamic>.from(data['event'] as Map);
    }
    return null;
  }

  // ───────────────────────── Cricket Rankings (cricket-live-line1, ICC-style) ─────────────────────────
  // Player rankings. category: 1=batting, 2=bowling, 3=all-rounders.
  // Returns list of {rank,name,country,rating,image,playerId}.
  static Future<List<Map<String, dynamic>>> fetchCricketPlayerRankings(
      [int category = 1]) async {
    final data = await _get(
        'cricket-live-line1.p.rapidapi.com', '/playerRanking/$category');
    if (data is List) {
      return data
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return [];
  }

  // Team rankings. category: 1=test, 2=odi, 3=t20.
  // Returns list of {rank,name,country,rating,image,teamId}.
  static Future<List<Map<String, dynamic>>> fetchCricketTeamRankings(
      [int category = 1]) async {
    final data = await _get(
        'cricket-live-line1.p.rapidapi.com', '/teamRanking/$category');
    if (data is List) {
      return data
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    if (data is Map && data['data'] is List) {
      return (data['data'] as List)
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return [];
  }

  // ── Cricket rankings DIRECT from cricket-live-line-advance ──
  // NOTE: the old `/icc-ranking` endpoint no longer exists (404) and
  // cricket-live-line1 `/playerRanking` is frequently quota-limited (429).
  // So we build a real, always-available ranking from the live `/players`
  // list (sorted by fantasy_player_rating) — this is a genuine API fetch,
  // not the backend. Returns list of {rank,pid,name,country,rating,image}.
  static Future<List<Map<String, dynamic>>> fetchCricketPlayerRankingsDirect(
      [String? country]) async {
    final data =
        await _get('cricket-live-line-advance.p.rapidapi.com', '/players');
    if (data is Map && data['response'] is Map) {
      final items = data['response']['items'] as List? ?? [];
      var players = items.whereType<Map>().toList();
      if (country != null && country.isNotEmpty) {
        players = players
            .where((p) =>
                (p['country']?.toString().toLowerCase() ?? '') ==
                country.toLowerCase())
            .toList();
      }
      players.sort((a, b) {
        final ra = double.tryParse(
                (a['fantasy_player_rating'] ?? '0').toString()) ??
            0;
        final rb = double.tryParse(
                (b['fantasy_player_rating'] ?? '0').toString()) ??
            0;
        return rb.compareTo(ra);
      });
      return players.take(50).map((p) {
        return <String, dynamic>{
          'rank': 0, // assigned by caller
          'pid': p['pid'],
          'name': p['title'] ?? p['short_name'] ?? 'Unknown',
          'country': p['nationality'] ?? p['country'] ?? '',
          'rating': p['fantasy_player_rating'] ?? 0,
          'image': p['profile_image'] ?? p['thumb_url'] ?? p['logo_url'] ?? '',
          'role': p['playing_role'] ?? '',
        };
      }).toList();
    }
    return [];
  }

  // Cricket tournaments (real logos) from cricket-live-line-advance.
  // Returns list of {tournament_id,name,logo_url,country,type}.
  static Future<List<Map<String, dynamic>>> fetchCricketTournaments() async {
    final data =
        await _get('cricket-live-line-advance.p.rapidapi.com', '/tournaments');
    if (data is Map && data['response'] is Map) {
      final groups = data['response']['items'] as List? ?? [];
      final flat = <Map<String, dynamic>>[];
      for (final g in groups) {
        if (g is! Map) continue;
        final country = (g['country'] ?? 'International').toString();
        final tours = g['tournaments'] as List? ?? [];
        for (final t in tours) {
          if (t is! Map) continue;
          flat.add({
            'tournament_id': t['tournament_id'],
            'name': t['name'],
            'logo_url': t['logo_url'],
            'country': country,
            'type': t['type'] ?? '',
          });
        }
      }
      return flat;
    }
    return [];
  }

  // Matches for a specific cricket tournament (from /matches, filtered by
  // competition.tournament_id).
  static Future<List<Map<String, dynamic>>> fetchCricketTournamentMatches(
      String tournamentId) async {
    final data = await _get('cricket-live-line-advance.p.rapidapi.com', '/matches');
    if (data is Map && data['response'] is Map) {
      final items = data['response']['items'] as List? ?? [];
      return items
          .whereType<Map>()
          .where((m) =>
              (m['competition']?['tournament_id']?.toString() == tournamentId) ||
              (m['tournament_id']?.toString() == tournamentId))
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    return [];
  }

  // IDs of tournaments that currently have a LIVE match (used to filter the
  // Series slider to "active" tournaments only).
  static Future<Set<String>> fetchCricketLiveTournamentIds() async {
    final data = await _get('cricket-live-line-advance.p.rapidapi.com', '/matches');
    final ids = <String>{};
    if (data is Map && data['response'] is Map) {
      final items = data['response']['items'] as List? ?? [];
      for (final m in items) {
        if (m is! Map) continue;
        final status = (m['status_str'] ?? '').toString().toLowerCase();
        if (status != 'live') continue;
        final tid = m['competition']?['tournament_id']?.toString() ??
            m['tournament_id']?.toString();
        if (tid != null) ids.add(tid);
      }
    }
    return ids;
  }

  // ─── Cricket live matches DIRECT from cricket-live-line-advance ───
  // Returns list of raw match maps from /matches?status=3 (live) endpoint.
  static Future<List<Map<String, dynamic>>> fetchCricketLiveMatches(
      {int page = 1, int perPage = 50}) async {
    final data = await _get(
        'cricket-live-line-advance.p.rapidapi.com', '/matches',
        query: {
          'status': '3',
          'per_paged': perPage.toString(),
          'paged': page.toString(),
        });
    if (data is Map && data['response'] is Map) {
      final items = data['response']['items'] as List? ?? [];
      return items.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    }
    return [];
  }

  // ───────────────────────── Cricbuzz Commentary ─────────────────────────
  // Structured ball-by-ball commentary with eventtype (WICKET, FOUR, SIX, NONE, over-break).
  static Future<List<Map<String, dynamic>>> fetchCricbuzzCommentary(
      String matchId) async {
    final data = await _get(
        'cricbuzz-cricket.p.rapidapi.com', '/mcenter/v1/$matchId/comm');
    if (data is Map && data['comwrapper'] is List) {
      final items = data['comwrapper'] as List;
      return items
          .where((e) => e is Map && e['commentary'] is Map)
          .map((e) => Map<String, dynamic>.from(e['commentary'] as Map))
          .toList();
    }
    return [];
  }
}

class _CacheEntry {
  final DateTime time;
  final dynamic data;
  _CacheEntry(this.time, this.data);
}
