// Fetches real matches from the Fanconnact backend (/api/matches),
// which pulls live data (with team logos) from ESPN's scoreboard API.
// Falls back to the static `matches` list in data.dart on failure.

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../data.dart';

class MatchService {
  static Future<List<MatchItem>> fetchMatches({String sport = 'all'}) async {
    try {
      final uri = Uri.parse('$apiBaseUrl/api/matches')
          .replace(queryParameters: {'sport': sport});
      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final list = (json['matches'] as List?) ?? [];
        if (list.isNotEmpty) {
          return list.map<MatchItem>((m) {
            final map = m as Map<String, dynamic>;
            return MatchItem.fromApi(map, sportKey: sport);
          }).toList();
        }
      }
    } catch (e) {
      debugPrint('MatchService: falling back to static matches ($e)');
    }
    // Static fallback (real-looking data for all sports).
    if (sport == 'all') return matches;
    return matches.where((m) => m.sport == sport).toList();
  }
}
