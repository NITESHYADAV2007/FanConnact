// Fetches real sports news from the backend (/api/news).
// Sports-only, filterable by sport + language, with endless pagination
// (RSS + cricket-line + newsdata.io merged server-side). Falls back to the
// static `news` list in data.dart if the backend is unreachable.

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../data.dart';

class NewsService {
  // How long client-side results stay valid before we allow a backend call.
  static const Duration cacheTtl = Duration(minutes: 10);
  static const int pageSize = 20;

  // cache key ("$sport|$language") -> accumulated items + timestamp
  static final Map<String, List<NewsItem>> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static final Map<String, int> _loadedPages = {};
  static final Map<String, bool> _hasMore = {};
  // in-flight futures keyed by cache key (concurrent calls share ONE request)
  static final Map<String, Future<List<NewsItem>>> _inflight = {};

  // Force a fresh fetch (bypasses cache). Used by pull-to-refresh.
  static void invalidate({String sport = 'all', String language = 'en'}) {
    final key = '$sport|$language';
    _cache.remove(key);
    _cacheTime.remove(key);
    _loadedPages.remove(key);
    _hasMore.remove(key);
    _inflight.remove(key);
  }

  static bool _fresh(String key) {
    final t = _cacheTime[key];
    return t != null &&
        _cache.containsKey(key) &&
        DateTime.now().difference(t) < cacheTtl;
  }

  static bool hasMore(String sport, String language) =>
      _hasMore['$sport|$language'] ?? true;

  // Fetch the next page of sports news and append it to the cache.
  // Returns the full accumulated list. [reset] starts from page 0.
  static Future<List<NewsItem>> fetchNews({
    String sport = 'all',
    String language = 'en',
    bool reset = false,
  }) async {
    final key = '$sport|$language';
    if (reset) {
      _cache[key] = [];
      _loadedPages[key] = 0;
      _hasMore[key] = true;
      _cacheTime[key] = DateTime.now();
    }
    // If fresh and fully loaded, return immediately.
    if (_fresh(key) && !(_hasMore[key] ?? false)) return _cache[key] ?? [];

    final page = _loadedPages[key] ?? 0;
    final reqKey = '$key#$page';
    if (_inflight.containsKey(reqKey)) return _inflight[reqKey]!;

    final future = _doFetch(sport, language, key, page);
    _inflight[reqKey] = future;
    try {
      return await future;
    } finally {
      _inflight.remove(reqKey);
    }
  }

  static Future<List<NewsItem>> _doFetch(
      String sport, String language, String key, int page) async {
    try {
      final uri = Uri.parse('$apiBaseUrl/api/news').replace(
        queryParameters: {
          'sport': sport,
          'language': language,
          'page': page.toString(),
          'pageSize': pageSize.toString(),
        },
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 12));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final articles = (json['articles'] as List?) ?? [];
        final more = json['hasMore'] as bool? ?? false;
        _hasMore[key] = more;
        _loadedPages[key] = page + 1;
        _cacheTime[key] = DateTime.now();
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
          final existing = _cache[key] ?? [];
          // De-dupe by title+link.
          final seen = <String>{
            for (final n in existing) '${n.title}|${n.link}'
          };
          for (final n in parsed) {
            final k = '${n.title}|${n.link}';
            if (!seen.contains(k)) {
              existing.add(n);
              seen.add(k);
            }
          }
          _cache[key] = existing;
          return existing;
        }
      }
    } catch (e) {
      debugPrint('NewsService: error ($e)');
    }
    // On error/empty: if we have stale cache, serve it instead of static.
    if (_cache.containsKey(key) && _cache[key]!.isNotEmpty) {
      _hasMore[key] = false;
      return _cache[key]!;
    }
    if (page == 0) return news; // static fallback only on first load
    return _cache[key] ?? [];
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
