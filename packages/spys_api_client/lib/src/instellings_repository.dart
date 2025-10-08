import 'package:supabase_flutter/supabase_flutter.dart';
import 'db.dart';

class InstellingsRepository {
  InstellingsRepository(this._db);
  final SupabaseDb _db;

  SupabaseClient get _sb => _db.raw;

  /// Get a system setting value by key
  Future<String?> kryInstelling(String sleutel) async {
    final result = await _sb.rpc('get_instelling', params: {
      'p_sleutel': sleutel,
    });
    
    return result as String?;
  }

  /// Get all system settings
  Future<List<Map<String, dynamic>>> lysAlleInstellings() async {
    final rows = await _sb
        .from('stelsel_instellings')
        .select('*')
        .order('instelling_sleutel');
    
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Update a system setting (admin only)
  Future<Map<String, dynamic>> updateInstelling({
    required String sleutel,
    required String waarde,
  }) async {
    final result = await _sb.rpc('update_instelling', params: {
      'p_sleutel': sleutel,
      'p_waarde': waarde,
    });
    
    return Map<String, dynamic>.from(result as Map);
  }

  /// Get the current allowance distribution day
  Future<int> kryToelaeVerspreidingDag() async {
    final waarde = await kryInstelling('toelae_verspreiding_dag');
    return int.tryParse(waarde ?? '1') ?? 1;
  }

  /// Update the allowance distribution day and cron schedule (admin only)
  Future<Map<String, dynamic>> updateToelaeVerspreidingDag(int dag) async {
    final result = await _sb.rpc('update_toelae_cron_schedule', params: {
      'p_dag': dag,
    });
    
    return Map<String, dynamic>.from(result as Map);
  }
}

