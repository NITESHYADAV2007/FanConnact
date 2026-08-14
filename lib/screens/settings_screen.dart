import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../theme.dart';
import '../l10n.dart';
import '../app_prefs.dart';
import '../services/news_service.dart';
import '../services/otp_service.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

// ── helper icon for sport icons that may not exist in all SDK versions ──
IconData _sportIcon(String sport) {
  switch (sport) {
    case 'cricket': return Icons.sports_cricket;
    case 'football': return Icons.sports_soccer;
    case 'basketball': return Icons.sports_basketball;
    case 'tennis': return Icons.sports_tennis;
    case 'hockey': return Icons.sports_hockey;
    case 'kabaddi': return Icons.sports_kabaddi;
    case 'volleyball': return Icons.sports_volleyball;
    case 'tabletennis': return Icons.sports_handball;
    case 'esports': return Icons.sports_esports;
    case 'baseball': return Icons.sports_baseball;
    case 'rugby': return Icons.sports_rugby;
    case 'golf': return Icons.golf_course;
    case 'mma': return Icons.sports_mma;
    default: return Icons.sports;
  }
}

class SettingsScreen extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;
  final ThemeType themeType;
  final ValueChanged<ThemeType> onThemeChanged;
  final ValueChanged<Locale> onLocaleChanged;
  final Locale locale;
  final Color accentColor;
  final ValueChanged<Color> onAccentColorChanged;

  const SettingsScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
    required this.themeType,
    required this.onThemeChanged,
    required this.onLocaleChanged,
    required this.locale,
    required this.accentColor,
    required this.onAccentColorChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── Locale ──
  // Kept as local state (not just widget.locale) because pushed routes capture
  // their widget parameters at push time, so a root-level locale change never
  // rebuilds this route with the new value. Mirroring it here lets the page
  // switch language immediately when the user picks one.
  Locale _locale = const Locale('en');

  // ── App theme ──
  String _selectedAppTheme = 'dark';
  bool _compactMode = false;
  bool _reduceAnimations = false;
  bool _largeText = false;

  // ── Notification prefs ──
  bool _liveMatchAlerts = true;
  bool _breakingNews = true;
  bool _predictionResults = true;
  bool _communityUpdates = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _mentionsReplies = true;
  bool _newFollowers = true;

  // ── Security / region prefs ──
  bool _twoFactorEnabled = false;
  String _timezone = 'Asia/Kolkata';
  String _region = 'India';
  bool _googleConnected = false;
  bool _facebookConnected = false;

  // ── Sport selections ──
  final Set<String> _selectedSports = {
    'cricket', 'football', 'basketball', 'tennis', 'hockey',
    'kabaddi', 'volleyball', 'tabletennis', 'baseball',
  };

  // ── User data ──
  Map<String, dynamic>? _userData;

  // ── Custom theme builder state ──
  Color _ctPageBg = const Color(0xFF0b1220);
  Color _ctCardBg = const Color(0xFF111827);
  Color _ctBorder = const Color(0xFF243347);
  Color _ctText = const Color(0xFFffffff);
  Color _ctTextLight = const Color(0xFF94a3b8);
  Color _ctPrimary = const Color(0xFF22c55e);
  Color _ctHover = const Color(0xFF162132);
  bool _ctIsDark = true;
  String _ctBgImage = '';

  // Runtime config built from the user's custom-theme values so the settings
  // preview matches what gets applied app-wide (colors + optional URL image).
  ThemeConfig get _customThemeCfg => ThemeConfig(
        type: ThemeType.custom,
        label: 'Custom',
        fanColor: Colors.white,
        connactColor: _ctPrimary,
        backgroundAsset: _ctBgImage.trim().isNotEmpty ? _ctBgImage.trim() : null,
        glassCards: _ctBgImage.trim().isNotEmpty,
        cardBg: _ctCardBg,
        isDarkOverride: _ctIsDark,
        pageBg: _ctPageBg,
        textPrimaryColor: _ctText,
        textSecondaryColor: _ctTextLight,
      );

  // Theme config for the currently selected preset. Drives the settings page's
  // own background, glass cards and "Fanconnact" wordmark colors so the page
  // previews each theme exactly like the rest of the app.
  ThemeConfig get _themeCfg {
    switch (_selectedAppTheme) {
      case 'light':
        return themeConfigFor(ThemeType.light);
      case 'stadium':
        return themeConfigFor(ThemeType.stadium);
      case 'esports':
        return themeConfigFor(ThemeType.esports);
      case 'royal':
        return themeConfigFor(ThemeType.royal);
      case 'custom':
        return _customThemeCfg;
      default:
        return themeConfigFor(ThemeType.dark);
    }
  }

  bool get _isGlass => _themeCfg.glassCards;

  String _t(String key) => AppStrings.get(_locale.languageCode, key);

  // App-bar toggle: flips dark-ish themes to light (and vice versa) through the
  // real onThemeChanged chain, keeping the settings page preview in sync.
  void _toggleThemeLocal() {
    final current = _themeCfg.type;
    final darkish = current == ThemeType.dark ||
        current == ThemeType.stadium ||
        current == ThemeType.esports ||
        current == ThemeType.royal ||
        current == ThemeType.custom;
    final next = darkish ? ThemeType.light : ThemeType.dark;
    widget.onThemeChanged(next);
    final nextName = next == ThemeType.light ? 'light' : 'dark';
    setState(() => _selectedAppTheme = nextName);
    SharedPreferences.getInstance().then((prefs) => prefs.setString('selectedAppTheme', nextName));
  }

  // ── All sport keys ──
  static const _allSports = [
    'cricket', 'football', 'basketball', 'tennis', 'hockey',
    'kabaddi', 'volleyball', 'tabletennis', 'esports', 'baseball',
    'rugby', 'golf', 'mma',
  ];

  static const _sportNames = {
    'cricket': 'Cricket', 'football': 'Football', 'basketball': 'Basketball',
    'tennis': 'Tennis', 'hockey': 'Hockey', 'kabaddi': 'Kabaddi',
    'volleyball': 'Volleyball', 'tabletennis': 'Table Tennis',
    'esports': 'Esports', 'baseball': 'Baseball',
    'rugby': 'Rugby', 'golf': 'Golf', 'mma': 'MMA',
  };

  @override
  void initState() {
    super.initState();
    _locale = widget.locale;
    _loadPrefs();
    _loadUser();
  }

  @override
  void didUpdateWidget(SettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.locale.languageCode != _locale.languageCode) {
      _locale = widget.locale;
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedAppTheme = prefs.getString('selectedAppTheme') ?? (widget.isDark ? 'dark' : 'light');
      _compactMode = prefs.getBool('compactMode') ?? false;
      _reduceAnimations = prefs.getBool('reduceAnimations') ?? false;
      _largeText = prefs.getBool('largeText') ?? false;
      _liveMatchAlerts = prefs.getBool('liveMatchAlerts') ?? true;
      _breakingNews = prefs.getBool('breakingNews') ?? true;
      _predictionResults = prefs.getBool('predictionResults') ?? true;
      _communityUpdates = prefs.getBool('communityUpdates') ?? true;
      _emailNotifications = prefs.getBool('emailNotifications') ?? true;
      _pushNotifications = prefs.getBool('pushNotifications') ?? true;
      _mentionsReplies = prefs.getBool('mentionsReplies') ?? true;
      _newFollowers = prefs.getBool('newFollowers') ?? true;
      _twoFactorEnabled = prefs.getBool('twoFactorEnabled') ?? false;
      _timezone = prefs.getString('timezone') ?? 'Asia/Kolkata';
      _region = prefs.getString('region') ?? 'India';
      final savedSports = prefs.getStringList('selectedSports');
      if (savedSports != null) {
        _selectedSports.clear();
        _selectedSports.addAll(savedSports);
      }
      // Load custom theme
      _ctPageBg = Color(prefs.getInt('ctPageBg') ?? 0xFF0b1220);
      _ctCardBg = Color(prefs.getInt('ctCardBg') ?? 0xFF111827);
      _ctBorder = Color(prefs.getInt('ctBorder') ?? 0xFF243347);
      _ctText = Color(prefs.getInt('ctText') ?? 0xFFffffff);
      _ctTextLight = Color(prefs.getInt('ctTextLight') ?? 0xFF94a3b8);
      _ctPrimary = Color(prefs.getInt('ctPrimary') ?? 0xFF22c55e);
      _ctHover = Color(prefs.getInt('ctHover') ?? 0xFF162132);
      _ctIsDark = prefs.getBool('ctIsDark') ?? true;
      _ctBgImage = prefs.getString('ctBgImage') ?? '';
    });
  }

  Future<void> _saveBool(String key, bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, val);
  }

  Future<void> _saveString(String key, String val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, val);
  }

  Future<void> _selectTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedAppTheme', theme);

    final ThemeType? tt = switch (theme) {
      'light' => ThemeType.light,
      'dark' => ThemeType.dark,
      'stadium' => ThemeType.stadium,
      'esports' => ThemeType.esports,
      'royal' => ThemeType.royal,
      'custom' => ThemeType.custom,
      _ => null,
    };
    if (tt != null) {
      widget.onThemeChanged(tt);
      if (theme == 'light') {
        widget.onAccentColorChanged(AppColors.brandBlue);
      } else if (theme == 'dark') {
        widget.onAccentColorChanged(AppColors.brandGreen);
      } else if (theme == 'stadium') {
        widget.onAccentColorChanged(const Color(0xFF22c55e));
      } else if (theme == 'esports') {
        widget.onAccentColorChanged(const Color(0xFFa855f7));
      } else if (theme == 'royal') {
        widget.onAccentColorChanged(const Color(0xFF3b82f6));
      } else if (theme == 'custom') {
        widget.onAccentColorChanged(_ctPrimary);
      }
    }

    setState(() => _selectedAppTheme = theme);
  }

  Future<void> _toggleSport(String sport) async {
    setState(() {
      if (_selectedSports.contains(sport)) {
        _selectedSports.remove(sport);
      } else {
        _selectedSports.add(sport);
      }
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selectedSports', _selectedSports.toList());
  }

  void _addMoreSports() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Add more sports', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 4),
            Text('Select the sports you want to follow', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
            const SizedBox(height: 8),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: _allSports.map((s) {
                  final checked = _selectedSports.contains(s);
                  return ListTile(
                    leading: Icon(_sportIcon(s), color: checked ? AppColors.brandGreen : Colors.grey),
                    title: Text(_sportNames[s]!, style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: checked
                        ? const Icon(Icons.check_circle, color: AppColors.brandGreen)
                        : const Icon(Icons.add_circle_outline, color: Colors.grey),
                    onTap: () => _toggleSport(s),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10b981)),
                onPressed: () {
                  Navigator.pop(ctx);
                  _toast('Sports preferences updated');
                },
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadUser() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;
    try {
      final snap = await FirebaseFirestore.instance.collection('users').doc(u.uid).get();
      final data = snap.data();
      if (mounted) setState(() {
        _userData = data;
        _twoFactorEnabled = data?['twoFactorEnabled'] == true;
      });
    } catch (_) {}
    _refreshProviders(u);
  }

  void _refreshProviders(User? u) {
    if (u == null) {
      if (mounted) setState(() { _googleConnected = false; _facebookConnected = false; });
      return;
    }
    final ids = u.providerData.map((p) => p.providerId).toSet();
    if (mounted) setState(() {
      _googleConnected = ids.contains('google.com');
      _facebookConnected = ids.contains('facebook.com');
    });
  }

  Future<void> _handleProvider(String provider) async {
    var user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // Not signed in yet — send them to the login page to authenticate.
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            isDark: widget.isDark,
            onToggleTheme: widget.onToggleTheme,
            themeType: widget.themeType,
            onThemeChanged: widget.onThemeChanged,
            locale: _locale,
            onLocaleChanged: widget.onLocaleChanged,
            accentColor: widget.accentColor,
            onAccentColorChanged: widget.onAccentColorChanged,
          ),
        ),
      );
      _refreshProviders(FirebaseAuth.instance.currentUser);
      return;
    }
    final providerId = provider == 'google' ? 'google.com' : 'facebook.com';
    final connected = user.providerData.any((p) => p.providerId == providerId);

    if (connected) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Disconnect account', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          content: Text('Disconnect your ${provider == 'google' ? 'Google' : 'Facebook'} account from FanConnact?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.liveRed),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Disconnect'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      try {
        await user.unlink(providerId);
        _refreshProviders(FirebaseAuth.instance.currentUser);
        _toast('${provider == 'google' ? 'Google' : 'Facebook'} account disconnected.');
      } catch (e) {
        _toast('Error: ${e.toString().replaceAll('PlatformException(firebase_auth, ', '').replaceAll(')', '')}');
      }
      return;
    }

    // Link flow
    try {
      if (provider == 'google') {
        final google = GoogleSignIn(scopes: ['email', 'profile']);
        final ga = await google.signIn();
        if (ga == null) return;
        final auth = await ga.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: auth.accessToken,
          idToken: auth.idToken,
        );
        await user.linkWithCredential(credential);
        _toast('Google account connected!');
      } else {
        final result = await FacebookAuth.instance.login(permissions: ['email', 'public_profile']);
        if (result.status != LoginStatus.success) return;
        final credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
        await user.linkWithCredential(credential);
        _toast('Facebook account connected!');
      }
      _refreshProviders(FirebaseAuth.instance.currentUser);
    } catch (e) {
      _toast('Error: ${e.toString().replaceAll('PlatformException(firebase_auth, ', '').replaceAll(')', '')}');
    }
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _toast('Please log in first to change your password.');
      return;
    }
    if (user.email == null) {
      _toast('Your account has no email, so password reset is unavailable.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
        content: Text('We\'ll email a reset link to ${user.email}. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Send reset link'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.mark_email_read, color: AppColors.brandGreen, size: 36),
          title: const Text('Reset link sent', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          content: Text('Check ${user.email} (and your spam folder) for the link to set a new password.'),
          actions: [
            FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
          ],
        ),
      );
    } catch (e) {
      _toast('Error: ${e.toString().replaceAll('PlatformException(firebase_auth, ', '').replaceAll(')', '')}');
    }
  }

  Future<void> _toggle2fa() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _toast('Please log in first to enable 2FA.');
      return;
    }
    if (_twoFactorEnabled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Disable Two-Factor Authentication?', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          content: const Text('You will no longer need a verification code to log in.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.liveRed),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Disable'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      setState(() => _twoFactorEnabled = false);
      await _saveBool('twoFactorEnabled', false);
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'twoFactorEnabled': false});
      } catch (_) {}
      _toast('Two-Factor Authentication has been disabled.');
      return;
    }

    if (user.email == null) {
      _toast('Add an email address to your account to enable 2FA.');
      return;
    }

    // Enable: send a code to the user's email and require it before turning on.
    final ok = await OtpService.verifyDialog(
      context,
      email: user.email!,
      title: 'Enable Two-Factor Authentication',
      message: 'A 6-digit code was sent to ${user.email}. Enter it to enable 2FA.',
    );
    if (ok != true) {
      _toast('2FA was not enabled.');
      return;
    }
    setState(() => _twoFactorEnabled = true);
    await _saveBool('twoFactorEnabled', true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'twoFactorEnabled': true});
    } catch (_) {}
    _toast('Two-Factor Authentication enabled. You\'ll get a code on login.');
  }

  static const _timezones = [
    'Asia/Kolkata', 'Asia/Dubai', 'Asia/Singapore', 'Asia/Tokyo',
    'America/New_York', 'America/Chicago', 'America/Los_Angeles',
    'Europe/London', 'Europe/Berlin', 'Australia/Sydney',
  ];
  static const _tzOffsets = {
    'Asia/Kolkata': '+5:30', 'Asia/Dubai': '+4:00', 'Asia/Singapore': '+8:00',
    'Asia/Tokyo': '+9:00', 'America/New_York': '-5:00', 'America/Chicago': '-6:00',
    'America/Los_Angeles': '-8:00', 'Europe/London': '+0:00', 'Europe/Berlin': '+1:00',
    'Australia/Sydney': '+11:00',
  };
  static const _regions = [
    'India', 'USA', 'UAE', 'UK', 'Singapore', 'Australia', 'Canada', 'Germany', 'Japan', 'Brazil',
  ];

  void _pickOption<T>({
    required String title,
    required List<T> options,
    required T current,
    required String Function(T) display,
    required Future<void> Function(T) onSelect,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: options.map((opt) {
                    final sel = opt == current;
                    return ListTile(
                      title: Text(display(opt), style: TextStyle(fontWeight: sel ? FontWeight.w800 : FontWeight.w600)),
                      trailing: sel ? const Icon(Icons.check_circle, color: AppColors.brandGreen) : null,
                      onTap: () async {
                        Navigator.pop(ctx);
                        await onSelect(opt);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showFeedbackModal({required bool isBug}) async {
    final user = FirebaseAuth.instance.currentUser;
    final nameCtrl = TextEditingController(text: _userData?['fullName'] ?? user?.displayName ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final msgCtrl = TextEditingController();
    int rating = 0;
    bool sending = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> submit() async {
            final name = nameCtrl.text.trim();
            final email = emailCtrl.text.trim();
            final message = msgCtrl.text.trim();
            if (name.isEmpty) { _toast('Please enter your name'); return; }
            if (!email.contains('@')) { _toast('Please enter a valid email'); return; }
            if (message.isEmpty) { _toast(isBug ? 'Please enter a bug description' : 'Please enter your feedback'); return; }
            setModalState(() => sending = true);
            final subject = isBug ? 'Bug Report - FanConnact' : 'Feedback - FanConnact';
            final bodyText = isBug
                ? 'Bug Report\n\nName: $name\nEmail: $email\n\nDescription:\n$message'
                : 'Feedback\n\nName: $name\nEmail: $email\nRating: ${rating > 0 ? '$rating/5' : 'Not rated'}\n\nMessage:\n$message';
              final payload = {
                '_subject': subject, '_captcha': 'false', '_template': 'box',
                'name': name, 'email': email, 'message': bodyText,
              };
              var ok = false;
              var blocked = false;
              try {
                final res = await http.post(
                  Uri.parse('https://formsubmit.co/ajax/techh.pantherr@gmail.com'),
                  headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'Origin': 'https://fanconnact.com',
                    'Referer': 'https://fanconnact.com/',
                  },
                  body: jsonEncode(payload),
                ).timeout(const Duration(seconds: 20));
                final data = jsonDecode(res.body);
                final success = data is Map ? data['success'] : null;
                ok = success == true || success == 'true';
                final msg = '${data is Map ? data['message'] : ''}';
                if (msg.toLowerCase().contains('activation')) blocked = true;
              } catch (_) {
                ok = false;
              }
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (ok) {
                _toast(isBug ? 'Bug report sent! Thank you.' : 'Feedback sent! Thank you.');
              } else if (blocked) {
                _toast('One-time setup needed: open the "Activate Form" email sent to techh.pantherr@gmail.com and click the link.');
              } else {
                _toast('Could not send. Try again later.');
              }
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Icon(isBug ? Icons.bug_report_outlined : Icons.chat_bubble_outline, color: AppColors.brandBlue),
                const SizedBox(width: 10),
                Text(isBug ? 'Report a Bug' : 'Send Feedback', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Your Name', prefixIcon: Icon(Icons.person_outline)),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Your Email', prefixIcon: Icon(Icons.mail_outline)),
                  ),
                  if (!isBug) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (i) {
                        final filled = i < rating;
                        return IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(filled ? Icons.star : Icons.star_border, color: Colors.amber, size: 28),
                          onPressed: () => setModalState(() => rating = i + 1),
                        );
                      }),
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextField(
                    controller: msgCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: isBug ? 'Bug Description' : 'Your Feedback',
                      alignLabelWithHint: true,
                      prefixIcon: const Icon(Icons.description_outlined),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: sending ? null : () => Navigator.pop(ctx), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF10b981)),
                onPressed: sending ? null : submit,
                child: sending
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isBug ? 'Send Report' : 'Submit Feedback'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> launchMailto(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _showLegal(String kind) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final privacy = kind == 'privacy';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.92,
        builder: (ctx, scrollCtrl) => Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(privacy ? Icons.policy_outlined : Icons.description_outlined, color: AppColors.brandBlue),
                  const SizedBox(width: 10),
                  Text(privacy ? 'Privacy Policy' : 'Terms & Conditions',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  controller: scrollCtrl,
                  children: [
                    _legalSection(isDark, privacy ? 'Data We Collect' : 'Use of Service',
                        privacy
                            ? 'FanConnact collects basic account information (name, email, profile photo) to provide personalized sports scores, news, predictions and social features. Live scores and content are fetched from third-party sports data providers.'
                            : 'By using FanConnact you agree to use the service for personal, non-commercial purposes. Live scores and rankings are provided for informational purposes and may be delayed or inaccurate.'),
                    _legalSection(isDark, privacy ? 'How We Use Your Data' : 'User Responsibilities',
                        privacy
                            ? 'Your data is used to authenticate you, personalize content (favorite sports, themes, language) and display leaderboards. We do not sell personal data to third parties.'
                            : 'You agree not to misuse the platform, post harmful content in communities, or attempt to disrupt the service. Accounts violating these terms may be suspended.'),
                    _legalSection(isDark, privacy ? 'Third-Party Services' : 'Predictions & Content',
                        privacy
                            ? 'Authentication is provided by Firebase/Google. Sport data and news come from third-party APIs (ESPN, cricbuzz, etc.) which have their own privacy policies.'
                            : 'Predictions are for entertainment only and do not guarantee outcomes. All match data is sourced from third-party providers and may contain errors.'),
                    _legalSection(isDark, privacy ? 'Contact' : 'Contact',
                        'For questions about ${privacy ? 'your data' : 'the terms'}, contact us at techh.pantherr@gmail.com.'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _legalSection(bool isDark, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 4),
          Text(body, style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
        ],
      ),
    );
  }

  void _contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'techh.pantherr@gmail.com',
      queryParameters: {'subject': 'Support Request'},
    );
    try {
      await launchMailto(uri);
    } catch (_) {
      _toast('Support: techh.pantherr@gmail.com');
    }
  }

  String _currentLangName() {
    final code = _locale.languageCode;
    final found = AppStrings.languages.firstWhere(
      (l) => l['code'] == code,
      orElse: () => AppStrings.languages.first,
    );
    return found['name']!;
  }

  void _pickLanguage() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 16),
              Text(_t('selectLanguage'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              const SizedBox(height: 16),
              ...AppStrings.languages.map((l) {
                final sel = l['code'] == _locale.languageCode;
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: sel ? widget.accentColor.withValues(alpha: 0.1) : (isDark ? AppColors.darkCard : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: sel ? widget.accentColor.withValues(alpha: 0.3) : Colors.transparent),
                  ),
                  child: ListTile(
                    leading: Text(l['flag'] ?? '', style: const TextStyle(fontSize: 28)),
                    title: Text(l['name']!, style: TextStyle(fontWeight: sel ? FontWeight.w800 : FontWeight.w600)),
                    trailing: sel ? Icon(Icons.check_circle, color: widget.accentColor) : null,
                    onTap: () {
                      final code = l['code']!;
                      setState(() => _locale = Locale(code));
                      Navigator.pop(ctx);
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        widget.onLocaleChanged(Locale(code));
                      });
                    },
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.liveRed, size: 24),
            SizedBox(width: 10),
            Text('Sign Out', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.liveRed),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) Navigator.pop(context);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cfg = _themeCfg;
    final isDark = cfg.isDark;
    final accent = widget.accentColor;
    final user = FirebaseAuth.instance.currentUser;
    final displayName = _userData?['fullName'] ?? _userData?['username'] ?? user?.displayName ?? 'Fan';
    final email = user?.email ?? '';
    final photoURL = (_userData?['photoURL']?.toString() ?? user?.photoURL ?? '')
        .replaceAll('/svg?', '/png?');

    final st = Theme.of(context).textTheme;
    final muted = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final cardBg = isDark ? AppColors.darkCard : Colors.white;
    final surfaceContainer = isDark ? const Color(0xFF1C2230) : const Color(0xFFF4F6FA);

    Widget body = Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: cfg.glassCards ? Colors.transparent : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
        foregroundColor: isDark ? Colors.white : Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: _buildLogo(cfg),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode, color: isDark ? Colors.amber : Colors.grey.shade700),
            onPressed: _toggleThemeLocal,
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_outlined, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                onPressed: () {},
              ),
              Positioned(
                right: 6, top: 6,
                child: Container(
                  width: 16, height: 16,
                  decoration: BoxDecoration(color: AppColors.liveRed, shape: BoxShape.circle),
                  child: const Center(child: Text('3', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => ProfileScreen(
                  locale: _locale, isDark: widget.isDark,
                  onToggleTheme: widget.onToggleTheme,
                  themeType: widget.themeType,
                  onThemeChanged: widget.onThemeChanged,
                  onLocaleChanged: widget.onLocaleChanged,
                  accentColor: widget.accentColor,
                  onAccentColorChanged: widget.onAccentColorChanged,
                ),
              )),
              child: CircleAvatar(
                radius: 16,
                backgroundImage: photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
                backgroundColor: accent.withValues(alpha: 0.2),
                child: photoURL.isEmpty
                    ? Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                        style: TextStyle(fontWeight: FontWeight.w800, color: accent, fontSize: 14))
                    : null,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          _buildPageHeader(isDark),
          const SizedBox(height: 16),
          _buildAccountCard(isDark, accent, user, displayName, email, photoURL, cardBg),
          const SizedBox(height: 20),
          _buildAppearanceCard(isDark, accent, surfaceContainer, cardBg, st, muted),
          const SizedBox(height: 20),
          _buildPrefsRow(isDark, accent, surfaceContainer, cardBg, st, muted),
          const SizedBox(height: 20),
          _buildBottomRow(isDark, accent, surfaceContainer, cardBg, st, muted),
          const SizedBox(height: 24),
          Center(child: Text('Version 1.0.0', style: TextStyle(color: muted, fontSize: 12))),
          const SizedBox(height: 32),
        ],
      ),
    );

    if (cfg.hasBackground) {
      body = Stack(
        children: [
          Positioned.fill(child: ThemeBackground(src: cfg.backgroundAsset!)),
          Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.5))),
          body,
        ],
      );
    }
    return body;
  }

  // ── Logo ──
  Widget _buildLogo(ThemeConfig cfg) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset('assets/fancoin/fanconnactlogo.png', width: 24, height: 24, errorBuilder: (_, __, ___) => const Icon(Icons.sports, size: 24)),
          const SizedBox(width: 6),
          Text('Fan', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: cfg.fanColor)),
          Text('Connact', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: cfg.connactColor)),
        ],
      ),
    );
  }

  // ── Page Header ──
  Widget _buildPageHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppStrings.get(_locale.languageCode, 'settings'), style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: -0.5, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 2),
              Text('Manage your preferences and account settings',
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
            ],
          ),
        ],
      ),
    );
  }

  // ── Account Overview Card ──
  Widget _buildAccountCard(bool isDark, Color accent, User? user, String name, String email, String photoURL, Color cardBg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _isGlass
          ? glassDecoration(bg: isDark ? const Color(0xCC1C2230) : const Color(0xE6FFFFFF))
          : BoxDecoration(
              gradient: LinearGradient(
                colors: [accent.withValues(alpha: 0.12), Colors.transparent],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15)),
            ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (user != null) {
                Navigator.push(context, MaterialPageRoute(
                builder: (_) => ProfileScreen(
                  locale: _locale, isDark: widget.isDark,
                  onToggleTheme: widget.onToggleTheme,
                  themeType: widget.themeType,
                  onThemeChanged: widget.onThemeChanged,
                  onLocaleChanged: widget.onLocaleChanged,
                  accentColor: widget.accentColor,
                  onAccentColorChanged: widget.onAccentColorChanged,
                  ),
                ));
              }
            },
            child: CircleAvatar(
              radius: 32,
              backgroundImage: photoURL.isNotEmpty ? NetworkImage(photoURL) : null,
              backgroundColor: accent.withValues(alpha: 0.15),
              child: photoURL.isEmpty
                  ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 24, color: accent))
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 1),
                Text(email, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6, runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(width: 6, height: 6, decoration: BoxDecoration(color: accent, shape: BoxShape.circle)),
                          const SizedBox(width: 4),
                          Text('Level 28', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: accent)),
                        ],
                      ),
                    ),
                    Text('Active now', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => ProfileScreen(
                  locale: _locale, isDark: widget.isDark,
                  onToggleTheme: widget.onToggleTheme,
                  themeType: widget.themeType,
                  onThemeChanged: widget.onThemeChanged,
                  onLocaleChanged: widget.onLocaleChanged,
                  accentColor: widget.accentColor,
                  onAccentColorChanged: widget.onAccentColorChanged,
                ),
              ));
            },
            style: TextButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  // ── Appearance Section ──
  Widget _buildAppearanceCard(bool isDark, Color accent, Color surfaceContainer, Color cardBg, TextTheme st, Color muted) {
    return _Card(isDark: isDark, glass: _isGlass, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: Icons.palette_outlined, title: _t('appearance'), subtitle: 'Customize the look and feel of FanConnact', isDark: isDark, accent: accent),
        const SizedBox(height: 16),
        // Theme grid
        _buildThemeGrid(isDark, accent),
        const SizedBox(height: 12),
        // Custom theme builder button
        Row(
          children: [
            Expanded(
              child: Text('Pick a preset above, or build your own theme with custom colors.',
                  style: TextStyle(fontSize: 11, color: muted)),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _showCustomThemeBuilder,
              icon: const Icon(Icons.palette, size: 18),
              label: const Text('Custom Theme Builder', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide.none,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15)),
        const SizedBox(height: 12),
        // 3 toggles
        _ToggleRow(
          icon: Icons.grid_view, title: 'Compact Mode', subtitle: 'Show more content in less space',
          value: _compactMode, onChanged: (v) {
            setState(() => _compactMode = v);
            _saveBool('compactMode', v);
            AppPrefs.maybeOf(context)?.onCompactModeChanged(v);
          },
          isDark: isDark, accent: accent,
        ),
        const SizedBox(height: 4),
        _ToggleRow(
          icon: Icons.motion_photos_paused, title: 'Reduce Animations', subtitle: 'Reduce motion for a smoother experience',
          value: _reduceAnimations, onChanged: (v) {
            setState(() => _reduceAnimations = v);
            _saveBool('reduceAnimations', v);
            AppPrefs.maybeOf(context)?.onReduceAnimationsChanged(v);
          },
          isDark: isDark, accent: accent,
        ),
        const SizedBox(height: 4),
        _ToggleRow(
          icon: Icons.text_fields, title: 'Large Text', subtitle: 'Increase text size for better readability',
          value: _largeText, onChanged: (v) {
            setState(() => _largeText = v);
            _saveBool('largeText', v);
            AppPrefs.maybeOf(context)?.onLargeTextChanged(v);
          },
          isDark: isDark, accent: accent,
        ),
      ],
    ));
  }

  Widget _buildThemeGrid(bool isDark, Color accent) {
    final themes = [
      ('light', Icons.light_mode, const Color(0xFFf8fafc), const Color(0xFFf1f5f9), _t('light'), 'Clean and bright', Colors.amber),
      ('dark', Icons.dark_mode, const Color(0xFF0f172a), const Color(0xFF1e293b), _t('dark'), 'Easy on the eyes', Colors.white),
      ('stadium', Icons.sports_soccer, const Color(0xFF07140f), const Color(0xFF0a1f14), _t('stadium'), 'Feel the game', const Color(0xFF22c55e)),
      ('esports', Icons.sports_esports, const Color(0xFF120622), const Color(0xFF1c0a33), _t('esports'), 'For esports fans', const Color(0xFFa855f7)),
      ('royal', Icons.shield, const Color(0xFF06142f), const Color(0xFF0a1f4a), _t('royal'), 'Classic and sleek', const Color(0xFF3b82f6)),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.75,
      children: [
        ...themes.map((t) => _ThemeCard(
          themeKey: t.$1,
          icon: t.$2,
          bgColor: t.$3,
          cardColor: t.$4,
          title: t.$5,
          subtitle: t.$6,
          iconColor: t.$7,
          isSelected: _selectedAppTheme == t.$1,
          accent: accent,
          onTap: () => _selectTheme(t.$1),
        )),
        // Custom theme card
        _buildCustomThemeCard(isDark, accent),
      ],
    );
  }

  Widget _buildCustomThemeCard(bool isDark, Color accent) {
    return GestureDetector(
      onTap: _showCustomThemeBuilder,
      child: Container(
        decoration: BoxDecoration(
          gradient: const SweepGradient(
            colors: [
              Color(0xFF22c55e), Color(0xFF3b82f6), Color(0xFFa855f7),
              Color(0xFFf7941d), Color(0xFF22c55e),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _selectedAppTheme == 'custom'
                ? accent
                : (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.2)),
            width: _selectedAppTheme == 'custom' ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withValues(alpha: 0.4),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.tune, color: Colors.white, size: 32),
                  const SizedBox(height: 4),
                  Text(_t('custom'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(_t('makeYourOwn'), style: const TextStyle(color: Colors.white70, fontSize: 10)),
                ],
              ),            ),
            if (_selectedAppTheme == 'custom')
              Positioned(
                top: 6, right: 6,
                child: Icon(Icons.check_circle, color: accent, size: 22),
              ),
          ],
        ),
      ),
    );
  }

  // ── Sports + Notification Row ──
  Widget _buildPrefsRow(bool isDark, Color accent, Color surfaceContainer, Color cardBg, TextTheme st, Color muted) {
    if (MediaQuery.of(context).size.width < 700) {
      return Column(
        children: [
          _buildSportsCard(isDark, accent, surfaceContainer, cardBg, st, muted),
          const SizedBox(height: 16),
          _buildNotifCard(isDark, accent, surfaceContainer, cardBg, st, muted),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildSportsCard(isDark, accent, surfaceContainer, cardBg, st, muted)),
        const SizedBox(width: 16),
        Expanded(child: _buildNotifCard(isDark, accent, surfaceContainer, cardBg, st, muted)),
      ],
    );
  }

  // ── Sports Preferences Card ──
  Widget _buildSportsCard(bool isDark, Color accent, Color surfaceContainer, Color cardBg, TextTheme st, Color muted) {
    return _Card(isDark: isDark, glass: _isGlass, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: Icons.sports_soccer, title: _t('sportsPrefs'), subtitle: _t('sportsSubtitle'), isDark: isDark, accent: accent),
        const SizedBox(height: 12),
        ..._allSports.map((s) => _SportCheckRow(
          sport: s,
          icon: _sportIcon(s),
          name: _sportNames[s]!,
          checked: _selectedSports.contains(s),
          isDark: isDark,
          accent: accent,
          onChanged: () => _toggleSport(s),
        )),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _addMoreSports,
          child: Row(
            children: [
              Icon(Icons.add, size: 18, color: accent),
              const SizedBox(width: 4),
              Text('Add more sports', style: TextStyle(color: accent, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ],
    ));
  }

  // ── Notification Preferences Card ──
  Widget _buildNotifCard(bool isDark, Color accent, Color surfaceContainer, Color cardBg, TextTheme st, Color muted) {
    final notifs = [
      (Icons.sensors, 'Live Match Alerts', _liveMatchAlerts, (v) => setState(() { _liveMatchAlerts = v; _saveBool('liveMatchAlerts', v); })),
      (Icons.article_outlined, 'Breaking News', _breakingNews, (v) => setState(() { _breakingNews = v; _saveBool('breakingNews', v); })),
      (Icons.analytics, 'Prediction Results', _predictionResults, (v) => setState(() { _predictionResults = v; _saveBool('predictionResults', v); })),
      (Icons.group_outlined, 'Community Updates', _communityUpdates, (v) => setState(() { _communityUpdates = v; _saveBool('communityUpdates', v); })),
      (Icons.mail_outline, 'Email Notifications', _emailNotifications, (v) => setState(() { _emailNotifications = v; _saveBool('emailNotifications', v); })),
      (Icons.notifications_active, 'Push Notifications', _pushNotifications, (v) => setState(() { _pushNotifications = v; _saveBool('pushNotifications', v); })),
      (Icons.alternate_email, 'Mentions & Replies', _mentionsReplies, (v) => setState(() { _mentionsReplies = v; _saveBool('mentionsReplies', v); })),
      (Icons.person_add, 'New Followers', _newFollowers, (v) => setState(() { _newFollowers = v; _saveBool('newFollowers', v); })),
    ];

    return _Card(isDark: isDark, glass: _isGlass, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: Icons.notifications_outlined, title: _t('notifPrefs'), subtitle: _t('notifSubtitle'), isDark: isDark, accent: accent),
        const SizedBox(height: 12),
        ...notifs.map((n) => _ToggleRow(
          icon: n.$1, title: n.$2, value: n.$3, onChanged: n.$4,
          isDark: isDark, accent: accent, subtitle: null,
        )),
      ],
    ));
  }

  // ── Bottom 3-column row ──
  Widget _buildBottomRow(bool isDark, Color accent, Color surfaceContainer, Color cardBg, TextTheme st, Color muted) {
    final width = MediaQuery.of(context).size.width;
    if (width < 700) {
      return Column(
        children: [
          _buildSecurityCard(isDark, accent, cardBg),
          const SizedBox(height: 16),
          _buildLangRegionCard(isDark, accent, cardBg),
          const SizedBox(height: 16),
          _buildSupportCard(isDark, accent, cardBg),
        ],
      );
    }
    if (width < 1000) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildSecurityCard(isDark, accent, cardBg)),
              const SizedBox(width: 16),
              Expanded(child: _buildLangRegionCard(isDark, accent, cardBg)),
            ],
          ),
          const SizedBox(height: 16),
          _buildSupportCard(isDark, accent, cardBg),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildSecurityCard(isDark, accent, cardBg)),
        const SizedBox(width: 16),
        Expanded(child: _buildLangRegionCard(isDark, accent, cardBg)),
        const SizedBox(width: 16),
        Expanded(child: _buildSupportCard(isDark, accent, cardBg)),
      ],
    );
  }

  // ── Security Card ──
  Widget _buildSecurityCard(bool isDark, Color accent, Color cardBg) {
    return _Card(isDark: isDark, glass: _isGlass, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: Icons.shield_outlined, title: 'Security', subtitle: 'Keep your account safe and secure', isDark: isDark, accent: accent),
        const SizedBox(height: 8),
        _AuthRow(
          icon: _googleIcon(),
          title: 'Google',
          status: _googleConnected ? 'Connected' : 'Link',
          statusColor: _googleConnected ? const Color(0xFF00855b) : const Color(0xFF2563EB),
          isDark: isDark,
          onTap: () => _handleProvider('google'),
        ),
        _AuthRow(
          icon: _facebookIcon(),
          title: 'Facebook',
          status: _facebookConnected ? 'Connected' : 'Link',
          statusColor: _facebookConnected ? const Color(0xFF00855b) : const Color(0xFF2563EB),
          isDark: isDark,
          onTap: () => _handleProvider('facebook'),
        ),
        _ChevronRow(icon: Icons.lock_outlined, title: 'Change Password', isDark: isDark, onTap: _changePassword),
        _ChevronRow(
          icon: Icons.security_outlined,
          title: 'Two-Factor Authentication',
          trailing: _twoFactorEnabled ? 'On' : 'Off',
          isDark: isDark,
          onTap: _toggle2fa,
        ),
        const Divider(height: 1, color: Colors.transparent),
        _ChevronRow(
          icon: Icons.logout, title: 'Logout All Devices',
          isDark: isDark, iconColor: AppColors.liveRed, textColor: AppColors.liveRed,
          onTap: _signOut,
        ),
      ],
    ));
  }

  Widget _googleIcon() => SizedBox(
    width: 20, height: 20,
    child: Image.network(
      'https://www.google.com/favicon.ico',
      errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 20, color: Color(0xFF4285F4)),
    ),
  );

  Widget _facebookIcon() => SizedBox(
    width: 20, height: 20,
    child: Image.network(
      'https://www.facebook.com/favicon.ico',
      errorBuilder: (_, __, ___) => const Icon(Icons.facebook, size: 20, color: Color(0xFF1877F2)),
    ),
  );

  // ── Language & Region Card ──
  Widget _buildLangRegionCard(bool isDark, Color accent, Color cardBg) {
    return _Card(isDark: isDark, glass: _isGlass, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: Icons.translate, title: _t('languageRegion'), subtitle: _t('manageLangRegion'), isDark: isDark, accent: accent),
        const SizedBox(height: 12),
        _SelectorRow(
          icon: Icons.language, label: _t('language'), value: _currentLangName(),
          isDark: isDark, onTap: _pickLanguage,
        ),
        const SizedBox(height: 4),
        _SelectorRow(
          icon: Icons.schedule, label: _t('timezone'), value: '(GMT${_tzOffsets[_timezone] ?? '+0:00'}) $_timezone',
          isDark: isDark, onTap: () => _pickOption<String>(
            title: _t('timezone'),
            options: _timezones,
            current: _timezone,
            display: (tz) => '(GMT${_tzOffsets[tz] ?? '+0:00'}) $tz',
            onSelect: (tz) async {
              setState(() => _timezone = tz);
              await _saveString('timezone', tz);
              _toast('Timezone set to (GMT${_tzOffsets[tz] ?? '+0:00'}) $tz');
            },
          ),
        ),
        const SizedBox(height: 4),
        _SelectorRow(
          icon: Icons.location_on, label: _t('region'), value: _region,
          isDark: isDark, onTap: () => _pickOption<String>(
            title: _t('selectRegion'),
            options: _regions,
            current: _region,
            display: (r) => r,
            onSelect: (r) async {
              setState(() => _region = r);
              await _saveString('region', r);
              NewsService.clearCache();
              _toast('Region set to $r');
            },
          ),
        ),
      ],
    ));
  }

  // ── Support & About Card ──
  Widget _buildSupportCard(bool isDark, Color accent, Color cardBg) {
    return _Card(isDark: isDark, glass: _isGlass, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(icon: Icons.help_outlined, title: _t('aboutSection'), subtitle: 'Help, feedback and app information', isDark: isDark, accent: accent),
        const SizedBox(height: 8),
        _ChevronRow(icon: Icons.bug_report_outlined, title: 'Report Bug', isDark: isDark, onTap: () => _showFeedbackModal(isBug: true)),
        _ChevronRow(icon: Icons.chat_bubble_outlined, title: 'Send Feedback', isDark: isDark, onTap: () => _showFeedbackModal(isBug: false)),
        _ChevronRow(icon: Icons.contact_support_outlined, title: 'Contact Support', isDark: isDark, onTap: _contactSupport),
        _ChevronRow(icon: Icons.policy_outlined, title: 'Privacy Policy', isDark: isDark, onTap: () => _showLegal('privacy')),
        _ChevronRow(icon: Icons.description_outlined, title: 'Terms & Conditions', isDark: isDark, onTap: () => _showLegal('terms')),
        const SizedBox(height: 12),
        Center(child: Text('Version 1.0.0', style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400))),
      ],
    ));
  }

  // ─────────────────────────────────────────────────────────────
  // CUSTOM THEME BUILDER MODAL
  // ─────────────────────────────────────────────────────────────
  void _showCustomThemeBuilder() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _CustomThemeDialog(
        pageBg: _ctPageBg,
        cardBg: _ctCardBg,
        border: _ctBorder,
        text: _ctText,
        textLight: _ctTextLight,
        primary: _ctPrimary,
        hover: _ctHover,
        isDark: _ctIsDark,
        bgImage: _ctBgImage,
        onApply: (vals) async {
          setState(() {
            _ctPageBg = vals['pageBg'] as Color;
            _ctCardBg = vals['cardBg'] as Color;
            _ctBorder = vals['border'] as Color;
            _ctText = vals['text'] as Color;
            _ctTextLight = vals['textLight'] as Color;
            _ctPrimary = vals['primary'] as Color;
            _ctHover = vals['hover'] as Color;
            _ctIsDark = vals['isDark'] as bool;
            _ctBgImage = vals['bgImage'] as String;
          });
          await _saveCustomTheme();
          await _selectTheme('custom');
        },
      ),
    );
  }

  Future<void> _saveCustomTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('ctPageBg', _ctPageBg.toARGB32());
    await prefs.setInt('ctCardBg', _ctCardBg.toARGB32());
    await prefs.setInt('ctBorder', _ctBorder.toARGB32());
    await prefs.setInt('ctText', _ctText.toARGB32());
    await prefs.setInt('ctTextLight', _ctTextLight.toARGB32());
    await prefs.setInt('ctPrimary', _ctPrimary.toARGB32());
    await prefs.setInt('ctHover', _ctHover.toARGB32());
    await prefs.setBool('ctIsDark', _ctIsDark);
    await prefs.setString('ctBgImage', _ctBgImage);
  }
}

// ═══════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ═══════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  final bool isDark;
  final bool glass;
  final Widget child;
  const _Card({required this.isDark, required this.child, this.glass = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: glass
          ? glassDecoration(
              bg: isDark ? const Color(0xCC1C2230) : const Color(0xE6FFFFFF),
            )
          : BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15)),
            ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final Color accent;

  const _SectionHeader({
    required this.icon, required this.title, required this.subtitle,
    required this.isDark, required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 20, color: accent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String themeKey;
  final IconData icon;
  final Color bgColor;
  final Color cardColor;
  final String title;
  final String subtitle;
  final Color iconColor;
  final bool isSelected;
  final Color accent;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.themeKey, required this.icon, required this.bgColor,
    required this.cardColor, required this.title, required this.subtitle,
    required this.iconColor, required this.isSelected, required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accent : cardColor.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(height: 8),
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 10)),
              ],
            ),
            if (isSelected)
              Positioned(
                top: 6, right: 6,
                child: Icon(Icons.check_circle, color: accent, size: 22),
              ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;
  final Color accent;

  const _ToggleRow({
    required this.icon, required this.title, this.subtitle,
    required this.value, required this.onChanged,
    required this.isDark, required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : Colors.black)),
                if (subtitle != null)
                  Text(subtitle!, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SportCheckRow extends StatelessWidget {
  final String sport;
  final IconData icon;
  final String name;
  final bool checked;
  final bool isDark;
  final Color accent;
  final VoidCallback onChanged;

  const _SportCheckRow({
    required this.sport, required this.icon, required this.name,
    required this.checked, required this.isDark, required this.accent,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : Colors.black)),
          ),
          SizedBox(
            height: 24, width: 24,
            child: Checkbox(
              value: checked,
              activeColor: accent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              onChanged: (_) => onChanged(),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthRow extends StatelessWidget {
  final Widget icon;
  final String title;
  final String status;
  final Color statusColor;
  final bool isDark;
  final VoidCallback onTap;

  const _AuthRow({
    required this.icon, required this.title, required this.status,
    required this.statusColor, required this.isDark, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final connected = status == 'Connected';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(width: 24, height: 24, child: icon),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : Colors.black))),
            Text(status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor)),
            const SizedBox(width: 4),
            Icon(connected ? Icons.check_circle : Icons.link, size: 16, color: statusColor),
          ],
        ),
      ),
    );
  }
}

class _ChevronRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final bool isDark;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? textColor;

  const _ChevronRow({
    required this.icon, required this.title, this.trailing,
    required this.isDark, this.onTap, this.iconColor, this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final iColor = iconColor ?? (isDark ? Colors.grey.shade400 : Colors.grey.shade600);
    final tColor = textColor ?? (isDark ? Colors.white : Colors.black);
    final subColor = textColor ?? (isDark ? Colors.grey.shade400 : Colors.grey.shade600);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iColor),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: tColor))),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(trailing!, style: TextStyle(fontSize: 11, color: subColor)),
              ),
            Icon(Icons.chevron_right, size: 18, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _SelectorRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final VoidCallback onTap;

  const _SelectorRow({
    required this.icon, required this.label, required this.value,
    required this.isDark, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : Colors.black)),
                ],
              ),
            ),
            Icon(Icons.expand_more, size: 20, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CUSTOM THEME DIALOG
// ═══════════════════════════════════════════════════════════════

class _CustomThemeDialog extends StatefulWidget {
  final Color pageBg, cardBg, border, text, textLight, primary, hover;
  final bool isDark;
  final String bgImage;
  final void Function(Map<String, dynamic> values) onApply;

  const _CustomThemeDialog({
    required this.pageBg, required this.cardBg, required this.border,
    required this.text, required this.textLight, required this.primary,
    required this.hover, required this.isDark, required this.bgImage,
    required this.onApply,
  });

  @override
  State<_CustomThemeDialog> createState() => _CustomThemeDialogState();
}

class _CustomThemeDialogState extends State<_CustomThemeDialog> {
  late Color _pageBg, _cardBg, _border, _text, _textLight, _primary, _hover;
  late bool _isDark;
  late TextEditingController _bgCtrl;

  static const _presetColors = {
    'sunset': [Color(0xFF2b1055), Color(0xFF3a1c71), Color(0xFFff7e5f), Color(0xFFffffff), Color(0xFFffd6c4), Color(0xFFff7e5f), Color(0xFF4a2575), true],
    'ocean': [Color(0xFF031b2e), Color(0xFF06304d), Color(0xFF0ea5e9), Color(0xFFffffff), Color(0xFFbae6fd), Color(0xFF0ea5e9), Color(0xFF0a3a5c), true],
    'mono': [Color(0xFF0a0a0a), Color(0xFF171717), Color(0xFF404040), Color(0xFFfafafa), Color(0xFFa3a3a3), Color(0xFFfafafa), Color(0xFF262626), true],
    'mint': [Color(0xFFecfdf5), Color(0xFFffffff), Color(0xFF6ee7b7), Color(0xFF064e3b), Color(0xFF047857), Color(0xFF10b981), Color(0xFFd1fae5), false],
  };

  @override
  void initState() {
    super.initState();
    _pageBg = widget.pageBg;
    _cardBg = widget.cardBg;
    _border = widget.border;
    _text = widget.text;
    _textLight = widget.textLight;
    _primary = widget.primary;
    _hover = widget.hover;
    _isDark = widget.isDark;
    _bgCtrl = TextEditingController(text: widget.bgImage);
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(String name) {
    final p = _presetColors[name];
    if (p == null) return;
    setState(() {
      _pageBg = p[0] as Color;
      _cardBg = p[1] as Color;
      _border = p[2] as Color;
      _text = p[3] as Color;
      _textLight = p[4] as Color;
      _primary = p[5] as Color;
      _hover = p[6] as Color;
      _isDark = p[7] as bool;
    });
  }

  void _pickColor(Color current, ValueChanged<Color> onPicked) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose Color', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        content: SizedBox(
          width: 280,
          child: Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              Colors.black, const Color(0xFF0b1220), const Color(0xFF111827), const Color(0xFF1e293b),
              const Color(0xFF374151), const Color(0xFF475569), const Color(0xFF64748b), const Color(0xFF94a3b8),
              const Color(0xFFcbd5e1), const Color(0xFFe2e8f0), const Color(0xFFf1f5f9), const Color(0xFFf8fafc),
              Colors.white,
              const Color(0xFFdc2626), const Color(0xFFea580c), const Color(0xFFf59e0b), Colors.amber,
              const Color(0xFF22c55e), const Color(0xFF10b981), const Color(0xFF06b6d4), const Color(0xFF0ea5e9),
              const Color(0xFF2563eb), const Color(0xFF3b82f6), const Color(0xFF6366f1), const Color(0xFF8b5cf6),
              const Color(0xFFa855f7), const Color(0xFFd946ef), const Color(0xFFec4899), const Color(0xFFf43f5e),
            ].map((c) {
              final sel = c.toARGB32() == current.toARGB32();
              return GestureDetector(
                onTap: () {
                  onPicked(c);
                  Navigator.pop(ctx);
                },
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: c,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: sel ? Colors.white : Colors.grey.shade300, width: sel ? 3 : 1),
                    boxShadow: sel ? [BoxShadow(color: c.withValues(alpha: 0.5), blurRadius: 8)] : null,
                  ),
                  child: sel ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                ),
              );
            }).toList(),
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel'))],
      ),
    );
  }

  Color _previewBg() {
    if (_bgCtrl.text.trim().isNotEmpty) return const Color(0xFF0b1220);
    return _pageBg;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 640),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: widget.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                    child: Icon(Icons.palette_outlined, size: 20, color: widget.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Custom Theme Builder', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: isDarkMode ? Colors.white : Colors.black))),
                  IconButton(
                    icon: Icon(Icons.close, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live preview
                    Text('Live Preview', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: _previewBg(),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15)),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(8)),
                              child: const Text('Primary', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(border: Border.all(color: _border), borderRadius: BorderRadius.circular(8)),
                              child: Text('Card', style: TextStyle(color: _textLight, fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                            const SizedBox(width: 8),
                            Text('Text sample', style: TextStyle(color: _text, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Color pickers
                    Row(children: [
                      _ColorField(label: 'Background', color: _pageBg, onTap: () => _pickColor(_pageBg, (c) => setState(() => _pageBg = c))),
                      const SizedBox(width: 12),
                      _ColorField(label: 'Card', color: _cardBg, onTap: () => _pickColor(_cardBg, (c) => setState(() => _cardBg = c))),
                      const SizedBox(width: 12),
                      _ColorField(label: 'Border', color: _border, onTap: () => _pickColor(_border, (c) => setState(() => _border = c))),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      _ColorField(label: 'Text', color: _text, onTap: () => _pickColor(_text, (c) => setState(() => _text = c))),
                      const SizedBox(width: 12),
                      _ColorField(label: 'Muted', color: _textLight, onTap: () => _pickColor(_textLight, (c) => setState(() => _textLight = c))),
                      const SizedBox(width: 12),
                      _ColorField(label: 'Accent', color: _primary, onTap: () => _pickColor(_primary, (c) => setState(() => _primary = c))),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      _ColorField(label: 'Hover', color: _hover, onTap: () => _pickColor(_hover, (c) => setState(() => _hover = c))),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mode', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)),
                            const SizedBox(height: 6),
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border.all(color: isDarkMode ? Colors.white.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.25)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(_isDark ? 'Dark' : 'Light', style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white : Colors.black)),
                                  const SizedBox(width: 8),
                                  Switch(
                                    value: _isDark,
                                    activeThumbColor: widget.primary,
                                    onChanged: (v) => setState(() => _isDark = v),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    // Background image URL
                    Text('Background Image (optional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _bgCtrl,
                      decoration: InputDecoration(
                        hintText: 'https://... or leave empty for solid color',
                        hintStyle: TextStyle(fontSize: 13, color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400),
                        filled: true,
                        fillColor: isDarkMode ? AppColors.darkBg : Colors.grey.shade100,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white : Colors.black),
                    ),
                    const SizedBox(height: 16),
                    // Presets
                    Text('Quick Presets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: ['sunset', 'ocean', 'mono', 'mint'].map((n) {
                        return OutlinedButton(
                          onPressed: () => _applyPreset(n),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            side: BorderSide(color: isDarkMode ? Colors.white.withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.25)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: Text(n == 'sunset' ? 'Sunset' : n == 'ocean' ? 'Ocean' : n == 'mono' ? 'Mono Dark' : 'Mint Light',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.white : Colors.black)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: isDarkMode ? Colors.white.withValues(alpha: 0.08) : Colors.grey.withValues(alpha: 0.15))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      widget.onApply({
                        'pageBg': _pageBg, 'cardBg': _cardBg, 'border': _border,
                        'text': _text, 'textLight': _textLight, 'primary': _primary,
                        'hover': _hover, 'isDark': _isDark, 'bgImage': _bgCtrl.text.trim(),
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10b981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Apply Custom Theme', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorField extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ColorField({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
