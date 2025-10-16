import 'package:shared_preferences/shared_preferences.dart';

class NotificationArchiveService {
  static const String _archivedKey = 'archived_notifications';
  static const String _deletedKey = 'deleted_notifications';

  /// Get list of archived notification IDs
  static Future<List<String>> getArchivedNotificationIds() async {
    final prefs = await SharedPreferences.getInstance();
    final archivedIds = prefs.getStringList(_archivedKey) ?? [];
    return archivedIds;
  }

  /// Get list of permanently deleted notification IDs
  static Future<List<String>> getDeletedNotificationIds() async {
    final prefs = await SharedPreferences.getInstance();
    final deletedIds = prefs.getStringList(_deletedKey) ?? [];
    return deletedIds;
  }

  /// Archive a notification (mark as archived locally)
  static Future<bool> archiveNotification(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final archivedIds = await getArchivedNotificationIds();
      
      if (!archivedIds.contains(notificationId)) {
        archivedIds.add(notificationId);
        await prefs.setStringList(_archivedKey, archivedIds);
      }
      return true;
    } catch (e) {
      print('Error archiving notification: $e');
      return false;
    }
  }

  /// Archive multiple notifications
  static Future<bool> archiveNotifications(List<String> notificationIds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final archivedIds = await getArchivedNotificationIds();
      
      for (final id in notificationIds) {
        if (!archivedIds.contains(id)) {
          archivedIds.add(id);
        }
      }
      
      await prefs.setStringList(_archivedKey, archivedIds);
      return true;
    } catch (e) {
      print('Error archiving notifications: $e');
      return false;
    }
  }

  /// Restore an archived notification
  static Future<bool> restoreNotification(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final archivedIds = await getArchivedNotificationIds();
      
      archivedIds.remove(notificationId);
      await prefs.setStringList(_archivedKey, archivedIds);
      return true;
    } catch (e) {
      print('Error restoring notification: $e');
      return false;
    }
  }

  /// Permanently delete an archived notification
  static Future<bool> permanentlyDeleteNotification(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deletedIds = await getDeletedNotificationIds();
      
      if (!deletedIds.contains(notificationId)) {
        deletedIds.add(notificationId);
        await prefs.setStringList(_deletedKey, deletedIds);
      }
      
      // Also remove from archived list
      await restoreNotification(notificationId);
      return true;
    } catch (e) {
      print('Error permanently deleting notification: $e');
      return false;
    }
  }

  /// Check if a notification is archived
  static Future<bool> isNotificationArchived(String notificationId) async {
    final archivedIds = await getArchivedNotificationIds();
    return archivedIds.contains(notificationId);
  }

  /// Check if a notification is permanently deleted
  static Future<bool> isNotificationDeleted(String notificationId) async {
    final deletedIds = await getDeletedNotificationIds();
    return deletedIds.contains(notificationId);
  }

  /// Clear all archived notifications (for testing)
  static Future<void> clearAllArchived() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_archivedKey);
    await prefs.remove(_deletedKey);
  }

  /// Get archive statistics
  static Future<Map<String, int>> getArchiveStatistics() async {
    final archivedIds = await getArchivedNotificationIds();
    final deletedIds = await getDeletedNotificationIds();
    
    return {
      'archived': archivedIds.length,
      'deleted': deletedIds.length,
    };
  }
}
