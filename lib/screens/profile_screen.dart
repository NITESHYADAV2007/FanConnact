import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import '../l10n.dart';

// Profile screen — mirrors the web profile.html / user-profile.html.
class ProfileScreen extends StatefulWidget {
  final Locale locale;
  final bool isDark;

  const ProfileScreen({super.key, required this.locale, required this.isDark});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  int _rank = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final snap =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final d = snap.data() ?? {};
      // Merge auth display info if missing.
      d['email'] ??= user.email;
      d['photoURL'] ??= user.photoURL;
      d['fullName'] ??= user.displayName;
      // Compute global rank by sorting all users by xp.
      final all = await FirebaseFirestore.instance.collection('users').get();
      final users = all.docs.map((e) {
        final m = e.data();
        return {
          'uid': e.id,
          'xp': int.tryParse('${m['xp'] ?? 0}') ?? 0,
        };
      }).toList();
      users.sort((a, b) => (b['xp'] as int).compareTo(a['xp'] as int));
      final idx = users.indexWhere((u) => u['uid'] == user.uid);
      _rank = idx >= 0 ? idx + 1 : 0;
      setState(() {
        _data = d;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  String _displayName(Map<String, dynamic> d) {
    return (d['fullName'] ?? d['username'] ?? d['email'] ?? 'Fan')
        .toString()
        .split('@')[0];
  }

  String _avatar(Map<String, dynamic> d) {
    if (d['photoURL'] != null && d['photoURL'].toString().isNotEmpty) {
      return d['photoURL'];
    }
    final seed = d['email'] ?? d['username'] ?? 'fan';
    return 'https://i.pravatar.cc/100?u=${Uri.encodeComponent(seed)}';
  }

  int _level(Map<String, dynamic> d) {
    final xp = int.tryParse('${d['xp'] ?? 0}') ?? 0;
    // Same formula as web LevelSystem.levelFromXP (1 level per 500 xp).
    return (xp / 500).floor() + 1;
  }

  int _xpToNext(int xp) => ((xp / 500).floor() + 1) * 500 - xp;
  double _xpProgress(int xp) => (_xpToNext(xp) == 500 ? 0 : 1 - _xpToNext(xp) / 500);

  @override
  Widget build(BuildContext context) {
    final lang = widget.locale.languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final d = _data ?? {};
    final xp = int.tryParse('${d['xp'] ?? 0}') ?? 0;
    final coins = int.tryParse('${d['coins'] ?? 100}') ?? 100;
    final level = _level(d);
    final followers = (d['followers'] as List?)?.length ?? 0;
    final following = (d['following'] as List?)?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get(lang, 'editProfile'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
            tooltip: 'Sign out',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 42,
            backgroundImage: NetworkImage(_avatar(d)),
            onBackgroundImageError: (_, __) {},
            child: d['photoURL'] == null
                ? const Icon(Icons.person, size: 40)
                : null,
          ),
          const SizedBox(height: 10),
          Text(_displayName(d),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center),
          if (d['username'] != null)
            Text('@${d['username']}',
                style: TextStyle(color: Colors.grey.shade500),
                textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Level $level  ·  $xp XP',
                style: const TextStyle(
                    color: AppColors.brandBlue, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _xpProgress(xp),
            color: AppColors.brandBlue,
            backgroundColor: Colors.grey.withOpacity(0.2),
          ),
          Text('${_xpToNext(xp)} XP to Level ${level + 1}',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _stat('$coins', 'Coins'),
              _stat('$followers', 'Followers'),
              _stat('$following', 'Following'),
              _stat(_rank > 0 ? '#$_rank' : '—', 'Rank'),
            ],
          ),
          const SizedBox(height: 20),
          _SectionTitle('Details'),
          if (d['fullName'] != null) _row('Full Name', '${d['fullName']}'),
          if (d['gender'] != null && d['gender'] != 'Not Specified')
            _row('Gender', '${d['gender']}'),
          if (d['location'] != null && d['location'] != 'Not Specified')
            _row('Location', '${d['location']}'),
          if (d['mobile'] != null && d['mobile'] != 'Not Specified')
            _row('Mobile', '${d['mobile']}'),
          if (d['createdAt'] != null)
            _row('Joined', _formatDate(d['createdAt'])),
        ],
      ),
    );
  }

  Widget _stat(String value, String label) => Column(
        children: [
          Text(value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ],
      );

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(width: 110, child: Text(k, style: const TextStyle(color: Colors.grey))),
            Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
      );

  String _formatDate(dynamic v) {
    try {
      final dt = v is Timestamp ? v.toDate() : DateTime.tryParse('$v');
      if (dt == null) return '$v';
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return '$v';
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: AppColors.brandBlue)),
      );
}
