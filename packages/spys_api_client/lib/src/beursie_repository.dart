import 'package:supabase_flutter/supabase_flutter.dart';
import 'db.dart';

class BeursieRepository {
  BeursieRepository(this._db);
  final SupabaseDb _db;

  SupabaseClient get _sb => _db.raw;

  /// Kry die huidige beursie balans vir 'n gebruiker
  Future<double> kryBeursieBalans(String gebrId) async {
    final row = await _sb.from('gebruikers')
        .select('beursie_balans')
        .eq('gebr_id', gebrId)
        .maybeSingle();
    
    if (row != null && row['beursie_balans'] != null) {
      return (row['beursie_balans'] as num).toDouble();
    }
    return 0.0;
  }

  /// Laai beursie op met 'n spesifieke bedrag
  Future<bool> laaiBeursieOp(String gebrId, double bedrag, String betaalmetode) async {
    try {
      // Kry huidige balans
      final huidigeBalans = await kryBeursieBalans(gebrId);
      final nuweBalans = huidigeBalans + bedrag;

      // Kry of skep 'inbetaling' transaksie tipe
      final transTipeId = await _kryOfSkepTransaksieTipe('inbetaling');

      // Skep transaksie rekord
      await _sb.from('beursie_transaksie').insert({
        'gebr_id': gebrId,
        'trans_bedrag': bedrag,
        'trans_tipe_id': transTipeId,
        'trans_beskrywing': 'Beursie opgelaai via $betaalmetode',
      });

      // Opdateer gebruiker se beursie balans
      await _sb.from('gebruikers').update({
        'beursie_balans': nuweBalans,
      }).eq('gebr_id', gebrId);

      return true;
    } catch (e) {
      print('Fout met beursie opgelaai: $e');
      return false;
    }
  }

  /// Kry of skep 'n transaksie tipe
  Future<String> _kryOfSkepTransaksieTipe(String tipeNaam) async {
    // Probeer om bestaande tipe te kry
    final row = await _sb.from('transaksie_tipe')
        .select('trans_tipe_id')
        .eq('trans_tipe_naam', tipeNaam)
        .maybeSingle();
    
    if (row != null && row['trans_tipe_id'] != null) {
      return row['trans_tipe_id'].toString();
    }

    // Skep nuwe tipe as dit nie bestaan nie
    final inserted = await _sb.from('transaksie_tipe').insert({
      'trans_tipe_naam': tipeNaam,
    }).select().maybeSingle();

    if (inserted != null && inserted['trans_tipe_id'] != null) {
      return inserted['trans_tipe_id'].toString();
    }

    throw Exception('Kon transaksie tipe nie kry of skep nie ($tipeNaam)');
  }

  /// Kry alle transaksies vir 'n gebruiker
  Future<List<Map<String, dynamic>>> lysTransaksies(String gebrId) async {
    final rows = await _sb.from('beursie_transaksie')
        .select('''
          *,
          transaksie_tipe:trans_tipe_id(trans_tipe_naam)
        ''')
        .eq('gebr_id', gebrId)
        .order('trans_geskep_datum', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Simuleer betaling (vir demo doeleindes)
  Future<bool> simuleerBetaling(String betaalmetode, double bedrag) async {
    // Simuleer betaling vertraging
    await Future.delayed(const Duration(seconds: 2));
    
    // Vir demo doeleindes, aanvaar alle betalings
    return true;
  }
} 