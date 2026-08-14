// Pro Crex-style Communities screen:
//   - hero banner with live stats (communities / members / fans online)
//   - category chips (Sports / Teams / Fan Clubs + per-sport quick filters)
//   - search
//   - polished community cards (gradient icon, member count, online badge,
//     join/leave CTA)
//   - community detail with banner, post composer and a vertical posts feed
//     (likes + threaded replies), real-time via Firestore.
// Existing wiring (Firestore communities, coin-gated creation, public joins)
// is preserved.

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../config.dart';
import '../theme.dart';

class CommunitiesScreen extends StatefulWidget {
  final Locale locale;
  final bool isDark;

  const CommunitiesScreen({super.key, required this.locale, required this.isDark});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  String _tab = 'discover';
  String _category = 'All';
  String _search = '';
  final TextEditingController _searchCtrl = TextEditingController();
  int _onlineNow = 0;

  static const _categories = <String>[
    'All', 'Sports', 'Teams', 'Fan Clubs',
    'Cricket', 'Football', 'Basketball', 'Esports',
  ];

  @override
  void initState() {
    super.initState();
    _fetchOnlineTotal();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchOnlineTotal() async {
    try {
      final r = await http
          .get(Uri.parse('$apiBaseUrl/api/presence/total'))
          .timeout(const Duration(seconds: 6));
      final j = json.decode(r.body);
      final count = (j['count'] as num?)?.toInt() ?? 0;
      if (mounted) setState(() => _onlineNow = count);
    } catch (_) {}
  }

  bool _matchesCategory(Map<String, dynamic> d) {
    final cat = _category;
    if (cat == 'All') return true;
    final name = (d['name'] ?? '').toString().toLowerCase();
    final desc = (d['description'] ?? '').toString().toLowerCase();
    final icon = (d['icon'] ?? 'groups').toString().toLowerCase();
    if (cat == 'Sports' || cat == 'Teams' || cat == 'Fan Clubs') {
      return _broadCategory(d) == cat;
    }
    if (cat == 'Cricket') return name.contains('cricket') || icon == 'cricket' || name.contains('ipl');
    if (cat == 'Football') return name.contains('football') || name.contains('soccer') || icon == 'football';
    if (cat == 'Basketball') return name.contains('basketball') || icon == 'basketball';
    if (cat == 'Esports') return name.contains('esport') || name.contains('gaming') || icon == 'esports';
    return desc.contains(cat.toLowerCase()) || name.contains(cat.toLowerCase());
  }

  String _broadCategory(Map<String, dynamic> d) {
    final name = (d['name'] ?? '').toString().toLowerCase();
    final icon = (d['icon'] ?? 'groups').toString().toLowerCase();
    const sportIcons = ['cricket', 'football', 'basketball', 'esports', 'sports', 'sports_soccer', 'sports_cricket', 'sports_basketball', 'sports_esports'];
    if (sportIcons.contains(icon) ||
        name.contains('fan') && name.contains('club')) {
      return 'Fan Clubs';
    }
    if (icon == 'groups' || name.contains('club') || name.contains('fan')) {
      return 'Fan Clubs';
    }
    if (sportIcons.contains(icon) || name.contains('team') || name.contains('fc')) {
      return 'Teams';
    }
    return 'Sports';
  }

  bool _matchesSearch(Map<String, dynamic> d) {
    final q = _search.trim().toLowerCase();
    if (q.isEmpty) return true;
    final name = (d['name'] ?? '').toString().toLowerCase();
    final desc = (d['description'] ?? '').toString().toLowerCase();
    return name.contains(q) || desc.contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Communities',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'Create Community',
              onPressed: () => _showCreateDialog(context),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Hero banner ──
          _HeroBanner(onlineNow: _onlineNow),
          // ── Category chips ──
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final c = _categories[i];
                final selected = c == _category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _category = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.brandBlue
                            : isDark
                                ? AppColors.darkCard
                                : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected
                              ? AppColors.brandBlue
                              : Colors.grey.withOpacity(0.25),
                        ),
                      ),
                      child: Text(c,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected
                                ? Colors.white
                                : (isDark ? Colors.white70 : Colors.black54),
                          )),
                    ),
                  ),
                );
              },
            ),
          ),
          // ── Search ──
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search communities…',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: isDark ? AppColors.darkCard : Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                ),
              ),
            ),
          ),
          // ── Tabs ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                _TabBtn(label: 'Discover', selected: _tab == 'discover', onTap: () => setState(() => _tab = 'discover')),
                const SizedBox(width: 8),
                _TabBtn(label: 'My Communities', selected: _tab == 'joined', onTap: () => setState(() => _tab = 'joined')),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: user == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.groups_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text('Sign in to join communities',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 15)),
                      ],
                    ),
                  )
                : _tab == 'joined'
                    ? _CommunitiesList(
                        user: user,
                        isDark: isDark,
                        search: _search,
                        category: _category,
                        onCategory: _matchesCategory,
                        onSearch: _matchesSearch,
                      )
                    : _DiscoverList(
                        user: user,
                        isDark: isDark,
                        search: _search,
                        category: _category,
                        onCategory: _matchesCategory,
                        onSearch: _matchesSearch,
                      ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String visibility = 'public';
    String icon = 'groups';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Create Community'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Community Name', border: OutlineInputBorder()), textCapitalization: TextCapitalization.words),
                const SizedBox(height: 12),
                TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()), maxLines: 3),
                const SizedBox(height: 16),
                const Text('Visibility', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _VisibilityOption(
                      label: 'Public',
                      icon: Icons.public,
                      selected: visibility == 'public',
                      onTap: () => setDialogState(() => visibility = 'public'),
                    ),
                    const SizedBox(width: 8),
                    _VisibilityOption(
                      label: 'Private',
                      icon: Icons.lock_outline,
                      selected: visibility == 'private',
                      onTap: () => setDialogState(() => visibility = 'private'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Icon', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _communityIcons.entries.map((e) {
                    final selected = icon == e.key;
                    return GestureDetector(
                      onTap: () => setDialogState(() => icon = e.key),
                      child: Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.brandBlue.withOpacity(0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: selected ? AppColors.brandBlue : Colors.grey.withOpacity(0.3),
                            width: selected ? 2 : 1,
                          ),
                        ),
                        child: Icon(e.value, color: selected ? AppColors.brandBlue : Colors.grey, size: 22),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                final created = await _createCommunity(nameCtrl.text.trim(), descCtrl.text.trim(), visibility: visibility, icon: icon);
                if (created && ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Create (50 🪙)'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _createCommunity(String name, String desc, {String visibility = 'public', String icon = 'groups'}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final db = FirebaseFirestore.instance;
    final userRef = db.collection('users').doc(user.uid);
    final communityRef = db.collection('communities').doc();

    try {
      await db.runTransaction((tx) async {
        final userSnap = await tx.get(userRef);
        final data = userSnap.data() ?? <String, dynamic>{};
        final coins = (data['coins'] is num) ? (data['coins'] as num).toInt() : 100;

        if (coins < 50) {
          throw StateError('INSUFFICIENT_COINS');
        }

        tx.set(communityRef, {
          'name': name,
          'description': desc,
          'createdBy': user.uid,
          'createdByName': user.displayName ?? user.email ?? 'Unknown',
          'createdAt': FieldValue.serverTimestamp(),
          'visibility': visibility,
          'icon': icon,
          'memberCount': 1,
          'members': [user.uid],
        });

        tx.set(userRef, {
          'coins': coins - 50,
          'communities': FieldValue.arrayUnion([communityRef.id]),
        }, SetOptions(merge: true));
      });

      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(visibility == 'public'
            ? 'Community created and published!'
            : 'Private community created!')),
      );
      return true;
    } on StateError catch (e) {
      if (!mounted) return false;
      final message = e.message == 'INSUFFICIENT_COINS'
          ? 'You need at least 50 FanCoins to create a community.'
          : 'Could not create the community.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      return false;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create the community. Please try again.')),
      );
      return false;
    }
  }
}

// ── Hero banner ──────────────────────────────────────────────────────────────
class _HeroBanner extends StatelessWidget {
  final int onlineNow;
  const _HeroBanner({required this.onlineNow});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.brandBlue, Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandBlue.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.groups, color: Colors.white, size: 26),
              const SizedBox(width: 10),
              const Expanded(
                child: Text('Fan Communities',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 19)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF4CD964),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text('$onlineNow online',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Join fan clubs, follow your teams and share match-day moments.',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85), fontSize: 12.5)),
        ],
      ),
    );
  }
}

const Map<String, IconData> _communityIcons = {
  'groups': Icons.groups,
  'sports': Icons.sports,
  'cricket': Icons.sports_cricket,
  'football': Icons.sports_soccer,
  'basketball': Icons.sports_basketball,
  'esports': Icons.sports_esports,
  'music': Icons.music_note,
  'movie': Icons.movie,
  'favorite': Icons.favorite,
  'star': Icons.star,
  'school': Icons.school,
  'camera': Icons.camera_alt,
};

IconData communityIconFor(String? name) {
  if (name != null && _communityIcons.containsKey(name)) return _communityIcons[name]!;
  return Icons.groups;
}

class _VisibilityOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _VisibilityOption({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandBlue.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.brandBlue : Colors.grey.withOpacity(0.3),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? AppColors.brandBlue : Colors.grey),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: selected ? AppColors.brandBlue : Colors.grey,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _TabBtn({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.brandBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? AppColors.brandBlue : Colors.grey.withOpacity(0.3)),
        ),
        child: Text(label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: selected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54),
            )),
      ),
    );
  }
}

// ── Joined communities list ──────────────────────────────────────────────────
class _CommunitiesList extends StatelessWidget {
  final User user;
  final bool isDark;
  final String search;
  final String category;
  final bool Function(Map<String, dynamic>) onCategory;
  final bool Function(Map<String, dynamic>) onSearch;
  const _CommunitiesList({
    required this.user,
    required this.isDark,
    required this.search,
    required this.category,
    required this.onCategory,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('communities')
          .where('members', arrayContains: user.uid)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('Could not load your communities.',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                ],
              ),
            ),
          );
        }
        final docs = (snap.data?.docs ?? [])
          ..sort((a, b) {
            final ta = (a.data() as Map<String, dynamic>)['createdAt'];
            final tb = (b.data() as Map<String, dynamic>)['createdAt'];
            if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
            return 0;
          });
        final filtered = docs
            .where((d) => onCategory(d.data() as Map<String, dynamic>))
            .where((d) => onSearch(d.data() as Map<String, dynamic>))
            .toList();
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.group_off_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('You haven\'t joined any communities yet',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                const SizedBox(height: 8),
                Text('Create one or discover communities below',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final d = filtered[i].data() as Map<String, dynamic>;
            return _CommunityCard(
              name: d['name'] ?? 'Unnamed',
              desc: d['description'] ?? '',
              memberCount: (d['memberCount'] ?? 1).toInt(),
              createdByName: d['createdByName'] ?? 'Unknown',
              docId: filtered[i].id,
              isDark: isDark,
              visibility: d['visibility'] ?? 'public',
              icon: d['icon'] ?? 'groups',
              isMember: true,
            );
          },
        );
      },
    );
  }
}

// ── Discover list ────────────────────────────────────────────────────────────
class _DiscoverList extends StatelessWidget {
  final User user;
  final bool isDark;
  final String search;
  final String category;
  final bool Function(Map<String, dynamic>) onCategory;
  final bool Function(Map<String, dynamic>) onSearch;
  const _DiscoverList({
    required this.user,
    required this.isDark,
    required this.search,
    required this.category,
    required this.onCategory,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('communities')
          .where('visibility', isEqualTo: 'public')
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('Could not load communities.',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                ],
              ),
            ),
          );
        }
        final docs = (snap.data?.docs ?? [])
          ..sort((a, b) {
            final ma = (a.data() as Map<String, dynamic>)['memberCount'] ?? 0;
            final mb = (b.data() as Map<String, dynamic>)['memberCount'] ?? 0;
            return (mb is num ? mb.toInt() : 0) - (ma is num ? ma.toInt() : 0);
          });
        final filtered = docs
            .where((d) => onCategory(d.data() as Map<String, dynamic>))
            .where((d) => onSearch(d.data() as Map<String, dynamic>))
            .take(50)
            .toList();
        if (filtered.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.explore_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('No communities found.',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final d = filtered[i].data() as Map<String, dynamic>;
            final members = (d['members'] as List?) ?? [];
            final isMember = members.contains(user.uid);
            return _CommunityCard(
              name: d['name'] ?? 'Unnamed',
              desc: d['description'] ?? '',
              memberCount: (d['memberCount'] ?? 1).toInt(),
              createdByName: d['createdByName'] ?? 'Unknown',
              docId: filtered[i].id,
              isDark: isDark,
              isDiscover: true,
              isMember: isMember,
              visibility: d['visibility'] ?? 'public',
              icon: d['icon'] ?? 'groups',
            );
          },
        );
      },
    );
  }
}

// ── Community card (pro) ─────────────────────────────────────────────────────
class _CommunityCard extends StatefulWidget {
  final String name;
  final String desc;
  final int memberCount;
  final String createdByName;
  final String docId;
  final bool isDark;
  final bool isDiscover;
  final bool isMember;
  final String visibility;
  final String icon;

  const _CommunityCard({
    required this.name,
    required this.desc,
    required this.memberCount,
    required this.createdByName,
    required this.docId,
    required this.isDark,
    this.isDiscover = false,
    this.isMember = false,
    this.visibility = 'public',
    this.icon = 'groups',
  });

  @override
  State<_CommunityCard> createState() => _CommunityCardState();
}

class _CommunityCardState extends State<_CommunityCard> {
  bool _joining = false;

  Future<void> _join() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _joining || widget.isMember) return;
    setState(() => _joining = true);

    try {
      final db = FirebaseFirestore.instance;
      final communityRef = db.collection('communities').doc(widget.docId);
      final userRef = db.collection('users').doc(user.uid);

      await db.runTransaction((tx) async {
        final communitySnap = await tx.get(communityRef);
        if (!communitySnap.exists) {
          throw StateError('COMMUNITY_NOT_FOUND');
        }

        final data = communitySnap.data() as Map<String, dynamic>;
        if (data['visibility'] != 'public') {
          throw StateError('NOT_PUBLIC');
        }

        final members = List<String>.from((data['members'] as List?) ?? const []);
        if (members.contains(user.uid)) return;

        tx.update(communityRef, {
          'members': FieldValue.arrayUnion([user.uid]),
          'memberCount': (data['memberCount'] as num? ?? members.length) + 1,
        });
        tx.set(userRef, {
          'communities': FieldValue.arrayUnion([widget.docId]),
        }, SetOptions(merge: true));
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not join this community. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _leave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _joining || !widget.isMember) return;
    setState(() => _joining = true);

    try {
      final db = FirebaseFirestore.instance;
      final communityRef = db.collection('communities').doc(widget.docId);
      final userRef = db.collection('users').doc(user.uid);

      await db.runTransaction((tx) async {
        final communitySnap = await tx.get(communityRef);
        if (!communitySnap.exists) return;
        final data = communitySnap.data() as Map<String, dynamic>;
        final members = List<String>.from((data['members'] as List?) ?? const []);
        if (!members.contains(user.uid)) return;
        if (members.length <= 1) return; // owner can't leave their own community
        tx.update(communityRef, {
          'members': FieldValue.arrayRemove([user.uid]),
          'memberCount': ((data['memberCount'] as num? ?? members.length) - 1).clamp(1, 1 << 31),
        });
        tx.set(userRef, {
          'communities': FieldValue.arrayRemove([widget.docId]),
        }, SetOptions(merge: true));
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not leave this community. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => _CommunityDetailScreen(
              docId: widget.docId,
              name: widget.name,
              desc: widget.desc,
              memberCount: widget.memberCount,
              createdByName: widget.createdByName,
              visibility: widget.visibility,
              icon: widget.icon,
              isDark: isDark,
              isMember: widget.isMember,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Gradient icon tile
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppColors.brandBlue, Color(0xFF764BA2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(communityIconFor(widget.icon), color: Colors.white, size: 25),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(widget.name,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        widget.visibility == 'private' ? Icons.lock_outline : Icons.public,
                        size: 13,
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ],
                  ),
                  if (widget.desc.isNotEmpty)
                    Text(widget.desc,
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black45),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.people_outline,
                          size: 13, color: isDark ? Colors.white38 : Colors.black38),
                      const SizedBox(width: 4),
                      Text('${widget.memberCount} members',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : Colors.black54)),
                      const SizedBox(width: 10),
                      _PresenceBadge(communityId: widget.docId),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            if (widget.isDiscover)
              _joining
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                  : widget.isMember
                      ? OutlinedButton(
                          onPressed: _leave,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            side: BorderSide(color: Colors.grey.withOpacity(0.4)),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Leave',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        )
                      : FilledButton(
                          onPressed: _join,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandBlue,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            minimumSize: Size.zero,
                          ),
                          child: const Text('Join',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
            if (!widget.isDiscover)
              const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// Live "N online" badge — polls the backend presence endpoint so community
// activity feels real without any Firestore writes.
class _PresenceBadge extends StatefulWidget {
  final String communityId;
  const _PresenceBadge({required this.communityId});

  @override
  State<_PresenceBadge> createState() => _PresenceBadgeState();
}

class _PresenceBadgeState extends State<_PresenceBadge> {
  int _online = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 25), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final r = await http
          .get(Uri.parse(
              '$apiBaseUrl/api/presence/online?matchId=${widget.communityId}'))
          .timeout(const Duration(seconds: 6));
      final j = json.decode(r.body);
      final count = (j['count'] as num?)?.toInt() ?? 0;
      if (mounted) setState(() => _online = count);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_online <= 0) return const SizedBox.shrink();
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(
            color: Color(0xFF4CD964),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text('$_online online',
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF4CD964))),
      ],
    );
  }
}

// ── Community detail: banner + composer + vertical feed ─────────────────────
class _CommunityDetailScreen extends StatefulWidget {
  final String docId;
  final String name;
  final String desc;
  final int memberCount;
  final String createdByName;
  final String visibility;
  final String icon;
  final bool isDark;
  final bool isMember;

  const _CommunityDetailScreen({
    required this.docId,
    required this.name,
    required this.desc,
    required this.memberCount,
    required this.createdByName,
    required this.visibility,
    required this.icon,
    required this.isDark,
    required this.isMember,
  });

  @override
  State<_CommunityDetailScreen> createState() => _CommunityDetailScreenState();
}

class _CommunityDetailScreenState extends State<_CommunityDetailScreen> {
  final TextEditingController _composer = TextEditingController();
  final Map<String, TextEditingController> _replyCtrls = {};
  final Set<String> _expandedReplies = {};
  bool _isMember = false;

  @override
  void initState() {
    super.initState();
    _isMember = widget.isMember;
  }

  @override
  void dispose() {
    _composer.dispose();
    for (final c in _replyCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  String get _postPath => 'communities/${widget.docId}/posts';

  Future<void> _join() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final db = FirebaseFirestore.instance;
    final communityRef = db.collection('communities').doc(widget.docId);
    try {
      await db.runTransaction((tx) async {
        final snap = await tx.get(communityRef);
        final data = snap.data() as Map<String, dynamic>;
        tx.update(communityRef, {
          'members': FieldValue.arrayUnion([user.uid]),
          'memberCount': (data['memberCount'] as num? ?? 1) + 1,
        });
        tx.set(db.collection('users').doc(user.uid), {
          'communities': FieldValue.arrayUnion([widget.docId]),
        }, SetOptions(merge: true));
      });
      if (mounted) setState(() => _isMember = true);
    } catch (_) {}
  }

  Future<void> _leave() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final db = FirebaseFirestore.instance;
    final communityRef = db.collection('communities').doc(widget.docId);
    try {
      await db.runTransaction((tx) async {
        final snap = await tx.get(communityRef);
        final data = snap.data() as Map<String, dynamic>;
        final members = List<String>.from((data['members'] as List?) ?? const []);
        if (members.length <= 1) return;
        tx.update(communityRef, {
          'members': FieldValue.arrayRemove([user.uid]),
          'memberCount': ((data['memberCount'] as num? ?? members.length) - 1),
        });
        tx.set(db.collection('users').doc(user.uid), {
          'communities': FieldValue.arrayRemove([widget.docId]),
        }, SetOptions(merge: true));
      });
      if (mounted) setState(() => _isMember = false);
    } catch (_) {}
  }

  void _sendPost() {
    final user = FirebaseAuth.instance.currentUser;
    final t = _composer.text.trim();
    if (user == null || t.isEmpty || !_isMember) return;
    FirebaseFirestore.instance.collection(_postPath).add({
      'text': t,
      'uid': user.uid,
      'userName': user.displayName ?? user.email ?? 'Fan',
      'userPhoto': user.photoURL,
      'createdAt': FieldValue.serverTimestamp(),
      'likes': <String>[],
      'replies': <dynamic>[],
    });
    _composer.clear();
    FocusScope.of(context).unfocus();
  }

  String _timeAgo(dynamic v) {
    if (v is! Timestamp) return 'now';
    final diff = DateTime.now().difference(v.toDate());
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: Column(
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brandBlue, Color(0xFF764BA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 54, height: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(communityIconFor(widget.icon),
                          color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 17),
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.people_outline,
                                  size: 13, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text('${widget.memberCount} members',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                              const SizedBox(width: 10),
                              Icon(widget.visibility == 'private'
                                  ? Icons.lock_outline
                                  : Icons.public,
                                  size: 13, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(widget.visibility == 'private'
                                  ? 'Private'
                                  : 'Public',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (user != null)
                      _isMember
                          ? OutlinedButton(
                              onPressed: _leave,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(color: Colors.white70),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                              ),
                              child: const Text('Leave',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                            )
                          : FilledButton(
                              onPressed: _join,
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.brandBlue,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                              ),
                              child: const Text('Join',
                                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                            ),
                  ],
                ),
                if (widget.desc.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(widget.desc,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12.5)),
                ],
                const SizedBox(height: 6),
                Text('Created by ${widget.createdByName}',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 11)),
              ],
            ),
          ),
          // Composer (members only)
          if (user != null && _isMember)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              color: isDark ? AppColors.darkSurface : Colors.grey.shade50,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : null,
                    child: user.photoURL == null
                        ? Text(((user.displayName ?? user.email ?? 'F')
                                .toString()[0])
                            .toUpperCase())
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _composer,
                      maxLines: 3,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: 'Share with ${widget.name}…',
                        filled: true,
                        fillColor: isDark ? AppColors.darkCard : Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.brandBlue),
                    onPressed: _sendPost,
                  ),
                ],
              ),
            )
          else if (user == null)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text('Sign in and join to post in this community.',
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45)),
            ),
          // Feed
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(_postPath)
                  .orderBy('createdAt', descending: true)
                  .limit(100)
                  .snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Text('Could not load posts.',
                        style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black45)),
                  );
                }
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.article_outlined,
                            size: 52, color: AppColors.brandBlue),
                        const SizedBox(height: 10),
                        Text('No posts yet — be the first!',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white70 : Colors.black54)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (_, i) => _postCard(docs[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _postCard(QueryDocumentSnapshot doc) {
    final isDark = widget.isDark;
    final d = doc.data() as Map<String, dynamic>;
    final uid = (d['uid'] ?? '').toString();
    final likes = List<String>.from((d['likes'] as List?) ?? const []);
    final replies = ((d['replies'] as List?) ?? const [])
        .whereType<Map>()
        .toList();
    final user = FirebaseAuth.instance.currentUser;
    final likedByMe = user != null && likes.contains(user.uid);
    final expanded = _expandedReplies.contains(doc.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 17,
                backgroundImage:
                    d['userPhoto'] != null ? NetworkImage(d['userPhoto'].toString()) : null,
                child: d['userPhoto'] == null
                    ? Text((d['userName'] ?? '?').toString().isNotEmpty
                        ? (d['userName'] ?? '?').toString()[0].toUpperCase()
                        : '?')
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d['userName']?.toString() ?? 'Fan',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Text(_timeAgo(d['createdAt']),
                        style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? Colors.white38 : Colors.black38)),
                  ],
                ),
              ),
              if (user != null && uid == user.uid)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      size: 17, color: Colors.grey),
                  onPressed: () => doc.reference.delete(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(d['text']?.toString() ?? '',
              style: const TextStyle(fontSize: 14, height: 1.35)),
          const SizedBox(height: 10),
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () {
                  if (user == null) return;
                  if (likedByMe) {
                    doc.reference.update(
                        {'likes': FieldValue.arrayRemove([user.uid])});
                  } else {
                    doc.reference.update(
                        {'likes': FieldValue.arrayUnion([user.uid])});
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: likedByMe
                        ? AppColors.liveRed.withValues(alpha: 0.12)
                        : Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        likedByMe ? Icons.favorite : Icons.favorite_border,
                        size: 15,
                        color: likedByMe
                            ? AppColors.liveRed
                            : (isDark ? Colors.white54 : Colors.black45),
                      ),
                      const SizedBox(width: 5),
                      Text('${likes.length}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: likedByMe
                                  ? AppColors.liveRed
                                  : (isDark ? Colors.white70 : Colors.black54))),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() {
                  if (expanded) {
                    _expandedReplies.remove(doc.id);
                  } else {
                    _expandedReplies.add(doc.id);
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 15,
                          color: isDark ? Colors.white54 : Colors.black45),
                      const SizedBox(width: 5),
                      Text('${replies.length}',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white70 : Colors.black54)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (expanded && replies.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF141A26) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: replies.map((r) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundImage: r['userPhoto'] != null
                              ? NetworkImage(r['userPhoto'].toString())
                              : null,
                          child: r['userPhoto'] == null
                              ? Text((r['userName'] ?? '?').toString().isNotEmpty
                                  ? (r['userName'] ?? '?').toString()[0].toUpperCase()
                                  : '?',
                                  style: const TextStyle(fontSize: 10))
                              : null,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(r['userName']?.toString() ?? 'Fan',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11.5),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(_timeAgo(r['createdAt']),
                                      style: TextStyle(
                                          fontSize: 9.5,
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.black38)),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(r['text']?.toString() ?? '',
                                  style:
                                      const TextStyle(fontSize: 12.5, height: 1.3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          if (expanded) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyCtrls.putIfAbsent(
                        doc.id, TextEditingController.new),
                    decoration: InputDecoration(
                      hintText: 'Reply…',
                      isDense: true,
                      filled: true,
                      fillColor:
                          isDark ? const Color(0xFF141A26) : Colors.grey.shade50,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _sendReply(doc.id),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  icon: const Icon(Icons.send, size: 18, color: AppColors.brandBlue),
                  onPressed: () => _sendReply(doc.id),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _sendReply(String postId) {
    final user = FirebaseAuth.instance.currentUser;
    final ctrl = _replyCtrls[postId];
    final t = ctrl?.text.trim() ?? '';
    if (user == null || t.isEmpty) return;
    FirebaseFirestore.instance.collection(_postPath).doc(postId).update({
      'replies': FieldValue.arrayUnion([
        {
          'uid': user.uid,
          'userName': user.displayName ?? user.email ?? 'Fan',
          'userPhoto': user.photoURL,
          'text': t,
          'createdAt': Timestamp.now(),
        }
      ]),
    });
    ctrl!.clear();
    FocusScope.of(context).unfocus();
  }
}