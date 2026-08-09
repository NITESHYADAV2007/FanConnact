import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';

class CommunitiesScreen extends StatefulWidget {
  final Locale locale;
  final bool isDark;

  const CommunitiesScreen({super.key, required this.locale, required this.isDark});

  @override
  State<CommunitiesScreen> createState() => _CommunitiesScreenState();
}

class _CommunitiesScreenState extends State<CommunitiesScreen> {
  String _tab = 'joined';

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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _TabBtn(label: 'My Communities', selected: _tab == 'joined', onTap: () => setState(() => _tab = 'joined')),
                const SizedBox(width: 8),
                _TabBtn(label: 'Discover', selected: _tab == 'discover', onTap: () => setState(() => _tab = 'discover')),
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
                    ? _CommunitiesList(user: user, isDark: isDark)
                    : _DiscoverList(user: user, isDark: isDark),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Community'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Community Name', border: OutlineInputBorder()), textCapitalization: TextCapitalization.words),
            const SizedBox(height: 12),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
<<<<<<< HEAD
              await _createCommunity(nameCtrl.text.trim(), descCtrl.text.trim());
              if (ctx.mounted) Navigator.pop(ctx);
=======
              final created = await _createCommunity(nameCtrl.text.trim(), descCtrl.text.trim());
              if (created && ctx.mounted) Navigator.pop(ctx);
>>>>>>> 939fcc1 (Add public communities feature)
            },
            child: const Text('Create (50 🪙)'),
          ),
        ],
      ),
    );
  }

  Future<void> _createCommunity(String name, String desc) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance.collection('communities').add({
      'name': name,
      'description': desc,
      'createdBy': user.uid,
      'createdByName': user.displayName ?? user.email ?? 'Unknown',
      'createdAt': FieldValue.serverTimestamp(),
      'memberCount': 1,
      'members': [user.uid],
    });
    final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
    await userRef.set({
      'coins': FieldValue.increment(-50),
      'communities': FieldValue.arrayUnion([name]),
    }, SetOptions(merge: true));
  }
  Future<bool> _createCommunity(String name, String desc) async {
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
          'visibility': 'public',
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
        const SnackBar(content: Text('Community created and published!')),
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

class _CommunitiesList extends StatelessWidget {
  final User user;
  final bool isDark;
  const _CommunitiesList({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('communities')
          .where('members', arrayContains: user.uid)
<<<<<<< HEAD
          .orderBy('createdAt', descending: true)
=======
>>>>>>> 939fcc1 (Add public communities feature)
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
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            return _CommunityCard(
              name: d['name'] ?? 'Unnamed',
              desc: d['description'] ?? '',
              memberCount: (d['memberCount'] ?? 1).toInt(),
              createdByName: d['createdByName'] ?? 'Unknown',
              docId: docs[i].id,
              isDark: isDark,
            );
          },
        );
      },
    );
  }
}

class _DiscoverList extends StatelessWidget {
  final User user;
  final bool isDark;
  const _DiscoverList({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('communities')
<<<<<<< HEAD
          .orderBy('memberCount', descending: true)
=======
          .where('visibility', isEqualTo: 'public')
>>>>>>> 939fcc1 (Add public communities feature)
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
                Icon(Icons.explore_outlined, size: 64, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text('No communities yet. Be the first!',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final d = docs[i].data() as Map<String, dynamic>;
            final members = (d['members'] as List?) ?? [];
            final isMember = members.contains(user.uid);
            return _CommunityCard(
              name: d['name'] ?? 'Unnamed',
              desc: d['description'] ?? '',
              memberCount: (d['memberCount'] ?? 1).toInt(),
              createdByName: d['createdByName'] ?? 'Unknown',
              docId: docs[i].id,
              isDark: isDark,
              isDiscover: true,
              isMember: isMember,
            );
          },
        );
      },
    );
  }
}

class _CommunityCard extends StatefulWidget {
  final String name;
  final String desc;
  final int memberCount;
  final String createdByName;
  final String docId;
  final bool isDark;
  final bool isDiscover;
  final bool isMember;

  const _CommunityCard({
    required this.name,
    required this.desc,
    required this.memberCount,
    required this.createdByName,
    required this.docId,
    required this.isDark,
    this.isDiscover = false,
    this.isMember = false,
  });

  @override
  State<_CommunityCard> createState() => _CommunityCardState();
}

class _CommunityCardState extends State<_CommunityCard> {
  bool _joining = false;

  Future<void> _join() async {
    final user = FirebaseAuth.instance.currentUser;
<<<<<<< HEAD
    if (user == null || _joining) return;
    setState(() => _joining = true);
    try {
      await FirebaseFirestore.instance.collection('communities').doc(widget.docId).update({
        'members': FieldValue.arrayUnion([user.uid]),
        'memberCount': FieldValue.increment(1),
      });
    } catch (_) {}
    if (mounted) setState(() => _joining = false);
=======
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
>>>>>>> 939fcc1 (Add public communities feature)
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.brandBlue, Color(0xFF764BA2)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.groups, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                if (widget.desc.isNotEmpty)
                  Text(widget.desc,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black45),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('${widget.memberCount} members · Created by ${widget.createdByName}',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white38 : Colors.black38)),
              ],
            ),
          ),
          if (widget.isDiscover)
            _joining
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : TextButton(
                    onPressed: widget.isMember ? null : _join,
                    child: Text(widget.isMember ? 'Joined' : 'Join',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: widget.isMember ? Colors.grey : AppColors.brandBlue,
                        )),
                  ),
          if (!widget.isDiscover)
            const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
