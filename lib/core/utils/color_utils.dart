import 'package:flutter/material.dart';

/// Helper function to set opacity on colors using the new withValues syntax
/// This replaces the deprecated withOpacity method
Color setOpacity(Color color, double opacity) =>
    Color.fromARGB(
      (opacity * 255).round(),
      color.red,
      color.green,
      color.blue,
    ); 
