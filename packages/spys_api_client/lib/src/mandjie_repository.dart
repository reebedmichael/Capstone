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
  String? weekDagNaam,
}) async {
  // note: if your schema has 'qty' column on mandjie, include it
  final data = {
    'gebr_id': gebrId,
    'kos_item_id': kosItemId,
    'qty': aantal,
    if (weekDagNaam != null) 'week_dag_naam': weekDagNaam,
  };

  final result = await _sb.from('mandjie').insert(data).select().single();
  return Map<String, dynamic>.from(result);
}



  Future<void> verwyderUitMandjie({
    required String gebrId,
    required String kosItemId,
    String? weekDagNaam,
    int aantal = 1,
  }) async {
    await _sb.from('mandjie')
        .delete()
        .eq('gebr_id', gebrId)
        .eq('kos_item_id', kosItemId)
        .eq('week_dag_naam', weekDagNaam ?? '');
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