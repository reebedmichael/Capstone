import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:uuid/uuid.dart';
import 'db.dart';

class KosTemplaatRepository {
  final SupabaseDb _db;
  KosTemplaatRepository(this._db);

  SupabaseClient get _sb => _db.client;
  //Add kositem to kos_item. Add kos_item_id and dieet_id to kos_item_dieet_vereistes where dieet_id in dieet table and kos_item_id in kos_item table
  // Future<void> addKosItem(Map<String, dynamic> kosItem) async {
  //   await _sb.from('kos_item').insert(kosItem);
  // }
  Future<void> addKosItem(
    Map<String, dynamic> kosItem,
    List<String> selectedCategories,
  ) async {
    // final client = _db.client;

    // 1. Insert kos_item
    final inserted = await _sb
        .from('kos_item')
        .insert(kosItem)
        .select()
        .single();
    final kosItemId = inserted['kos_item_id'];

    // 2. Fetch dieet_ids from dieet table for selected categories
    if (selectedCategories.isNotEmpty) {
      final dieetRows = await _sb
          .from('dieet_vereiste')
          .select('dieet_id, dieet_naam')
          .inFilter('dieet_naam', selectedCategories);

      // 3. Insert relations into kos_item_dieet_vereistes
      final inserts = dieetRows.map((row) {
        return {'kos_item_id': kosItemId, 'dieet_id': row['dieet_id']};
      }).toList();

      if (inserts.isNotEmpty) {
        await _sb.from('kos_item_dieet_vereistes').insert(inserts);
      }
    }
  }

  // Future<void> updateKosItem(String id, Map<String, dynamic> kosItem) async {
  //   await _sb.from('kos_item').update(kosItem).eq('kos_item_id', id);
  // }
  Future<void> updateKosItem(
    String id,
    Map<String, dynamic> kosItem,
    List<String> selectedCategories,
  ) async {
    // 1. Update kos_item
    await _sb.from('kos_item').update(kosItem).eq('kos_item_id', id);

    // 2. Clear old relations
    await _sb.from('kos_item_dieet_vereistes').delete().eq('kos_item_id', id);

    // 3. Re-insert selected categories
    if (selectedCategories.isNotEmpty) {
      final dieetRows = await _sb
          .from('dieet_vereiste')
          .select('dieet_id, dieet_naam')
          .inFilter('dieet_naam', selectedCategories);

      final inserts = dieetRows.map((row) {
        return {'kos_item_id': id, 'dieet_id': row['dieet_id']};
      }).toList();

      if (inserts.isNotEmpty) {
        await _sb.from('kos_item_dieet_vereistes').insert(inserts);
      }
    }
  }

  Future<String> uploadKosItemPrent(
    Uint8List imageBytes,
    String fileName,
  ) async {
    // Extract file extension from the original file name
    final fileExtension = fileName.split('.').last;

    // Construct the path with the original extension
    final path =
        '$fileName-${DateTime.now().millisecondsSinceEpoch}.$fileExtension';

    await _sb.storage
        .from('kost-item-prentjie')
        .uploadBinary(
          path,
          imageBytes,
          fileOptions: const FileOptions(upsert: true),
        );

    // Get public URL
    final url = _sb.storage.from('kost-item-prentjie').getPublicUrl(path);

    return url;
  }

  Future<void> softDeleteKosItem(String id) async {
    // UuidValue uuidValue = UuidValue.fromList(Uuid.parse(id));
    await _sb
        .from('kos_item')
        .update({'is_aktief': false})
        .eq('kos_item_id', id);
  }

  Future<void> deleteKosItem(String id) async {
    await _sb.from('kos_item').delete().eq('id', id);
  }

  //get all from kos_item where is_aktief =true, get dieet_id(UUiD) from kos_item_dieet_vereistes where kos_item_id, get dieet_naam where dieet_id
  // Future<List<Map<String, dynamic>>> getKosItems() async {
  //   final response = await _sb.from('kos_item').select().eq('is_aktief', true);
  //   return List<Map<String, dynamic>>.from(response as List);
  // }
  Future<List<Map<String, dynamic>>> getKosItems() async {
    final response = await _sb
        .from('kos_item')
        .select(
          '*, kos_item_dieet_vereistes(dieet_id, dieet:dieet_id(dieet_naam)), bestelling_kos_item!inner(best_kos_is_liked)',
        )
        .eq('is_aktief', true);

    // Process the response to count likes
    final List<Map<String, dynamic>> processedResponse = [];

    for (final item in response) {
      final Map<String, dynamic> processedItem = Map<String, dynamic>.from(
        item,
      );

      // Count likes from bestelling_kos_item where best_kos_is_liked is true
      final bestellingKosItems = item['bestelling_kos_item'] as List? ?? [];
      final likesCount = bestellingKosItems
          .where((bki) => bki['best_kos_is_liked'] == true)
          .length;

      // Add the calculated likes count
      processedItem['kos_item_likes'] = likesCount;

      // Remove the bestelling_kos_item data as it's not needed in the final result
      processedItem.remove('bestelling_kos_item');

      processedResponse.add(processedItem);
    }

    return processedResponse;
  }

  Future<List<Map<String, dynamic>>> lysSpyskaartVirWeek(
    String spyskaartId,
  ) async {
    final rows = await _sb
        .from('spyskaart_kos_item')
        .select('*, kos_item:kos_item_id(*), week_dag:week_dag_id(*)')
        .eq('spyskaart_id', spyskaartId);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> lysAktiefOpDatum(DateTime datum) async {
    final dateStr = datum.toIso8601String().split('T')[0];
    final rows = await _sb
        .from('spyskaart')
        .select(
          '*, spyskaart_kos_item:spyskaart_kos_item(*, kos_item:kos_item_id(*), week_dag:week_dag_id(*))',
        )
        .gte('spyskaart_datum', dateStr)
        .lte('spyskaart_datum', dateStr);
    return List<Map<String, dynamic>>.from(rows as List);
  }
}
