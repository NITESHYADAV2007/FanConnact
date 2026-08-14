import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
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
                      themeType: widget.themeType,
                      onThemeChanged: widget.onThemeChanged ?? (_) {},
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
            icon: const Icon(Icons.edit_outlined),
            tooltip: AppStrings.get(Localizations.localeOf(context).languageCode, 'editProfile'),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => EditProfileScreen(
                  initialData: _data ?? {},
                  onSaved: _load,
                ),
              ));
            },
          ),
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

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final VoidCallback onSaved;

  const EditProfileScreen({super.key, required this.initialData, required this.onSaved});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _bioCtrl;
  final _picker = ImagePicker();
  File? _photoFile;
  String _photoUrl = '';
  bool _saving = false;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final d = widget.initialData;
    _nameCtrl = TextEditingController(text: (d['fullName'] ?? '').toString());
    _usernameCtrl = TextEditingController(text: (d['username'] ?? '').toString());
    _locationCtrl = TextEditingController(text: (d['location'] ?? '').toString());
    _bioCtrl = TextEditingController(text: (d['bio'] ?? '').toString());
    _photoUrl = (d['photoURL'] ?? '').toString();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _locationCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final f = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);
    if (f != null) {
      final cropped = await _cropIfNeeded(File(f.path));
      if (cropped != null) setState(() => _photoFile = cropped);
    }
  }

  Future<void> _pickFromCamera() async {
    final f = await _picker.pickImage(source: ImageSource.camera, maxWidth: 1024);
    if (f != null) {
      final cropped = await _cropIfNeeded(File(f.path));
      if (cropped != null) setState(() => _photoFile = cropped);
    }
  }

  Future<File?> _cropIfNeeded(File file) async {
    try {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final tmpDir = Directory.systemTemp.createTempSync('fc_edit_crop');
      final copy = File('${tmpDir.path}/input.jpg');
      await copy.writeAsBytes(await file.readAsBytes());
      final cropped = await ImageCropper().cropImage(
        sourcePath: copy.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop',
            toolbarColor: isDark ? const Color(0xFF161B22) : Colors.white,
            toolbarWidgetColor: isDark ? Colors.white : const Color(0xFF0F172A),
            backgroundColor: isDark ? const Color(0xFF02060C) : const Color(0xFFF8F9FF),
            activeControlsWidgetColor: AppColors.brandBlue,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Crop', aspectRatioLockEnabled: true),
        ],
      );
      try { tmpDir.deleteSync(recursive: true); } catch (_) {}
      return cropped == null ? null : File(cropped.path);
    } catch (_) {
      return file;
    }
  }

  Future<void> _pickPhoto() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPhoto = _photoFile != null || _photoUrl.isNotEmpty;
    Widget option(IconData icon, String label, VoidCallback onTap) {
      return ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.brandBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.brandBlue),
        ),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        onTap: () { Navigator.pop(context); onTap(); },
      );
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Change Photo', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              const SizedBox(height: 8),
              option(Icons.photo_library_outlined, 'Choose from Gallery', _pickFromGallery),
              option(Icons.camera_alt_outlined, 'Take Photo (Camera)', _pickFromCamera),
              if (hasPhoto)
                option(Icons.delete_outline, 'Remove Photo', () => setState(() {
                  _photoFile = null;
                  _photoUrl = '';
                })),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() { _saving = true; _error = null; });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');
      String photoUrl = _photoUrl;
      if (_photoFile != null) {
        setState(() => _uploading = true);
        final bytes = await _photoFile!.readAsBytes();
        final ref = FirebaseStorage.instance.ref('avatars/${user.uid}.png');
        await ref.putData(bytes, SettableMetadata(contentType: 'image/png'));
        photoUrl = await ref.getDownloadURL();
      }
      final updates = <String, dynamic>{
        'fullName': _nameCtrl.text.trim(),
        'username': _usernameCtrl.text.trim().toLowerCase(),
        'location': _locationCtrl.text.trim(),
        'bio': _bioCtrl.text.trim(),
        'photoURL': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(updates, SetOptions(merge: true));
      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to save: $e');
    } finally {
      if (mounted) setState(() { _saving = false; _uploading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('SAVE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar preview with camera/gallery picker
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: isDark ? AppColors.darkCard : Colors.grey.shade100,
                  backgroundImage: _photoFile != null
                      ? FileImage(_photoFile!)
                      : (_photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null),
                  onBackgroundImageError: _photoFile == null ? (_, __) {} : null,
                  child: _photoFile == null && _photoUrl.isEmpty
                      ? const Icon(Icons.person, size: 44)
                      : null,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: _uploading ? null : _pickPhoto,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.brandBlue,
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? AppColors.darkCard : Colors.white, width: 2),
                      ),
                      child: _uploading
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton.icon(
              onPressed: _uploading ? null : _pickPhoto,
              icon: const Icon(Icons.photo_library_outlined, size: 18, color: AppColors.brandBlue),
              label: Text(
                _photoFile != null ? 'Change Photo (Camera / Gallery)' : 'Add Photo (Camera / Gallery)',
                style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.brandBlue),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _section('Basic Info'),
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _usernameCtrl,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.alternate_email),
              helperText: 'Letters, numbers, underscores only',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _locationCtrl,
            decoration: const InputDecoration(
              labelText: 'Location (optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on_outlined),
            ),
          ),
          const SizedBox(height: 16),
          _section('Bio'),
          const SizedBox(height: 8),
          TextField(
            controller: _bioCtrl,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Bio (optional)',
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
              prefixIcon: Icon(Icons.info_outline),
            ),
          ),
          const SizedBox(height: 20),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(title.toUpperCase(),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.brandBlue)),
  );
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
