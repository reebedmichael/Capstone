// lib/src/week_templaat_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'db.dart';

/// Handles CRUD for week templates (SPYSKAART + SPYSKAART_KOS_ITEM)
/// and resolves WEEK_DAG ids by dag name ("maandag", ...).
class WeekTemplaatRepository {
  final SupabaseDb _db;
  WeekTemplaatRepository(this._db);

  SupabaseClient get _sb => _db.client;

  Map<String, String>? _weekDagCache; // dag_naam -> week_dag_id

  /// Ensure we have a { dag_naam -> week_dag_id } cache
  Future<Map<String, String>> _ensureWeekDagCache() async {
    if (_weekDagCache != null) return _weekDagCache!;
    final rows = await _sb
        .from('week_dag')
        .select('week_dag_id, week_dag_naam');
    final map = <String, String>{};
    for (final r in rows as List) {
      final naam = (r['week_dag_naam'] as String).toLowerCase();
      map[naam] = r['week_dag_id'] as String;
    }
    _weekDagCache = map;
    return map;
  }

  /// Create a new week template with child rows in SPYSKAART_KOS_ITEM.
  /// `dae` is: { 'maandag': [ {'id': kos_item_id, ...}, ... ], ... }
  /// Only 'id' is used for inserts; other fields are ignored here.
  Future<Map<String, dynamic>> createWeekTemplate({
    required String naam,
    String? beskrywing, // optional; only saved if column exists in DB
    required Map<String, List<Map<String, dynamic>>> dae,
  }) async {
    // Insert into SPYSKAART
    final insertPayload = {
      'spyskaart_naam': naam,
      'spyskaart_beskrywing': beskrywing,
      'spyskaart_is_templaat': true,
      'spyskaart_is_active': false,
      'spyskaart_datum': DateTime.now().toIso8601String(),
      // If you added a description column, uncomment the next line:
      // 'spyskaart_beskrywing': beskrywing ?? '',
    };

    final spyskaart = await _sb
        .from('spyskaart')
        .insert(insertPayload)
        .select()
        .single();

    final spyskaartId = spyskaart['spyskaart_id'] as String;

    // Insert children
    final dagMap = await _ensureWeekDagCache();
    final inserts = <Map<String, dynamic>>[];

    dae.forEach((dagNaam, lys) {
      final dagId = dagMap[dagNaam.toLowerCase()];
      if (dagId == null) return;
      for (final item in lys) {
        final kosId = item['id'] as String?;
        if (kosId == null) continue;
        inserts.add({
          'spyskaart_id': spyskaartId,
          'kos_item_id': kosId,
          'week_dag_id': dagId,
        });
      }
    });

    if (inserts.isNotEmpty) {
      await _sb.from('spyskaart_kos_item').insert(inserts);
    }

    return spyskaart;
  }

  /// Update week template root + replace children (simple strategy).
  Future<void> updateWeekTemplate({
    required String spyskaartId,
    required String naam,
    String? beskrywing,
    required Map<String, List<Map<String, dynamic>>> dae,
  }) async {
    final updatePayload = {
      'spyskaart_naam': naam,
      // 'spyskaart_beskrywing': beskrywing ?? '', // if you add the column
    };

    await _sb
        .from('spyskaart')
        .update(updatePayload)
        .eq('spyskaart_id', spyskaartId);

    // Replace children
    await _sb
        .from('spyskaart_kos_item')
        .delete()
        .eq('spyskaart_id', spyskaartId);

    final dagMap = await _ensureWeekDagCache();
    final inserts = <Map<String, dynamic>>[];

    dae.forEach((dagNaam, lys) {
      final dagId = dagMap[dagNaam.toLowerCase()];
      if (dagId == null) return;
      for (final item in lys) {
        final kosId = item['id'] as String?;
        if (kosId == null) continue;
        inserts.add({
          'spyskaart_id': spyskaartId,
          'kos_item_id': kosId,
          'week_dag_id': dagId,
        });
      }
    });

    if (inserts.isNotEmpty) {
      await _sb.from('spyskaart_kos_item').insert(inserts);
    }
  }

  Future<void> deleteWeekTemplate(String spyskaartId) async {
    await _sb
        .from('spyskaart')
        .update({'spyskaart_is_templaat': false})
        .eq('spyskaart_id', spyskaartId);
  }

  /// Return raw templates with nested children (for page to shape).
  Future<List<Map<String, dynamic>>> listWeekTemplatesRaw() async {
    final rows = await _sb
        .from('spyskaart')
        .select('''
          spyskaart_id,
          spyskaart_naam,
          spyskaart_beskrywing,
          spyskaart_datum,
          spyskaart_is_templaat,
          spyskaart_kos_item:spyskaart_kos_item(
            spyskaart_kos_id,
            kos_item:kos_item_id(*),
            week_dag:week_dag_id(*)
          )
          ''')
        .eq('spyskaart_is_templaat', true)
        .order('spyskaart_datum', ascending: false);

    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<Map<String, dynamic>?> getTemplateRawById(String spyskaartId) async {
    final row = await _sb
        .from('spyskaart')
        .select('''
          spyskaart_id,
          spyskaart_naam,
          spyskaart_datum,
          spyskaart_is_templaat,
          spyskaart_kos_item:spyskaart_kos_item(
            spyskaart_kos_id,
            kos_item:kos_item_id(*),
            week_dag:week_dag_id(*)
          )
          ''')
        .eq('spyskaart_id', spyskaartId)
        .maybeSingle();

    return row;
  }
}
