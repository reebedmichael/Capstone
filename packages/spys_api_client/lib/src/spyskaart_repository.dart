import 'package:supabase_flutter/supabase_flutter.dart';
import 'db.dart';

class SpyskaartRepository {
  SpyskaartRepository(this._db);
  final SupabaseDb _db;

  SupabaseClient get _sb => _db.raw;

  /// Haal die eerste aktiewe spyskaart met al sy kositems (inkl. kos_item_bestandele)
  Future<Map<String, dynamic>?> getAktieweSpyskaart() async {
    final rows = await _sb
        .from('spyskaart')
        .select('''
          *,
          spyskaart_kos_item:spyskaart_kos_item(
            *,
            kos_item:kos_item_id(
              kos_item_id,
              kos_item_naam,
              kos_item_koste,
              kos_item_prentjie,
              kos_item_kategorie,
              kos_item_beskrywing,
              kos_item_bestandele,
              is_aktief,
              kos_item_geskep_datum
            ),
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
