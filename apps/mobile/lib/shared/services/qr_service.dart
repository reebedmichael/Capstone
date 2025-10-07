import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/qr_payload.dart';
import '../state/order_refresh_notifier.dart';

/// Service for handling QR code validation and status updates
class QrService {
  final SupabaseClient _supabase;

  QrService(this._supabase);

  /// Validate and process a scanned QR code
  /// Returns a map with success status and message
  Future<Map<String, dynamic>> processScannedQr(String qrString) async {
    try {
      print('🔍 Processing QR code: $qrString');
      
      // Parse the QR code
      final payload = QrPayload.fromQrString(qrString);
      print('🔍 Parsed payload: bestKosId=${payload.bestKosId}, bestId=${payload.bestId}');

      // Validate signature
      if (!payload.isValidSignature()) {
        print('❌ Invalid signature');
        return {
          'success': false,
          'message': 'Ongeldige QR kode - kan nie geverifieer word nie',
        };
      }
      print('✅ Signature valid');

      // Check expiration
      if (payload.isExpired()) {
        print('❌ QR code expired');
        return {
          'success': false,
          'message': 'QR kode het verval. Vra die gebruiker om dit te verfris.',
        };
      }
      print('✅ QR code not expired');

      // Verify the item exists in database and get the order date
      print('🔍 Looking for item in database: ${payload.bestKosId}');
      final itemData = await _supabase
          .from('bestelling_kos_item')
          .select('best_kos_id, best_id, kos_item_id, best_datum, kos_item:kos_item_id(kos_item_naam)')
          .eq('best_kos_id', payload.bestKosId)
          .maybeSingle();

      if (itemData == null) {
        print('❌ Item not found in database');
        return {
          'success': false,
          'message': 'Item nie gevind in databasis nie',
        };
      }
      print('✅ Item found in database: ${itemData['kos_item']?['kos_item_naam']}');

      // Check if the QR code is being scanned on the correct day
      final bestDatumStr = itemData['best_datum'] as String?;
      if (bestDatumStr != null) {
        try {
          final bestDatum = DateTime.parse(bestDatumStr);
          final today = DateTime.now();
          
          // Check if the order date matches today's date (ignoring time)
          final orderDate = DateTime(bestDatum.year, bestDatum.month, bestDatum.day);
          final todayDate = DateTime(today.year, today.month, today.day);
          
          if (!orderDate.isAtSameMomentAs(todayDate)) {
            print('❌ QR code scanned on wrong day. Order date: $orderDate, Today: $todayDate');
            return {
              'success': false,
              'message': 'Hierdie QR kode kan slegs op ${_formatDateForDisplay(orderDate)} geskandeer word. Vandag is ${_formatDateForDisplay(todayDate)}.',
            };
          }
          print('✅ QR code scanned on correct day');
        } catch (e) {
          print('❌ Error parsing order date: $e');
          return {
            'success': false,
            'message': 'Fout met verwerking van bestelling datum',
          };
        }
      } else {
        print('❌ No order date found for item');
        return {
          'success': false,
          'message': 'Geen bestelling datum gevind nie',
        };
      }

      // Check if item has already been collected
      final existingStatuses = await _supabase
          .from('best_kos_item_statusse')
          .select('kos_stat_id, kos_item_statusse:kos_stat_id(kos_stat_naam)')
          .eq('best_kos_id', payload.bestKosId)
          .order('best_kos_wysig_datum', ascending: false);

      // Check if already marked as "Ontvang" or "Afgehandel"
      if (existingStatuses.isNotEmpty) {
        final lastStatus = existingStatuses.first;
        final statusInfo = lastStatus['kos_item_statusse'] as Map<String, dynamic>?;
        final statusName = statusInfo?['kos_stat_naam'] as String?;
        
        if (statusName == 'Ontvang' || statusName == 'Afgehandel') {
          return {
            'success': false,
            'message': 'Item is reeds afgehaal',
            'alreadyCollected': true,
          };
        }
      }

      // Get the "Afgehandel" status ID
      print('🔍 Looking for "Afgehandel" status...');
      final completedStatusData = await _supabase
          .from('kos_item_statusse')
          .select('kos_stat_id')
          .eq('kos_stat_naam', 'Afgehandel')
          .maybeSingle();

      if (completedStatusData == null) {
        print('🔍 Creating "Afgehandel" status...');
        // If "Afgehandel" status doesn't exist, create it
        final newStatus = await _supabase
            .from('kos_item_statusse')
            .insert({'kos_stat_naam': 'Afgehandel'})
            .select('kos_stat_id')
            .single();
        
        await _insertStatusRecord(payload.bestKosId, newStatus['kos_stat_id'] as String);
        print('✅ Created new "Afgehandel" status and inserted record');
      } else {
        await _insertStatusRecord(payload.bestKosId, completedStatusData['kos_stat_id'] as String);
        print('✅ Updated item status to "Afgehandel"');
      }

      // Get item name for success message
      final kosItemMap = itemData['kos_item'] as Map<String, dynamic>?;
      final itemName = kosItemMap?['kos_item_naam'] as String? ?? 'Item';

      // Get the user ID from the order to refresh their data
      final bestId = itemData['best_id'] as String?;
      if (bestId != null) {
        try {
          final bestellingData = await _supabase
              .from('bestelling')
              .select('gebr_id')
              .eq('best_id', bestId)
              .maybeSingle();
          
          if (bestellingData != null) {
            final userId = bestellingData['gebr_id'] as String?;
            if (userId != null) {
              await refreshUserData(userId);
            }
          }
        } catch (e) {
          print('🔄 Error refreshing user data after scan: $e');
        }
      }

      print('✅ QR processing completed successfully for: $itemName');
      return {
        'success': true,
        'message': 'Bestelling afgehandel: $itemName',
        'itemName': itemName,
        'bestKosId': payload.bestKosId,
      };
    } catch (e) {
      print('❌ Error processing QR code: $e');
      return {
        'success': false,
        'message': 'Fout met verwerking van QR kode: $e',
      };
    }
  }

  /// Insert a new status record
  Future<void> _insertStatusRecord(String bestKosId, String kosStatId) async {
    await _supabase.from('best_kos_item_statusse').insert({
      'best_kos_id': bestKosId,
      'kos_stat_id': kosStatId,
      'best_kos_wysig_datum': DateTime.now().toIso8601String(),
    });
  }

  /// Generate a QR payload for a food item
  QrPayload generateQrPayload({
    required String bestKosId,
    required String bestId,
    required String kosItemId,
  }) {
    return QrPayload.create(
      bestKosId: bestKosId,
      bestId: bestId,
      kosItemId: kosItemId,
    );
  }

  /// Format date for display in Afrikaans
  String _formatDateForDisplay(DateTime date) {
    final months = [
      'Januarie', 'Februarie', 'Maart', 'April', 'Mei', 'Junie',
      'Julie', 'Augustus', 'September', 'Oktober', 'November', 'Desember'
    ];
    
    final weekdays = [
      'Sondag', 'Maandag', 'Dinsdag', 'Woensdag', 'Donderdag', 'Vrydag', 'Saterdag'
    ];
    
    final weekday = weekdays[date.weekday % 7];
    final month = months[date.month - 1];
    
    return '$weekday ${date.day} $month ${date.year}';
  }

  /// Check if a user is a tertiary admin
  Future<bool> isTertiaryAdmin(String userId) async {
    try {
      print('🔍 Checking admin status for user: $userId');
      
      final userData = await _supabase
          .from('gebruikers')
          .select('admin_tipe_id, admin_tipes:admin_tipe_id(admin_tipe_naam)')
          .eq('gebr_id', userId)
          .maybeSingle();

      print('🔍 User data: $userData');

      if (userData == null) {
        print('🔍 No user data found');
        return false;
      }

      final adminTypeMap = userData['admin_tipes'] as Map<String, dynamic>?;
      final adminTypeName = adminTypeMap?['admin_tipe_naam'] as String?;

      print('🔍 Admin type name: $adminTypeName');

      // Check if user is a "Tertiary" admin
      final isAdmin = adminTypeName?.toLowerCase() == 'tertiary' || 
             adminTypeName?.toLowerCase() == 'tersiêr' || 
             adminTypeName?.toLowerCase() == 'tersier';
      
      print('🔍 Is admin: $isAdmin');
      return isAdmin;
    } catch (e) {
      print('🔍 Error checking admin status: $e');
      return false;
    }
  }

  /// Refresh user data after successful QR scan
  Future<void> refreshUserData(String userId) async {
    try {
      // Send a notification to the user's device
      await _sendOrderUpdateNotification(userId);
      
      // Trigger global refresh
      OrderRefreshNotifier().triggerRefresh();
      
      print('🔄 User data refreshed for: $userId');
    } catch (e) {
      print('🔄 Error refreshing user data: $e');
    }
  }

  /// Send a notification to the user about order status change
  Future<void> _sendOrderUpdateNotification(String userId) async {
    try {
      // Create a notification record in the database
      await _supabase.from('kennisgewings').insert({
        'gebr_id': userId,
        'kennisgewing_titel': 'Bestelling Afgehandel',
        'kennisgewing_beskrywing': 'Jou bestelling is suksesvol afgehandel!',
        'kennisgewing_tipe': 'bestelling',
        'is_gelees': false,
        'kennisgewing_datum': DateTime.now().toIso8601String(),
      });
      
      print('📱 Notification sent to user: $userId');
    } catch (e) {
      print('📱 Error sending notification: $e');
    }
  }
}

