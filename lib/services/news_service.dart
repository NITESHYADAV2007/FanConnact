// Fetches real sports news from the backend (/api/news) powered by newsdata.io.
// Sports-only, filterable by sport + language. Falls back to the static `news`
// list in data.dart if the backend is unreachable.

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../data.dart';

class NewsService {
  // How long client-side results stay valid before we allow a backend call.
  static const Duration cacheTtl = Duration(minutes: 10);

  // cache key ("$sport|$language") -> payload + timestamp
  static final Map<String, List<NewsItem>> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  // in-flight futures keyed by cache key (concurrent calls share ONE request)
  static final Map<String, Future<List<NewsItem>>> _inflight = {};

  // Force a fresh fetch (bypasses cache). Used by pull-to-refresh.
  static void invalidate({String sport = 'all', String language = 'en'}) {
    final key = '$sport|$language';
    _cache.remove(key);
    _cacheTime.remove(key);
    _inflight.remove(key);
  }

  static bool _fresh(String key) {
    final t = _cacheTime[key];
    return t != null &&
        _cache.containsKey(key) &&
        DateTime.now().difference(t) < cacheTtl;
  }

  // Fetch sports news. [sport] is an app sport key ('all' shows every sport).
  // [language] is an ISO code like 'en', 'hi', 'es'.
  static Future<List<NewsItem>> fetchNews({
    String sport = 'all',
    String language = 'en',
  }) async {
    final key = '$sport|$language';
    // 1) Return cached data immediately if still fresh.
    if (_fresh(key)) return _cache[key]!;
    // 2) If a request for this key is already running, reuse it.
    if (_inflight.containsKey(key)) return _inflight[key]!;

    // 3) Otherwise start ONE request and share it via _inflight.
    final future = _doFetch(sport, language, key);
    _inflight[key] = future;
    try {
      return await future;
    } finally {
      _inflight.remove(key);
    }
  }

  static Future<List<NewsItem>> _doFetch(
      String sport, String language, String key) async {
    try {
      final uri = Uri.parse('$apiBaseUrl/api/news').replace(
        queryParameters: {'sport': sport, 'language': language},
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 9));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final articles = (json['articles'] as List?) ?? [];
        if (articles.isNotEmpty) {
          final parsed = articles.map<NewsItem>((a) {
            final map = a as Map<String, dynamic>;
            final img = (map['image'] ?? '').toString();
            final sportKey = _detectSport(map);
            return NewsItem(
              sport: sportKey,
              sportEmoji: _emojiFor(sportKey),
              title: (map['title'] ?? '').toString(),
              source: (map['source'] ?? 'News').toString(),
              timeAgo: _timeAgo(map['pubDate']?.toString() ?? ''),
              tag: 'NEWS',
              image: img.isNotEmpty ? img : null,
              description: (map['description'] ?? '').toString(),
              link: (map['link'] ?? '').toString(),
            );
          }).toList();
          // Cache the successful result.
          _cache[key] = parsed;
          _cacheTime[key] = DateTime.now();
          return parsed;
        }
      }
    } catch (e) {
      debugPrint('NewsService: falling back to static news ($e)');
    }
    // On error/empty: if we have stale cache, serve it instead of static.
    if (_cache.containsKey(key)) return _cache[key]!;
    return news; // static fallback
  }

  static String _detectSport(Map<String, dynamic> map) {
    final blob = '${map['title'] ?? ''} ${map['description'] ?? ''} '
        '${(map['category'] ?? '').toString().toLowerCase()}';
    final lower = blob.toLowerCase();
    const map2 = {
      'cricket': ['cricket', 'ipl', 'wicket', 'batter', 'batsman'],
      'football': ['football', 'soccer', 'fifa', 'premier league', 'goal'],
      'basketball': ['basketball', 'nba', 'nfl', 'hoops'],
      'tennis': ['tennis', 'wimbledon', 'atp', 'wta', 'open'],
      'hockey': ['hockey', 'nhl', 'puck'],
      'baseball': ['baseball', 'mlb', 'bat'],
      'volleyball': ['volleyball'],
      'kabaddi': ['kabaddi', 'pro kabaddi'],
      'esports': ['esports', 'gaming'],
      'tabletennis': ['table tennis', 'ping pong'],
    };
    for (final entry in map2.entries) {
      if (entry.value.any((k) => lower.contains(k))) return entry.key;
    }
    return 'all';
  }

  static String _emojiFor(String sport) {
    const emojis = {
      'cricket': '🏏',
      'football': '⚽',
      'basketball': '🏀',
      'tennis': '🎾',
      'hockey': '🏑',
      'baseball': '⚾',
      'volleyball': '🏐',
      'kabaddi': '🤼',
      'esports': '🎮',
      'tabletennis': '🏓',
    };
    return emojis[sport] ?? '🏟️';
  }

  static String _timeAgo(String pubDate) {
    if (pubDate.isEmpty) return '';
    try {
      final dt = DateTime.parse(pubDate);
      final diff = DateTime.now().toUtc().difference(dt.toUtc());
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}
