import 'package:flutter/material.dart';

class Shadows {
  static const List<BoxShadow> e1 = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.12),
      offset: Offset(0, 1),
      blurRadius: 2,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> e2 = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.14),
      offset: Offset(0, 2),
      blurRadius: 4,
      spreadRadius: 0,
    ),
  ];

  static const List<BoxShadow> e3 = [
    BoxShadow(
      color: Color.fromRGBO(0, 0, 0, 0.16),
      offset: Offset(0, 4),
      blurRadius: 8,
      spreadRadius: 0,
    ),
  ];
} 