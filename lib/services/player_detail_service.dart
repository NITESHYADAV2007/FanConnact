// Player detail client — talks to the BACKEND proxy (never direct RapidAPI):
//   - cricket:  /api/players/resolve/:name  ->  /api/players/:id/profile
//   - ESPN:     /api/players/espn/:league/:athleteId  (NBA / MLB / NHL)
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class PlayerDetailService {
  static Future<int?> resolveCricketPlayerId(String name) async {
    try {
      final r = await http
          .get(Uri.parse(
              '$apiBaseUrl/api/players/resolve/${Uri.encodeComponent(name)}'))
          .timeout(const Duration(seconds: 20));
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body) as Map<String, dynamic>;
        if (j['success'] == true) return int.tryParse('${j['id']}');
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> fetchCricketProfile(int pid) async {
    try {
      final r = await http
          .get(Uri.parse('$apiBaseUrl/api/players/$pid/profile'))
          .timeout(const Duration(seconds: 30));
      if (r.statusCode == 200) {
        return jsonDecode(r.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> fetchEspnProfile(
      String league, String athleteId) async {
    try {
      final r = await http
          .get(Uri.parse('$apiBaseUrl/api/players/espn/$league/$athleteId'))
          .timeout(const Duration(seconds: 25));
      if (r.statusCode == 200) {
        return jsonDecode(r.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }
}