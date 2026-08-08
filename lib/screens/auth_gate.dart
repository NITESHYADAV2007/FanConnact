import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import 'main_shell.dart';

class AuthGate extends StatelessWidget {
  final ThemeType themeType;
  final ValueChanged<ThemeType> onThemeChanged;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;
  final Color accentColor;
  final ValueChanged<Color> onAccentColorChanged;

  const AuthGate({
    super.key,
    required this.themeType,
    required this.onThemeChanged,
    required this.locale,
    required this.onLocaleChanged,
    required this.accentColor,
    required this.onAccentColorChanged,
  });

  bool get isDark => themeConfigFor(themeType).isDark;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return MainShell(
          themeType: themeType,
          onThemeChanged: onThemeChanged,
          isDark: isDark,
          locale: locale,
          onLocaleChanged: onLocaleChanged,
          accentColor: accentColor,
          onAccentColorChanged: onAccentColorChanged,
        );
      },
    );
  }
}
