import 'package:flutter/material.dart';

class AppTypography {
  static const String fontFamily = 'Inter';

  // New scale
  static const TextStyle displayLarge = TextStyle(
    fontSize: 21,
    height: 1.3,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 17.5,
    height: 1.35,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );

  static const TextStyle titleLarge = TextStyle(
    fontSize: 15.75,
    height: 1.4,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );

  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );

  // Compatibility aliases mapped to closest new styles
  static const TextStyle displayMedium = headlineMedium;
  static const TextStyle displaySmall = titleLarge;
  static const TextStyle headlineLarge = displayLarge;
  static const TextStyle headlineSmall = titleLarge;
  static const TextStyle titleMedium = bodyMedium;
  static const TextStyle titleSmall = TextStyle(
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    height: 1.45,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    height: 1.2,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );

  // Supplementary
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
  );

  static const TextStyle overline = TextStyle(
    fontSize: 10,
    height: 1.2,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.0,
    fontFamily: fontFamily,
  );

  static const TextStyle errorText = TextStyle(
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w400,
    fontFamily: fontFamily,
  );

  static const TextStyle linkText = TextStyle(
    fontSize: 14,
    height: 1.3,
    fontWeight: FontWeight.w500,
    decoration: TextDecoration.underline,
    fontFamily: fontFamily,
  );
}
