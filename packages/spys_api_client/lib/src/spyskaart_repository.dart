import 'package:supabase_flutter/supabase_flutter.dart';
import 'db.dart';

class SpyskaartRepository {
  SpyskaartRepository(this._db);
  final SupabaseDb _db;

  SupabaseClient get _sb => _db.raw;

  /// Haal die eerste aktiewe spyskaart met al sy kositems
  Future<Map<String, dynamic>?> getAktieweSpyskaart() async {
    final rows = await _sb
        .from('spyskaart')
        .select('''
          *,
          spyskaart_kos_item:spyskaart_kos_item(
            *,
            kos_item:kos_item_id(*),
            week_dag:week_dag_id(*)
          )
        ''')
        .eq('spyskaart_is_active', true)
        .limit(1)
        .single();
    
    if (rows == null) return null;
    return Map<String, dynamic>.from(rows);
  }
}
