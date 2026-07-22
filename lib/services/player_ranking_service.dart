// Fetches real player rankings from the backend (/api/rankings/:sport/:category)
// powered by ICC / ESPN / API-Sports / allsportsapi2 + procedural fallbacks.

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class RankingColumn {
  final String key;
  final String label;
  final String align;
  final String? hide;
  const RankingColumn({
    required this.key,
    required this.label,
    this.align = 'left',
    this.hide,
  });
  factory RankingColumn.fromJson(Map<String, dynamic> m) => RankingColumn(
        key: (m['key'] ?? '').toString(),
        label: (m['label'] ?? '').toString(),
        align: (m['align'] ?? 'left').toString(),
        hide: m['hide']?.toString(),
      );
}

class RankingFilterOption {
  final String value;
  final String label;
  const RankingFilterOption({required this.value, required this.label});
  factory RankingFilterOption.fromJson(Map<String, dynamic> m) =>
      RankingFilterOption(
        value: (m['value'] ?? '').toString(),
        label: (m['label'] ?? '').toString(),
      );
}

class RankingFilterGroup {
  final String group;
  final String label;
  final List<RankingFilterOption> options;
  const RankingFilterGroup({
    required this.group,
    required this.label,
    required this.options,
  });
  factory RankingFilterGroup.fromJson(Map<String, dynamic> m) =>
      RankingFilterGroup(
        group: (m['group'] ?? '').toString(),
        label: (m['label'] ?? '').toString(),
        options: (m['options'] as List? ?? [])
            .map((o) => RankingFilterOption.fromJson(o))
            .toList(),
      );
}

class PlayerRanking {
  final int rank;
  final String name;
  final String? country;
  final Map<String, dynamic> extra;
  PlayerRanking({
    required this.rank,
    required this.name,
    this.country,
    required this.extra,
  });
  factory PlayerRanking.fromJson(Map<String, dynamic> m) {
    final extra = Map<String, dynamic>.from(m);
    extra.remove('rank');
    extra.remove('name');
    extra.remove('country');
    return PlayerRanking(
      rank: int.tryParse(m['rank']?.toString() ?? '') ?? 0,
      name: (m['name'] ?? '').toString(),
      country: m['country']?.toString(),
      extra: extra,
    );
  }
}

class PlayerRankingResponse {
  final String sport;
  final String label;
  final String title;
  final String subtitle;
  final String category;
  final String defaultCategory;
  final List<RankingFilterGroup> filters;
  final List<RankingColumn> columns;
  final String source;
  final List<PlayerRanking> players;
  final String? lastSync;
  const PlayerRankingResponse({
    required this.sport,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.defaultCategory,
    required this.filters,
    required this.columns,
    required this.source,
    required this.players,
    this.lastSync,
  });
  factory PlayerRankingResponse.fromJson(Map<String, dynamic> json) =>
      PlayerRankingResponse(
        sport: (json['sport'] ?? '').toString(),
        label: (json['label'] ?? '').toString(),
        title: (json['title'] ?? '').toString(),
        subtitle: (json['subtitle'] ?? '').toString(),
        category: (json['category'] ?? '').toString(),
        defaultCategory: (json['defaultCategory'] ?? '').toString(),
        filters: (json['filters'] as List? ?? [])
            .map((f) => RankingFilterGroup.fromJson(f))
            .toList(),
        columns: (json['columns'] as List? ?? [])
            .map((c) => RankingColumn.fromJson(c))
            .toList(),
        source: (json['source'] ?? '').toString(),
        players: (json['players'] as List? ?? [])
            .map((p) => PlayerRanking.fromJson(p))
            .toList(),
        lastSync: json['_lastSync']?.toString(),
      );
}

class PlayerRankingService {
  static const Duration cacheTtl = Duration(minutes: 5);
  static final Map<String, PlayerRankingResponse> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static final Map<String, Future<PlayerRankingResponse?>> _inflight = {};

  static void invalidate({String key = ''}) {
    if (key.isEmpty) {
      _cache.clear();
      _cacheTime.clear();
      _inflight.clear();
    } else {
      _cache.remove(key);
      _cacheTime.remove(key);
      _inflight.remove(key);
    }
  }

  static bool _fresh(String key) {
    final t = _cacheTime[key];
    return t != null &&
        _cache.containsKey(key) &&
        DateTime.now().difference(t) < cacheTtl;
  }

  // sport: app sport key (e.g. 'cricket', 'football', 'kabaddi'...)
  // category: optional filter combination, e.g. 'odi_bat_men' or 'scorers_men'
  static Future<PlayerRankingResponse?> fetchRankings({
    required String sport,
    String? category,
  }) async {
    final key = '$sport|${category ?? ''}';
    if (_fresh(key)) return _cache[key];
    if (_inflight.containsKey(key)) return _inflight[key];

    final future = _doFetch(sport, category);
    _inflight[key] = future;
    try {
      return await future;
    } finally {
      _inflight.remove(key);
    }
  }

  static Future<PlayerRankingResponse?> _doFetch(
      String sport, String? category) async {
    try {
      final query = <String, String>{};
      if (category != null && category.isNotEmpty) query['category'] = category;
      final uri = Uri.parse('$apiBaseUrl/api/rankings/$sport')
          .replace(queryParameters: query.isNotEmpty ? query : null);
      final res = await http.get(uri).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final resp = PlayerRankingResponse.fromJson(json);
        final key = '$sport|${category ?? ''}';
        _cache[key] = resp;
        _cacheTime[key] = DateTime.now();
        return resp;
      }
    } catch (e) {
      debugPrint('PlayerRankingService: failed ($e)');
    }
    final key = '$sport|${category ?? ''}';
    if (_cache.containsKey(key)) return _cache[key];
    return null;
  }
}
