// lib/core/theme/app_theme/app_theme_dark.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../colors/app_colors_dark.dart';
import '../text_styles/app_text_styles.dart';

class AppThemeDark {
  AppThemeDark._();

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColorsDark.primary,
        onPrimary: AppColorsDark.background,
        primaryContainer: AppColorsDark.primaryContainer,
        onPrimaryContainer: AppColorsDark.primaryLight,
        secondary: AppColorsDark.secondary,
        onSecondary: AppColorsDark.background,
        secondaryContainer: AppColorsDark.secondaryContainer,
        onSecondaryContainer: AppColorsDark.secondaryLight,
        tertiary: AppColorsDark.accent,
        onTertiary: AppColorsDark.background,
        error: AppColorsDark.error,
        onError: AppColorsDark.background,
        surface: AppColorsDark.surface,
        onSurface: AppColorsDark.textPrimary,
        surfaceContainerHighest: AppColorsDark.surfaceContainer,
        outline: AppColorsDark.border,
        shadow: AppColorsDark.shadow,
      ),

      // Scaffold
      scaffoldBackgroundColor: AppColorsDark.background,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColorsDark.surface,
        foregroundColor: AppColorsDark.textPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTextStyles.titleLarge().copyWith(
          color: AppColorsDark.textPrimary,
        ),
        iconTheme: const IconThemeData(
          color: AppColorsDark.textPrimary,
          size: 24,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: AppColorsDark.shadow,
        color: AppColorsDark.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColorsDark.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColorsDark.border,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColorsDark.border,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColorsDark.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColorsDark.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColorsDark.error,
            width: 2,
          ),
        ),
        labelStyle: AppTextStyles.inputLabel().copyWith(
          color: AppColorsDark.textSecondary,
        ),
        hintStyle: AppTextStyles.inputLabel().copyWith(
          color: AppColorsDark.textTertiary,
        ),
        errorStyle: AppTextStyles.inputError().copyWith(
          color: AppColorsDark.error,
        ),
      ),

      // Elevated Button
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: AppColorsDark.primary,
          foregroundColor: AppColorsDark.background,
          disabledBackgroundColor: AppColorsDark.surfaceVariant,
          disabledForegroundColor: AppColorsDark.textDisabled,
          shadowColor: AppColorsDark.shadow,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.button(),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColorsDark.primary,
          side: const BorderSide(
            color: AppColorsDark.primary,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.button(),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColorsDark.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: AppTextStyles.button(),
        ),
      ),

      // FAB
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: AppColorsDark.primary,
        foregroundColor: AppColorsDark.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Bottom Nav
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColorsDark.surface,
        selectedItemColor: AppColorsDark.primary,
        unselectedItemColor: AppColorsDark.textSecondary,
        selectedLabelStyle: AppTextStyles.labelSmall(),
        unselectedLabelStyle: AppTextStyles.labelSmall(),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColorsDark.surface,
        indicatorColor: AppColorsDark.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmall().copyWith(
              color: AppColorsDark.primary,
            );
          }
          return AppTextStyles.labelSmall().copyWith(
            color: AppColorsDark.textSecondary,
          );
        }),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: AppColorsDark.surfaceVariant,
        selectedColor: AppColorsDark.primaryContainer,
        disabledColor: AppColorsDark.surfaceContainer,
        labelStyle: AppTextStyles.labelMedium().copyWith(
          color: AppColorsDark.textPrimary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: AppColorsDark.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: AppTextStyles.headlineSmall().copyWith(
          color: AppColorsDark.textPrimary,
        ),
        contentTextStyle: AppTextStyles.bodyMedium().copyWith(
          color: AppColorsDark.textSecondary,
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColorsDark.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColorsDark.surfaceContainer,
        contentTextStyle: AppTextStyles.bodyMedium().copyWith(
          color: AppColorsDark.textPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: AppColorsDark.divider,
        thickness: 1,
        space: 1,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge().copyWith(
          color: AppColorsDark.textPrimary,
        ),
        displayMedium: AppTextStyles.displayMedium().copyWith(
          color: AppColorsDark.textPrimary,
        ),
        displaySmall: AppTextStyles.displaySmall().copyWith(
          color: AppColorsDark.textPrimary,
        ),
        headlineLarge: AppTextStyles.headlineLarge().copyWith(
          color: AppColorsDark.textPrimary,
        ),
        headlineMedium: AppTextStyles.headlineMedium().copyWith(
          color: AppColorsDark.textPrimary,
        ),
        headlineSmall: AppTextStyles.headlineSmall().copyWith(
          color: AppColorsDark.textPrimary,
        ),
        titleLarge: AppTextStyles.titleLarge().copyWith(
          color: AppColorsDark.textPrimary,
        ),
        titleMedium: AppTextStyles.titleMedium().copyWith(
          color: AppColorsDark.textPrimary,
        ),
        titleSmall: AppTextStyles.titleSmall().copyWith(
          color: AppColorsDark.textPrimary,
        ),
        bodyLarge: AppTextStyles.bodyLarge().copyWith(
          color: AppColorsDark.textPrimary,
        ),
        bodyMedium: AppTextStyles.bodyMedium().copyWith(
          color: AppColorsDark.textSecondary,
        ),
        bodySmall: AppTextStyles.bodySmall().copyWith(
          color: AppColorsDark.textSecondary,
        ),
        labelLarge: AppTextStyles.labelLarge().copyWith(
          color: AppColorsDark.textPrimary,
        ),
        labelMedium: AppTextStyles.labelMedium().copyWith(
          color: AppColorsDark.textSecondary,
        ),
        labelSmall: AppTextStyles.labelSmall().copyWith(
          color: AppColorsDark.textSecondary,
        ),
      ),
    );
  }
}