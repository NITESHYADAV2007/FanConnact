// Fetches real sports reels from the backend (/api/reels) powered by Instagram.
// Filterable by sport. Falls back to an empty list (UI shows a placeholder).

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ReelItem {
  final String code;
  final int type;
  final String productType;
  final String caption;
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final int takenAt;
  final String? videoUrl;
  final String? imageUrl;
  final String link;
  final String? username;

  const ReelItem({
    required this.code,
    required this.type,
    required this.productType,
    required this.caption,
    required this.likeCount,
    required this.commentCount,
    required this.viewCount,
    required this.takenAt,
    this.videoUrl,
    this.imageUrl,
    required this.link,
    this.username,
  });

  bool get isVideo => type == 2 || videoUrl != null;
  String get thumb => imageUrl ?? '';
}

class ReelsService {
  static const Duration cacheTtl = Duration(minutes: 15);
  static const int pageSize = 50;
  static String _prefsKey(String sport) => 'cache_reels_$sport';

  static final Map<String, List<ReelItem>> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static final Map<String, int> _loadedPages = {};
  static final Map<String, bool> _hasMore = {};
  static final Map<String, Future<List<ReelItem>>> _inflight = {};

  static Future<void> hydrateFromDisk({String sport = 'all'}) async {
    if (_cache.containsKey(sport)) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey(sport));
      if (raw == null) return;
      final json = jsonDecode(raw) as List;
      if (json.isEmpty) return;
      final parsed = json.map<ReelItem>((r) {
        final map = r as Map<String, dynamic>;
        return ReelItem(
          code: (map['code'] ?? '').toString(),
          type: map['type'] is int ? map['type'] : 1,
          productType: (map['productType'] ?? '').toString(),
          caption: (map['caption'] ?? '').toString(),
          likeCount: map['likeCount'] is int ? map['likeCount'] : 0,
          commentCount: map['commentCount'] is int ? map['commentCount'] : 0,
          viewCount: map['viewCount'] is int ? map['viewCount'] : 0,
          takenAt: map['takenAt'] is int ? map['takenAt'] : 0,
          videoUrl: (map['videoUrl'] ?? '').toString().isNotEmpty ? map['videoUrl'].toString() : null,
          imageUrl: (map['imageUrl'] ?? '').toString().isNotEmpty ? map['imageUrl'].toString() : null,
          link: (map['link'] ?? '').toString(),
          username: (map['username'] ?? '').toString().isNotEmpty ? map['username'].toString() : null,
        );
      }).toList();
      _cache[sport] = parsed;
      _cacheTime[sport] = DateTime.now();
      _hasMore[sport] = false;
    } catch (_) {}
  }

  static void invalidate({String sport = 'all'}) {
    _cache.remove(sport);
    _cacheTime.remove(sport);
    _loadedPages.remove(sport);
    _hasMore.remove(sport);
    _inflight.remove(sport);
  }

  static bool _fresh(String sport) {
    final t = _cacheTime[sport];
    return t != null &&
        _cache.containsKey(sport) &&
        DateTime.now().difference(t) < cacheTtl;
  }

  static bool hasMore(String sport) => _hasMore[sport] ?? true;

  // Fetch the next page of reels and append it to the cache.
  // Returns the full accumulated list. [reset] starts from page 0.
  static Future<List<ReelItem>> fetchReels({
    String sport = 'all',
    bool reset = false,
  }) async {
    if (reset) {
      _cache[sport] = [];
      _loadedPages[sport] = 0;
      _hasMore[sport] = true;
      _cacheTime[sport] = DateTime.now();
    }
    if (_fresh(sport) && !(_hasMore[sport] ?? false)) return _cache[sport] ?? [];

    final page = _loadedPages[sport] ?? 0;
    final reqKey = '$sport#$page';
    if (_inflight.containsKey(reqKey)) return _inflight[reqKey]!;

    final future = _doFetch(sport, page);
    _inflight[reqKey] = future;
    try {
      return await future;
    } finally {
      _inflight.remove(reqKey);
    }
  }

  static Future<List<ReelItem>> _doFetch(String sport, int page) async {
    try {
      final uri = Uri.parse('$apiBaseUrl/api/reels').replace(
        queryParameters: {
          'sport': sport,
          'page': page.toString(),
          'pageSize': pageSize.toString(),
        },
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final reels = (json['reels'] as List?) ?? [];
        _hasMore[sport] = json['hasMore'] as bool? ?? false;
        _loadedPages[sport] = page + 1;
        // Only mark the cache fresh when we actually got content — an empty
        // response must never block the next fetch for cacheTtl minutes.
        if (reels.isNotEmpty) {
          _cacheTime[sport] = DateTime.now();
        }
        if (reels.isNotEmpty) {
          final parsed = reels.map<ReelItem>((r) {
            final map = r as Map<String, dynamic>;
            final user = map['user'] as Map<String, dynamic>?;
            return ReelItem(
              code: (map['code'] ?? '').toString(),
              type: map['type'] is int ? map['type'] : int.tryParse(map['type'].toString()) ?? 1,
              productType: (map['productType'] ?? '').toString(),
              caption: (map['caption'] ?? '').toString(),
              likeCount: map['likeCount'] is int ? map['likeCount'] : int.tryParse(map['likeCount'].toString()) ?? 0,
              commentCount: map['commentCount'] is int ? map['commentCount'] : int.tryParse(map['commentCount'].toString()) ?? 0,
              viewCount: map['viewCount'] is int ? map['viewCount'] : int.tryParse(map['viewCount'].toString()) ?? 0,
              takenAt: map['takenAt'] is int ? map['takenAt'] : int.tryParse(map['takenAt'].toString()) ?? 0,
              videoUrl: (map['videoUrl'] ?? '').toString().isNotEmpty ? map['videoUrl'].toString() : null,
              imageUrl: (map['imageUrl'] ?? '').toString().isNotEmpty ? map['imageUrl'].toString() : null,
              link: (map['link'] ?? '').toString(),
              username: user != null ? (user['username'] ?? '').toString() : null,
            );
          }).toList();
          final existing = _cache[sport] ?? [];
          final seen = <String>{for (final r in existing) r.code};
          for (final r in parsed) {
            if (!seen.contains(r.code)) {
              existing.add(r);
              seen.add(r.code);
            }
          }

          _cache[sport] = existing;
          // Persist to disk per-sport for fast cold-start switch.
          SharedPreferences.getInstance().then((prefs) {
            final simple = existing.map((r) => {
              'code': r.code, 'type': r.type, 'productType': r.productType,
              'caption': r.caption, 'likeCount': r.likeCount,
              'commentCount': r.commentCount, 'viewCount': r.viewCount,
              'takenAt': r.takenAt, 'videoUrl': r.videoUrl,
              'imageUrl': r.imageUrl, 'link': r.link, 'username': r.username,
            }).toList();
            prefs.setString(_prefsKey(sport), jsonEncode(simple));
          });
          return existing;
        }
      }
    } catch (e) {
      debugPrint('ReelsService: failed ($e)');
    }
    // On error/empty: if we have stale cache, serve it instead of empty.
    if (_cache.containsKey(sport) && _cache[sport]!.isNotEmpty) {
      _hasMore[sport] = false;
      return _cache[sport]!;
    }
    return [];
  }
}
