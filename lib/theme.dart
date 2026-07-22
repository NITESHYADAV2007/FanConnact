import 'package:flutter/material.dart';

// Brand colors taken from the Fanconnact website (css/style.css, matchcenter.css).
class AppColors {
  static const Color brandBlue = Color(0xFF2196F3);
  static const Color brandBlueDark = Color(0xFF1565C0);
  static const Color liveRed = Color(0xFFE53935);
  static const Color completedGrey = Color(0xFF9E9E9E);
  static const Color upcomingAmber = Color(0xFFFF9800);

  // Dark theme surfaces
  static const Color darkBg = Color(0xFF0E1116);
  static const Color darkSurface = Color(0xFF161B22);
  static const Color darkCard = Color(0xFF1C2230);

  // Light theme surfaces
  static const Color lightBg = Color(0xFFF4F6FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
}

ThemeData buildTheme({required bool dark}) {
  final bg = dark ? AppColors.darkBg : AppColors.lightBg;
  final surface = dark ? AppColors.darkSurface : AppColors.lightSurface;
  final card = dark ? AppColors.darkCard : AppColors.lightCard;
  final textPrimary = dark ? Colors.white : const Color(0xFF1A1F2B);
  final textSecondary = dark ? Colors.white70 : Colors.black54;

  return ThemeData(
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: bg,
    primaryColor: AppColors.brandBlue,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.brandBlue,
      brightness: dark ? Brightness.dark : Brightness.light,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: textPrimary,
      elevation: 0,
      iconTheme: IconThemeData(color: textPrimary),
    ),
    cardColor: card,
    textTheme: TextTheme(
      bodyMedium: TextStyle(color: textPrimary),
      bodySmall: TextStyle(color: textSecondary),
    ),
    useMaterial3: true,
  );
}
