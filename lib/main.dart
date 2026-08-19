import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'app_prefs.dart';
import 'services/news_service.dart';
import 'services/ad_service.dart';
import 'screens/auth_gate.dart';
import 'screens/splash_screen.dart';

Future<FirebaseApp> _initFirebase() async {
  if (!kIsWeb) {
    // Android/iOS: read the native config (android/app/google-services.json /
    // GoogleService-Info.plist) so auth tokens from Google sign-in verify
    // against the same Firebase project the website uses. Falling back to the
    // web config on Android breaks Google sign-in (wrong token audience).
    try {
      return await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Native Firebase config unavailable, falling back to web options: $e');
    }
  }
  return Firebase.initializeApp(
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
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await _initFirebase();
  } catch (e) {
    debugPrint('Firebase init warning: $e');
  }
  AdService.init();
  runApp(const FanconnactApp());
}

class FanconnactApp extends StatefulWidget {
  const FanconnactApp({super.key});

  @override
  State<FanconnactApp> createState() => _FanconnactAppState();
}

class _FanconnactAppState extends State<FanconnactApp> {
  ThemeType _themeType = ThemeType.dark;
  Locale _locale = const Locale('en');
  Color _accent = AppColors.brandBlue;
  ThemeConfig _customCfg = themeConfigFor(ThemeType.custom);
  bool _ready = false;
  bool _splashDone = false;

  // Accessibility / behavior prefs (toggled from Settings).
  bool _compactMode = false;
  bool _reduceAnimations = false;
  bool _largeText = false;

  ThemeConfig get _effectiveCfg => _themeType == ThemeType.custom ? _customCfg : themeConfigFor(_themeType);

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  ThemeConfig _readCustomCfg(SharedPreferences prefs) {
    final pageBg = Color(prefs.getInt('ctPageBg') ?? 0xFF0b1220);
    final cardBg = Color(prefs.getInt('ctCardBg') ?? 0xFF111827);
    final text = Color(prefs.getInt('ctText') ?? 0xFFffffff);
    final textLight = Color(prefs.getInt('ctTextLight') ?? 0xFF94a3b8);
    final primary = Color(prefs.getInt('ctPrimary') ?? 0xFF22c55e);
    final isDark = prefs.getBool('ctIsDark') ?? true;
    final bgImage = (prefs.getString('ctBgImage') ?? '').trim();
    return ThemeConfig(
      type: ThemeType.custom,
      label: 'Custom',
      fanColor: Colors.white,
      connactColor: primary,
      backgroundAsset: bgImage.isNotEmpty ? bgImage : null,
      glassCards: bgImage.isNotEmpty,
      cardBg: cardBg,
      isDarkOverride: isDark,
      pageBg: pageBg,
      textPrimaryColor: text,
      textSecondaryColor: textLight,
    );
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final themeStr = prefs.getString('themeType') ?? 'dark';
    _themeType = ThemeType.values.firstWhere((t) => t.name == themeStr, orElse: () => ThemeType.dark);
    final accentKey = prefs.getString('accentColor') ?? 'blue';
    _accent = Color(AppColors.accentColors[accentKey] ?? AppColors.brandBlue.value);
    final langCode = prefs.getString('appLanguage');
    if (langCode != null) {
      _locale = Locale(langCode);
    }
    _customCfg = _readCustomCfg(prefs);
    _compactMode = prefs.getBool('compactMode') ?? false;
    _reduceAnimations = prefs.getBool('reduceAnimations') ?? false;
    _largeText = prefs.getBool('largeText') ?? false;
    if (mounted) setState(() => _ready = true);
  }

  void _setThemeType(ThemeType t) async {
    setState(() => _themeType = t);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeType', t.name);
    if (t == ThemeType.custom) {
      _customCfg = _readCustomCfg(prefs);
      if (mounted) setState(() {});
    }
  }

  void _setAccentColor(Color c) async {
    setState(() => _accent = c);
    final entry = AppColors.accentColors.entries.firstWhere(
      (e) => e.value == c.value,
      orElse: () => const MapEntry('blue', 0xFF2196F3),
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('accentColor', entry.key);
    if (_themeType == ThemeType.custom) {
      _customCfg = _readCustomCfg(prefs);
      if (mounted) setState(() {});
    }
  }

  void _setLocale(Locale l) async {
    setState(() => _locale = l);
    NewsService.clearCache();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('appLanguage', l.languageCode);
  }

  void _setCompactMode(bool v) async {
    setState(() => _compactMode = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('compactMode', v);
  }

  void _setReduceAnimations(bool v) async {
    setState(() => _reduceAnimations = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reduceAnimations', v);
  }

  void _setLargeText(bool v) async {
    setState(() => _largeText = v);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('largeText', v);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));

    return MaterialApp(
      title: 'Fanconnact',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(
        type: _themeType,
        accent: _accent,
        customConfig: _themeType == ThemeType.custom ? _customCfg : null,
        compact: _compactMode,
        reduceAnimations: _reduceAnimations,
      ),
      locale: _locale,
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('hi'), Locale('es')],
      builder: (context, child) {
        var data = MediaQuery.of(context);
        if (_largeText) {
          data = data.copyWith(textScaler: const TextScaler.linear(1.2));
        }
        return AppPrefs(
          compactMode: _compactMode,
          reduceAnimations: _reduceAnimations,
          largeText: _largeText,
          onCompactModeChanged: _setCompactMode,
          onReduceAnimationsChanged: _setReduceAnimations,
          onLargeTextChanged: _setLargeText,
          child: MediaQuery(
            data: data,
            child: _withBackground(child, _effectiveCfg),
          ),
        );
      },
      home: AnimatedSwitcher(
        duration: Duration(milliseconds: _reduceAnimations ? 0 : 350),
        child: _splashDone
            ? AuthGate(
                key: const ValueKey('auth'),
                themeType: _themeType,
                onThemeChanged: _setThemeType,
                locale: _locale,
                onLocaleChanged: _setLocale,
                accentColor: _accent,
                onAccentColorChanged: _setAccentColor,
              )
            : SplashScreen(
                key: const ValueKey('splash'),
                onDone: () {
                  if (mounted) setState(() => _splashDone = true);
                },
              ),
      ),
    );
  }

  // Wraps the whole navigator with the theme's background image (stadium /
  // esports / royal, or the custom theme's URL) so it shows through on every
  // screen, pushed routes included. Scaffolds use a translucent background in
  // those themes.
  Widget _withBackground(Widget? child, ThemeConfig cfg) {
    if (!cfg.hasBackground || child == null) return child ?? const SizedBox.shrink();
    return Stack(
      children: [
        Positioned.fill(
          child: ThemeBackground(src: cfg.backgroundAsset!),
        ),
        Positioned.fill(
          child: Container(color: Colors.black.withValues(alpha: 0.45)),
        ),
        child,
      ],
    );
  }
}
