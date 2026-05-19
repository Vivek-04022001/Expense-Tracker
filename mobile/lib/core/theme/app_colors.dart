import 'package:flutter/material.dart';

extension AppThemeColors on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bgBase =>
      _isDark ? AppColors.darkBgBase : AppColors.lightBgBase;
  Color get bgSurface =>
      _isDark ? AppColors.darkBgSurface : AppColors.lightBgSurface;
  Color get bgSubtle =>
      _isDark ? AppColors.darkBgSubtle : AppColors.lightBgSubtle;
  Color get bgElevated =>
      _isDark ? AppColors.darkBgElevated : AppColors.lightBgElevated;
  Color get borderSubtle =>
      _isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
  Color get textPrimary =>
      _isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color get textSecondary =>
      _isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get textTertiary =>
      _isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
}

abstract class AppColors {
  // Primary
  static const primary500 = Color(0xFF0B5FFF);
  static const primary100 = Color(0xFFE6EEFF);

  // Accent
  static const accent500 = Color(0xFF00C48C);

  // Semantic
  static const success = Color(0xFF00C48C);
  static const warning = Color(0xFFFFB020);
  static const danger = Color(0xFFFF4D6A);
  static const info = Color(0xFF5B8DEF);

  // Light theme surfaces
  static const lightBgBase = Color(0xFFFAFAFB);
  static const lightBgSubtle = Color(0xFFF3F4F6);
  static const lightBgSurface = Color(0xFFFFFFFF);
  static const lightBgElevated = Color(0xFFFFFFFF);
  static const lightBorderSubtle = Color(0xFFECEDF0);
  static const lightTextPrimary = Color(0xFF0E0F12);
  static const lightTextSecondary = Color(0xFF5B616E);
  static const lightTextTertiary = Color(0xFF8A90A0);

  // Dark theme surfaces
  static const darkBgBase = Color(0xFF0E0F12);
  static const darkBgSubtle = Color(0xFF1C1E26);
  static const darkBgSurface = Color(0xFF17191F);
  static const darkBgElevated = Color(0xFF1F222A);
  static const darkBorderSubtle = Color(0xFF252830);
  static const darkTextPrimary = Color(0xFFF4F5F7);
  static const darkTextSecondary = Color(0xFFA0A6B3);
  static const darkTextTertiary = Color(0xFF6B7280);

  // Category colors — fixed, never themed
  static const categoryFood = Color(0xFFFF6B4A);
  static const categoryTransport = Color(0xFF5B8DEF);
  static const categoryShopping = Color(0xFFB66BFF);
  static const categoryBills = Color(0xFFFFB020);
  static const categoryEntertainment = Color(0xFFFF4D9D);
  static const categoryHealth = Color(0xFF00C48C);
  static const categoryEducation = Color(0xFF7AC74F);
  static const categoryOther = Color(0xFF8A90A0);

  // Map from your backend enum strings
  static Color forCategory(String category) {
    return switch (category.toLowerCase()) {
      'food_and_drink' => categoryFood,
      'transport' => categoryTransport,
      'shopping' => categoryShopping,
      'bills_and_utilities' => categoryBills,
      'entertainment' => categoryEntertainment,
      'health' => categoryHealth,
      'education' => categoryEducation,
      _ => categoryOther,
    };
  }
}
