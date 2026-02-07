// lib/core/theme/colors/app_colors_dark.dart

import 'package:flutter/material.dart';

/// Enhanced Dark Theme Colors - Modern & Eye-Friendly
class AppColorsDark {
  AppColorsDark._();
  // Primary Colors - FoodPanda Pink
  static const Color primary = Color(0xFFD70F64); // FoodPanda Pink
  static const Color primaryLight = Color(0xFFFF6B9D);
  static const Color primaryDark = Color(0xFFC10E5B);
  static const Color primaryContainer = Color(0xFFFFE5EE);

  // Secondary Colors - Fresh Green
  static const Color secondary = Color(0xFF00A699);
  static const Color secondaryLight = Color(0xFF4ECDC4);
  static const Color secondaryDark = Color(0xFF008C80);
  static const Color secondaryContainer = Color(0xFFE0F7F6);

  // Accent
  static const Color accent = Color(0xFFFF8E3C);
  static const Color accentLight = Color(0xFFFFB380);
  static const Color accentDark = Color(0xFFE67E32);

  // Background & Surface - Clean White
  static const Color background = Color(0xFFFAFAFA);
  static const Color backgroundSecondary = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color surfaceContainer = Color(0xFFEEEEEE);

  // Text Colors
  static const Color textPrimary = Color(0xFF2E3333);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textDisabled = Color(0xFFBDBDBD);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFF81C784);
  static const Color successDark = Color(0xFF388E3C);

  static const Color error = Color(0xFFF44336);
  static const Color errorLight = Color(0xFFE57373);
  static const Color errorDark = Color(0xFFD32F2F);

  static const Color warning = Color(0xFFFF9800);
  static const Color warningLight = Color(0xFFFFB74D);
  static const Color warningDark = Color(0xFFF57C00);

  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFF64B5F6);
  static const Color infoDark = Color(0xFF1976D2);

  // Border & Divider
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFEEEEEE);
  static const Color divider = Color(0xFFE0E0E0);

  // Card
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBackgroundHover = Color(0xFFF5F5F5);

  // Special
  static const Color foodRating = Color(0xFFFFC107);
  static const Color deliveryActive = Color(0xFF4CAF50);
  static const Color priceTag = Color(0xFFD70F64);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFD70F64), Color(0xFFFF6B9D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFAFAFA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFAFAFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Overlay
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);
  static const Color scrim = Color(0xCC000000);

  // Shadow
  static const Color shadow = Color(0x1A000000);
  static const Color shadowStrong = Color(0x33000000);

  // White & Black
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}
