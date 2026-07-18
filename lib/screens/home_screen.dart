import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets/sport_selector.dart';
import '../widgets/match_card.dart';
import '../widgets/news_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedSport = 'all'; // default = All Sports

  List<MatchItem> get _filteredMatches {
    if (_selectedSport == 'all') return matches;
    return matches.where((m) => m.sport == _selectedSport).toList();
  }

  List<NewsItem> get _filteredNews {
    if (_selectedSport == 'all') return news;
    return news.where((n) => n.sport == _selectedSport).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/fancoin/fanconnactlogo.png',
              height: 28,
              width: 28,
            ),
            const SizedBox(width: 8),
            const Text(
              'Fanconnact',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Sticky sport selector at top
          SportSelector(
            selectedKey: _selectedSport,
            onSelected: (key) => setState(() => _selectedSport = key),
          ),
          const Divider(height: 1),
          // Scrollable content: matches then news feed
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {},
              child: ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 14, 16, 4),
                    child: Text(
                      'MATCHES',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (_filteredMatches.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('No matches for this sport right now.',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ..._filteredMatches
                        .map((m) => MatchCard(match: m))
                        .toList(),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 18, 16, 4),
                    child: Text(
                      'NEWS FEED',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (_filteredNews.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text('No news for this sport right now.',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    )
                  else
                    ..._filteredNews.map((n) => NewsCard(item: n)).toList(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
