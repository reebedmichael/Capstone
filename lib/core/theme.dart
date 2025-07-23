import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      brightness: Brightness.light,
      primary: AppConstants.primaryColor,
      secondary: AppConstants.secondaryColor,
      surface: AppConstants.surfaceColor,
      background: AppConstants.backgroundColor,
      tertiary: AppConstants.accentColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppConstants.darkColor,
    ),
    textTheme: GoogleFonts.robotoTextTheme(),
    scaffoldBackgroundColor: AppConstants.backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: const CardThemeData(
      elevation: 3,
      color: Colors.white,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: AppConstants.primaryColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLarge,
          vertical: AppConstants.paddingMedium,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        borderSide: BorderSide(color: AppConstants.primaryColor.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
      ),
      filled: true,
      fillColor: AppConstants.lightColor,
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppConstants.lightColor,
      selectedIconTheme: const IconThemeData(
        color: AppConstants.primaryColor,
        size: 28,
      ),
      unselectedIconTheme: IconThemeData(
        color: AppConstants.primaryColor.withOpacity(0.6),
        size: 24,
      ),
      selectedLabelTextStyle: GoogleFonts.roboto(
        color: AppConstants.primaryColor,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: GoogleFonts.roboto(
        color: AppConstants.primaryColor.withOpacity(0.7),
        fontWeight: FontWeight.w400,
        fontSize: 12,
      ),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: AppConstants.lightColor,
      surfaceTintColor: AppConstants.primaryColor.withOpacity(0.05),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppConstants.primaryColor,
      brightness: Brightness.dark,
      primary: AppConstants.primaryColor,
      secondary: AppConstants.secondaryColor,
      surface: const Color(0xFF2E1B15), // Dark orange-brown surface
      background: const Color(0xFF1A0E0A), // Very dark orange-brown background
      tertiary: AppConstants.accentColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppConstants.lightColor,
    ),
    textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
    scaffoldBackgroundColor: const Color(0xFF1A0E0A), // Very dark orange-brown
    appBarTheme: AppBarTheme(
      backgroundColor: AppConstants.primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    ),
    cardTheme: const CardThemeData(
      elevation: 3,
      color: Color(0xFF2E1B15), // Dark orange-brown card
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: AppConstants.primaryColor.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.paddingLarge,
          vertical: AppConstants.paddingMedium,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        borderSide: BorderSide(color: AppConstants.primaryColor.withOpacity(0.5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[800],
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: AppConstants.darkColor,
      selectedIconTheme: const IconThemeData(
        color: AppConstants.primaryColor,
        size: 28,
      ),
      unselectedIconTheme: IconThemeData(
        color: AppConstants.primaryColor.withOpacity(0.6),
        size: 24,
      ),
      selectedLabelTextStyle: GoogleFonts.roboto(
        color: AppConstants.primaryColor,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      unselectedLabelTextStyle: GoogleFonts.roboto(
        color: AppConstants.primaryColor.withOpacity(0.7),
        fontWeight: FontWeight.w400,
        fontSize: 12,
      ),
    ),
    drawerTheme: DrawerThemeData(
      backgroundColor: const Color(0xFF2E1B15), // Dark orange-brown drawer
      surfaceTintColor: AppConstants.primaryColor.withOpacity(0.15),
    ),
  );
} 
