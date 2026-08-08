import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme.dart';

class UserProfileScreen extends StatefulWidget {
  final String uid;
  final String? initialName;
  final String? initialImg;
  final int? initialXp;
  final int? initialCoins;
  final bool isDark;

  const UserProfileScreen({
    super.key,
    required this.uid,
    this.initialName,
    this.initialImg,
    this.initialXp,
    this.initialCoins,
    required this.isDark,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _isFollowing = false;
  bool _isOwnProfile = false;

  @override
  void initState() {
    super.initState();
    _isOwnProfile = FirebaseAuth.instance.currentUser?.uid == widget.uid;
    _load();
  }

  Future<void> _load() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      final d = snap.data() ?? {};
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid != null && !_isOwnProfile) {
        final following = (d['followers'] as List?)?.cast<String>() ?? <String>[];
        _isFollowing = following.contains(currentUid);
      }
      if (mounted) setState(() { _data = d; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null || _isOwnProfile) return;
    final batch = FirebaseFirestore.instance.batch();
    final targetRef = FirebaseFirestore.instance.collection('users').doc(widget.uid);
    final myRef = FirebaseFirestore.instance.collection('users').doc(currentUid);

    if (_isFollowing) {
      batch.update(targetRef, {'followers': FieldValue.arrayRemove([currentUid])});
      batch.update(myRef, {'following': FieldValue.arrayRemove([widget.uid])});
    } else {
      batch.update(targetRef, {'followers': FieldValue.arrayUnion([currentUid])});
      batch.update(myRef, {'following': FieldValue.arrayUnion([widget.uid])});
    }
    await batch.commit();
    setState(() => _isFollowing = !_isFollowing);
  }

  String _displayName(Map<String, dynamic> d) {
    return (d['fullName'] ?? d['username'] ?? d['email'] ?? 'Fan').toString().split('@')[0];
  }

  String _avatar(Map<String, dynamic> d) {
    if (d['photoURL'] != null && d['photoURL'].toString().isNotEmpty) {
      return d['photoURL'].toString().replaceAll('/svg?', '/png?');
    }
    if (widget.initialImg != null && widget.initialImg!.isNotEmpty) return widget.initialImg!;
    return 'https://i.pravatar.cc/100?u=${Uri.encodeComponent(d['email'] ?? widget.uid)}';
  }

  int _level(Map<String, dynamic> d) {
    final xp = int.tryParse('${d['xp'] ?? widget.initialXp ?? 0}') ?? 0;
    return (xp / 500).floor() + 1;
  }

  @override
  Widget build(BuildContext context) {
    final d = _data ?? {};
    final xp = int.tryParse('${d['xp'] ?? widget.initialXp ?? 0}') ?? 0;
    final coins = int.tryParse('${d['coins'] ?? widget.initialCoins ?? 100}') ?? 100;
    final level = _level(d);
    final followers = (d['followers'] as List?)?.length ?? 0;
    final following = (d['following'] as List?)?.length ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_data != null ? _displayName(d) : (widget.initialName ?? 'Profile'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage: NetworkImage(_avatar(d)),
                  onBackgroundImageError: (_, __) {},
                  child: const Icon(Icons.person, size: 44),
                ),
                const SizedBox(height: 10),
                if (!_isOwnProfile && FirebaseAuth.instance.currentUser != null)
                  FilledButton.icon(
                    icon: Icon(_isFollowing ? Icons.person_remove : Icons.person_add, size: 18),
                    label: Text(_isFollowing ? 'Unfollow' : 'Follow',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    style: FilledButton.styleFrom(
                      backgroundColor: _isFollowing ? Colors.grey.shade400 : AppColors.brandBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    onPressed: _toggleFollow,
                  ),
                const SizedBox(height: 10),
                Text(_data != null ? _displayName(d) : (widget.initialName ?? 'Fan'),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                    textAlign: TextAlign.center),
                if (d['username'] != null)
                  Text('@${d['username']}', style: TextStyle(color: Colors.grey.shade500), textAlign: TextAlign.center),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('Level $level  ·  $xp XP',
                      style: const TextStyle(color: AppColors.brandBlue, fontWeight: FontWeight.w800, fontSize: 14)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat('$coins', 'Coins'),
                    _stat('$followers', 'Followers'),
                    _stat('$following', 'Following'),
                  ],
                ),
                if (_isOwnProfile && _data != null) ...[
                  const SizedBox(height: 20),
                  // Show stats similar to profile screen for own profile
                ],
                const SizedBox(height: 24),
                if (_data != null && _data!.isNotEmpty) ...[
                  _SectionTitle('Details'),
                  if (d['fullName'] != null) _row('Name', '${d['fullName']}'),
                  if (d['location'] != null && d['location'] != 'Not Specified') _row('Location', '${d['location']}'),
                  if (d['createdAt'] != null) _row('Joined', _formatDate(d['createdAt'])),
                ],
              ],
            ),
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
            SizedBox(width: 100, child: Text(k, style: const TextStyle(color: Colors.grey))),
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
