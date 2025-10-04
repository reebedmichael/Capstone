import 'package:supabase_flutter/supabase_flutter.dart';
import 'db.dart';

class AllowanceRepository {
  AllowanceRepository(this._db);
  final SupabaseDb _db;

  SupabaseClient get _sb => _db.raw;

  /// Get allowance for a specific user (from gebr_tipe.gebr_toelaag only)
  /// Removed: view vw_gebruiker_toelae and toelaag_override - not in client schema
  Future<Map<String, dynamic>?> getUserAllowance(String gebruikerId) async {
    final result = await _sb
        .from('gebruikers')
        .select('*, gebr_tipe:gebr_tipe_id(gebr_tipe_naam, gebr_toelaag)')
        .eq('gebr_id', gebruikerId)
        .maybeSingle();
    
    if (result != null) {
      // Calculate allowance from type only - no override support
      final typeAllowance = result['gebr_tipe']?['gebr_toelaag']?.toDouble() ?? 0.0;
      result['aktiewe_toelaag'] = typeAllowance;
      result['tipe_toelaag'] = typeAllowance;
      result['toelaag_bron'] = typeAllowance > 0 ? 'From user type' : 'No allowance';
    }
    
    return result != null ? Map<String, dynamic>.from(result) : null;
  }

  /// Get all users with their allowances (admin view)
  /// Uses only existing tables - no view or override support
  Future<List<Map<String, dynamic>>> getAllUsersWithAllowances() async {
    final rows = await _sb
        .from('gebruikers')
        .select('*, gebr_tipe:gebr_tipe_id(gebr_tipe_naam, gebr_toelaag)')
        .order('gebr_naam');
    
    // Add calculated allowance fields
    for (final row in rows) {
      final typeAllowance = row['gebr_tipe']?['gebr_toelaag']?.toDouble() ?? 0.0;
      row['aktiewe_toelaag'] = typeAllowance;
      row['tipe_toelaag'] = typeAllowance;
      row['toelaag_bron'] = typeAllowance > 0 ? 'From user type' : 'No allowance';
    }
    
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Removed: setUserAllowanceOverride - toelaag_override column doesn't exist in client schema

  /// Update the default allowance for a user type (equivalent to PATCH /api/gebr_tipe/:id)
  Future<void> updateGebrTipeAllowance({
    required String gebrTipeId,
    required double? bedrag,
  }) async {
    await _sb
        .from('gebruiker_tipes')
        .update({'gebr_toelaag': bedrag})
        .eq('gebr_tipe_id', gebrTipeId);
  }

  /// Get count of users who have allowances (from type only)
  /// Uses existing tables only - no view support
  Future<int> getUsersWithAllowancesCount() async {
    final result = await _sb
        .from('gebruikers')
        .select('gebr_id, gebr_tipe:gebr_tipe_id(gebr_toelaag)')
        .not('gebr_tipe.gebr_toelaag', 'is', null)
        .gt('gebr_tipe.gebr_toelaag', 0);
    
    return result.length;
  }

  /// Get all user types with their default allowances
  Future<List<Map<String, dynamic>>> getGebrTipesWithAllowances() async {
    final rows = await _sb
        .from('gebruiker_tipes')
        .select('gebr_tipe_id, gebr_tipe_naam, gebr_tipe_beskrywing, gebr_toelaag')
        .order('gebr_tipe_naam');
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Check if user has any allowance (from type only)
  Future<bool> userHasAllowance(String gebruikerId) async {
    final allowance = await getUserAllowance(gebruikerId);
    final amount = allowance?['aktiewe_toelaag']?.toDouble() ?? 0.0;
    return amount > 0;
  }

  /// Removed: getUsersWithOverrides - toelaag_override column doesn't exist in client schema
  /// Removed: removeUserAllowanceOverride - toelaag_override column doesn't exist in client schema

  /// Get allowance summary for admin dashboard
  /// Simplified to only use existing schema
  Future<Map<String, dynamic>> getAllowanceSummary() async {
    final allUsers = await getAllUsersWithAllowances();
    
    final totalUsers = allUsers.length;
    final usersWithAllowances = allUsers.where((u) {
      final amount = u['aktiewe_toelaag']?.toDouble() ?? 0.0;
      return amount > 0;
    }).length;
    
    return {
      'total_users': totalUsers,
      'users_with_allowances': usersWithAllowances,
      'users_with_overrides': 0, // No override support
      'users_with_type_allowances': usersWithAllowances,
    };
  }
}

