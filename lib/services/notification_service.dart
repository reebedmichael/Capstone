import 'dart:async';
import '../models/notification.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<AppNotification> _notifications = [];
  final StreamController<List<AppNotification>> _notificationController = 
      StreamController<List<AppNotification>>.broadcast();

  Stream<List<AppNotification>> get notificationStream => _notificationController.stream;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  // Initialize with mock notifications
  void initialize() {
    _notifications.addAll([
      AppNotification(
        id: '1',
        title: 'Welkom by Spys!',
        description: 'Jou rekening is suksesvol geskep. Geniet jou eerste bestelling!',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        type: 'system',
        isRead: false,
      ),
      AppNotification(
        id: '2',
        title: 'Spesiale Aanbieding',
        description: 'Kry 20% afslag op alle burgers vandag! Gebruik kode: BURGER20',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        type: 'promotion',
        isRead: false,
      ),
      AppNotification(
        id: '3',
        title: 'Bestelling Gereed',
        description: 'Jou bestelling #1001 is gereed vir afhaal by die hoofkombuis.',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        type: 'order',
        isRead: true,
      ),
      AppNotification(
        id: '4',
        title: 'Nuwe Menu Items',
        description: 'Kyk uit vir ons nuwe vegetariese opsies wat hierdie week beskikbaar is!',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        type: 'system',
        isRead: true,
      ),
    ]);
    _notificationController.add(_notifications);
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      _notificationController.add(_notifications);
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    _notificationController.add(_notifications);
  }

  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    _notificationController.add(_notifications);
  }

  // TODO: Backend integration - Add methods for fetching from server
  Future<void> fetchNotifications() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    // TODO: Replace with actual API call
  }

  void dispose() {
    _notificationController.close();
  }
} 