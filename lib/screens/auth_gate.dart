import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme.dart';
import '../l10n.dart';
import 'login_screen.dart';
import 'main_shell.dart';

// Shows the login/signup flow on first open, then the main app once signed in.
class AuthGate extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggleTheme;
  final Locale locale;
  final ValueChanged<Locale> onLocaleChanged;

  const AuthGate({
    super.key,
    required this.isDark,
    required this.onToggleTheme,
    required this.locale,
    required this.onLocaleChanged,
  });

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
        if (snapshot.hasData && snapshot.data != null) {
          // Signed in — show the main app shell.
          return MainShell(
            isDark: isDark,
            onToggleTheme: onToggleTheme,
            locale: locale,
            onLocaleChanged: onLocaleChanged,
          );
        }
        // Not signed in — show login (which can navigate to signup).
        return LoginScreen(
          isDark: isDark,
          onToggleTheme: onToggleTheme,
          locale: locale,
          onLocaleChanged: onLocaleChanged,
        );
      },
    );
  }
}
