import 'package:supabase_flutter/supabase_flutter.dart';
import 'db.dart';

class GebruikersRepository {
  GebruikersRepository(this._db);
  final SupabaseDb _db;

  SupabaseClient get _sb => _db.raw;

  Future<Map<String, dynamic>?> kryGebruiker(String gebrId) async {
    final data = await _sb.from('vw_gebruikers_volledig')
        .select()
        .eq('gebr_id', gebrId)
        .maybeSingle();
    return data;
  }

  Future<List<Map<String, dynamic>>> soekGebruikers(String q) async {
    final rows = await _sb.from('gebruikers').select().ilike('gebr_epos', '%$q%');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> skepOfOpdateerGebruiker(Map<String, dynamic> data) async {
    await _sb.from('gebruikers').upsert(data, onConflict: 'gebr_id');
  }

  /// Approve a user (equivalent to PATCH /api/users/:id/approve)
  /// Only updates existing gebruiker columns - no audit logging or approval tracking
  /// as those columns/tables don't exist in the client schema
  Future<void> approveUser({
    required String userId,
    required String currentAdminId,
    String? gebrTipeId,
    String? adminTipeId,
  }) async {
    // Prevent self-approval
    if (userId == currentAdminId) {
      throw Exception('Cannot approve yourself (403 Forbidden)');
    }

    // Default to Tierseriy admin type if none provided
    final chosenAdminId = adminTipeId ?? '6afec372-3294-49fd-a79f-fc244406ee57';

    try {
      // Get current user data
      final currentUser = await _sb
          .from('gebruikers')
          .select('gebr_tipe_id, admin_tipe_id, is_aktief')
          .eq('gebr_id', userId)
          .single();

      // Ensure user has a valid gebr_tipe_id - default to Ekstern if null
      final finalGebrTipeId = gebrTipeId ?? 
                              currentUser['gebr_tipe_id'] ?? 
                              '4b2cadfb-90ee-4f89-931d-2b1e7abbc284'; // Ekstern as fallback

      // Update user - only use existing columns
      await _sb.from('gebruikers').update({
        'admin_tipe_id': chosenAdminId,
        'gebr_tipe_id': finalGebrTipeId,
        'is_aktief': true,
        // Removed: approved_by, approved_at - columns don't exist in client schema
      }).eq('gebr_id', userId);

      // Removed: admin_audit insert - table doesn't exist in client schema
    } catch (e) {
      throw Exception('Failed to approve user: $e');
    }
  }

  /// Get user with effective allowance (equivalent to GET /api/users/:id)
  /// Uses only existing tables - joins gebruiker with gebruiker_tipes to get allowance
  Future<Map<String, dynamic>?> getUserWithAllowance(String userId) async {
    final result = await _sb
        .from('gebruikers')
        .select('*, gebr_tipe:gebr_tipe_id(gebr_tipe_naam, gebr_toelaag)')
        .eq('gebr_id', userId)
        .maybeSingle();
    
    if (result != null) {
      // Calculate effective allowance from gebr_tipe.gebr_toelaag only
      // Removed: toelaag_override - column doesn't exist in client schema
      final typeAllowance = result['gebr_tipe']?['gebr_toelaag']?.toDouble() ?? 0.0;
      result['effective_toelaag'] = typeAllowance;
    }
    
    return result;
  }
} 