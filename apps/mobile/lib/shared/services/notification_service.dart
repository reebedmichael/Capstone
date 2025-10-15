import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io' show Platform;

// Top-level background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('📱 Background message ontvang: ${message.notification?.title}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  FirebaseMessaging? _messaging;
  
  bool _initialized = false;
  String? _fcmToken;
  RealtimeChannel? _notificationChannel;

  /// Initialiseer notifikasie service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialiseer lokale notifikasies
      await _initializeLocalNotifications();

      // Initialiseer Firebase Cloud Messaging
      await _initializeFirebaseMessaging();

      // Initialiseer Supabase Realtime subscriptions
      await _initializeRealtimeSubscriptions();

      _initialized = true;
      print('✅ Notifikasie service geïnitialiseer (lokale + FCM + Realtime)');
    } catch (e) {
      print('❌ Fout met initialiseer notifikasie service: $e');
      // Maak nie 'n fout nie, laat die app loop
      _initialized = true;
    }
  }

  /// Initialiseer Supabase Realtime subscriptions
  Future<void> _initializeRealtimeSubscriptions() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('⚠️ Geen gebruiker aangemeld nie, spring realtime oor');
        return;
      }

      // Subscribe to user-specific notifications
      _notificationChannel = Supabase.instance.client
          .channel('notifications:${user.id}')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'kennisgewings',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'gebr_id',
              value: user.id,
            ),
            callback: (payload) {
              print('📬 Nuwe notifikasie ontvang via Realtime!');
              _handleRealtimeNotification(payload.newRecord);
            },
          )
          .subscribe();

      print('✅ Supabase Realtime subscriptions geaktiveer');
    } catch (e) {
      print('❌ Fout met initialiseer realtime: $e');
    }
  }

  /// Handle new notifications from Supabase Realtime
  Future<void> _handleRealtimeNotification(Map<String, dynamic> record) async {
    try {
      // Extract notification details
      final titel = record['kennis_titel'] as String?;
      final beskrywing = record['kennis_beskrywing'] as String?;
      
      if (beskrywing == null) return;

      // Show local notification
      await _showLocalNotification({
        'title': titel ?? 'Nuwe Kennisgewing',
        'body': beskrywing,
      });

      // Update notification badge count
      await _updateNotificationBadge();
    } catch (e) {
      print('❌ Fout met hanteer realtime notifikasie: $e');
    }
  }

  /// Update notification badge count
  Future<void> _updateNotificationBadge() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final kennisgewingRepo = KennisgewingRepository(SupabaseDb(Supabase.instance.client));
      final ongelees = await kennisgewingRepo.kryOngeleesKennisgewings(user.id);
      
      // Update badge in app
      // This would typically update a global state that the UI listens to
      print('📊 Ongelees notifikasies: ${ongelees.length}');
    } catch (e) {
      print('❌ Fout met opdateer badge: $e');
    }
  }

  /// Stop Realtime subscriptions (call when user logs out)
  Future<void> stopRealtimeSubscriptions() async {
    try {
      if (_notificationChannel != null) {
        await Supabase.instance.client.removeChannel(_notificationChannel!);
        _notificationChannel = null;
        print('✅ Realtime subscriptions gestop');
      }
    } catch (e) {
      print('❌ Fout met stop realtime: $e');
    }
  }

  /// Initialiseer Firebase Cloud Messaging
  Future<void> _initializeFirebaseMessaging() async {
    try {
      // Check if Firebase is already initialized
      try {
        _messaging = FirebaseMessaging.instance;
      } catch (e) {
        print('⚠️ Firebase nie geïnitialiseer nie, spring FCM oor: $e');
        return;
      }

      // Request permissions
      NotificationSettings settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('✅ Gebruiker het notifikasie toestemmings gegee');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('✅ Gebruiker het voorlopige notifikasie toestemmings gegee');
      } else {
        print('❌ Gebruiker het notifikasie toestemmings geweier');
        return;
      }

      // Get FCM token
      _fcmToken = await _messaging!.getToken();
      print('📱 FCM Token: $_fcmToken');

      // Save FCM token to database
      if (_fcmToken != null) {
        await _saveFcmTokenToDatabase(_fcmToken!);
      }

      // Listen for token refresh
      _messaging!.onTokenRefresh.listen((newToken) {
        _fcmToken = newToken;
        print('🔄 FCM Token vervang: $newToken');
        _saveFcmTokenToDatabase(newToken);
      });

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📱 Foreground message ontvang: ${message.notification?.title}');
        _handleForegroundMessage(message);
      });

      // Handle notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('📱 Notifikasie geklik (app in agtergrond)');
        _handleNotificationTap(message);
      });

      // Check if app was opened from a notification
      RemoteMessage? initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        print('📱 App geopen vanaf notifikasie');
        _handleNotificationTap(initialMessage);
      }

      print('✅ Firebase Cloud Messaging geïnitialiseer');
    } catch (e) {
      print('❌ Fout met initialiseer FCM: $e');
    }
  }

  /// Stoor FCM token in databasis
  Future<void> _saveFcmTokenToDatabase(String token) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        print('⚠️ Geen gebruiker aangemeld nie, kan nie FCM token stoor nie');
        return;
      }

      await Supabase.instance.client
          .from('gebruikers')
          .update({'fcm_token': token})
          .eq('gebr_id', user.id);

      print('✅ FCM token gestoor in databasis');
    } catch (e) {
      print('❌ Fout met stoor FCM token: $e');
    }
  }

  /// Initialiseer lokale notifikasies
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const DarwinInitializationSettings macosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macosSettings,
    );

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Vra vir toestemmings
    await _requestPermissions();
  }

  /// Vra vir notifikasie toestemmings
  Future<void> _requestPermissions() async {
    // Android toestemmings
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // iOS toestemmings
    await _localNotifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Handle foreground messages from Firebase
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('📱 Foreground message ontvang: ${message.notification?.title}');
    
    // Toon lokale notifikasie
    final notification = message.notification;
    if (notification != null) {
      await _showLocalNotificationFromFirebase(notification);
    }
  }

  /// Handle notification tap from Firebase
  Future<void> _handleNotificationTap(RemoteMessage message) async {
    print('📱 Notifikasie geklik: ${message.notification?.title}');
    
    // Store notification ID for navigation
    final data = message.data;
    if (data.containsKey('notification_id')) {
      // Navigate to notification details or mark as read
      // This can be implemented later with proper navigation handling
      print('📱 Navigeer na notifikasie: ${data['notification_id']}');
    }
  }

  /// Handle local notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('📱 Lokale notifikasie geklik: ${response.payload}');
    
    // Navigate to notifications page
    // This can be implemented later with proper navigation handling
  }

  /// Toon lokale notifikasie vanaf Firebase
  Future<void> _showLocalNotificationFromFirebase(RemoteNotification notification) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'spys_notifications',
      'Spys Notifikasies',
      channelDescription: 'Notifikasies vir Spys app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const DarwinNotificationDetails macosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: macosDetails,
    );

    await _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'Spys Notifikasie',
      notification.body ?? 'Nuwe kennisgewing',
      details,
      payload: notification.body,
    );
  }

  /// Toon lokale notifikasie (vir programatiese gebruik)
  Future<void> _showLocalNotification(Map<String, dynamic> message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'spys_notifications',
      'Spys Notifikasies',
      channelDescription: 'Notifikasies vir Spys app',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const DarwinNotificationDetails macosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
      macOS: macosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      message['title'] ?? 'Spys Notifikasie',
      message['body'] ?? 'Nuwe kennisgewing',
      details,
      payload: message.toString(),
    );
  }

  /// Stuur notifikasie aan spesifieke gebruiker
  Future<bool> stuurNotifikasie({
    required String gebrId,
    required String titel,
    required String boodskap,
    String? tipe,
  }) async {
    try {
      final kennisgewingRepo = KennisgewingRepository(SupabaseDb(Supabase.instance.client));
      
      final sukses = await kennisgewingRepo.skepKennisgewing(
        gebrId: gebrId,
        beskrywing: boodskap,
        tipeNaam: tipe ?? 'info',
      );

      if (sukses) {
        print('✅ Notifikasie gestuur aan gebruiker $gebrId');
        return true;
      } else {
        print('❌ Fout met stuur notifikasie');
        return false;
      }
    } catch (e) {
      print('❌ Fout met stuur notifikasie: $e');
      return false;
    }
  }

  /// Stuur notifikasie aan alle gebruikers
  Future<bool> stuurAanAlleGebruikers({
    required String titel,
    required String boodskap,
    String? tipe,
  }) async {
    try {
      final kennisgewingRepo = KennisgewingRepository(SupabaseDb(Supabase.instance.client));
      
      final sukses = await kennisgewingRepo.stuurAanAlleGebruikers(
        beskrywing: boodskap,
        tipeNaam: tipe ?? 'info',
      );

      if (sukses) {
        print('✅ Notifikasie gestuur aan alle gebruikers');
        return true;
      } else {
        print('❌ Fout met stuur notifikasie aan alle gebruikers');
        return false;
      }
    } catch (e) {
      print('❌ Fout met stuur notifikasie aan alle gebruikers: $e');
      return false;
    }
  }

  /// Kry FCM token
  String? get fcmToken => _fcmToken;

  /// Kry notifikasie statistieke
  Future<Map<String, int>> kryStatistieke() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return {'totaal': 0, 'ongelees': 0, 'gelees': 0};

    try {
      final kennisgewingRepo = KennisgewingRepository(SupabaseDb(Supabase.instance.client));
      return await kennisgewingRepo.kryKennisgewingStatistieke(user.id);
    } catch (e) {
      print('❌ Fout met kry statistieke: $e');
      return {'totaal': 0, 'ongelees': 0, 'gelees': 0};
    }
  }
}
