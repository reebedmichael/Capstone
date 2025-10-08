import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'app_colors.dart';

class AppTheme {
	final ThemeMode themeMode;
	final ThemeData lightTheme;
	final ThemeData darkTheme;
	const AppTheme({required this.themeMode, required this.lightTheme, required this.darkTheme});
}

final appThemeProvider = StateNotifierProvider<_ThemeController, AppTheme>((ref) {
	return _ThemeController();
});

class _ThemeController extends StateNotifier<AppTheme> {
	_ThemeController()
			: super(AppTheme(
					themeMode: ThemeMode.system,
					lightTheme: _buildLightTheme(),
					darkTheme: _buildDarkTheme(),
			));

	void setThemeMode(ThemeMode mode) {
		state = AppTheme(themeMode: mode, lightTheme: _buildLightTheme(), darkTheme: _buildDarkTheme());
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
		surface: isDark ? AppColors.neutralDark : Colors.white,
		onSurface: isDark ? Colors.white : const Color(0xFF111827),
	);


	final textTheme = GoogleFonts.interTextTheme();

	final radius = const BorderRadius.all(Radius.circular(12));

	return ThemeData(
		useMaterial3: true,
		brightness: brightness,
		colorScheme: colorScheme,
		scaffoldBackgroundColor: isDark ? AppColors.neutralDark : AppColors.neutralLight,
		textTheme: textTheme,
		inputDecorationTheme: InputDecorationTheme(
			border: OutlineInputBorder(borderRadius: radius),
			enabledBorder: OutlineInputBorder(
				borderRadius: radius,
				borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
			),
			focusedBorder: OutlineInputBorder(
				borderRadius: radius,
				borderSide: BorderSide(color: colorScheme.primary),
			),
		),
		cardTheme: const CardThemeData().copyWith(
			color: colorScheme.surface,
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
		tabBarTheme: const TabBarThemeData().copyWith(indicatorColor: colorScheme.primary, labelColor: colorScheme.primary),
	);
}

ThemeData _buildLightTheme() => _baseTheme(Brightness.light);
ThemeData _buildDarkTheme() => _baseTheme(Brightness.dark); 