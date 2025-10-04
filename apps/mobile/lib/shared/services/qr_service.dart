import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/qr_payload.dart';

/// Service for handling QR code validation and status updates
class QrService {
  final SupabaseClient _supabase;

  QrService(this._supabase);

  /// Validate and process a scanned QR code
  /// Returns a map with success status and message
  Future<Map<String, dynamic>> processScannedQr(String qrString) async {
    try {
      // Parse the QR code
      final payload = QrPayload.fromQrString(qrString);

      // Validate signature
      if (!payload.isValidSignature()) {
        return {
          'success': false,
          'message': 'Ongeldige QR kode - kan nie geverifieer word nie',
        };
      }

      // Check expiration
      if (payload.isExpired()) {
        return {
          'success': false,
          'message': 'QR kode het verval. Vra die gebruiker om dit te verfris.',
        };
      }

      // Verify the item exists in database
      final itemData = await _supabase
          .from('bestelling_kos_item')
          .select('best_kos_id, best_id, kos_item_id, kos_item:kos_item_id(kos_item_naam)')
          .eq('best_kos_id', payload.bestKosId)
          .maybeSingle();

      if (itemData == null) {
        return {
          'success': false,
          'message': 'Item nie gevind in databasis nie',
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

      // Get the "Ontvang" status ID
      final receivedStatusData = await _supabase
          .from('kos_item_statusse')
          .select('kos_stat_id')
          .eq('kos_stat_naam', 'Ontvang')
          .maybeSingle();

      if (receivedStatusData == null) {
        // If "Ontvang" status doesn't exist, create it
        final newStatus = await _supabase
            .from('kos_item_statusse')
            .insert({'kos_stat_naam': 'Ontvang'})
            .select('kos_stat_id')
            .single();
        
        await _insertStatusRecord(payload.bestKosId, newStatus['kos_stat_id'] as String);
      } else {
        await _insertStatusRecord(payload.bestKosId, receivedStatusData['kos_stat_id'] as String);
      }

      // Get item name for success message
      final kosItemMap = itemData['kos_item'] as Map<String, dynamic>?;
      final itemName = kosItemMap?['kos_item_naam'] as String? ?? 'Item';

      return {
        'success': true,
        'message': 'Item suksesvol afgehaal: $itemName',
        'itemName': itemName,
        'bestKosId': payload.bestKosId,
      };
    } catch (e) {
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
}

