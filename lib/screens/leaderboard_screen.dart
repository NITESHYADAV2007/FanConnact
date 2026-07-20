import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import '../l10n.dart';

// Leaderboard — mirrors the web leaderboard.html (real Firestore users only).
class LeaderboardScreen extends StatefulWidget {
  final Locale locale;
  final bool isDark;

  const LeaderboardScreen({super.key, required this.locale, required this.isDark});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('users').get();
      final list = snap.docs.map((e) {
        final d = e.data();
        final xp = int.tryParse('${d['xp'] ?? 0}') ?? 0;
        final coins = int.tryParse('${d['coins'] ?? 100}') ?? 100;
        final level = (xp / 500).floor() + 1;
        final name = d['username'] ?? d['fullName'] ?? d['email'] ?? 'Fan';
        final img = d['photoURL'] ??
            (d['email'] != null
                ? 'https://i.pravatar.cc/100?u=${Uri.encodeComponent(d['email'])}'
                : '');
        return {
          'uid': e.id,
          'name': name,
          'xp': xp,
          'coins': coins,
          'level': level,
          'img': img,
        };
      }).toList();
      list.sort((a, b) {
        if (a['xp'] != b['xp']) return b['xp'].compareTo(a['xp']);
        if (a['coins'] != b['coins']) return b['coins'].compareTo(a['coins']);
        return a['name'].compareTo(b['name']);
      });
      for (var i = 0; i < list.length; i++) list[i]['rank'] = i + 1;
      setState(() {
        _users = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.locale.languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get(lang, 'leaderboard') != null
            ? 'Leaderboard'
            : 'Leaderboard'),
        automaticallyImplyLeading: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text('Could not load users: $_error',
                        style: const TextStyle(color: AppColors.liveRed),
                        textAlign: TextAlign.center),
                  ),
                )
              : _users.isEmpty
                  ? const Center(child: Text('No users yet'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, i) {
                        final u = _users[i];
                        final top = u['rank'] <= 3;
                        return Container(
                          decoration: BoxDecoration(
                            color: top
                                ? AppColors.brandBlue.withValues(alpha: 0.12)
                                : (Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkCard
                                    : Colors.white),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.grey.withOpacity(0.15)),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: u['img'].isNotEmpty
                                  ? NetworkImage(u['img'])
                                  : null,
                              child: u['img'].isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(u['name'],
                                style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text('Level ${u['level']}  ·  ${u['coins']} 🪙'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.brandBlue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('#${u['rank']}',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
