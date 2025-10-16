import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

class Spacing {
  // Common gaps
  static const double gap4 = 4.0;
  static const double gap8 = 8.0;
  static const double gap12 = 12.0;
  static const double gap16 = 16.0;
  static const double gap20 = 20.0;
  static const double gap24 = 24.0;
  static const double gap32 = 32.0;
  static const double gap40 = 40.0;
  static const double gap48 = 48.0;
  
  // Responsive screen padding
  static EdgeInsets screenPadding(BuildContext context) {
    return ResponsiveUtils.getScreenPadding(context);
  }
  
  // Legacy static values for backward compatibility
  static const double screenHPad = 24.0;
  static const double screenVPad = 16.0;
  
  // Widget spacing
  static const double cardPadding = 16.0;
  static const double buttonPadding = 12.0;
  static const double inputPadding = 16.0;
  
  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  
  // Convenience widgets
  static const SizedBox gap4Widget = SizedBox(height: gap4, width: gap4);
  static const SizedBox gap8Widget = SizedBox(height: gap8, width: gap8);
  static const SizedBox gap12Widget = SizedBox(height: gap12, width: gap12);
  static const SizedBox gap16Widget = SizedBox(height: gap16, width: gap16);
  static const SizedBox gap20Widget = SizedBox(height: gap20, width: gap20);
  static const SizedBox gap24Widget = SizedBox(height: gap24, width: gap24);
  static const SizedBox gap32Widget = SizedBox(height: gap32, width: gap32);
  static const SizedBox gap40Widget = SizedBox(height: gap40, width: gap40);
  static const SizedBox gap48Widget = SizedBox(height: gap48, width: gap48);
  
  // Vertical gaps
  static const SizedBox vGap4 = SizedBox(height: gap4);
  static const SizedBox vGap8 = SizedBox(height: gap8);
  static const SizedBox vGap12 = SizedBox(height: gap12);
  static const SizedBox vGap16 = SizedBox(height: gap16);
  static const SizedBox vGap20 = SizedBox(height: gap20);
  static const SizedBox vGap24 = SizedBox(height: gap24);
  static const SizedBox vGap32 = SizedBox(height: gap32);
  static const SizedBox vGap40 = SizedBox(height: gap40);
  static const SizedBox vGap48 = SizedBox(height: gap48);
  
  // Horizontal gaps
  static const SizedBox hGap4 = SizedBox(width: gap4);
  static const SizedBox hGap8 = SizedBox(width: gap8);
  static const SizedBox hGap12 = SizedBox(width: gap12);
  static const SizedBox hGap16 = SizedBox(width: gap16);
  static const SizedBox hGap20 = SizedBox(width: gap20);
  static const SizedBox hGap24 = SizedBox(width: gap24);
  static const SizedBox hGap32 = SizedBox(width: gap32);
  static const SizedBox hGap40 = SizedBox(width: gap40);
  static const SizedBox hGap48 = SizedBox(width: gap48);
  
  // Responsive spacing methods
  static double responsiveGap(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return ResponsiveUtils.getResponsiveSpacing(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
  
  static double responsiveFontSize(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return ResponsiveUtils.getResponsiveFontSize(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
  
  // Responsive widgets
  static Widget responsiveVGap(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return SizedBox(
      height: responsiveGap(context, mobile: mobile, tablet: tablet, desktop: desktop),
    );
  }
  
  static Widget responsiveHGap(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return SizedBox(
      width: responsiveGap(context, mobile: mobile, tablet: tablet, desktop: desktop),
    );
  }
  
  // Responsive padding
  static EdgeInsets responsivePadding(BuildContext context, {
    required EdgeInsets mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    if (ResponsiveUtils.isDesktop(context) && desktop != null) {
      return desktop;
    } else if (ResponsiveUtils.isTablet(context) && tablet != null) {
      return tablet;
    } else {
      return mobile;
    }
  }
}
