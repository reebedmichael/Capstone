import 'package:flutter/material.dart';

class AppColors {
  // Light palette (backward-compatible static names)
  static const Color primary = Color(0xFFFF6600);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color secondary = Color(0xFFF2F3F9);
  static const Color onSecondary = Color(0xFF030213);
  static const Color background = Color(0xFFFFFFFF);
  static const Color onBackground = Color(0xFF111111);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF111111);
  static const Color error = Color(0xFFD4183D);
  static const Color onError = Color(0xFFFFFFFF);

  // Additional semantic tokens (light)
  static const Color accent = Color(0xFF2563EB); // Blue for success/positive actions
  static const Color onAccent = Color(0xFFFFFFFF);
  static const Color muted = Color(0xFFECECF0);
  static const Color onMuted = Color(0xFF717182);
  static const Color outline = Color(0x1A000000); // #0000001A
  static const Color inputBackground = Color(0xFFF3F3F5);
  static const Color switchBackground = Color(0xFFCBCED4);
  static const Color ringLight = Color(0x66FF6600); // primary @ 40%

  // Backward-compat aliases
  static const Color surfaceVariant = muted;
  static const Color onSurfaceVariant = onMuted;
  static const Color border = outline;
  static const Color borderFocused = primary;
  static const Color borderError = error;

  // Shadows (kept for existing usage)
  static const Color shadow = Color(0x1F000000);
  static const Color shadowLight = Color(0x0A000000);

  // Dark palette
  static const Color primaryDark = Color(0xFFFF7722);
  static const Color onPrimaryDark = Color(0xFF2F2F2F);
  static const Color secondaryDark = Color(0xFF30343A);
  static const Color onSecondaryDark = Color(0xFFF7F7F7);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color onBackgroundDark = Color(0xFFF7F7F7);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color onSurfaceDark = Color(0xFFF7F7F7);
  static const Color errorDark = Color(0xFF7A2B23);
  static const Color onErrorDark = Color(0xFFF7F7F7);

  // Additional semantic tokens (dark)
  static const Color accentDark = Color(0xFF3B82F6); // Brighter blue for dark mode
  static const Color onAccentDark = Color(0xFFFFFFFF);
  static const Color mutedDark = Color(0xFF2B2B2B);
  static const Color onMutedDark = Color(0xFFB4B4B4);
  static const Color outlineDark = Color(0xFF424242);
  static const Color inputBackgroundDark = Color(0xFF1E1E1E);
  static const Color switchBackgroundDark = Color(0xFF3C3F45);
  static const Color ringDark = Color(0x66FF7722); // primaryDark @ 40%

  // Backward-compat aliases (dark)
  static const Color surfaceVariantDark = mutedDark;
  static const Color onSurfaceVariantDark = onMutedDark;
  static const Color borderDark = outlineDark;
  static const Color borderFocusedDark = primaryDark;
  static const Color borderErrorDark = errorDark;

  // Color schemes derived from tokens
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primary,
    onPrimary: onPrimary,
    secondary: secondary,
    onSecondary: onSecondary,
    error: error,
    onError: onError,
    surface: surface,
    onSurface: onSurface,
    // M3 extended roles
    surfaceContainerHighest: muted,
    onSurfaceVariant: onMuted,
    outline: outline,
    tertiary: accent,
    onTertiary: onAccent,
    inverseSurface: Color(0xFF111111),
    onInverseSurface: Color(0xFFFFFFFF),
    inversePrimary: primary,
  );

  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primaryDark,
    onPrimary: onPrimaryDark,
    secondary: secondaryDark,
    onSecondary: onSecondaryDark,
    error: errorDark,
    onError: onErrorDark,
    surface: surfaceDark,
    onSurface: onSurfaceDark,
    // M3 extended roles
    surfaceContainerHighest: mutedDark,
    onSurfaceVariant: onMutedDark,
    outline: outlineDark,
    tertiary: accentDark,
    onTertiary: onAccentDark,
    inverseSurface: Color(0xFFEDEDED),
    onInverseSurface: Color(0xFF111111),
    inversePrimary: primaryDark,
  );

  // Ring utility
  static Color ring(Brightness brightness) =>
      brightness == Brightness.dark ? ringDark : ringLight;
}
