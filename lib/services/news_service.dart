// Fetches real news from the Fanconnact website backend (/api/match/news).
// Falls back to the static `news` list in data.dart if the backend is
// unreachable (e.g. PC is off, phone on different network, or API down).

import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../data.dart';

class NewsService {
  // Mirrors the website's logic: hit the backend news endpoint, parse the
  // cricbuzz articles, and fall back to generated/static content on failure.
  static Future<List<NewsItem>> fetchNews() async {
    try {
      final res = await http
          .get(Uri.parse('$apiBaseUrl/api/match/news'))
          .timeout(const Duration(seconds: 8));

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final source = (json['source'] ?? 'Cricbuzz').toString();
        final articles = (json['articles'] as List?) ?? [];

        if (articles.isNotEmpty) {
          return articles.map<NewsItem>((a) {
            final map = a as Map<String, dynamic>;
            final img = (map['image'] ?? '').toString();
            return NewsItem(
              sport: 'cricket',
              sportEmoji: '🏏',
              title: (map['title'] ?? '').toString(),
              source: source,
              timeAgo: (map['time'] ?? '').toString(),
              tag: 'NEWS',
              image: img.isNotEmpty ? img : null,
            );
          }).toList();
        }
      }
    } catch (e) {
      // Network error / timeout / parse error → use static fallback below.
      debugPrint('NewsService: falling back to static news ($e)');
    }
    return news; // static fallback
  }
}
