// // import 'package:supabase_flutter/supabase_flutter.dart';
// // import 'db.dart';



// // class AdminBestellingRepository {
// //   AdminBestellingRepository(this._db);
// //   final SupabaseDb _db;

// //   SupabaseClient get _sb => _db.raw;
// //   Future<List<Map<String, dynamic>>> getBestellings() async {
// //     final rows = await _sb.from('bestelling')
// //         .select(
// //           //Gets best_id,best_geskep_datum,best_volledige_prys,gebr_id,kampus_id
// //           //from gebruiker get gebr_epos where gebr_id
// //           //from kampus get kampus_naam where kampus_id
// //           //from bestelling_kos_item get best_kos_id,kos_item_id, item_hoev, best_datum(translate to weekday name) where best_id
// //           //from kos_item get kos_item_naam where kos_item_id
// //           //from best_kos_item_statusse get kos_stat_id where best_kos_id
// //           //from kos_item_statusse get kos_stat_naam where kos_stat_id

          
// //         )
// //         .order('best_geskep_datum', ascending: false);
// //     return List<Map<String, dynamic>>.from(rows);
// //   }

// //   }
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'db.dart';

// /// AdminBestellingRepository
// /// Voltooi Supabase/Dart backend funksies om bestellings saam met verwante data
// /// (gebruiker e-pos, kampus naam, kos item name en statusse) te laai.
// class AdminBestellingRepository {
//   AdminBestellingRepository(this._db);
//   final SupabaseDb _db;

//   SupabaseClient get _sb => _db.raw;

//   /// Haal bestellings en assembles al die verwante data in `kos_items`.
//   ///
//   /// Returned `List<Map<String, dynamic>>` met elke bestelling se kern velde
//   /// en 'n `kos_items` sleutel wat 'n lys van items met name en statusse bevat.
//   Future<List<Map<String, dynamic>>> getBestellings() async {
//     try {
//       // Stap 1: laai basiese bestellingsreeks
//       final rows = await _sb
//           .from('bestelling')
//           .select<List<Map<String, dynamic>>>(
//               '''best_id, best_geskep_datum, best_volledige_prys, gebr_id, kampus_id''')
//           .order('best_geskep_datum', ascending: false);

//       if (rows == null || rows.isEmpty) return <Map<String, dynamic>>[];

//       // Verzamel ids vir batched navrae
//       final bestIds = <int>{};
//       final gebrIds = <int>{};
//       final kampusIds = <int>{};

//       for (final r in rows) {
//         if (r['best_id'] != null) bestIds.add(r['best_id'] as int);
//         if (r['gebr_id'] != null) gebrIds.add(r['gebr_id'] as int);
//         if (r['kampus_id'] != null) kampusIds.add(r['kampus_id'] as int);
//       }

//       // Stap 2: laai gebruikers en kampusse in batch
//       final gebruikersMap = await _fetchGebruikerMap(gebrIds.toList());
//       final kampusMap = await _fetchKampusMap(kampusIds.toList());

//       // Stap 3: laai bestelling_kos_item rye vir die bestIds
//       final bestellingKosItems = await _sb
//           .from('bestelling_kos_item')
//           .select<List<Map<String, dynamic>>>(
//               'best_kos_id, best_id, kos_item_id, item_hoev, best_datum')
//           .in_('best_id', bestIds.toList());

//       // Map best_id -> list of items
//       final Map<int, List<Map<String, dynamic>>> itemsByBestId = {};
//       final kosItemIds = <int>{};
//       final bestKosIds = <int>{};

//       if (bestellingKosItems != null) {
//         for (final it in bestellingKosItems) {
//           final bestId = it['best_id'] as int;
//           final bestKosId = it['best_kos_id'] as int;
//           final kosItemId = it['kos_item_id'] as int;

//           itemsByBestId.putIfAbsent(bestId, () => []).add(Map<String, dynamic>.from(it));
//           kosItemIds.add(kosItemId);
//           bestKosIds.add(bestKosId);
//         }
//       }

//       // Stap 4: laai kos_item name in batch
//       final kosItemMap = await _fetchKosItemMap(kosItemIds.toList());

//       // Stap 5: laai status koppelings uit best_kos_item_statusse
//       final bestKosStatRows = await _sb
//           .from('best_kos_item_statusse')
//           .select<List<Map<String, dynamic>>>(
//               'best_kos_id, kos_stat_id')
//           .in_('best_kos_id', bestKosIds.toList());

//       // Map best_kos_id -> lis van kos_stat_id
//       final Map<int, List<int>> statIdsByBestKosId = {};
//       final kosStatIds = <int>{};

//       if (bestKosStatRows != null) {
//         for (final r in bestKosStatRows) {
//           final bk = r['best_kos_id'] as int;
//           final ks = r['kos_stat_id'] as int;
//           statIdsByBestKosId.putIfAbsent(bk, () => []).add(ks);
//           kosStatIds.add(ks);
//         }
//       }

//       // Stap 6: laai kos_item_statusse name
//       final kosStatMap = await _fetchKosStatMap(kosStatIds.toList());

//       // Stap 7: assembleer finale resultate
//       final List<Map<String, dynamic>> results = [];

//       for (final r in rows) {
//         final bestId = r['best_id'] as int;
//         final gebrId = r['gebr_id'] as int?;
//         final kampusId = r['kampus_id'] as int?;

//         final Map<String, dynamic> order = {
//           'best_id': bestId,
//           'best_geskep_datum': r['best_geskep_datum'],
//           'best_volledige_prys': r['best_volledige_prys'],
//           'gebr_id': gebrId,
//           'gebr_epos': gebrId != null ? gebruikersMap[gebrId] : null,
//           'kampus_id': kampusId,
//           'kampus_naam': kampusId != null ? kampusMap[kampusId] : null,
//         };

//         // voeg kos items by
//         final items = itemsByBestId[bestId] ?? [];
//         final List<Map<String, dynamic>> assembledItems = [];

//         for (final it in items) {
//           final bestKosId = it['best_kos_id'] as int;
//           final kosItemId = it['kos_item_id'] as int;
//           final itemHoev = it['item_hoev'];
//           final bestDatumRaw = it['best_datum'];

//           // probeer om weekdag naam te kry
//           String? weekdag;
//           try {
//             if (bestDatumRaw != null) {
//               final dt = DateTime.parse(bestDatumRaw.toString());
//               weekdag = _weekdayAfr(dt.weekday);
//             }
//           } catch (_) {
//             weekdag = null;
//           }

//           final statusIds = statIdsByBestKosId[bestKosId] ?? [];
//           final statusNamen = statusIds.map((id) => kosStatMap[id]).whereType<String>().toList();

//           assembledItems.add({
//             'best_kos_id': bestKosId,
//             'kos_item_id': kosItemId,
//             'kos_item_naam': kosItemMap[kosItemId],
//             'item_hoev': itemHoev,
//             'best_datum': bestDatumRaw,
//             'weekdag': weekdag,
//             'statusse': statusNamen,
//           });
//         }

//         order['kos_items'] = assembledItems;

//         // Indien gewen, voeg ook 'best_geskep_datum_weekdag' by
//         try {
//           if (r['best_geskep_datum'] != null) {
//             final dt = DateTime.parse(r['best_geskep_datum'].toString());
//             order['best_geskep_datum_weekdag'] = _weekdayAfr(dt.weekday);
//           }
//         } catch (_) {
//           order['best_geskep_datum_weekdag'] = null;
//         }

//         results.add(order);
//       }

//       return results;
//     } catch (e, st) {
//       // Log of return empty list on error. In 'production' you may want to rethrow
//       // or convert to a custom error type.
//       print('Fout in getBestellings: $e\n$st');
//       return <Map<String, dynamic>>[];
//     }
//   }

//   // Helper om gebruikers e-posse te kry: map van gebr_id -> epos
//   Future<Map<int, String>> _fetchGebruikerMap(List<int> gebrIds) async {
//     if (gebrIds.isEmpty) return {};
//     final rows = await _sb
//         .from('gebruiker')
//         .select<List<Map<String, dynamic>>>('gebr_id, gebr_epos')
//         .in_('gebr_id', gebrIds);
//     final Map<int, String> m = {};
//     if (rows != null) {
//       for (final r in rows) {
//         if (r['gebr_id'] != null && r['gebr_epos'] != null) {
//           m[r['gebr_id'] as int] = r['gebr_epos'] as String;
//         }
//       }
//     }
//     return m;
//   }

//   // Helper om kampus id -> naam
//   Future<Map<int, String>> _fetchKampusMap(List<int> kampusIds) async {
//     if (kampusIds.isEmpty) return {};
//     final rows = await _sb
//         .from('kampus')
//         .select<List<Map<String, dynamic>>>('kampus_id, kampus_naam')
//         .in_('kampus_id', kampusIds);
//     final Map<int, String> m = {};
//     if (rows != null) {
//       for (final r in rows) {
//         if (r['kampus_id'] != null && r['kampus_naam'] != null) {
//           m[r['kampus_id'] as int] = r['kampus_naam'] as String;
//         }
//       }
//     }
//     return m;
//   }

//   // Helper om kos_item id -> kos_item_naam
//   Future<Map<int, String>> _fetchKosItemMap(List<int> kosItemIds) async {
//     if (kosItemIds.isEmpty) return {};
//     final rows = await _sb
//         .from('kos_item')
//         .select<List<Map<String, dynamic>>>('kos_item_id, kos_item_naam')
//         .in_('kos_item_id', kosItemIds);
//     final Map<int, String> m = {};
//     if (rows != null) {
//       for (final r in rows) {
//         if (r['kos_item_id'] != null && r['kos_item_naam'] != null) {
//           m[r['kos_item_id'] as int] = r['kos_item_naam'] as String;
//         }
//       }
//     }
//     return m;
//   }

//   // Helper om kos_item_statusse id -> naam
//   Future<Map<int, String>> _fetchKosStatMap(List<int> kosStatIds) async {
//     if (kosStatIds.isEmpty) return {};
//     final rows = await _sb
//         .from('kos_item_statusse')
//         .select<List<Map<String, dynamic>>>('kos_stat_id, kos_stat_naam')
//         .in_('kos_stat_id', kosStatIds);
//     final Map<int, String> m = {};
//     if (rows != null) {
//       for (final r in rows) {
//         if (r['kos_stat_id'] != null && r['kos_stat_naam'] != null) {
//           m[r['kos_stat_id'] as int] = r['kos_stat_naam'] as String;
//         }
//       }
//     }
//     return m;
//   }

//   // Weekdag name in Afrikaans vir DateTime.weekday (1..7)
//   String _weekdayAfr(int weekday) {
//     const names = [
//       'Maandag',
//       'Dinsdag',
//       'Woensdag',
//       'Donderdag',
//       'Vrydag',
//       'Saterdag',
//       'Sondag'
//     ];
//     // DateTime.weekday: 1 = Monday
//     if (weekday < 1 || weekday > 7) return '';
//     return names[weekday - 1];
//   }
// }
