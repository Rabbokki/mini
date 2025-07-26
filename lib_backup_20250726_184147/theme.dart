import 'package:flutter/material.dart';

class AppColors {
  // Light theme colors (CSS :root variables) - HSL을 RGB로 변환
  static const Color background = Color(0xFFE8DCC6); // hsl(43, 28%, 89%)
  static const Color foreground = Color(0xFF3D3024); // hsl(28, 25%, 20%)
  
  static const Color card = Color(0xFFF0EBE0); // hsl(43, 28%, 95%)
  static const Color cardForeground = Color(0xFF3D3024); // hsl(28, 25%, 20%)
  
  static const Color primary = Color(0xFFB8956A); // hsl(25, 45%, 55%)
  static const Color primaryForeground = Color(0xFFF0EBE0); // hsl(43, 28%, 95%)
  static const Color primaryGradientStart = Color(0xFFB8956A); // hsl(25, 45%, 55%)
  static const Color primaryGradientEnd = Color(0xFFA0845C); // hsl(25, 35%, 50%)
  
  static const Color secondary = Color(0xFF292929); // hsl(240, 4%, 16%)
  static const Color secondaryForeground = Color(0xFFFAFAFA); // hsl(0, 0%, 98%)
  
  static const Color muted = Color(0xFFDDD1BB); // hsl(43, 28%, 85%)
  static const Color mutedForeground = Color(0xFF5C4F3A); // hsl(28, 25%, 40%)
  
  static const Color accent = Color(0xFFDDD1BB); // hsl(43, 28%, 85%)
  static const Color accentForeground = Color(0xFF3D3024); // hsl(28, 25%, 20%)
  
  static const Color destructive = Color(0xFFE53E3E); // hsl(0, 84%, 60%)
  static const Color destructiveForeground = Color(0xFFFAFAFA); // hsl(0, 0%, 98%)
  
  static const Color border = Color(0xFFC7B299); // hsl(35, 20%, 75%)
  static const Color input = Color(0xFFDDD1BB); // hsl(43, 28%, 85%)
  static const Color ring = Color(0xFF22C55E); // hsl(142, 76%, 36%)
  
  // Emotion colors for calendar
  static const Color emotionHappy = Color(0xFFFFD700); // hsl(51, 100%, 50%)
  static const Color emotionSad = Color(0xFF3B82F6); // hsl(217, 91%, 60%)
  static const Color emotionAngry = Color(0xFFE53E3E); // hsl(0, 84%, 60%)
  static const Color emotionCalm = Color(0xFF22C55E); // hsl(142, 76%, 36%)
  static const Color emotionExcited = Color(0xFFD946EF); // hsl(280, 100%, 70%)
  static const Color emotionNeutral = Color(0xFF64748B); // hsl(240, 5%, 65%)
  
  // Calendar specific colors
  static const Color calendarBg = Color(0xFFE3D5B7); // hsl(43, 28%, 92%)
  static const Color calendarDateBg = Color(0xFFF5F1E8); // hsl(43, 28%, 97%)
  static const Color calendarDateHover = Color(0xFFD2C3A3); // hsl(35, 30%, 82%)
  
  // Dark theme colors (CSS .dark variables)
  static const Color darkBackground = Color(0xFF0F0F23); // hsl(222.2, 84%, 4.9%)
  static const Color darkForeground = Color(0xFFF8FAFC); // hsl(210, 40%, 98%)
  static const Color darkCard = Color(0xFF0F0F23); // hsl(222.2, 84%, 4.9%)
  static const Color darkCardForeground = Color(0xFFF8FAFC); // hsl(210, 40%, 98%)
  static const Color darkPrimary = Color(0xFFF8FAFC); // hsl(210, 40%, 98%)
  static const Color darkPrimaryForeground = Color(0xFF1E293B); // hsl(222.2, 47.4%, 11.2%)
}



class AppTheme {
  static const double borderRadius = 16.0; // --radius: 1rem
  
  // App.css 스타일 constants
  static const double maxWidth = 1280.0; // #root max-width
  static const double rootPadding = 32.0; // #root padding: 2rem
  static const double logoSize = 96.0; // .logo height: 6em (16px * 6)
  static const double logoPadding = 24.0; // .logo padding: 1.5em
  static const double cardPadding = 32.0; // .card padding: 2em
  static const Color readTheDocsColor = Color(0xFF888888); // .read-the-docs color
  
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.light(
      surface: AppColors.background,
      onSurface: AppColors.foreground,
      primary: AppColors.primary,
      onPrimary: AppColors.primaryForeground,
      secondary: AppColors.secondary,
      onSecondary: AppColors.secondaryForeground,
      error: AppColors.destructive,
      onError: AppColors.destructiveForeground,
      outline: AppColors.border,
    ),
    cardTheme: CardThemeData(
      color: AppColors.card,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: AppColors.input,
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide(color: AppColors.ring, width: 2),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForeground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    ),
  );
  
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      surface: AppColors.darkBackground,
      onSurface: AppColors.darkForeground,
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkPrimaryForeground,
      secondary: AppColors.secondary,
      onSecondary: AppColors.secondaryForeground,
      error: AppColors.destructive,
      onError: AppColors.destructiveForeground,
      outline: AppColors.border,
    ),
    cardTheme: CardThemeData(
      color: AppColors.darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ),
  );
} 