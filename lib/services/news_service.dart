// Fetches real sports news from the backend (/api/news).
// Sports-only, filterable by sport + language, with endless pagination
// (RSS + cricket-line + newsdata.io merged server-side). Falls back to the
// static `news` list in data.dart if the backend is unreachable.

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';
import '../data.dart';

class NewsService {
  static const Duration cacheTtl = Duration(minutes: 10);
  static const int pageSize = 20;
  static const String _prefsKey = 'cache_news';

  static final Map<String, List<NewsItem>> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static final Map<String, int> _loadedPages = {};
  static final Map<String, bool> _hasMore = {};
  static final Map<String, Future<List<NewsItem>>> _inflight = {};

  static Future<void> hydrateFromDisk() async {
    if (_cache.containsKey('all|en')) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;
      final json = jsonDecode(raw) as List;
      if (json.isEmpty) return;
      final parsed = json.map<NewsItem>((a) {
        final map = a as Map<String, dynamic>;
        return NewsItem(
          sport: (map['sport'] ?? 'all').toString(),
          sportEmoji: (map['sportEmoji'] ?? '').toString(),
          title: (map['title'] ?? '').toString(),
          source: (map['source'] ?? 'News').toString(),
          timeAgo: (map['timeAgo'] ?? '').toString(),
          tag: (map['tag'] ?? 'NEWS').toString(),
          image: (map['image'] ?? '').toString().isNotEmpty ? map['image'].toString() : null,
          description: (map['description'] ?? '').toString(),
          link: (map['link'] ?? '').toString(),
        );
      }).toList();
      _cache['all|en'] = parsed;
      _cacheTime['all|en'] = DateTime.now();
      _hasMore['all|en'] = false;
    } catch (_) {}
  }

  static void invalidate({String sport = 'all', String language = 'en', String? region}) {
    final key = region == null ? '$sport|$language' : '$sport|$language|$region';
    _cache.remove(key);
    _cacheTime.remove(key);
    _loadedPages.remove(key);
    _hasMore.remove(key);
    _inflight.remove(key);
  }

  // Drop every cached feed so the next fetch reflects the new language/region.
  static void clearCache() {
    _cache.clear();
    _cacheTime.clear();
    _loadedPages.clear();
    _hasMore.clear();
    _inflight.clear();
  }

  static bool _fresh(String key) {
    final t = _cacheTime[key];
    return t != null &&
        _cache.containsKey(key) &&
        DateTime.now().difference(t) < cacheTtl;
  }

  static bool hasMore(String sport, String language, [String region = '']) =>
      _hasMore['$sport|$language${region.isEmpty ? '' : '|$region'}'] ?? true;

  // Fetch the next page of sports news and append it to the cache.
  // Returns the full accumulated list. [reset] starts from page 0.
  static Future<List<NewsItem>> fetchNews({
    String sport = 'all',
    String language = 'en',
    String region = '',
    bool reset = false,
  }) async {
    final key = '$sport|$language${region.isEmpty ? '' : '|$region'}';
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

    final future = _doFetch(sport, language, region, key, page);
    _inflight[reqKey] = future;
    try {
      return await future;
    } finally {
      _inflight.remove(reqKey);
    }
  }

  static Future<List<NewsItem>> _doFetch(
      String sport, String language, String region, String key, int page) async {
    try {
      final uri = Uri.parse('$apiBaseUrl/api/news').replace(
        queryParameters: {
          'sport': sport,
          'language': language,
          if (region.isNotEmpty) 'region': region,
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
          // Persist to disk for cold-start speed.
          if (sport == 'all' && language == 'en') {
            SharedPreferences.getInstance().then((prefs) {
              final simple = existing.map((n) => {
                'sport': n.sport, 'sportEmoji': n.sportEmoji,
                'title': n.title, 'source': n.source,
                'timeAgo': n.timeAgo, 'tag': n.tag,
                'image': n.image, 'description': n.description,
                'link': n.link,
              }).toList();
              prefs.setString(_prefsKey, jsonEncode(simple));
            });
          }
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
