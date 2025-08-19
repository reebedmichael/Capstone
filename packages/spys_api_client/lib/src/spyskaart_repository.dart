import 'package:supabase_flutter/supabase_flutter.dart';
import 'db.dart';

class SpyskaartRepository {
  SpyskaartRepository(this._db);
  final SupabaseDb _db;

  SupabaseClient get _sb => _db.raw;

  Future<List<Map<String, dynamic>>> lysSpyskaartVirWeek(String spyskaartId) async {
    final rows = await _sb.from('spyskaart_kos_item')
        .select('''
          *,
          kos_item:kos_item_id(*),
          week_dag:week_dag_id(*)
        ''')
        .eq('spyskaart_id', spyskaartId);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> lysAktiefOpDatum(DateTime datum) async {
    final dateStr = datum.toIso8601String().split('T')[0];
    final rows = await _sb.from('spyskaart')
        .select('''
          *,
          spyskaart_kos_item:spyskaart_kos_item(
            *,
            kos_item:kos_item_id(*),
            week_dag:week_dag_id(*)
          )
        ''')
        .gte('spyskaart_datum', dateStr)
        .lte('spyskaart_datum', dateStr);
    return List<Map<String, dynamic>>.from(rows);
  }
} 