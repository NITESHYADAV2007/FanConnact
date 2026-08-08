import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../data.dart';

class CurrentsService {
  static const String _base = 'https://api.currentsapi.services/v1';
  static const String _key = 'BrnWuEr94XsAc5qamVCNN-RJGYqobJvE6u43RUqrGC08prWS';

  static const String fallbackImage =
      'https://images.unsplash.com/photo-1504450758481-7338eba7524a?auto=format&fit=crop&q=80&w=1536';

  static Future<List<NewsItem>> fetchHeadlines({String category = '', String language = 'en'}) async {
    final articles = <NewsItem>[];
    try {
      final params = <String, String>{'apiKey': _key, 'language': language};
      String endpoint;
      if (category.isNotEmpty && category != 'all') {
        endpoint = '/search';
        params['keywords'] = category;
      } else {
        endpoint = '/latest-news';
        params['category'] = 'sports';
      }
      int page = 1;
      bool hasMore = true;
      while (hasMore && page <= 2) {
        params['page_number'] = page.toString();
        final uri = Uri.parse('$_base$endpoint').replace(queryParameters: params);
        final res = await http.get(uri).timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final j = jsonDecode(res.body) as Map<String, dynamic>;
          if (j['status'] == 'ok' && j['news'] is List) {
            for (final item in j['news'] as List) {
              final map = item as Map<String, dynamic>;
              final img = (map['image'] ?? '').toString();
              articles.add(NewsItem(
                sport: category.isNotEmpty ? category : 'all',
                sportEmoji: '📰',
                title: (map['title'] ?? '').toString(),
                source: (map['source'] is Map ? (map['source']!['name'] ?? 'Currents') : map['source'] ?? 'Currents').toString(),
                timeAgo: '',
                tag: 'BREAKING',
                image: img.isNotEmpty ? img : null,
                description: (map['description'] ?? '').toString(),
                link: (map['url'] ?? '').toString(),
              ));
            }
          }
          hasMore = (j['next'] ?? false) == true;
          page++;
        } else {
          break;
        }
      }
    } catch (_) {}
    if (articles.isEmpty) {
      articles.addAll(_fallbackHeadlines);
    }
    return articles;
  }

  static final List<NewsItem> _fallbackHeadlines = [
    NewsItem(sport:'all',sportEmoji:'📰',title:'IPL 2025: MI Clinch Thrilling Victory Over CSK in Final Over',source:'Sports',timeAgo:'',tag:'BREAKING',image:fallbackImage,description:'Mumbai Indians chased down 189 with a last-ball six.',link:''),
    NewsItem(sport:'all',sportEmoji:'📰',title:'Premier League: Arsenal Go Top After Dominant Win Over Chelsea',source:'Sports',timeAgo:'',tag:'BREAKING',image:fallbackImage,description:'Arsenal put on a masterclass at the Emirates.',link:''),
    NewsItem(sport:'all',sportEmoji:'📰',title:'NBA Finals: Lakers Take Game 1 Behind LeBron Triple-Double',source:'Sports',timeAgo:'',tag:'BREAKING',image:fallbackImage,description:'LeBron recorded his 40th playoff triple-double.',link:''),
    NewsItem(sport:'all',sportEmoji:'📰',title:'French Open: Djokovic Battles Past Alcaraz in Epic Quarterfinal',source:'Sports',timeAgo:'',tag:'BREAKING',image:fallbackImage,description:'Djokovic showed his champion grit at Roland Garros.',link:''),
    NewsItem(sport:'all',sportEmoji:'📰',title:'F1 Australian GP: Verstappen Dominates from Pole to Checkered Flag',source:'Sports',timeAgo:'',tag:'BREAKING',image:fallbackImage,description:'Verstappen led every lap at Albert Park.',link:''),
    NewsItem(sport:'all',sportEmoji:'📰',title:'Champions Trophy: India Set Up Final Clash With Australia',source:'Sports',timeAgo:'',tag:'BREAKING',image:fallbackImage,description:'India bowled out England for 218 and chased with six wickets.',link:''),
    NewsItem(sport:'all',sportEmoji:'📰',title:'MLB: Yankees Clinch Division Title With Walk-Off Homer',source:'Sports',timeAgo:'',tag:'BREAKING',image:fallbackImage,description:'Aaron Judge hit a walk-off two-run homer.',link:''),
    NewsItem(sport:'all',sportEmoji:'📰',title:'Hockey World Cup: Netherlands Edge Belgium in Shootout',source:'Sports',timeAgo:'',tag:'BREAKING',image:fallbackImage,description:'Netherlands defeated Belgium 4-3 in penalty shootout.',link:''),
  ];
}
