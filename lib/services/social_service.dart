import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class SocialService {
  static Future<int> likeReel(String code) async {
    try {
      final r = await http
          .post(Uri.parse('$apiBaseUrl/api/social/reel/$code/like'))
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body) as Map;
        return (j['likes'] ?? 0) as int;
      }
    } catch (_) {}
    return 0;
  }

  static Future<int> unlikeReel(String code) async {
    try {
      final r = await http
          .post(Uri.parse('$apiBaseUrl/api/social/reel/$code/unlike'))
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body) as Map;
        return (j['likes'] ?? 0) as int;
      }
    } catch (_) {}
    return 0;
  }

  static Future<Map<String, dynamic>?> commentOnReel(
      String code, String text, String username) async {
    try {
      final r = await http
          .post(
            Uri.parse('$apiBaseUrl/api/social/reel/$code/comment'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'text': text, 'username': username}),
          )
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body) as Map;
        return j['comment'] as Map<String, dynamic>?;
      }
    } catch (_) {}
    return null;
  }

  static Future<int> shareReel(String code) async {
    try {
      final r = await http
          .post(Uri.parse('$apiBaseUrl/api/social/reel/$code/share'))
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) {
        final j = jsonDecode(r.body) as Map;
        return (j['shares'] ?? 0) as int;
      }
    } catch (_) {}
    return 0;
  }

  static Future<Map<String, dynamic>?> getReelStats(String code) async {
    try {
      final r = await http
          .get(Uri.parse('$apiBaseUrl/api/social/reel/$code'))
          .timeout(const Duration(seconds: 5));
      if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }
}
