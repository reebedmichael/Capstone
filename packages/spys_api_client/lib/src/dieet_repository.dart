import 'package:supabase_flutter/supabase_flutter.dart';
import 'db.dart';

class DieetRepository {
  DieetRepository(this._db);
  final SupabaseDb _db;

  SupabaseClient get _sb => _db.raw;

  /// Get all diet types for the filter (distinct)
  Future<List<Map<String, dynamic>>> getAllDietTypes() async {
    final rows = await _sb
        .from('dieet_vereiste')
        .select('dieet_id, dieet_naam')
        .order('dieet_naam');
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Get diets for a specific food item
  Future<List<Map<String, dynamic>>> getDietsForItem(String kosItemId) async {
    final rows = await _sb
        .from('dieet_vereiste')
        .select('''
          dieet_id,
          dieet_naam,
          dieet_beskrywing
        ''')
        .eq('dieet_id', _sb
            .from('kos_item_dieet_vereistes')
            .select('dieet_id')
            .eq('kos_item_id', kosItemId));
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Get food items that match specific diet requirements
  Future<List<String>> getItemsForDiet(String dieetId) async {
    final rows = await _sb
        .from('kos_item_dieet_vereistes')
        .select('kos_item_id')
        .eq('dieet_id', dieetId);
    return rows.map<String>((row) => row['kos_item_id'].toString()).toList();
  }
}

