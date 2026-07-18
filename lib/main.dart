import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(const FanconnactApp());
}

class FanconnactApp extends StatefulWidget {
  const FanconnactApp({super.key});

  @override
  State<FanconnactApp> createState() => _FanconnactAppState();
}

class _FanconnactAppState extends State<FanconnactApp> {
  bool _dark = true;

  void _toggleTheme() => setState(() => _dark = !_dark);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fanconnact',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(dark: _dark),
      home: MainShell(onToggleTheme: _toggleTheme, isDark: _dark),
    );
  }
}

class MainShell extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool isDark;

  const MainShell({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
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
    _NavItem(icon: Icons.sports_outlined, active: Icons.sports, label: 'Sports'),
    _NavItem(icon: Icons.leaderboard_outlined, active: Icons.leaderboard, label: 'Leaderboard'),
    _NavItem(icon: Icons.settings_outlined, active: Icons.settings, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          HomeScreen(),
          Center(child: Text('Sports hub - coming soon')),
          Center(child: Text('Leaderboard - coming soon')),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) {
          if (_tabs[i].label == 'Settings') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SettingsScreenWithTheme(
                  onToggleTheme: widget.onToggleTheme,
                  isDark: widget.isDark,
                ),
              ),
            );
          } else {
            setState(() => _index = i);
          }
        },
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

  const SettingsScreenWithTheme({
    super.key,
    required this.onToggleTheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w800)),
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
          _SectionTitle('Appearance'),
          _SettingTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            trailing: Switch(
              value: isDark,
              activeColor: AppColors.brandBlue,
              onChanged: (_) => onToggleTheme(),
            ),
          ),
          _SectionTitle('Account'),
          _SettingTile(icon: Icons.person_outline, title: 'Edit Profile', onTap: () {}),
          _SettingTile(icon: Icons.notifications_outlined, title: 'Notifications', onTap: () {}),
          _SettingTile(icon: Icons.security_outlined, title: 'Privacy & Security', onTap: () {}),
          _SectionTitle('Preferences'),
          _SettingTile(icon: Icons.sports_cricket_outlined, title: 'Favorite Sports', onTap: () {}),
          _SettingTile(icon: Icons.language_outlined, title: 'Language', onTap: () {}),
          _SectionTitle('About'),
          _SettingTile(icon: Icons.info_outline, title: 'About Fanconnact', onTap: () {}),
          _SettingTile(icon: Icons.description_outlined, title: 'Terms & Conditions', onTap: () {}),
          const SizedBox(height: 12),
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.brandBlue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: trailing ?? const Icon(Icons.chevron_right),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
