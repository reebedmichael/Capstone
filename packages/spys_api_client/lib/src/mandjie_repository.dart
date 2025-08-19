import 'package:supabase_flutter/supabase_flutter.dart';
import 'db.dart';

class MandjieRepository {
  MandjieRepository(this._db);
  final SupabaseDb _db;

  SupabaseClient get _sb => _db.raw;

  Future<Map<String, dynamic>> voegByMandjie({
    required String gebrId,
    required String kosItemId,
    int aantal = 1,
  }) async {
    // Note: schema doesn't support aantal directly, but keeping for future
    final data = {
      'gebr_id': gebrId,
      'kos_item_id': kosItemId,
    };
    final result = await _sb.from('mandjie').insert(data).select().single();
    return Map<String, dynamic>.from(result);
  }

  Future<void> verwyderUitMandjie({
    required String gebrId,
    required String kosItemId,
  }) async {
    await _sb.from('mandjie')
        .delete()
        .match({'gebr_id': gebrId, 'kos_item_id': kosItemId});
  }

  Future<List<Map<String, dynamic>>> kryMandjie(String gebrId) async {
    final rows = await _sb.from('mandjie')
        .select('''
          *,
          kos_item:kos_item_id(*)
        ''')
        .eq('gebr_id', gebrId);
    return List<Map<String, dynamic>>.from(rows);
  }
} 