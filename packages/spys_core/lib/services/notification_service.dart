import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  StreamSubscription<RemoteMessage>? _messageSubscription;
  String? _fcmToken;

  /// Initialize Firebase Cloud Messaging
  Future<void> initialize() async {
    try {
      // Request permission for notifications
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission for notifications');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('User granted provisional permission for notifications');
      } else {
        print('User declined or has not accepted permission for notifications');
        return;
      }

      // Get FCM token
      _fcmToken = await _messaging.getToken();
      print('FCM Token: $_fcmToken');

      // Save token to database
      await _saveTokenToDatabase();

      // Set up message handlers
      _setupMessageHandlers();

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        _saveTokenToDatabase();
      });

    } catch (e) {
      print('Error initializing FCM: $e');
    }
  }

  /// Save FCM token to Supabase database
  Future<void> _saveTokenToDatabase() async {
    if (_fcmToken == null) return;

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client
          .from('gebruikers')
          .update({'fcm_token': _fcmToken})
          .eq('gebr_id', user.id);

      print('FCM token saved to database');
    } catch (e) {
      print('Error saving FCM token: $e');
    }
  }

  /// Set up message handlers for foreground and background
  void _setupMessageHandlers() {
    // Handle foreground messages
    _messageSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.messageId}');
      _handleMessage(message);
    });

    // Handle background messages (when app is in background but not terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message opened app: ${message.messageId}');
      _handleMessage(message);
    });

    // Handle messages when app is terminated
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App opened from terminated state: ${message.messageId}');
        _handleMessage(message);
      }
    });
  }

  /// Handle incoming messages
  void _handleMessage(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    print('Message data: $data');
    print('Message notification: ${notification?.title} - ${notification?.body}');

    // Handle different message types
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'order_update':
          _handleOrderUpdate(data);
          break;
        case 'allowance_update':
          _handleAllowanceUpdate(data);
          break;
        case 'menu_update':
          _handleMenuUpdate(data);
          break;
        default:
          _handleGeneralNotification(data, notification);
      }
    } else {
      _handleGeneralNotification(data, notification);
    }
  }

  /// Handle order update notifications
  void _handleOrderUpdate(Map<String, dynamic> data) {
    final orderId = data['order_id'];
    final status = data['status'];
    final message = data['message'] ?? 'Your order status has been updated';

    print('Order $orderId status updated to: $status');
    // You can add navigation logic here to go to orders page
  }

  /// Handle allowance update notifications
  void _handleAllowanceUpdate(Map<String, dynamic> data) {
    final amount = data['amount'];
    final type = data['transaction_type'];
    final message = data['message'] ?? 'Your allowance has been updated';

    print('Allowance $type: R$amount');
    // You can add navigation logic here to go to wallet page
  }

  /// Handle menu update notifications
  void _handleMenuUpdate(Map<String, dynamic> data) {
    final week = data['week'];
    final message = data['message'] ?? 'New menu items are available';

    print('Menu updated for week: $week');
    // You can add navigation logic here to go to home page
  }

  /// Handle general notifications
  void _handleGeneralNotification(Map<String, dynamic> data, RemoteNotification? notification) {
    final title = notification?.title ?? 'Spys Notification';
    final body = notification?.body ?? 'You have a new notification';

    print('General notification: $title - $body');
  }

  /// Send a test notification (for testing purposes)
  Future<void> sendTestNotification() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // This would typically be done from a backend service
      // For now, we'll just log that we would send a notification
      print('Would send test notification to user: ${user.id}');
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }

  /// Get current FCM token
  String? get fcmToken => _fcmToken;

  /// Dispose resources
  void dispose() {
    _messageSubscription?.cancel();
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Initialize Firebase if not already done
  await Firebase.initializeApp();
  
  print('Handling background message: ${message.messageId}');
  
  // Handle the message here
  // Note: You can't show UI from background handler
  // You can save data to local storage or database
}
