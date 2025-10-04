import 'package:supabase_flutter/supabase_flutter.dart';
import 'db.dart';

class ToelaeRepository {
  ToelaeRepository(this._db);
  final SupabaseDb _db;

  SupabaseClient get _sb => _db.raw;

  /// Get user's current balance (same as wallet - beursie_balans)
  Future<double> kryBeursieBalans(String gebrId) async {
    final row = await _sb
        .from('gebruikers')
        .select('beursie_balans')
        .eq('gebr_id', gebrId)
        .maybeSingle();

    if (row == null) return 0.0;

    final balance = row['beursie_balans'];
    if (balance is num) {
      return balance.toDouble();
    }
    return double.tryParse(balance.toString()) ?? 0.0;
  }
  
  /// Get user's allowance amount from their gebruiker_tipe
  Future<double> kryGebruikerToelaag(String gebrId) async {
    final row = await _sb
        .from('gebruikers')
        .select('gebruiker_tipes(gebr_toelaag)')
        .eq('gebr_id', gebrId)
        .maybeSingle();

    if (row == null) return 0.0;
    
    final toelaag = row['gebruiker_tipes']?['gebr_toelaag'];
    if (toelaag is num) {
      return toelaag.toDouble();
    }
    return double.tryParse(toelaag.toString()) ?? 0.0;
  }

  /// Add allowance to a user (admin only) - uses add_toelae function
  Future<Map<String, dynamic>> voegToelaeBy({
    required String gebrId,
    required double bedrag,
    String beskrywing = 'Toelae bygevoeg deur admin',
  }) async {
    final result = await _sb.rpc('add_toelae', params: {
      'p_gebr_id': gebrId,
      'p_bedrag': bedrag,
      'p_beskrywing': beskrywing,
    });
    
    return Map<String, dynamic>.from(result as Map);
  }

  /// Deduct allowance from a user - uses deduct_toelae function
  Future<Map<String, dynamic>> trekToelaeAf({
    required String gebrId,
    required double bedrag,
    String beskrywing = 'Toelae gebruik',
  }) async {
    final result = await _sb.rpc('deduct_toelae', params: {
      'p_gebr_id': gebrId,
      'p_bedrag': bedrag,
      'p_beskrywing': beskrywing,
    });
    
    return Map<String, dynamic>.from(result as Map);
  }

  /// Get allowance transaction history for a user
  /// (filters beursie_transaksie by toelae transaction types)
  Future<List<Map<String, dynamic>>> lysToelaeTransaksies(String gebrId) async {
    final rows = await _sb
        .from('beursie_transaksie')
        .select('*, transaksie_tipe:trans_tipe_id(trans_tipe_naam)')
        .eq('gebr_id', gebrId)
        .or('trans_tipe_id.eq.a1e58a24-1a1d-4940-8855-df4c35ae5d5f,trans_tipe_id.eq.a2e58a24-1a1d-4940-8855-df4c35ae5d5f')
        .order('trans_geskep_datum', ascending: false);
    
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Get all allowance transactions (admin only)
  Future<List<Map<String, dynamic>>> lysAlleToelaeTransaksies() async {
    final rows = await _sb
        .from('beursie_transaksie')
        .select('*, transaksie_tipe:trans_tipe_id(trans_tipe_naam), gebruikers:gebr_id(gebr_naam, gebr_van, gebr_epos)')
        .or('trans_tipe_id.eq.a1e58a24-1a1d-4940-8855-df4c35ae5d5f,trans_tipe_id.eq.a2e58a24-1a1d-4940-8855-df4c35ae5d5f')
        .order('trans_geskep_datum', ascending: false);
    
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Distribute monthly allowances to all users based on their gebruiker_tipe
  Future<Map<String, dynamic>> distribueeMaandelikseToelaes() async {
    final result = await _sb.rpc('distribute_monthly_toelae');
    return Map<String, dynamic>.from(result as Map);
  }

  /// Get all gebruiker_tipes with their allowance amounts
  Future<List<Map<String, dynamic>>> lysGebruikerTipes() async {
    final rows = await _sb
        .from('gebruiker_tipes')
        .select('*')
        .order('gebr_tipe_naam');
    
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Update a gebruiker_tipe's allowance amount
  Future<void> updateToelaagVirTipe({
    required String gebrTipeId,
    required double nieuweToelaag,
  }) async {
    await _sb
        .from('gebruiker_tipes')
        .update({'gebr_toelaag': nieuweToelaag})
        .eq('gebr_tipe_id', gebrTipeId);
  }

  /// Get users with low balance (for admin alerts)
  Future<List<Map<String, dynamic>>> kryGebruikersMetLaeBalans({
    double drempel = 50.0,
  }) async {
    final rows = await _sb
        .from('gebruikers')
        .select('gebr_id, gebr_naam, gebr_van, gebr_epos, beursie_balans, gebruiker_tipes(gebr_tipe_naam, gebr_toelaag)')
        .lte('beursie_balans', drempel)
        .eq('is_aktief', true)
        .order('beursie_balans', ascending: true);

    return List<Map<String, dynamic>>.from(rows);
  }
}
