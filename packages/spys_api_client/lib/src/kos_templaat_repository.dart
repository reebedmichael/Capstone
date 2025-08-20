import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:uuid/uuid.dart';
import 'db.dart';

class KosTemplaatRepository {
  final SupabaseDb _db;
  KosTemplaatRepository(this._db);

  SupabaseClient get _sb => _db.client;

  Future<void> addKosItem(Map<String, dynamic> kosItem) async {
    await _sb.from('kos_item').insert(kosItem);
  }

  Future<void> updateKosItem(String id, Map<String, dynamic> kosItem) async {
    await _sb.from('kos_item').update(kosItem).eq('kos_item_id', id);
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

  Future<List<Map<String, dynamic>>> getKosItems() async {
    final response = await _sb.from('kos_item').select().eq('is_aktief', true);
    return List<Map<String, dynamic>>.from(response as List);
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
