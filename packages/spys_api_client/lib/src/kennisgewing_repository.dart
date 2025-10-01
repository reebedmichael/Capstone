import 'package:supabase_flutter/supabase_flutter.dart';
import 'db.dart';
import 'email_service.dart';

class KennisgewingRepository {
  KennisgewingRepository(this._db);
  final SupabaseDb _db;

  SupabaseClient get _sb => _db.raw;
  late final EmailService _emailService = EmailService(_db);

  /// Kry alle kennisgewings vir 'n spesifieke gebruiker
  Future<List<Map<String, dynamic>>> kryKennisgewings(String gebrId) async {
    final rows = await _sb.from('kennisgewings')
        .select('''
          *,
          kennisgewing_tipes:kennis_tipe_id(kennis_tipe_naam)
        ''')
        .eq('gebr_id', gebrId)
        .order('kennis_geskep_datum', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Kry globale kennisgewings
  Future<List<Map<String, dynamic>>> kryGlobaleKennisgewings() async {
    final rows = await _sb.from('globale_kennisgewings')
        .select('''
          *,
          kennisgewing_tipes:kennis_tipe_id(kennis_tipe_naam)
        ''')
        .order('glob_kennis_geskep_datum', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Kry ongelees kennisgewings vir 'n gebruiker
  Future<List<Map<String, dynamic>>> kryOngeleesKennisgewings(String gebrId) async {
    final rows = await _sb.from('kennisgewings')
        .select('''
          *,
          kennisgewing_tipes:kennis_tipe_id(kennis_tipe_naam)
        ''')
        .eq('gebr_id', gebrId)
        .eq('kennis_gelees', false)
        .order('kennis_geskep_datum', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Skep 'n nuwe kennisgewing vir 'n spesifieke gebruiker
  Future<bool> skepKennisgewing({
    required String gebrId,
    required String beskrywing,
    required String tipeNaam,
    String? titel,
    bool stuurEmail = false,
  }) async {
    try {
      // Kry of skep kennisgewing tipe
      final tipeId = await _kryOfSkepKennisgewingTipe(tipeNaam);

      // Skep kennisgewing
      await _sb.from('kennisgewings').insert({
        'gebr_id': gebrId,
        'kennis_beskrywing': beskrywing,
        'kennis_tipe_id': tipeId,
        'kennis_gelees': false,
      });

      // Stuur email as gevra
      if (stuurEmail) {
        await _emailService.stuurEmail(
          gebrId: gebrId,
          onderwerp: titel ?? 'Spys Kennisgewing',
          inhoud: beskrywing,
          tipe: tipeNaam,
        );
      }

      return true;
    } catch (e) {
      print('Fout met skep kennisgewing: $e');
      return false;
    }
  }

  /// Skep 'n globale kennisgewing
  Future<bool> skepGlobaleKennisgewing({
    required String beskrywing,
    required String tipeNaam,
  }) async {
    try {
      // Kry of skep kennisgewing tipe
      final tipeId = await _kryOfSkepKennisgewingTipe(tipeNaam);

      // Skep globale kennisgewing
      await _sb.from('globale_kennisgewings').insert({
        'glob_kennis_beskrywing': beskrywing,
        'kennis_tipe_id': tipeId,
      });

      return true;
    } catch (e) {
      print('Fout met skep globale kennisgewing: $e');
      return false;
    }
  }

  /// Stuur kennisgewing aan alle gebruikers
  Future<bool> stuurAanAlleGebruikers({
    required String beskrywing,
    required String tipeNaam,
    String? titel,
    bool stuurEmail = false,
  }) async {
    try {
      // Kry alle gebruikers
      final gebruikers = await _sb.from('gebruikers').select('gebr_id');
      
      if (gebruikers.isEmpty) return false;

      // Kry of skep kennisgewing tipe
      final tipeId = await _kryOfSkepKennisgewingTipe(tipeNaam);

      // Skep kennisgewings vir alle gebruikers
      final kennisgewings = gebruikers.map((gebruiker) => {
        'gebr_id': gebruiker['gebr_id'],
        'kennis_beskrywing': beskrywing,
        'kennis_tipe_id': tipeId,
        'kennis_gelees': false,
      }).toList();

      await _sb.from('kennisgewings').insert(kennisgewings);

      // Stuur email aan alle gebruikers as gevra
      if (stuurEmail) {
        await _emailService.stuurEmailAanAlleGebruikers(
          onderwerp: titel ?? 'Spys Kennisgewing',
          inhoud: beskrywing,
          tipe: tipeNaam,
        );
      }

      return true;
    } catch (e) {
      print('Fout met stuur aan alle gebruikers: $e');
      return false;
    }
  }

  /// Stuur kennisgewing aan spesifieke gebruikers
  Future<bool> stuurAanSpesifiekeGebruikers({
    required List<String> gebrIds,
    required String beskrywing,
    required String tipeNaam,
    String? titel,
    bool stuurEmail = false,
  }) async {
    try {
      if (gebrIds.isEmpty) return false;

      // Kry of skep kennisgewing tipe
      final tipeId = await _kryOfSkepKennisgewingTipe(tipeNaam);

      // Skep kennisgewings vir spesifieke gebruikers
      final kennisgewings = gebrIds.map((gebrId) => {
        'gebr_id': gebrId,
        'kennis_beskrywing': beskrywing,
        'kennis_tipe_id': tipeId,
        'kennis_gelees': false,
      }).toList();

      await _sb.from('kennisgewings').insert(kennisgewings);

      // Stuur email aan spesifieke gebruikers as gevra
      if (stuurEmail) {
        await _emailService.stuurEmailAanSpesifiekeGebruikers(
          gebrIds: gebrIds,
          onderwerp: titel ?? 'Spys Kennisgewing',
          inhoud: beskrywing,
          tipe: tipeNaam,
        );
      }

      return true;
    } catch (e) {
      print('Fout met stuur aan spesifieke gebruikers: $e');
      return false;
    }
  }

  /// Markeer kennisgewing as gelees
  Future<bool> markeerAsGelees(String kennisId) async {
    try {
      await _sb.from('kennisgewings')
          .update({'kennis_gelees': true})
          .eq('kennis_id', kennisId);
      return true;
    } catch (e) {
      print('Fout met markeer as gelees: $e');
      return false;
    }
  }

  /// Markeer alle kennisgewings as gelees vir 'n gebruiker
  Future<bool> markeerAllesAsGelees(String gebrId) async {
    try {
      await _sb.from('kennisgewings')
          .update({'kennis_gelees': true})
          .eq('gebr_id', gebrId);
      return true;
    } catch (e) {
      print('Fout met markeer alles as gelees: $e');
      return false;
    }
  }

  /// Verwyder kennisgewing
  Future<bool> verwyderKennisgewing(String kennisId) async {
    try {
      await _sb.from('kennisgewings')
          .delete()
          .eq('kennis_id', kennisId);
      return true;
    } catch (e) {
      print('Fout met verwyder kennisgewing: $e');
      return false;
    }
  }

  /// Verwyder globale kennisgewing
  Future<bool> verwyderGlobaleKennisgewing(String globKennisId) async {
    try {
      await _sb.from('globale_kennisgewings')
          .delete()
          .eq('glob_kennis_id', globKennisId);
      return true;
    } catch (e) {
      print('Fout met verwyder globale kennisgewing: $e');
      return false;
    }
  }

  /// Opdateer bestaande kennisgewing
  Future<bool> opdateerKennisgewing({
    required String kennisId,
    String? beskrywing,
    String? tipeNaam,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      
      if (beskrywing != null) {
        updates['kennis_beskrywing'] = beskrywing;
      }
      
      if (tipeNaam != null) {
        final tipeId = await _kryOfSkepKennisgewingTipe(tipeNaam);
        updates['kennis_tipe_id'] = tipeId;
      }
      
      if (updates.isEmpty) return true;
      
      await _sb.from('kennisgewings')
          .update(updates)
          .eq('kennis_id', kennisId);
      
      return true;
    } catch (e) {
      print('Fout met opdateer kennisgewing: $e');
      return false;
    }
  }

  /// Opdateer globale kennisgewing
  Future<bool> opdateerGlobaleKennisgewing({
    required String globKennisId,
    String? beskrywing,
    String? tipeNaam,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      
      if (beskrywing != null) {
        updates['glob_kennis_beskrywing'] = beskrywing;
      }
      
      if (tipeNaam != null) {
        final tipeId = await _kryOfSkepKennisgewingTipe(tipeNaam);
        updates['kennis_tipe_id'] = tipeId;
      }
      
      if (updates.isEmpty) return true;
      
      await _sb.from('globale_kennisgewings')
          .update(updates)
          .eq('glob_kennis_id', globKennisId);
      
      return true;
    } catch (e) {
      print('Fout met opdateer globale kennisgewing: $e');
      return false;
    }
  }

  /// Kry alle kennisgewings vir admin (beide gebruiker en globale)
  Future<List<Map<String, dynamic>>> kryAlleKennisgewingsVirAdmin() async {
    try {
      // Kry alle gebruiker kennisgewings met gebruiker inligting
      final gebruikerKennisgewings = await _sb.from('kennisgewings')
          .select('''
            *,
            kennisgewing_tipes:kennis_tipe_id(kennis_tipe_naam),
            gebruikers:gebr_id(gebr_naam, gebr_van, gebr_epos)
          ''')
          .order('kennis_geskep_datum', ascending: false);
      
      // Kry alle globale kennisgewings
      final globaleKennisgewings = await _sb.from('globale_kennisgewings')
          .select('''
            *,
            kennisgewing_tipes:kennis_tipe_id(kennis_tipe_naam)
          ''')
          .order('glob_kennis_geskep_datum', ascending: false);
      
      // Kombineer en merk elke item se tipe
      final alleKennisgewings = <Map<String, dynamic>>[];
      
      for (var k in gebruikerKennisgewings) {
        alleKennisgewings.add({
          ...k,
          '_kennisgewing_soort': 'gebruiker',
        });
      }
      
      for (var k in globaleKennisgewings) {
        alleKennisgewings.add({
          ...k,
          '_kennisgewing_soort': 'globaal',
        });
      }
      
      // Sorteer alles saam op datum
      alleKennisgewings.sort((a, b) {
        final dateA = DateTime.parse(
          a['kennis_geskep_datum'] ?? a['glob_kennis_geskep_datum']
        );
        final dateB = DateTime.parse(
          b['kennis_geskep_datum'] ?? b['glob_kennis_geskep_datum']
        );
        return dateB.compareTo(dateA); // nuutste eerste
      });
      
      return alleKennisgewings;
    } catch (e) {
      print('Fout met kry alle kennisgewings vir admin: $e');
      return [];
    }
  }

  /// Tel hoeveel gebruikers 'n spesifieke kennisgewing ontvang het
  Future<int> telOntvangers(String kennisId) async {
    try {
      final result = await _sb.from('kennisgewings')
          .select('kennis_id')
          .eq('kennis_beskrywing', kennisId);
      return result.length;
    } catch (e) {
      print('Fout met tel ontvangers: $e');
      return 0;
    }
  }

  /// Kry of skep 'n kennisgewing tipe
  Future<String> _kryOfSkepKennisgewingTipe(String tipeNaam) async {
    // Probeer om bestaande tipe te kry
    final row = await _sb.from('kennisgewing_tipes')
        .select('kennis_tipe_id')
        .eq('kennis_tipe_naam', tipeNaam)
        .maybeSingle();
    
    if (row != null && row['kennis_tipe_id'] != null) {
      return row['kennis_tipe_id'].toString();
    }

    // Skep nuwe tipe as dit nie bestaan nie
    final inserted = await _sb.from('kennisgewing_tipes').insert({
      'kennis_tipe_naam': tipeNaam,
    }).select().maybeSingle();

    if (inserted != null && inserted['kennis_tipe_id'] != null) {
      return inserted['kennis_tipe_id'].toString();
    }

    throw Exception('Kon kennisgewing tipe nie kry of skep nie ($tipeNaam)');
  }

  /// Kry kennisgewing statistieke vir 'n gebruiker
  Future<Map<String, int>> kryKennisgewingStatistieke(String gebrId) async {
    try {
      // Kry alle kennisgewings vir die gebruiker
      final alleKennisgewings = await _sb.from('kennisgewings')
          .select('kennis_gelees')
          .eq('gebr_id', gebrId);
      
      final totaal = alleKennisgewings.length;
      final ongelees = alleKennisgewings.where((k) => !(k['kennis_gelees'] ?? false)).length;
      final gelees = totaal - ongelees;

      return {
        'totaal': totaal,
        'ongelees': ongelees,
        'gelees': gelees,
      };
    } catch (e) {
      print('Fout met kry statistieke: $e');
      return {'totaal': 0, 'ongelees': 0, 'gelees': 0};
    }
  }
}
