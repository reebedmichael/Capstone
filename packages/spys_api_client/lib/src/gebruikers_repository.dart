import 'package:supabase_flutter/supabase_flutter.dart';
import 'db.dart';

class GebruikersRepository {
  GebruikersRepository(this._db);
  final SupabaseDb _db;

  SupabaseClient get _sb => _db.raw;

  Future<Map<String, dynamic>?> kryGebruiker(String gebrId) async {
    final data = await _sb.from('gebruikers')
        .select()
        .eq('gebr_id', gebrId)
        .maybeSingle();
    return data;
  }

  Future<List<Map<String, dynamic>>> soekGebruikers(String q) async {
    final rows = await _sb.from('gebruikers').select().ilike('gebr_epos', '%$q%');
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> skepOfOpdateerGebruiker(Map<String, dynamic> data) async {
    await _sb.from('gebruikers').upsert(data, onConflict: 'gebr_id');
  }
} 