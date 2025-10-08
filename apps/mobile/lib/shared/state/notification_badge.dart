import 'package:flutter/foundation.dart';

// Global notification count notifier for real-time badge updates across the app
class NotificationBadgeState {
  NotificationBadgeState._();
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);
}
