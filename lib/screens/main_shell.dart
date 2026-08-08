import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../l10n.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'sports_screen.dart';
import 'leaderboard_screen.dart';
import 'communities_screen.dart';
import 'prediction_screen.dart';

class MainShell extends StatefulWidget {
  final ValueChanged<ThemeType> onThemeChanged;
  final ThemeType themeType;
  final bool isDark;
  final ValueChanged<Locale> onLocaleChanged;
  final Locale locale;
  final Color accentColor;
  final ValueChanged<Color> onAccentColorChanged;

  const MainShell({
    super.key,
    required this.onThemeChanged,
    required this.themeType,
    required this.isDark,
    required this.onLocaleChanged,
    required this.locale,
    required this.accentColor,
    required this.onAccentColorChanged,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _NavItem {
  final IconData icon;
  final IconData active;
  final String label;
  final bool locked;
  const _NavItem({
    required this.icon,
    required this.active,
    required this.label,
    this.locked = false,
  });
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  bool get _loggedIn => FirebaseAuth.instance.currentUser != null;

  final List<_NavItem> _tabs = const [
    _NavItem(icon: Icons.home_outlined, active: Icons.home, label: 'Home'),
    _NavItem(icon: Icons.sports_outlined, active: Icons.sports, label: 'Matches'),
    _NavItem(icon: Icons.leaderboard_outlined, active: Icons.leaderboard, label: 'Leaderboard'),
    _NavItem(icon: Icons.groups_outlined, active: Icons.groups, label: 'Communities', locked: true),
    _NavItem(icon: Icons.casino_outlined, active: Icons.casino, label: 'Predict', locked: true),
  ];

  void _toggleTheme() {
    final darkish = widget.themeType == ThemeType.dark ||
        widget.themeType == ThemeType.stadium ||
        widget.themeType == ThemeType.esports ||
        widget.themeType == ThemeType.royal ||
        widget.themeType == ThemeType.custom;
    widget.onThemeChanged(darkish ? ThemeType.light : ThemeType.dark);
  }

  Future<void> _onTap(int i) async {
    if (_tabs[i].locked && !_loggedIn) {
      final loggedIn = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => LoginScreen(
            isDark: widget.isDark,
            onToggleTheme: _toggleTheme,
            locale: widget.locale,
            onLocaleChanged: widget.onLocaleChanged,
            accentColor: widget.accentColor,
            onAccentColorChanged: widget.onAccentColorChanged,
          ),
        ),
      );
      if (loggedIn == true) setState(() => _index = i);
      return;
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.locale.languageCode;
    String t(String k) => AppStrings.get(lang, k);
    final labels = <String>[t('navHome'), t('navMatches'), t('navLeaderboard'), t('navCommunities'), t('navPredict')];
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(
            themeType: widget.themeType,
            onToggleTheme: _toggleTheme,
            onThemeChanged: widget.onThemeChanged,
            locale: widget.locale,
            isDark: widget.isDark,
            onLocaleChanged: widget.onLocaleChanged,
            accentColor: widget.accentColor,
            onAccentColorChanged: widget.onAccentColorChanged,
          ),
          SportsScreen(
            locale: widget.locale,
            isDark: widget.isDark,
          ),
          LeaderboardScreen(
            locale: widget.locale,
            isDark: widget.isDark,
          ),
          CommunitiesScreen(
            locale: widget.locale,
            isDark: widget.isDark,
          ),
          PredictionScreen(locale: widget.locale, isDark: widget.isDark),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _onTap,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: widget.accentColor,
        unselectedItemColor: Colors.grey,
        items: _tabs
            .asMap()
            .entries
            .map((e) => BottomNavigationBarItem(
                  icon: Icon(_index == e.key ? _tabs[e.key].active : _tabs[e.key].icon),
                  label: labels[e.key],
                ))
            .toList(),
      ),
    );
  }
}
