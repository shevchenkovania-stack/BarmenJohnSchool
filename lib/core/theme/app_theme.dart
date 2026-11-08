import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Палитра переведена в тёплые тона «Школы бармена Джона»: раньше фон,
  // поверхности и разделители были фиолетово-синими, и любой экран на
  // этой теме читался как скриншот из прошлой версии приложения.
  // Тёплый эспрессо + латунь сочетаются с деревянными панелями урока.
  static const background = Color(0xFF1C1712);
  static const surface = Color(0xFF262019);
  static const surfaceLight = Color(0xFF33291F);
  static const primary = Color(0xFFE8A838);
  static const primaryDark = Color(0xFFB8821A);
  static const textPrimary = Color(0xFFF6EEE0);
  static const textSecondary = Color(0xFFC4B49B);
  static const divider = Color(0xFF3A2F24);
  static const shimmerBase = Color(0xFF2B241C);
  static const shimmerHighlight = Color(0xFF3E3327);
  static const border = Color(0xFF4A3C2C);
  static const accent = Color(0xFFC9A227);
  static const success = Color(0xFF7FA650);
}

// ─── Тема ────────────────────────────────────────────────────────────────────

final appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: const ColorScheme.dark(
    surface: AppColors.surface,
    primary: AppColors.primary,
    onPrimary: Colors.black,
    onSurface: AppColors.textPrimary,
  ),
  scaffoldBackgroundColor: AppColors.background,
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: AppColors.textPrimary,
      fontSize: 22,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(color: AppColors.textPrimary),
  ),
  cardTheme: CardThemeData(
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    margin: EdgeInsets.zero,
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textSecondary,
    showSelectedLabels: true,
    showUnselectedLabels: true,
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
  textTheme: const TextTheme(
    headlineMedium: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.bold),
    titleLarge: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 16),
    bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 14),
    labelSmall: TextStyle(color: AppColors.textSecondary, fontSize: 12),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
    prefixIconColor: AppColors.textSecondary,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),
  dividerTheme: const DividerThemeData(
    color: AppColors.divider,
    thickness: 1,
    space: 0,
  ),
);
