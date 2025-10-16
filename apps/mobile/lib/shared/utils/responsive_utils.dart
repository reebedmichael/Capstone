import 'package:flutter/material.dart';

/// Utility class for responsive design across different device sizes
class ResponsiveUtils {
  // Breakpoints for different device types
  static const double mobileBreakpoint = 480;
  static const double tabletBreakpoint = 768;
  static const double desktopBreakpoint = 1024;
  
  // Screen size categories
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }
  
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }
  
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }
  
  // Responsive padding based on screen size
  static EdgeInsets getScreenPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width < 360) {
      // Very small screens (old phones)
      return const EdgeInsets.symmetric(horizontal: 12, vertical: 8);
    } else if (width < 480) {
      // Small mobile screens
      return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    } else if (width < 768) {
      // Large mobile screens
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    } else {
      // Tablet and larger
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    }
  }
  
  // Responsive font sizes
  static double getResponsiveFontSize(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
  
  // Responsive spacing
  static double getResponsiveSpacing(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
  
  // Responsive grid columns
  static int getGridColumns(BuildContext context) {
    if (isDesktop(context)) {
      return 3;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 1;
    }
  }
  
  // Responsive card width
  static double getCardWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = getScreenPadding(context).horizontal;
    final availableWidth = screenWidth - padding;
    
    if (isDesktop(context)) {
      return (availableWidth - 32) / 3; // 3 columns with gap
    } else if (isTablet(context)) {
      return (availableWidth - 16) / 2; // 2 columns with gap
    } else {
      return availableWidth; // 1 column
    }
  }
  
  // Safe area handling
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top,
      bottom: mediaQuery.padding.bottom,
      left: mediaQuery.padding.left,
      right: mediaQuery.padding.right,
    );
  }
  
  // Keyboard-aware padding
  static EdgeInsets getKeyboardAwarePadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    
    return EdgeInsets.only(
      bottom: keyboardHeight > 0 ? keyboardHeight + 16 : 0,
    );
  }
  
  // Responsive text style
  static TextStyle getResponsiveTextStyle(BuildContext context, {
    required TextStyle baseStyle,
    TextStyle? tabletStyle,
    TextStyle? desktopStyle,
  }) {
    if (isDesktop(context) && desktopStyle != null) {
      return baseStyle.merge(desktopStyle);
    } else if (isTablet(context) && tabletStyle != null) {
      return baseStyle.merge(tabletStyle);
    } else {
      return baseStyle;
    }
  }
  
  // Responsive container constraints
  static BoxConstraints getResponsiveConstraints(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (isDesktop(context)) {
      return BoxConstraints(
        maxWidth: 1200,
        minWidth: 600,
      );
    } else if (isTablet(context)) {
      return BoxConstraints(
        maxWidth: screenWidth * 0.9,
        minWidth: 400,
      );
    } else {
      return BoxConstraints(
        maxWidth: screenWidth,
        minWidth: 280,
      );
    }
  }
  
  // Responsive image size
  static double getResponsiveImageSize(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet(context)) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }
  
  // Check if device has notches or rounded corners
  static bool hasNotch(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.padding.top > 24 || mediaQuery.padding.bottom > 0;
  }
  
  // Get optimal button size
  static Size getOptimalButtonSize(BuildContext context) {
    if (isSmallScreen(context)) {
      return const Size(120, 40);
    } else if (isLargeScreen(context)) {
      return const Size(160, 48);
    } else {
      return const Size(140, 44);
    }
  }
  
  // Responsive list item height
  static double getListItemHeight(BuildContext context) {
    if (isSmallScreen(context)) {
      return 60;
    } else if (isLargeScreen(context)) {
      return 80;
    } else {
      return 70;
    }
  }
  
  // Responsive header height
  static double getHeaderHeight(BuildContext context) {
    if (isSmallScreen(context)) {
      return 56;
    } else if (isLargeScreen(context)) {
      return 72;
    } else {
      return 64;
    }
  }
}
