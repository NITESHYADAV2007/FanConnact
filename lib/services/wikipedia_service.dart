// Wikipedia image fallback (keyless) — mirrors the website helper: search the
// name on Wikipedia, then grab the page's lead thumbnail. Used whenever a
// team/player logo is missing or broken, so no card is ever left icon-less.

import 'dart:convert';
import 'package:http/http.dart' as http;

class WikipediaService {
  static final Map<String, String?> _cache = {};
  static final Map<String, Future<String?>> _inflight = {};
  static const Duration timeout = Duration(seconds: 8);

  /// Returns a lead-image URL for [name] (e.g. "Mumbai Indians" -> logo pic),
  /// or null when nothing usable is found. Cached in-memory forever.
  static Future<String?> fetchImage(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return null;
    if (_cache.containsKey(clean)) return _cache[clean];
    if (_inflight.containsKey(clean)) return _inflight[clean];

    final future = _doFetch(clean);
    _inflight[clean] = future;
    try {
      return await future;
    } finally {
      _inflight.remove(clean);
    }
  }

  static Future<String?> _doFetch(String name) async {
    try {
      // One round-trip: generator=search + pageimages thumbnails.
      final query = Uri.parse('https://en.wikipedia.org/w/api.php').replace(
        queryParameters: {
          'action': 'query',
          'format': 'json',
          'origin': '*',
          'generator': 'search',
          'gsrsearch': '$name sports team',
          'gsrlimit': '1',
          'prop': 'pageimages',
          'pithumbsize': '400',
          'redirects': '1',
        },
      );
      final res = await http.get(query).timeout(timeout);
      if (res.statusCode != 200) return null;
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final pages = json['query']?['pages'];
      if (pages is! Map || pages.isEmpty) return null;
      final page = pages.values.first as Map<String, dynamic>;
      final thumb = page['thumbnail'] as Map<String, dynamic>?;
      final url = thumb?['source']?.toString() ?? '';
      _cache[name] = url.isNotEmpty ? url : null;
      return url.isNotEmpty ? url : null;
    } catch (_) {
      _cache[name] = null;
      return null;
    }
  }
}
