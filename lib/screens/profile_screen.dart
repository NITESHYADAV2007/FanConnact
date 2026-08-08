import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';
import '../l10n.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final Locale locale;
  final bool isDark;
  final VoidCallback? onToggleTheme;
  final ThemeType themeType;
  final ValueChanged<ThemeType>? onThemeChanged;
  final ValueChanged<Locale>? onLocaleChanged;
  final Color accentColor;
  final ValueChanged<Color>? onAccentColorChanged;

  const ProfileScreen({
    super.key,
    required this.locale,
    required this.isDark,
    this.onToggleTheme,
    this.themeType = ThemeType.dark,
    this.onThemeChanged,
    this.onLocaleChanged,
    this.accentColor = AppColors.brandBlue,
    this.onAccentColorChanged,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  int _rank = 0;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _load();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((_) => _load());
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final d = snap.data() ?? {};
      d['email'] ??= user.email;
      d['photoURL'] ??= user.photoURL;
      d['fullName'] ??= user.displayName;
      final all = await FirebaseFirestore.instance.collection('users').get();
      final users = all.docs.map((e) {
        final m = e.data();
        return {'uid': e.id, 'xp': int.tryParse('${m['xp'] ?? 0}') ?? 0};
      }).toList();
      users.sort((a, b) => (b['xp'] as int).compareTo(a['xp'] as int));
      final idx = users.indexWhere((u) => u['uid'] == user.uid);
      _rank = idx >= 0 ? idx + 1 : 0;
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _displayName(Map<String, dynamic> d) {
    return (d['fullName'] ?? d['username'] ?? d['email'] ?? 'Fan').toString().split('@')[0];
  }

  String _avatar(Map<String, dynamic> d) {
    if (d['photoURL'] != null && d['photoURL'].toString().isNotEmpty) {
      var url = d['photoURL'].toString();
      if (url.contains('/svg?')) url = url.replaceAll('/svg?', '/png?');
      return url;
    }
    return 'https://i.pravatar.cc/100?u=${Uri.encodeComponent(d['email'] ?? 'fan')}';
  }

  int _level(Map<String, dynamic> d) {
    final xp = int.tryParse('${d['xp'] ?? 0}') ?? 0;
    return (xp / 500).floor() + 1;
  }

  int _xpToNext(int xp) => ((xp / 500).floor() + 1) * 500 - xp;
  double _xpProgress(int xp) => (_xpToNext(xp) == 500 ? 0 : 1 - _xpToNext(xp) / 500);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('Profile', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.person_outline, size: 80, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text('Sign in to view your profile',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Sign In'),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => LoginScreen(
                      isDark: widget.isDark,
                      onToggleTheme: widget.onToggleTheme ?? () {},
                      locale: widget.locale,
                      onLocaleChanged: widget.onLocaleChanged ?? (l) {},
                      accentColor: widget.accentColor,
                      onAccentColorChanged: widget.onAccentColorChanged ?? (c) {},
                    ),
                  )).then((_) {
                    if (mounted) _load();
                  });
                },
              ),
            ],
          ),
        ),
      );
    }

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final d = _data ?? {};
    final xp = int.tryParse('${d['xp'] ?? 0}') ?? 0;
    final coins = int.tryParse('${d['coins'] ?? 100}') ?? 100;
    final level = _level(d);
    final followers = (d['followers'] as List?)?.length ?? 0;
    final following = (d['following'] as List?)?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(AppStrings.get(Localizations.localeOf(context).languageCode, 'profile'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: AppStrings.get(Localizations.localeOf(context).languageCode, 'settings'),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => SettingsScreen(
                  onToggleTheme: widget.onToggleTheme ?? () {},
                  isDark: widget.isDark,
                  themeType: widget.themeType,
                  onThemeChanged: widget.onThemeChanged ?? (_) {},
                  onLocaleChanged: widget.onLocaleChanged ?? (l) {},
                  locale: widget.locale,
                  accentColor: widget.accentColor,
                  onAccentColorChanged: widget.onAccentColorChanged ?? (c) {},
                ),
              ));
            },
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
            child: d['photoURL'] == null ? const Icon(Icons.person, size: 40) : null,
          ),
          const SizedBox(height: 10),
          Text(_displayName(d),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
              textAlign: TextAlign.center),
          if (d['username'] != null)
            Text('@${d['username']}', style: TextStyle(color: Colors.grey.shade500), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.brandBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('Level $level  ·  $xp XP',
                style: const TextStyle(color: AppColors.brandBlue, fontWeight: FontWeight.w800)),
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
          _ActionCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'FanCoin Wallet',
            subtitle: '$coins coins available',
            color: const Color(0xFFFF9800),
            onTap: () => _showCoinHistory(context, coins),
          ),
          const SizedBox(height: 8),
          _ActionCard(
            icon: Icons.track_changes_outlined,
            title: 'My Predictions',
            subtitle: 'View your prediction history',
            color: AppColors.brandBlue,
            onTap: () {},
          ),
          const SizedBox(height: 8),
          _ActionCard(
            icon: Icons.groups_outlined,
            title: 'My Communities',
            subtitle: 'Communities you\'ve joined',
            color: const Color(0xFF764BA2),
            onTap: () {},
          ),
          const SizedBox(height: 20),
          _SectionTitle('Details'),
          if (d['fullName'] != null) _row('Full Name', '${d['fullName']}'),
          if (d['gender'] != null && d['gender'] != 'Not Specified') _row('Gender', '${d['gender']}'),
          if (d['location'] != null && d['location'] != 'Not Specified') _row('Location', '${d['location']}'),
          if (d['mobile'] != null && d['mobile'] != 'Not Specified') _row('Mobile', '${d['mobile']}'),
          if (d['createdAt'] != null) _row('Joined', _formatDate(d['createdAt'])),
          const SizedBox(height: 24),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.logout, color: AppColors.liveRed),
              label: const Text('Sign Out', style: TextStyle(color: AppColors.liveRed)),
              onPressed: () => FirebaseAuth.instance.signOut(),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showCoinHistory(BuildContext context, int currentCoins) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.3,
          expand: false,
          builder: (ctx, scrollCtrl) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9800).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.monetization_on, color: Color(0xFFFF9800), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('FanCoin Wallet',
                                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                            Text('$currentCoins coins available',
                                style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white12 : Colors.black12,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      _FilterChip(label: 'All', selected: true, onTap: () {}),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Earned', selected: false, onTap: () {}),
                      const SizedBox(width: 8),
                      _FilterChip(label: 'Spent', selected: false, onTap: () {}),
                    ],
                  ),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('transactions')
                        .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                        .orderBy('createdAt', descending: true)
                        .limit(50)
                        .snapshots(),
                    builder: (ctx, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final docs = snap.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 8),
                              Text('No transactions yet',
                                  style: TextStyle(color: Colors.grey.shade500)),
                            ],
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: scrollCtrl,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: docs.length,
                        itemBuilder: (_, i) {
                          final tx = docs[i].data() as Map<String, dynamic>;
                          final amount = (tx['amount'] ?? 0).toInt();
                          final desc = tx['description'] ?? '';
                          final isEarned = amount > 0;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.withOpacity(0.1)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: isEarned ? Colors.green.withOpacity(0.12) : AppColors.liveRed.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(isEarned ? Icons.add : Icons.remove, color: isEarned ? Colors.green : AppColors.liveRed, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(desc, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                      Text(tx['date'] ?? '', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                    ],
                                  ),
                                ),
                                Text('${isEarned ? '+' : ''}$amount 🪙',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: isEarned ? Colors.green : AppColors.liveRed,
                                    )),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _stat(String value, String label) => Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
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
    } catch (_) { return '$v'; }
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black45)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Text(text.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.brandBlue)),
      );
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.brandBlue : Colors.grey.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                color: selected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54))),
      ),
    );
  }
}
