import 'package:flutter/material.dart';
import '../theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.w800)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // FanCoin promo card with the FanCoin logo
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.brandBlue, AppColors.brandBlueDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Image.asset(
                  'assets/fancoin/fancoin.png',
                  height: 44,
                  width: 44,
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FanCoin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Earn coins, unlock rewards & climb the leaderboard',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
          ),
          _SectionTitle('Appearance'),
          _SettingTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            trailing: Switch(
              value: isDark,
              activeColor: AppColors.brandBlue,
              onChanged: (v) {
                // Theme switching is wired in main.dart via state.
                // For now we pop and let the parent toggle handle it.
              },
            ),
          ),
          _SectionTitle('Account'),
          _SettingTile(
            icon: Icons.person_outline,
            title: 'Edit Profile',
            onTap: () {},
          ),
          _SettingTile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {},
          ),
          _SettingTile(
            icon: Icons.security_outlined,
            title: 'Privacy & Security',
            onTap: () {},
          ),
          _SectionTitle('Preferences'),
          _SettingTile(
            icon: Icons.sports_cricket_outlined,
            title: 'Favorite Sports',
            onTap: () {},
          ),
          _SettingTile(
            icon: Icons.language_outlined,
            title: 'Language',
            onTap: () {},
          ),
          _SectionTitle('About'),
          _SettingTile(
            icon: Icons.info_outline,
            title: 'About Fanconnact',
            onTap: () {},
          ),
          _SettingTile(
            icon: Icons.description_outlined,
            title: 'Terms & Conditions',
            onTap: () {},
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Fanconnact v0.1.0',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              textAlign: TextAlign.center,
            ),
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
