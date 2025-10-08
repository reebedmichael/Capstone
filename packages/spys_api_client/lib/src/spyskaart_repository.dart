import 'package:supabase_flutter/supabase_flutter.dart';
import 'db.dart';

class SpyskaartRepository {
  SpyskaartRepository(this._db);
  final SupabaseDb _db;

  SupabaseClient get _sb => _db.raw;

  /// Convert DateTime -> 'YYYY-MM-DD' date string (no time).
  String _dateOnly(DateTime d) {
    final iso = d.toIso8601String();
    return iso.split('T')[0];
  }

  /// Get or create a spyskaart for the given week start date.
  /// Returns the spyskaart with all kositems (inkl. kos_item_bestandele).
  Future<Map<String, dynamic>?> getAktieweSpyskaart([
    DateTime? weekStart,
  ]) async {
    // If no weekStart provided, use current week start (Monday)
    final targetDate = weekStart ?? _getCurrentWeekStart();
    final dateStr = _dateOnly(targetDate);

    // First try to find an existing spyskaart for this date
    final existing = await _sb
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
        .eq('spyskaart_datum', dateStr)
        .maybeSingle();

    if (existing != null) {
      return Map<String, dynamic>.from(existing);
    }

    // If no spyskaart exists for this date, create a new one
    final insert = {
      'spyskaart_naam': 'Week Spyskaart $dateStr',
      'spyskaart_is_templaat': false,
      'spyskaart_is_active': false,
      'spyskaart_datum': dateStr,
    };

    final created = await _sb
        .from('spyskaart')
        .insert(insert)
        .select()
        .single();

    // Fetch the created spyskaart with nested children (none at creation)
    final row = await _sb
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
        .eq('spyskaart_id', created['spyskaart_id'])
        .maybeSingle();

    return row != null ? Map<String, dynamic>.from(row) : null;
  }

  /// Get the start of the current week (Monday)
  DateTime _getCurrentWeekStart() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final daysToSubtract =
        weekday - 1; // Monday is 1, so subtract (weekday - 1) days
    return DateTime(now.year, now.month, now.day - daysToSubtract);
  }
}
