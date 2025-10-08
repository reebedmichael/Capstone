import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';

class AppTheme {
  final ThemeMode themeMode;
  final ThemeData lightTheme;
  final ThemeData darkTheme;
  const AppTheme({
    required this.themeMode,
    required this.lightTheme,
    required this.darkTheme,
  });
}

final appThemeProvider = StateNotifierProvider<_ThemeController, AppTheme>((
  ref,
) {
  return _ThemeController();
});

class _ThemeController extends StateNotifier<AppTheme> {
  static const String _themeKey = 'theme_mode';

  _ThemeController()
    : super(
        AppTheme(
          themeMode: ThemeMode.system,
          lightTheme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
        ),
      );

  Future<void> initializeTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    final themeMode = ThemeMode.values[themeIndex];

    state = AppTheme(
      themeMode: themeMode,
      lightTheme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);

    state = AppTheme(
      themeMode: mode,
      lightTheme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
    );
  }
}

ThemeData _baseTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final baseScheme = ColorScheme.fromSeed(
    brightness: brightness,
    seedColor: AppColors.primary,
  );
  final colorScheme = baseScheme.copyWith(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    tertiary: AppColors.accent,
    error: AppColors.destructive,
    surface: AppColors.getSurfaceColor(isDark),
    onSurface: AppColors.getOnSurfaceColor(isDark),
    onSurfaceVariant: AppColors.getOnSurfaceVariantColor(isDark),
  );

  final baseTextTheme = GoogleFonts.interTextTheme();
  final textTheme = baseTextTheme.apply(
    bodyColor: AppColors.getOnSurfaceColor(isDark),
    displayColor: AppColors.getOnSurfaceColor(isDark),
  );

  final radius = const BorderRadius.all(Radius.circular(12));

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.getBackgroundColor(isDark),
    cardColor: AppColors.getCardColor(isDark),
    dividerColor: AppColors.getDividerColor(isDark),
    textTheme: textTheme,
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: radius),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: AppColors.getBorderColor(isDark)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide(color: colorScheme.primary),
      ),
    ),
    cardTheme: const CardThemeData().copyWith(
      color: AppColors.getCardColor(isDark),
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: radius),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        textStyle: textTheme.labelLarge,
      ),
    ),
    tabBarTheme: const TabBarThemeData().copyWith(
      indicatorColor: colorScheme.primary,
      labelColor: colorScheme.primary,
    ),
  );
}

ThemeData _buildLightTheme() => _baseTheme(Brightness.light);
ThemeData _buildDarkTheme() => _baseTheme(Brightness.dark);
