import 'package:flutter/material.dart';

class AppColors {
  // One coherent graphite neutral ramp
  static const Color background = Color(0xFF111215);
  static const Color surface = Color(0xFF181A1F);
  static const Color surfaceRaised = Color(0xFF21242C);
  static const Color surfaceHigh = Color(0xFF2B2F3A);

  // Hairlines strictly at 8% and 4%
  static const Color border = Color(0x14FFFFFF); // 8% white
  static const Color borderSubtle = Color(0x0AFFFFFF); // 4% white
  static const Color borderFocus = Color(0x2EFFFFFF); // 18% white

  // Single calm accent (Emerald)
  static const Color accent = Color(0xFF10B981);
  static const Color accentMuted = Color(0xFF064E3B);
  static const Color onAccent = Color(0xFF022C22);

  // Danger/warning for delete or lapses
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerMuted = Color(0xFF451A1A);

  // 3 distinct text roles
  static const Color textPrimary = Color(0xFFEDEDF0);
  static const Color textSecondary = Color(0xFF9497A1);
  static const Color textMuted = Color(0xFF636672);

  // Category subtle indicators (pure flat colors, low saturation)
  static const Color catMind = Color(0xFF10B981);
  static const Color catHealth = Color(0xFF0EA5E9);
  static const Color catFocus = Color(0xFFA855F7);
  static const Color catFitness = Color(0xFFF59E0B);
}

class AppTypography {
  static const TextStyle titleLarge = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.2,
  );

  static const TextStyle titleMedium = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.1,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle bodySecondary = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle labelMuted = TextStyle(
    color: AppColors.textMuted,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
  );

  static const TextStyle numericLarge = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 28,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
    letterSpacing: -0.5,
  );

  static const TextStyle numericMedium = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static const TextStyle numericSmall = TextStyle(
    color: AppColors.textSecondary,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        surface: AppColors.surface,
        primary: AppColors.accent,
        secondary: AppColors.textSecondary,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: AppColors.textSecondary, size: 20),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
