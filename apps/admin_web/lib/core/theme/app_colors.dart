import 'package:flutter/material.dart';

class AppColors {
  // Primary colors (same for both themes)
  static const primary = Color(0xFFFF6B35);
  static const onPrimary = Color(0xFFFFFFFF);
  static const secondary = Color(0xFFFF8C42);
  static const onSecondary = Color(0xFFFFFFFF);
  static const accent = Color(0xFFFFA366);

  // Light theme colors
  static const lightBackground = Color(0xFFF8F9FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightOnSurface = Color(0xFF1C1B1F);
  static const lightOnSurfaceVariant = Color(0xFF49454F);
  static const lightBorder = Color(0x1A000000); // rgba(0,0,0,0.1)
  static const lightCardColor = Color(0xFFFFFFFF);
  static const lightDividerColor = Color(0x1A000000);

  // Dark theme colors
  static const darkBackground = Color(0xFF121212);
  static const darkSurface = Color(0xFF1E1E1E);
  static const darkOnSurface = Color(0xFFE1E1E1);
  static const darkOnSurfaceVariant = Color(0xFFB3B3B3);
  static const darkBorder = Color(0x26FFFFFF); // rgba(255,255,255,0.15)
  static const darkCardColor = Color(0xFF2D2D2D);
  static const darkDividerColor = Color(0x26FFFFFF);

  // Common colors
  static const destructive = Color(0xFFE74C3C);
  static const error = Color(0xFFD32F2F);
  static const shadow = Color(0x1F000000);
  static const shadowLight = Color(0x0A000000);

  // Legacy properties for backward compatibility
  static const onSurface = lightOnSurface;
  static const onSurfaceVariant = lightOnSurfaceVariant;

  // Helper methods to get theme-appropriate colors
  static Color getBackgroundColor(bool isDark) =>
      isDark ? darkBackground : lightBackground;
  static Color getSurfaceColor(bool isDark) =>
      isDark ? darkSurface : lightSurface;
  static Color getOnSurfaceColor(bool isDark) =>
      isDark ? darkOnSurface : lightOnSurface;
  static Color getOnSurfaceVariantColor(bool isDark) =>
      isDark ? darkOnSurfaceVariant : lightOnSurfaceVariant;
  static Color getBorderColor(bool isDark) => isDark ? darkBorder : lightBorder;
  static Color getCardColor(bool isDark) =>
      isDark ? darkCardColor : lightCardColor;
  static Color getDividerColor(bool isDark) =>
      isDark ? darkDividerColor : lightDividerColor;
}
