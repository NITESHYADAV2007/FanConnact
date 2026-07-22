import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: DefaultFirebaseOptions.apiKey,
        authDomain: DefaultFirebaseOptions.authDomain,
        projectId: DefaultFirebaseOptions.projectId,
        storageBucket: DefaultFirebaseOptions.storageBucket,
        messagingSenderId: DefaultFirebaseOptions.messagingSenderId,
        appId: DefaultFirebaseOptions.appId,
        measurementId: DefaultFirebaseOptions.measurementId,
      ),
    );
  } catch (e) {
    // Firebase already initialized or unavailable — continue without it.
    debugPrint('Firebase init warning: $e');
  }
  runApp(const FanconnactApp());
}

class FanconnactApp extends StatefulWidget {
  const FanconnactApp({super.key});

  @override
  State<FanconnactApp> createState() => _FanconnactAppState();
}

class _FanconnactAppState extends State<FanconnactApp> {
  bool _dark = true;
  Locale _locale = const Locale('en');

  void _toggleTheme() => setState(() => _dark = !_dark);
  void _setLocale(Locale l) => setState(() => _locale = l);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fanconnact',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(dark: _dark),
      locale: _locale,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('hi'), Locale('es')],
      home: AuthGate(
        isDark: _dark,
        onToggleTheme: _toggleTheme,
        locale: _locale,
        onLocaleChanged: _setLocale,
      ),
    );
  }
}
