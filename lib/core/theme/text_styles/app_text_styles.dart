// lib/core/theme/text_styles/app_text_styles.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../colors/app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Base Font Family
  static TextStyle _baseStyle() => GoogleFonts.inter(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.normal,
      );

  // Display Styles (Largest)
  static TextStyle displayLarge() => _baseStyle().copyWith(
        fontSize: 57.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        height: 1.12,
      );

  static TextStyle displayMedium() => _baseStyle().copyWith(
        fontSize: 45.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.16,
      );

  static TextStyle displaySmall() => _baseStyle().copyWith(
        fontSize: 36.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.22,
      );

  // Headline Styles
  static TextStyle headlineLarge() => _baseStyle().copyWith(
        fontSize: 32.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.25,
      );

  static TextStyle headlineMedium() => _baseStyle().copyWith(
        fontSize: 28.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.29,
      );

  static TextStyle headlineSmall() => _baseStyle().copyWith(
        fontSize: 24.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.33,
      );

  // Title Styles
  static TextStyle titleLarge() => _baseStyle().copyWith(
        fontSize: 22.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.27,
      );

  static TextStyle titleMedium() => _baseStyle().copyWith(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.15,
        height: 1.5,
      );

  static TextStyle titleSmall() => _baseStyle().copyWith(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
      );

  // Body Styles
  static TextStyle bodyLarge() => _baseStyle().copyWith(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        height: 1.5,
      );

  static TextStyle bodyMedium() => _baseStyle().copyWith(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        height: 1.43,
      );

  static TextStyle bodySmall() => _baseStyle().copyWith(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
      );

  // Label Styles (for buttons, chips, etc.)
  static TextStyle labelLarge() => _baseStyle().copyWith(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        height: 1.43,
      );

  static TextStyle labelMedium() => _baseStyle().copyWith(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.33,
      );

  static TextStyle labelSmall() => _baseStyle().copyWith(
        fontSize: 11.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.45,
      );

  // Custom Styles for specific use cases
  static TextStyle button() => _baseStyle().copyWith(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1.25,
      );

  static TextStyle buttonSmall() => _baseStyle().copyWith(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        height: 1.25,
      );

  static TextStyle caption() => _baseStyle().copyWith(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
        color: AppColors.textSecondary,
      );

  static TextStyle overline() => _baseStyle().copyWith(
        fontSize: 10.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 1.5,
        height: 1.6,
        color: AppColors.textSecondary,
      );

  // Specialized Styles
  static TextStyle inputText() => _baseStyle().copyWith(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        height: 1.5,
      );

  static TextStyle inputLabel() => _baseStyle().copyWith(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
        color: AppColors.textSecondary,
      );

  static TextStyle inputError() => _baseStyle().copyWith(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        height: 1.33,
        color: AppColors.error,
      );

  static TextStyle link() => _baseStyle().copyWith(
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        height: 1.43,
        color: AppColors.primary,
        decoration: TextDecoration.underline,
      );

  static TextStyle price() => _baseStyle().copyWith(
        fontSize: 24.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        height: 1.33,
        color: AppColors.primary,
      );

  static TextStyle code() => GoogleFonts.jetBrainsMono(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        height: 1.5,
        color: AppColors.textPrimary,
      );
}