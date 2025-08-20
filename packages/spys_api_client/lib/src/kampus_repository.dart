import 'package:supabase_flutter/supabase_flutter.dart';
import 'db.dart';

class KampusRepository {
  KampusRepository(this._db);
  final SupabaseDb _db;

  SupabaseClient get _sb => _db.raw;

  Future<List<Map<String, dynamic>?>> kryKampusse() async {
    final data = await _sb.from('kampus')
        .select("kampus_naam");
    return data;
  }

  Future<String?> kryKampusID(String naam) async {
    final data = await _sb
      .from('kampus')
      .select('kampus_id')
      .eq('kampus_naam', naam)
      .maybeSingle();

    if (data == null) return null; // no record found
    return data['kampus_id'] as String;
  }
} 