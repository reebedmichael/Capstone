import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;
  String? _fcmToken;

  /// Initialiseer notifikasie service
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialiseer slegs lokale notifikasies
      await _initializeLocalNotifications();

      _initialized = true;
      print('✅ Notifikasie service geïnitialiseer (slegs lokale notifikasies)');
    } catch (e) {
      print('❌ Fout met initialiseer notifikasie service: $e');
      // Maak nie 'n fout nie, laat die app loop
      _initialized = true;
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

  /// Handle foreground messages (vir toekomstige Firebase integrasie)
  Future<void> _handleForegroundMessage(Map<String, dynamic> message) async {
    print('📱 Foreground message ontvang: ${message['title']}');
    
    // Toon lokale notifikasie
    await _showLocalNotification(message);
  }

  /// Handle background messages (vir toekomstige Firebase integrasie)
  Future<void> _handleBackgroundMessage(Map<String, dynamic> message) async {
    print('📱 Background message ontvang: ${message['title']}');
    
    // Navigeer na notifikasie bladsy
    // Dit sal later geïmplementeer word met GoRouter
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('📱 Notifikasie geklik: ${response.payload}');
    
    // Navigeer na notifikasie bladsy
    // Dit sal later geïmplementeer word met GoRouter
  }

  /// Toon lokale notifikasie
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
