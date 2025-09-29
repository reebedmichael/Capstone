import 'package:supabase_flutter/supabase_flutter.dart';
import 'db.dart';

class DieetRepository {
  DieetRepository(this._db);
  final SupabaseDb _db;

  SupabaseClient get _sb => _db.raw;

  Future<List<Map<String, dynamic>?>> kryDieet() async {
    final data = await _sb.from('dieet_vereiste').select("dieet_naam");
    return data;
  }

  Future<String?> kryDieetID(String naam) async {
    final data = await _sb
        .from('dieet_vereiste')
        .select('dieet_id')
        .eq('dieet_naam', naam)
        .maybeSingle();

    if (data == null) return null; // no record found
    return data['dieet_id'] as String;
  }
}
