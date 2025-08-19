import 'package:supabase_flutter/supabase_flutter.dart';
import 'db.dart';

class BeursieRepository {
  BeursieRepository(this._db);
  final SupabaseDb _db;

  SupabaseClient get _sb => _db.raw;

  Future<List<Map<String, dynamic>>> lysTransaksies(String gebrId) async {
    final rows = await _sb.from('beursie_transaksie')
        .select('*')
        .eq('gebr_id', gebrId)
        .order('trans_geskep_datum', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }
} 