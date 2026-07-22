import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../l10n.dart';
import 'home_screen.dart';
import 'sports_screen.dart';
import 'series_screen.dart';
import 'settings_screen.dart';
import 'leaderboard_screen.dart';
import 'profile_screen.dart';
import 'prediction_screen.dart';

// Bottom-navigation shell shown after the user is authenticated.
class MainShell extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;
  final ValueChanged<Locale> onLocaleChanged;
  final Locale locale;

  const MainShell({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
    required this.onLocaleChanged,
    required this.locale,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _NavItem {
  final IconData icon;
  final IconData active;
  final String label;
  const _NavItem({
    required this.icon,
    required this.active,
    required this.label,
  });
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  final List<_NavItem> _tabs = const [
    _NavItem(icon: Icons.home_outlined, active: Icons.home, label: 'Home'),
    _NavItem(icon: Icons.emoji_events_outlined, active: Icons.emoji_events, label: 'Series'),
    _NavItem(icon: Icons.sports_outlined, active: Icons.sports, label: 'Matches'),
    _NavItem(icon: Icons.casino_outlined, active: Icons.casino, label: 'Predict'),
    _NavItem(icon: Icons.person_outline, active: Icons.person, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            locale: widget.locale,
            isDark: widget.isDark,
            onToggleTheme: widget.onToggleTheme,
          ),
          SeriesScreen(
            locale: widget.locale,
            isDark: widget.isDark,
          ),
          SportsScreen(
            locale: widget.locale,
            isDark: widget.isDark,
          ),
          PredictionScreen(locale: widget.locale, isDark: widget.isDark),
          ProfileScreen(locale: widget.locale, isDark: widget.isDark),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.brandBlue,
        unselectedItemColor: Colors.grey,
        items: _tabs
            .map((t) => BottomNavigationBarItem(
                  icon: Icon(_index == _tabs.indexOf(t) ? t.active : t.icon),
                  label: t.label,
                ))
            .toList(),
      ),
    );
  }
}

class SettingsScreenWithTheme extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;
  final ValueChanged<Locale> onLocaleChanged;
  final Locale locale;

  const SettingsScreenWithTheme({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
    required this.onLocaleChanged,
    required this.locale,
  });

  String _currentLangName() {
    final code = locale.languageCode;
    final found = AppStrings.languages.firstWhere(
      (l) => l['code'] == code,
      orElse: () => AppStrings.languages.first,
    );
    return found['name']!;
  }

  void _pickLanguage(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.get(locale.languageCode, 'selectLanguage')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppStrings.languages
              .map(
                (l) => RadioListTile<String>(
                  title: Text(l['name']!),
                  value: l['code']!,
                  groupValue: locale.languageCode,
                  activeColor: AppColors.brandBlue,
                  onChanged: (code) {
                    if (code != null) {
                      onLocaleChanged(Locale(code));
                      Navigator.pop(ctx);
                    }
                  },
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final lang = locale.languageCode;
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.get(lang, 'settings'),
            style: const TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: onToggleTheme,
            tooltip: 'Toggle theme',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _SectionTitle(AppStrings.get(lang, 'appearance')),
          _SettingTile(
            icon: Icons.dark_mode_outlined,
            title: AppStrings.get(lang, 'darkMode'),
            trailing: Switch(
              value: isDark,
              activeColor: AppColors.brandBlue,
              onChanged: (_) => onToggleTheme(),
            ),
          ),
          _SectionTitle(AppStrings.get(lang, 'account')),
          _SettingTile(
            icon: Icons.person_outline,
            title: AppStrings.get(lang, 'editProfile'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(locale: locale, isDark: isDark),
              ),
            ),
          ),
          _SettingTile(icon: Icons.notifications_outlined, title: AppStrings.get(lang, 'notifications'), onTap: () {}),
          _SettingTile(icon: Icons.security_outlined, title: AppStrings.get(lang, 'privacy'), onTap: () {}),
          _SectionTitle(AppStrings.get(lang, 'preferences')),
          _SettingTile(icon: Icons.sports_cricket_outlined, title: AppStrings.get(lang, 'favoriteSports'), onTap: () {}),
          _SettingTile(
            icon: Icons.language_outlined,
            title: AppStrings.get(lang, 'language'),
            trailing: Text(_currentLangName(),
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            onTap: () => _pickLanguage(context),
          ),
          _SectionTitle(AppStrings.get(lang, 'aboutSection')),
          _SettingTile(icon: Icons.info_outline, title: AppStrings.get(lang, 'about'), onTap: () {}),
          _SettingTile(icon: Icons.description_outlined, title: AppStrings.get(lang, 'terms'), onTap: () {}),
          const SizedBox(height: 12),
          _SettingTile(
            icon: Icons.logout,
            title: 'Sign Out',
            onTap: () => _signOut(context),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('Fanconnact v0.1.0',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
            color: AppColors.brandBlue,
          ),
        ),
      );
}

class _SettingTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: AppColors.brandBlue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
        tileColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.withOpacity(0.15)),
        ),
      ),
    );
  }
}
