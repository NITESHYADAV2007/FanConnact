import 'package:flutter/material.dart';
import '../theme.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onProfileTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onThemeToggle;
  final bool isDark;
  final String? profileImage;

  const AppTopBar({
    super.key,
    this.onProfileTap,
    this.onNotificationTap,
    this.onSettingsTap,
    this.onThemeToggle,
    this.isDark = true,
    this.profileImage,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      titleSpacing: 12,
      title: Row(
        children: [
          Icon(Icons.sports, color: AppColors.brandBlue, size: 26),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Fan',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: -0.5,
                  ),
                ),
                TextSpan(
                  text: 'connact',
                  style: TextStyle(
                    color: isDark ? AppColors.brandGreen : AppColors.brandBlue,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (onThemeToggle != null)
            IconButton(
              icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
              onPressed: onThemeToggle,
              tooltip: 'Toggle theme',
            ),
          if (onNotificationTap != null)
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: onNotificationTap,
            ),
          if (onSettingsTap != null)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: onSettingsTap,
            ),
          if (onProfileTap != null)
            IconButton(
              icon: CircleAvatar(
                radius: 14,
                backgroundImage: profileImage != null ? NetworkImage(profileImage!) : null,
                child: profileImage == null ? const Icon(Icons.person, size: 16) : null,
              ),
              onPressed: onProfileTap,
            ),
        ],
      ),
    );
  }
}
