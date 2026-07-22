// Fetches real sports reels from the backend (/api/reels) powered by Instagram.
// Filterable by sport. Falls back to an empty list (UI shows a placeholder).

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class ReelItem {
  final String code;
  final int type; // 1=image, 2=video/clip, 8=carousel
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
  // How long client-side results stay valid before we allow a backend call.
  static const Duration cacheTtl = Duration(minutes: 15);
  static const int pageSize = 20;

  // sport key -> accumulated payload + timestamp
  static final Map<String, List<ReelItem>> _cache = {};
  static final Map<String, DateTime> _cacheTime = {};
  static final Map<String, int> _loadedPages = {};
  static final Map<String, bool> _hasMore = {};
  // sport key -> in-flight future (so concurrent calls share ONE request)
  static final Map<String, Future<List<ReelItem>>> _inflight = {};

  // Force a fresh fetch (bypasses cache). Used by pull-to-refresh.
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
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final reels = (json['reels'] as List?) ?? [];
        _hasMore[sport] = json['hasMore'] as bool? ?? false;
        _loadedPages[sport] = page + 1;
        _cacheTime[sport] = DateTime.now();
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
