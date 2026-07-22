import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class CricketHubService {
  static const _base = '${apiBaseUrl}/api/real/cricket/proxy';

  static Future<Map<String, dynamic>> _get(String path) async {
    final r = await http.get(Uri.parse('$_base$path'));
    if (r.statusCode != 200) throw Exception('CricketHub ${r.statusCode}: $path');
    final j = json.decode(r.body);
    if (j is Map && j['data'] != null) {
      if (j['data'] is Map) return Map<String, dynamic>.from(j['data']);
      return {'items': j['data']};
    }
    if (j is Map && j['items'] != null) return {'items': List<dynamic>.from(j['items'])};
    if (j is List) return {'items': List<dynamic>.from(j)};
    if (j is Map) return Map<String, dynamic>.from(j);
    return {};
  }

  static Future<List<dynamic>> _items(String path) async {
    final data = await _get(path);
    if (data['items'] != null && data['items'] is List) return data['items'] as List<dynamic>;
    if (data['response'] != null && data['response'] is Map && data['response']['items'] != null) {
      return List<dynamic>.from(data['response']['items']);
    }
    final list = data.values.where((v) => v is List).map((v) => v as List).toList();
    if (list.isNotEmpty) return list.first;
    return [];
  }

  static Future<List<dynamic>> matches() => _items('/matches');
  static Future<List<dynamic>> players() => _items('/players');
  static Future<List<dynamic>> competitions() => _items('/competitions');
  static Future<List<dynamic>> tournaments() => _items('/tournaments');
  static Future<List<dynamic>> teams() => _items('/teams');
  static Future<List<dynamic>> seasons() => _items('/season');
  static Future<List<dynamic>> iccRanks() => _items('/iccranks');

  static Future<List<dynamic>> competitionMatches(String id) => _items('/competitions/$id/matches');
  static Future<List<dynamic>> competitionTeams(String id) => _items('/competitions/$id/teams');
  static Future<List<dynamic>> competitionSquads(String id) => _items('/competitions/$id/squads');
  static Future<Map<String, dynamic>> competitionStandings(String id) => _get('/competitions/$id/standings');
  static Future<Map<String, dynamic>> competitionInfo(String id) => _get('/competitions/$id');
  static Future<List<dynamic>> competitionStatsTypes(String id) => _items('/competitions/$id/stats');
  static Future<List<dynamic>> competitionStats(String id, String type) =>
      _items('/competitions/$id/stats/$type');

  static Future<List<dynamic>> tournamentCompetitions(String id) =>
      _items('/tournaments/$id/competitions');
  static Future<List<dynamic>> tournamentStatsTypes(String id) => _items('/tournaments/$id/stats');
  static Future<List<dynamic>> tournamentStats(String id, String type) =>
      _items('/tournaments/$id/stats/$type');

  static Future<Map<String, dynamic>> matchInfo(String id) => _get('/matches/$id/info');
  static Future<Map<String, dynamic>> matchAdvance(String id) => _get('/matches/$id/advance');
  static Future<Map<String, dynamic>> matchStatistics(String id) => _get('/matches/$id/statistics');
  static Future<Map<String, dynamic>> matchContent(String id) => _get('/matches/$id/content');
  static Future<List<dynamic>> matchSquads(String id) => _items('/matches/$id/squads');
  static Future<Map<String, dynamic>> matchWagons(String id) => _get('/matches/$id/wagons');
  static Future<List<dynamic>> matchCommentary(String id, String inningId) =>
      _items('/matches/$id/innings/$inningId/commentary');
  static Future<List<dynamic>> matchOddsHistory(String id) => _items('/matches/$id/oddshistory');

  static Future<Map<String, dynamic>> teamInfo(String id) => _get('/teams/$id');
  static Future<List<dynamic>> teamPlayers(String id) => _items('/teams/$id/player');
  static Future<List<dynamic>> teamSquads(String id) => _items('/teams/$id/squads');
  static Future<List<dynamic>> teamMatches(String id) => _items('/teams/$id/matches');
  static Future<List<dynamic>> teamTracker(String id) => _items('/teams/$id/stats');
  static Future<Map<String, dynamic>> teamStats(String id) => _get('/team/$id/crickettracker');

  static Future<Map<String, dynamic>> playerStats(String id) => _get('/players/$id/stats');
  static Future<List<dynamic>> playerMatches(String id) => _items('/players/$id/playermatches');
  static Future<Map<String, dynamic>> playerAdvanceStats(String id) =>
      _get('/players/$id/advancestats');

  static Future<Map<String, dynamic>> venueInfo(String id) => _get('/venues/$id');
  static Future<List<dynamic>> venueMatches(String id) => _items('/venues/$id/matches');
  static Future<Map<String, dynamic>> venueStats(String id) => _get('/venues/$id/stats');
}
