// lib/core/theme/app_theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../colors/app_colors.dart';
import '../text_styles/app_text_styles.dart';

class AppTheme {
  AppTheme._();

  // Light Theme
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: AppColors.white,
        primaryContainer: AppColors.primaryContainer,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.secondary,
        onSecondary: AppColors.white,
        secondaryContainer: AppColors.secondaryContainer,
        onSecondaryContainer: AppColors.secondaryDark,
        tertiary: AppColors.accent,
        onTertiary: AppColors.white,
        error: AppColors.error,
        onError: AppColors.white,
        errorContainer: AppColors.errorLight,
        onErrorContainer: AppColors.errorDark,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.grey100,
        outline: AppColors.border,
        shadow: AppColors.shadow,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppColors.background,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: AppTextStyles.titleLarge(),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimary,
          size: 24,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: AppColors.shadow,
        color: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.grey50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.border,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.grey200,
            width: 1,
          ),
        ),
        labelStyle: AppTextStyles.inputLabel(),
        hintStyle: AppTextStyles.inputLabel().copyWith(
          color: AppColors.textTertiary,
        ),
        errorStyle: AppTextStyles.inputError(),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.grey200,
          disabledForegroundColor: AppColors.textDisabled,
          shadowColor: AppColors.shadow,
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

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(
            color: AppColors.primary,
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

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
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

      // Icon Button Theme
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: AppTextStyles.labelSmall(),
        unselectedLabelStyle: AppTextStyles.labelSmall(),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Navigation Bar Theme (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.white,
        indicatorColor: AppColors.primaryContainer,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.labelSmall().copyWith(
              color: AppColors.primary,
            );
          }
          return AppTextStyles.labelSmall().copyWith(
            color: AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary);
          }
          return const IconThemeData(color: AppColors.textSecondary);
        }),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.grey100,
        selectedColor: AppColors.primaryContainer,
        disabledColor: AppColors.grey200,
        labelStyle: AppTextStyles.labelMedium(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titleTextStyle: AppTextStyles.headlineSmall(),
        contentTextStyle: AppTextStyles.bodyMedium(),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(20),
          ),
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.grey800,
        contentTextStyle: AppTextStyles.bodyMedium().copyWith(
          color: AppColors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
        space: 1,
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.displayLarge(),
        displayMedium: AppTextStyles.displayMedium(),
        displaySmall: AppTextStyles.displaySmall(),
        headlineLarge: AppTextStyles.headlineLarge(),
        headlineMedium: AppTextStyles.headlineMedium(),
        headlineSmall: AppTextStyles.headlineSmall(),
        titleLarge: AppTextStyles.titleLarge(),
        titleMedium: AppTextStyles.titleMedium(),
        titleSmall: AppTextStyles.titleSmall(),
        bodyLarge: AppTextStyles.bodyLarge(),
        bodyMedium: AppTextStyles.bodyMedium(),
        bodySmall: AppTextStyles.bodySmall(),
        labelLarge: AppTextStyles.labelLarge(),
        labelMedium: AppTextStyles.labelMedium(),
        labelSmall: AppTextStyles.labelSmall(),
      ),
    );
  }

  // Dark Theme
  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        onPrimary: AppColors.grey900,
        primaryContainer: AppColors.primaryDark,
        onPrimaryContainer: AppColors.primaryLight,
        secondary: AppColors.secondaryLight,
        onSecondary: AppColors.grey900,
        secondaryContainer: AppColors.secondaryDark,
        onSecondaryContainer: AppColors.secondaryLight,
        tertiary: AppColors.accentLight,
        onTertiary: AppColors.grey900,
        error: AppColors.errorLight,
        onError: AppColors.grey900,
        errorContainer: AppColors.errorDark,
        onErrorContainer: AppColors.errorLight,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        surfaceContainerHighest: AppColors.grey800,
        outline: AppColors.borderDark,
        shadow: AppColors.shadowDark,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppColors.backgroundDark,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: AppTextStyles.titleLarge().copyWith(
          color: AppColors.textPrimaryDark,
        ),
        iconTheme: const IconThemeData(
          color: AppColors.textPrimaryDark,
          size: 24,
        ),
      ),

      // Rest of the dark theme mirrors light theme structure
      // with appropriate color adjustments...
      
      // Card Theme
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: AppColors.shadowDark,
        color: AppColors.surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Add similar dark theme configurations for other components...
    );
  }
}