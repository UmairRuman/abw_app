// lib/core/theme/colors/app_colors_dark.dart

import 'package:flutter/material.dart';

/// Enhanced Dark Theme Colors - Modern & Eye-Friendly
class AppColorsDark {
  AppColorsDark._();

  // Primary Colors - Vibrant but comfortable for dark mode
  static const Color primary = Color(0xFF60A5FA); // Soft Blue
  static const Color primaryLight = Color(0xFF93C5FD);
  static const Color primaryDark = Color(0xFF3B82F6);
  static const Color primaryContainer = Color(0xFF1E3A8A);

  // Secondary Colors - Purple accent
  static const Color secondary = Color(0xFFA78BFA); // Soft Purple
  static const Color secondaryLight = Color(0xFFC4B5FD);
  static const Color secondaryDark = Color(0xFF8B5CF6);
  static const Color secondaryContainer = Color(0xFF4C1D95);

  // Accent Colors
  static const Color accent = Color(0xFFF472B6); // Pink
  static const Color accentLight = Color(0xFFF9A8D4);
  static const Color accentDark = Color(0xFFEC4899);

  // Background & Surface - Deep, rich blacks
  static const Color background = Color(0xFF0F172A); // Deep Navy Black
  static const Color backgroundSecondary = Color(0xFF1E293B);
  static const Color surface = Color(0xFF1E293B); // Slate
  static const Color surfaceVariant = Color(0xFF334155);
  static const Color surfaceContainer = Color(0xFF475569);

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC); // Almost white
  static const Color textSecondary = Color(0xFFCBD5E1); // Light gray
  static const Color textTertiary = Color(0xFF94A3B8); // Medium gray
  static const Color textDisabled = Color(0xFF64748B);

  // Semantic Colors - Softer for dark mode
  static const Color success = Color(0xFF34D399); // Emerald
  static const Color successLight = Color(0xFF6EE7B7);
  static const Color successDark = Color(0xFF10B981);

  static const Color error = Color(0xFFF87171); // Soft Red
  static const Color errorLight = Color(0xFFFCA5A5);
  static const Color errorDark = Color(0xFFEF4444);

  static const Color warning = Color(0xFFFBBF24); // Amber
  static const Color warningLight = Color(0xFFFCD34D);
  static const Color warningDark = Color(0xFFF59E0B);

  static const Color info = Color(0xFF60A5FA); // Blue
  static const Color infoLight = Color(0xFF93C5FD);
  static const Color infoDark = Color(0xFF3B82F6);

  // Border & Divider
  static const Color border = Color(0xFF334155);
  static const Color borderLight = Color(0xFF475569);
  static const Color divider = Color(0xFF334155);

  // Card & Container
  static const Color cardBackground = Color(0xFF1E293B);
  static const Color cardBackgroundHover = Color(0xFF334155);

  // Special - Food delivery specific
  static const Color foodRating = Color(0xFFFBBF24); // Star rating
  static const Color deliveryActive = Color(0xFF34D399); // Active delivery
  static const Color priceTag = Color(0xFF60A5FA); // Price highlight

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E293B), Color(0xFF334155)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Overlay
  static const Color overlay = Color(0x80000000);
  static const Color overlayLight = Color(0x40000000);
  static const Color scrim = Color(0xCC000000);

  // Shimmer for loading states
  static const Color shimmerBase = Color(0xFF334155);
  static const Color shimmerHighlight = Color(0xFF475569);

  // Shadow
  static const Color shadow = Color(0x40000000);
  static const Color shadowStrong = Color(0x60000000);

  // White & Black
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
}