import 'package:supabase_flutter/supabase_flutter.dart';
import 'db.dart';

class BestellingItemInput {
  BestellingItemInput({required this.kosItemId, this.aantal = 1});
  final String kosItemId;
  final int aantal;
}

class BestellingRepository {
  BestellingRepository(this._db);
  final SupabaseDb _db;

  SupabaseClient get _sb => _db.raw;

  Future<Map<String, dynamic>> skepBestelling({
    required String gebrId,
    required String kampusId,
    required List<BestellingItemInput> items,
  }) async {
    // Create bestelling
    final bestellingData = {
      'gebr_id': gebrId,
      'kampus_id': kampusId,
      'best_volledige_prys': 0.0, // Calculate later
    };
    
    final bestelling = await _sb.from('bestelling').insert(bestellingData).select().single();
    final bestId = bestelling['best_id'];
    
    // Add items
    for (final item in items) {
      await _sb.from('bestelling_kos_item').insert({
        'best_id': bestId,
        'kos_item_id': item.kosItemId,
      });
    }
    
    return Map<String, dynamic>.from(bestelling);
  }

  Future<List<Map<String, dynamic>>> lysBestellings(String gebrId) async {
    final rows = await _sb.from('bestelling')
        .select('''
          *,
          bestelling_kos_item:bestelling_kos_item(
            *,
            kos_item:kos_item_id(*)
          )
        ''')
        .eq('gebr_id', gebrId)
        .order('best_geskep_datum', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }
} 