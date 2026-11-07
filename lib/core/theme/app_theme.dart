import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const background   = Color(0xFF1A1825);
  static const surface      = Color(0xFF252336);
  static const surfaceLight = Color(0xFF2F2B48);
  static const primary      = Color(0xFFE8A838);
  static const primaryDark  = Color(0xFFB8821A);
  static const textPrimary  = Colors.white;
  static const textSecondary = Color(0xFFB0ABCF);
  static const divider      = Color(0xFF2F2D45);
  static const shimmerBase      = Color(0xFF2A2840);
  static const shimmerHighlight = Color(0xFF383555);
  static const border = Color(0xFF3D3A57);
  static const accent = Color(0xFF4CAF50);
  static const success = Color(0xFF4CAF50);
}

// ─── Тема ────────────────────────────────────────────────────────────────────

final appTheme = ThemeData(
  useMaterial3: true,

  colorScheme: const ColorScheme.dark(
    surface: AppColors.surface,
    primary: AppColors.primary,
    onPrimary: Colors.black,
    // Material 3 без явных secondary/tertiary берёт их из сид-цвета — в
    // интерфейсе это давало лиловые рамки, чекбоксы и подписи. Тёплые
    // оттенки вместо системного фиолета.
    secondary: AppColors.primaryDark,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.surfaceLight,
    onSecondaryContainer: AppColors.textPrimary,
    tertiary: AppColors.primaryDark,
    onTertiary: Colors.white,
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
    headlineMedium: TextStyle(color: AppColors.textPrimary,   fontSize: 24, fontWeight: FontWeight.bold),
    titleLarge:     TextStyle(color: AppColors.textPrimary,   fontSize: 18, fontWeight: FontWeight.w600),
    bodyLarge:      TextStyle(color: AppColors.textPrimary,   fontSize: 16),
    bodyMedium:     TextStyle(color: AppColors.textSecondary, fontSize: 14),
    labelSmall:     TextStyle(color: AppColors.textSecondary, fontSize: 12),
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
