// Player detail screen — shows real player info fetched from the RapidAPI
// cricket endpoint (cricket-live-line-advance). For other sports we show the
// basic info we have from the rankings payload.

import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/rapid_api_service.dart';

class PlayerDetailScreen extends StatefulWidget {
  final String sportKey;
  final String name;
  final String? country;
  final Map<String, dynamic>? extra; // ranking extra map (may hold pid/team/role)

  const PlayerDetailScreen({
    super.key,
    required this.sportKey,
    required this.name,
    this.country,
    this.extra,
  });

  @override
  State<PlayerDetailScreen> createState() => _PlayerDetailScreenState();
}

class _PlayerDetailScreenState extends State<PlayerDetailScreen> {
  Map<String, dynamic>? _player;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.sportKey == 'cricket') {
      final pid = int.tryParse(widget.extra?['pid']?.toString() ?? '');
      if (pid != null) {
        _player = await RapidApiService.fetchCricketPlayer(pid);
      }
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = widget.name;
    final country = widget.country ??
        (_player?['nationality']?.toString()) ??
        (_player?['country'] != null
            ? _countryName(_player!['country'].toString())
            : null);

    return Scaffold(
      appBar: AppBar(
        title: Text(name,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile link copied')),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark ? AppColors.darkCard : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: AppColors.brandBlue,
                        backgroundImage: _player?['country_flag'] != null &&
                                _player!['country_flag'].toString().isNotEmpty
                            ? NetworkImage(_player!['country_flag'].toString())
                            : null,
                        child: _player?['country_flag'] == null ||
                                _player!['country_flag'].toString().isEmpty
                            ? Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 28, color: Colors.white),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (country != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  country,
                                  style: const TextStyle(
                                      fontSize: 13, color: Colors.grey),
                                ),
                              ),
                            if (_player?['playing_role'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandBlue
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    _player!['playing_role']
                                        .toString()
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.brandBlue,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Stats grid
                _InfoTile('Batting Style',
                    _player?['batting_style']?.toString() ?? '—'),
                _InfoTile('Bowling Style',
                    _player?['bowling_style']?.toString() ?? '—'),
                _InfoTile(
                    'Fantasy Rating',
                    (_player?['fantasy_player_rating']?.toString() ?? '—')),
                _InfoTile('Birthdate',
                    _player?['birthdate']?.toString() ?? '—'),
                if (_player?['bio'] != null &&
                    _player!['bio'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _player!['bio'].toString(),
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.black54,
                        height: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _InfoTile(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isDark ? AppColors.darkCard : Colors.white,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  String _countryName(String code) {
    const map = {
      'lk': 'Sri Lanka',
      'ae': 'UAE',
      'in': 'India',
      'au': 'Australia',
      'en': 'England',
      'za': 'South Africa',
      'pk': 'Pakistan',
      'bd': 'Bangladesh',
      'nz': 'New Zealand',
      'us': 'USA',
      'ca': 'Canada',
    };
    return map[code.toLowerCase()] ?? code.toUpperCase();
  }
}
