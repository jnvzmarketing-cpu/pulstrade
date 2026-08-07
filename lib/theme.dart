import 'package:flutter/material.dart';
class AppColors {
  static const darkBg = Color(0xFF0D0D0D);
  static const darkCard = Color(0xFF1A1A1A);
  static const darkCard2 = Color(0xFF222222);
  static const darkBorder = Color(0xFF2A2A2A);
  static const lightBg = Color(0xFFF5F5F0);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightCard2 = Color(0xFFF0F0EB);
  static const lightBorder = Color(0x0F000000);
  static const gold = Color(0xFFC9A84C);
  static const goldDark = Color(0xFFA07830);
  static const goldDim = Color(0x26C9A84C);
  static const green = Color(0xFF4ADE80);
  static const greenDark = Color(0xFF16A34A);
  static const greenDim = Color(0x1A4ADE80);
  static const red = Color(0xFFF87171);
  static const redDark = Color(0xFFDC2626);
  static const redDim = Color(0x1AF87171);
  static const textMuted = Color(0xFF666666);
  static const textMutedLight = Color(0xFF999999);
}
class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true, brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.darkBg,
    colorScheme: const ColorScheme.dark(primary: AppColors.gold, surface: AppColors.darkCard),
    appBarTheme: const AppBarTheme(backgroundColor: AppColors.darkBg, elevation: 0, iconTheme: IconThemeData(color: AppColors.gold)),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: AppColors.darkBg, selectedItemColor: AppColors.gold, unselectedItemColor: AppColors.textMuted, type: BottomNavigationBarType.fixed, elevation: 0, selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600), unselectedLabelStyle: TextStyle(fontSize: 10)),
  );
  static ThemeData get light => ThemeData(
    useMaterial3: true, brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.lightBg,
    colorScheme: const ColorScheme.light(primary: AppColors.gold, surface: AppColors.lightCard),
    appBarTheme: const AppBarTheme(backgroundColor: AppColors.lightBg, elevation: 0, iconTheme: IconThemeData(color: AppColors.gold)),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: AppColors.lightCard, selectedItemColor: AppColors.gold, unselectedItemColor: AppColors.textMutedLight, type: BottomNavigationBarType.fixed, elevation: 0, selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w600), unselectedLabelStyle: TextStyle(fontSize: 10)),
  );
}
