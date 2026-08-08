import 'package:flutter/material.dart';

class AppColors {
  static const Color brandBlue = Color(0xFF2196F3);
  static const Color brandBlueDark = Color(0xFF1565C0);
  static const Color brandGreen = Color(0xFF21C25A);
  static const Color liveRed = Color(0xFFE53935);
  static const Color completedGrey = Color(0xFF9E9E9E);
  static const Color upcomingAmber = Color(0xFFFF9800);
  static const Color gold = Color(0xFFFFD700);

  static const Color darkBg = Color(0xFF0E1116);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkCard = Color(0xFF1C2230);

  static const Color lightBg = Color(0xFFF4F6FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);

  static const Map<String, int> accentColors = {
    'blue': 0xFF2196F3,
    'green': 0xFF4CAF50,
    'purple': 0xFF9C27B0,
    'orange': 0xFFFF9800,
    'red': 0xFFE53935,
    'teal': 0xFF009688,
  };
}

enum ThemeType { light, dark, stadium, esports, royal, custom }

class ThemeConfig {
  final ThemeType type;
  final String label;
  final Color fanColor;
  final Color connactColor;
  final String? backgroundAsset;
  final bool glassCards;
  final Color? cardBg;
  final bool? isDarkOverride;
  final Color? pageBg;
  final Color? textPrimaryColor;
  final Color? textSecondaryColor;

  const ThemeConfig({
    required this.type,
    required this.label,
    required this.fanColor,
    required this.connactColor,
    this.backgroundAsset,
    this.glassCards = false,
    this.cardBg,
    this.isDarkOverride,
    this.pageBg,
    this.textPrimaryColor,
    this.textSecondaryColor,
  });

  bool get hasBackground => backgroundAsset != null && backgroundAsset!.isNotEmpty;
  bool get isNetworkBackground =>
      hasBackground &&
      (backgroundAsset!.startsWith('http://') || backgroundAsset!.startsWith('https://'));
  bool get isDark =>
      isDarkOverride ??
      (type == ThemeType.dark ||
          type == ThemeType.stadium ||
          type == ThemeType.esports ||
          type == ThemeType.royal ||
          type == ThemeType.custom);
}

const List<ThemeConfig> themeConfigs = [
  ThemeConfig(type: ThemeType.light, label: 'Light', fanColor: Colors.black, connactColor: AppColors.brandBlue, cardBg: Colors.white),
  ThemeConfig(type: ThemeType.dark, label: 'Dark', fanColor: Colors.white, connactColor: AppColors.brandGreen, cardBg: Color(0xFF1C2230)),
  ThemeConfig(type: ThemeType.stadium, label: 'Stadium', fanColor: Colors.white, connactColor: AppColors.brandGreen, backgroundAsset: 'assets/cricket bg.jpg', glassCards: true, cardBg: Color(0xCC1C2230)),
  ThemeConfig(type: ThemeType.esports, label: 'Esports', fanColor: Colors.white, connactColor: AppColors.brandBlue, backgroundAsset: 'assets/esports bg.jpg', glassCards: true, cardBg: Color(0xCC1A1F2B)),
  ThemeConfig(type: ThemeType.royal, label: 'Royal', fanColor: AppColors.brandBlue, connactColor: AppColors.gold, backgroundAsset: 'assets/background.jpg', glassCards: true, cardBg: Colors.black26),
  ThemeConfig(type: ThemeType.custom, label: 'Custom', fanColor: Colors.white, connactColor: AppColors.brandGreen, cardBg: Color(0xFF1C2230)),
];

ThemeConfig themeConfigFor(ThemeType type) {
  return themeConfigs.firstWhere((c) => c.type == type);
}

BoxDecoration glassDecoration({double blur = 12, Color? bg, double radius = 16}) {
  return BoxDecoration(
    color: bg ?? Colors.white.withValues(alpha: 0.08),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    boxShadow: [
      BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: blur, offset: const Offset(0, 4)),
    ],
  );
}

// Renders a theme background from either a bundled asset path or a remote URL
// (custom theme). Falls back to a solid dark box if the image can't load.
class ThemeBackground extends StatelessWidget {
  final String src;
  final BoxFit fit;
  const ThemeBackground({super.key, required this.src, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    final isNet = src.startsWith('http://') || src.startsWith('https://');
    if (isNet) {
      return Image.network(
        src,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0E1116)),
      );
    }
    return Image.asset(
      src,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0E1116)),
    );
  }
}

ThemeData buildTheme({
  required ThemeType type,
  Color accent = AppColors.brandBlue,
  ThemeConfig? customConfig,
  bool compact = false,
  bool reduceAnimations = false,
}) {
  final cfg = customConfig ?? themeConfigFor(type);
  final isDark = cfg.isDark;
  final hasBg = cfg.hasBackground;
  final surface = cfg.pageBg ?? (isDark ? const Color(0xFF161B22) : const Color(0xFFFFFFFF));
  final textPrimary = (type == ThemeType.royal)
      ? AppColors.gold
      : (cfg.textPrimaryColor ?? (isDark ? Colors.white : const Color(0xFF1A1F2B)));
  final textSecondary = cfg.textSecondaryColor ?? (isDark ? Colors.white70 : Colors.black54);

  final base = ThemeData(
    brightness: isDark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: hasBg ? const Color(0x8C0E1116) : surface,
    primaryColor: accent,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accent,
      brightness: isDark ? Brightness.dark : Brightness.light,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: cfg.glassCards ? Colors.transparent : surface,
      foregroundColor: textPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: IconThemeData(color: textPrimary),
    ),
    cardColor: cfg.cardBg ?? (isDark ? AppColors.darkCard : AppColors.lightCard),
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: textPrimary),
      bodySmall: TextStyle(color: textSecondary),
    ),
    useMaterial3: true,
  );

  if (!compact && !reduceAnimations) return base;

  return base.copyWith(
    visualDensity: compact ? VisualDensity.compact : null,
    materialTapTargetSize: compact ? MaterialTapTargetSize.shrinkWrap : null,
    splashFactory: reduceAnimations ? NoSplash.splashFactory : null,
    pageTransitionsTheme: reduceAnimations
        ? const PageTransitionsTheme(
            builders: {
              TargetPlatform.android: _InstantPageTransitionsBuilder(),
              TargetPlatform.iOS: _InstantPageTransitionsBuilder(),
              TargetPlatform.windows: _InstantPageTransitionsBuilder(),
              TargetPlatform.macOS: _InstantPageTransitionsBuilder(),
              TargetPlatform.linux: _InstantPageTransitionsBuilder(),
              TargetPlatform.fuchsia: _InstantPageTransitionsBuilder(),
            },
          )
        : null,
  );
}

// Replaces route transitions with an instant swap (used by Reduce Animations).
class _InstantPageTransitionsBuilder extends PageTransitionsBuilder {
  const _InstantPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
