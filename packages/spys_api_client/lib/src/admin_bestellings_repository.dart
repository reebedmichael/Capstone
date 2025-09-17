import 'package:supabase_flutter/supabase_flutter.dart';
import 'db.dart';

/// AdminBestellingRepository
/// Voltooi Supabase/Dart backend funksies om bestellings saam met verwante data
/// (gebruiker e-pos, kampus naam, kos item name en statusse) te laai.
class AdminBestellingRepository {
  AdminBestellingRepository(this._db);
  final SupabaseDb _db;

  SupabaseClient get _sb => _db.raw;

  /// Haal bestellings en assembles al die verwante data in `kos_items`.
  ///
  /// Returned `List<Map<String, dynamic>>` met elke bestelling se kern velde
  /// en 'n `kos_items` sleutel wat 'n lys van items met name en statusse bevat.
  Future<List<Map<String, dynamic>>> getBestellings() async {
    try {
      // Stap 1: laai basiese bestellingsreeks
      final rows = await _sb
          .from('bestelling')
          .select(
            '''best_id, best_geskep_datum, best_volledige_prys, gebr_id, kampus_id''',
          )
          .order('best_geskep_datum', ascending: false);

      if (rows.isEmpty) return <Map<String, dynamic>>[];

      // Verzamel ids vir batched navrae - GEWYSIG NA STRING
      final bestIds = <String>{};
      final gebrIds = <String>{};
      final kampusIds = <String>{};

      for (final r in rows) {
        if (r['best_id'] != null) bestIds.add(r['best_id'] as String);
        if (r['gebr_id'] != null) gebrIds.add(r['gebr_id'] as String);
        if (r['kampus_id'] != null) kampusIds.add(r['kampus_id'] as String);
      }

      // Stap 2: laai gebruikers en kampusse in batch
      final gebruikersMap = await _fetchGebruikerMap(gebrIds.toList());
      final kampusMap = await _fetchKampusMap(kampusIds.toList());

      // Stap 3: laai bestelling_kos_item rye vir die bestIds
      final bestellingKosItems = await _sb
          .from('bestelling_kos_item')
          .select('best_kos_id, best_id, kos_item_id, item_hoev, best_datum')
          .inFilter('best_id', bestIds.toList());

      // Map best_id -> list of items - GEWYSIG NA STRING
      final Map<String, List<Map<String, dynamic>>> itemsByBestId = {};
      final kosItemIds = <String>{};
      final bestKosIds = <String>{};

      for (final it in bestellingKosItems) {
        final bestId = it['best_id'] as String;
        final bestKosId = it['best_kos_id'] as String;
        final kosItemId = it['kos_item_id'] as String;

        itemsByBestId
            .putIfAbsent(bestId, () => [])
            .add(Map<String, dynamic>.from(it));
        kosItemIds.add(kosItemId);
        bestKosIds.add(bestKosId);
      }

      // Stap 4: laai kos_item name in batch
      final kosItemMap = await _fetchKosItemMap(kosItemIds.toList());

      // Stap 5: laai status koppelings uit best_kos_item_statusse
      final bestKosStatRows = await _sb
          .from('best_kos_item_statusse')
          .select('best_kos_id, kos_stat_id')
          .inFilter('best_kos_id', bestKosIds.toList());

      // Map best_kos_id -> lis van kos_stat_id - GEWYSIG NA STRING
      final Map<String, List<String>> statIdsByBestKosId = {};
      final kosStatIds = <String>{};

      for (final r in bestKosStatRows) {
        final bk = r['best_kos_id'] as String;
        final ks = r['kos_stat_id'] as String;
        statIdsByBestKosId.putIfAbsent(bk, () => []).add(ks);
        kosStatIds.add(ks);
      }

      // Stap 6: laai kos_item_statusse name
      final kosStatMap = await _fetchKosStatMap(kosStatIds.toList());

      // Stap 7: assembleer finale resultate
      final List<Map<String, dynamic>> results = [];

      for (final r in rows) {
        final bestId = r['best_id'] as String;
        final gebrId = r['gebr_id'] as String?;
        final kampusId = r['kampus_id'] as String?;

        final Map<String, dynamic> order = {
          'best_id': bestId,
          'best_geskep_datum': r['best_geskep_datum'],
          'best_volledige_prys': r['best_volledige_prys'],
          'gebr_id': gebrId,
          'gebr_epos': gebrId != null ? gebruikersMap[gebrId] : null,
          'kampus_id': kampusId,
          'kampus_naam': kampusId != null ? kampusMap[kampusId] : null,
        };

        // voeg kos items by
        final items = itemsByBestId[bestId] ?? [];
        final List<Map<String, dynamic>> assembledItems = [];

        for (final it in items) {
          final bestKosId = it['best_kos_id'] as String;
          final kosItemId = it['kos_item_id'] as String;
          final itemHoev = it['item_hoev'];
          final bestDatumRaw = it['best_datum'];

          String? weekdag;
          try {
            if (bestDatumRaw != null) {
              final dt = DateTime.parse(bestDatumRaw.toString());
              weekdag = _weekdayAfr(dt.weekday);
            }
          } catch (_) {
            weekdag = null;
          }

          final statusIds = statIdsByBestKosId[bestKosId] ?? [];
          final statusNamen = statusIds
              .map((id) => kosStatMap[id])
              .whereType<String>()
              .toList();

          assembledItems.add({
            'best_kos_id': bestKosId,
            'kos_item_id': kosItemId,
            'kos_item_naam': kosItemMap[kosItemId],
            'item_hoev': itemHoev,
            'best_datum': bestDatumRaw,
            'weekdag': weekdag,
            'statusse': statusNamen,
          });
        }

        order['kos_items'] = assembledItems;

        try {
          if (r['best_geskep_datum'] != null) {
            final dt = DateTime.parse(r['best_geskep_datum'].toString());
            order['best_geskep_datum_weekdag'] = _weekdayAfr(dt.weekday);
          }
        } catch (_) {
          order['best_geskep_datum_weekdag'] = null;
        }

        results.add(order);
      }

      return results;
    } catch (e, st) {
      print('Fout in getBestellings: $e\n$st');
      return <Map<String, dynamic>>[];
    }
  }

  /// Dateer die status van 'n `bestelling_kos_item` op.
  Future<void> updateStatus({
    required String bestKosId, // GEWYSIG NA STRING
    required String newKosStatId, // GEWYSIG NA STRING
    required String statusNaam,
    String? gebrId, // GEWYSIG NA STRING
    double? refundAmount,
  }) async {
    try {
      await _sb
          .from('best_kos_item_statusse')
          .update({
            'kos_stat_id': newKosStatId,
            'best_wysig_datum': DateTime.now().toIso8601String(),
          })
          .eq('best_kos_id', bestKosId);

      if (statusNaam == 'Gekanseleer') {
        if (gebrId == null || refundAmount == null || refundAmount <= 0) {
          throw ArgumentError(
            'Vir kansellasie is `gebrId` en `refundAmount` verpligtend.',
          );
        }

        final transTipeData = await _sb
            .from('transaksie_tipe')
            .select('trans_tipe_id')
            .eq('trans_tipe_naam', 'admin kanselasie')
            .single();

        final transTipeId = transTipeData['trans_tipe_id'];
        if (transTipeId == null) {
          throw Exception("Transaksie tipe 'admin kanselasie' nie gevind nie.");
        }

        final gebruikerData = await _sb
            .from('gebruikers')
            .select('beursie_balans')
            .eq('gebr_id', gebrId)
            .single();

        final currentBalance =
            (gebruikerData['beursie_balans'] as num?)?.toDouble() ?? 0.0;

        final newBalance = currentBalance + refundAmount;
        await _sb
            .from('gebruikers')
            .update({'beursie_balans': newBalance})
            .eq('gebr_id', gebrId);

        await _sb.from('beursie_transaksie').insert({
          'trans_geskep_datum': DateTime.now().toIso8601String(),
          'trans_bedrag': refundAmount,
          'trans_beskrywing':
              'Terugbetaling vir gekanselleerde item (best_kos_id: $bestKosId).',
          'gebr_id': gebrId,
          'trans_tipe_id': transTipeId,
        });
      }
    } catch (e, st) {
      print('Fout in updateStatus: $e\n$st');
      rethrow;
    }
  }

  // Helper om gebruikers e-posse te kry: map van gebr_id -> epos
  Future<Map<String, String>> _fetchGebruikerMap(List<String> gebrIds) async {
    if (gebrIds.isEmpty) return {};
    final rows = await _sb
        .from('gebruikers')
        .select('gebr_id, gebr_epos')
        .inFilter('gebr_id', gebrIds);
    final Map<String, String> m = {};
    for (final r in rows) {
      if (r['gebr_id'] != null && r['gebr_epos'] != null) {
        m[r['gebr_id'] as String] = r['gebr_epos'] as String;
      }
    }
    return m;
  }

  // Helper om kampus id -> naam
  Future<Map<String, String>> _fetchKampusMap(List<String> kampusIds) async {
    if (kampusIds.isEmpty) return {};
    final rows = await _sb
        .from('kampus')
        .select('kampus_id, kampus_naam')
        .inFilter('kampus_id', kampusIds);
    final Map<String, String> m = {};
    for (final r in rows) {
      if (r['kampus_id'] != null && r['kampus_naam'] != null) {
        m[r['kampus_id'] as String] = r['kampus_naam'] as String;
      }
    }
    return m;
  }

  // Helper om kos_item id -> kos_item_naam
  Future<Map<String, String>> _fetchKosItemMap(List<String> kosItemIds) async {
    if (kosItemIds.isEmpty) return {};
    final rows = await _sb
        .from('kos_item')
        .select('kos_item_id, kos_item_naam')
        .inFilter('kos_item_id', kosItemIds);
    final Map<String, String> m = {};
    for (final r in rows) {
      if (r['kos_item_id'] != null && r['kos_item_naam'] != null) {
        m[r['kos_item_id'] as String] = r['kos_item_naam'] as String;
      }
    }
    return m;
  }

  // Helper om kos_item_statusse id -> naam
  Future<Map<String, String>> _fetchKosStatMap(List<String> kosStatIds) async {
    if (kosStatIds.isEmpty) return {};
    final rows = await _sb
        .from('kos_item_statusse')
        .select('kos_stat_id, kos_stat_naam')
        .inFilter('kos_stat_id', kosStatIds);
    final Map<String, String> m = {};
    for (final r in rows) {
      if (r['kos_stat_id'] != null && r['kos_stat_naam'] != null) {
        m[r['kos_stat_id'] as String] = r['kos_stat_naam'] as String;
      }
    }
    return m;
  }

  // Weekdag name in Afrikaans vir DateTime.weekday (1..7)
  String _weekdayAfr(int weekday) {
    const names = [
      'Maandag',
      'Dinsdag',
      'Woensdag',
      'Donderdag',
      'Vrydag',
      'Saterdag',
      'Sondag',
    ];
    if (weekday < 1 || weekday > 7) return '';
    return names[weekday - 1];
  }
}
