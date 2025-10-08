import 'package:flutter/foundation.dart';

// Global cart count notifier for real-time badge updates across the app
class CartBadgeState {
  CartBadgeState._();
  static final ValueNotifier<int> count = ValueNotifier<int>(0);
}


