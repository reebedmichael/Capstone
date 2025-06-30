import 'package:flutter/material.dart';

/// Notifications preferences management screen
/// TODO: Implement real notifications management with:
/// - Push notification settings
/// - Email notification preferences
/// - SMS notification settings
/// - Order status notifications
/// - Promotional notifications
/// - Notification history
/// - Quiet hours configuration
/// - Campus-wide announcements
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.notifications, size: 64, color: Colors.grey),
            SizedBox(height: 24),
            Text('Notifications - Coming Soon', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
} 