import 'package:supabase_flutter/supabase_flutter.dart';
import 'db.dart';

class AdminDashboardRepository {
  AdminDashboardRepository(this._db);
  final SupabaseDb _db;

  SupabaseClient get _sb => _db.raw;

  /// Fetch dashboard statistics:
  /// - total earnings today and yesterday
  /// - order count today and yesterday
  /// - most popular item today
  /// - number of uncompleted orders today
  Future<Map<String, dynamic>> fetcKpiStats() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayStr = today.toIso8601String();
    final yesterdayStr = yesterday.toIso8601String();

    // Execute all queries in parallel for better performance
    final results = await Future.wait([
      // 1. Today's orders with earnings
      _sb
          .from('bestelling')
          .select('best_id, best_volledige_prys')
          .gte('best_geskep_datum', todayStr)
          .lte('best_geskep_datum', now.toIso8601String()),

      // 2. Yesterday's orders with earnings
      _sb
          .from('bestelling')
          .select('best_id, best_volledige_prys')
          .gte('best_geskep_datum', yesterdayStr)
          .lt('best_geskep_datum', todayStr),

      // 3. Today's order items for popular item calculation
      _sb
          .from('bestelling')
          .select('best_id')
          .gte('best_geskep_datum', todayStr)
          .lte('best_geskep_datum', now.toIso8601String()),

      // 4. Get all status types once
      _sb.from('kos_item_statusse').select('kos_stat_id, kos_stat_naam'),
    ]);

    final todayOrdersRes = results[0] as List;
    final yesterdayOrdersRes = results[1] as List;
    final todayBestIdsRes = results[2] as List;
    final allStatusesRes = results[3] as List;

    // Calculate earnings and order counts
    final double todayEarnings = todayOrdersRes.fold<double>(
      0,
      (sum, row) => sum + (row['best_volledige_prys'] as num).toDouble(),
    );
    final double yesterdayEarnings = yesterdayOrdersRes.fold<double>(
      0,
      (sum, row) => sum + (row['best_volledige_prys'] as num).toDouble(),
    );

    final todayOrders = todayOrdersRes.length;
    final yesterdayOrders = yesterdayOrdersRes.length;

    // Get afgehandel status ID once
    final afgehandelIds = allStatusesRes
        .where((s) => s['kos_stat_naam'] == 'Afgehandel')
        .map((s) => s['kos_stat_id'] as String)
        .toSet();

    // Execute remaining queries in parallel
    final bestIdsToday = todayBestIdsRes.map((r) => r['best_id']).toList();

    if (bestIdsToday.isEmpty) {
      return {
        'todayEarnings': todayEarnings,
        'yesterdayEarnings': yesterdayEarnings,
        'todayOrders': todayOrders,
        'yesterdayOrders': yesterdayOrders,
        'mostPopularItem': null,
        'uncompletedOrders': 0,
      };
    }

    final remainingResults = await Future.wait([
      // Popular item calculation
      _getMostPopularItem(bestIdsToday),

      // Uncompleted orders calculation
      _getUncompletedOrdersCount(bestIdsToday, afgehandelIds),
    ]);

    final mostPopularItem = remainingResults[0] as String?;
    final uncompletedOrders = remainingResults[1] as int;

    return {
      'todayEarnings': todayEarnings,
      'yesterdayEarnings': yesterdayEarnings,
      'todayOrders': todayOrders,
      'yesterdayOrders': yesterdayOrders,
      'mostPopularItem': mostPopularItem,
      'uncompletedOrders': uncompletedOrders,
    };
  }

  /// Helper method to get most popular item efficiently
  Future<String?> _getMostPopularItem(List<dynamic> bestIdsToday) async {
    if (bestIdsToday.isEmpty) return null;

    // Get item counts in one query with join
    final itemRes = await _sb
        .from('bestelling_kos_item')
        .select('kos_item_id')
        .inFilter('best_id', bestIdsToday);

    if (itemRes.isEmpty) return null;

    // Count occurrences efficiently
    final counts = <dynamic, int>{};
    for (var row in itemRes) {
      final id = row['kos_item_id'];
      counts[id] = (counts[id] ?? 0) + 1;
    }

    // Find most frequent kos_item_id
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty) return null;

    final topItemId = sorted.first.key;

    // Get item name
    final kosItemRes = await _sb
        .from('kos_item')
        .select('kos_item_naam')
        .eq('kos_item_id', topItemId)
        .maybeSingle();

    return kosItemRes?['kos_item_naam'];
  }

  /// Helper method to get uncompleted orders count efficiently
  Future<int> _getUncompletedOrdersCount(
    List<dynamic> bestIdsToday,
    Set<String> afgehandelIds,
  ) async {
    if (bestIdsToday.isEmpty) return 0;

    // Get all order items and their statuses in one query
    final statusRes = await _sb
        .from('bestelling_kos_item')
        .select('best_kos_id, item_hoev')
        .inFilter('best_id', bestIdsToday);

    if (statusRes.isEmpty) return 0;

    final bestKosIds = statusRes
        .map((r) => r['best_kos_id'] as String)
        .toList();

    // Get statuses for these items
    final statCountRes = await _sb
        .from('best_kos_item_statusse')
        .select('kos_stat_id, best_kos_id')
        .inFilter('best_kos_id', bestKosIds);

    // Create quantity map
    final itemQtyMap = {
      for (var row in statusRes)
        row['best_kos_id'] as String: row['item_hoev'] as int,
    };

    // Count uncompleted items
    int uncompletedOrders = 0;
    final processedItems = <String>{};

    for (var s in statCountRes) {
      final bestKosId = s['best_kos_id'] as String;
      final kosStatId = s['kos_stat_id'] as String;

      // Only process each item once
      if (processedItems.contains(bestKosId)) continue;
      processedItems.add(bestKosId);

      // If status is not 'Afgehandel', count the quantity
      if (!afgehandelIds.contains(kosStatId)) {
        uncompletedOrders += itemQtyMap[bestKosId] ?? 0;
      }
    }

    return uncompletedOrders;
  }

  // Fetch total amount of items for each day in current week (Mon-Sun)
  Future<List<Map<String, dynamic>>> fetchWeeklyItemCount() async {
    final now = DateTime.now();

    // Start of week (Monday)
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final monday = DateTime(
      startOfWeek.year,
      startOfWeek.month,
      startOfWeek.day,
    );

    // End of week (Sunday, 23:59:59)
    final sunday = monday.add(const Duration(days: 6));
    final mondayStr = monday.toIso8601String();
    final sundayStr = DateTime(
      sunday.year,
      sunday.month,
      sunday.day,
      23,
      59,
      59,
    ).toIso8601String();

    // Directly query bestelling_kos_item by best_datum
    final res = await _sb
        .from('bestelling_kos_item')
        .select('item_hoev, best_datum')
        .gte('best_datum', mondayStr)
        .lte('best_datum', sundayStr);

    // Aggregate counts per day
    final Map<String, int> counts = {};
    for (final row in res) {
      final bestDatumStr = row['best_datum'] as String;
      final bestDatum = DateTime.parse(bestDatumStr);
      final dayKey = DateTime(
        bestDatum.year,
        bestDatum.month,
        bestDatum.day,
      ).toIso8601String();

      final qty = row['item_hoev'] as int? ?? 0;
      counts[dayKey] = (counts[dayKey] ?? 0) + qty;
    }

    // Ensure all days Mon–Sun are present
    final List<Map<String, dynamic>> result = [];
    for (int i = 0; i < 7; i++) {
      final d = monday.add(Duration(days: i));
      final key = DateTime(d.year, d.month, d.day).toIso8601String();
      result.add({'date': key, 'totalItems': counts[key] ?? 0});
    }

    return result;
  }

  //Fetch unread notifications for userid(UUID)
  //from 'kennisgewings' get * wher gebr_id==userid and kennis_gelees==false and get kennis_tipe_naam from kennisgewings_tipes where kennis_tipe_id
  Future<List<Map<String, dynamic>>> fetchUnreadNotifications(
    String userId,
  ) async {
    try {
      final res = await _sb
          .from('kennisgewings')
          .select('*, kennis_tipe:kennis_tipe_id(kennis_tipe_naam)')
          .eq('gebr_id', userId)
          .eq('kennis_gelees', false)
          .order('kennis_geskep_datum', ascending: false);

      // Flatten the nested JSON structure
      return (res as List).map((e) {
        final notification = Map<String, dynamic>.from(
          e as Map<String, dynamic>,
        );

        // Extract kennis_tipe_naam from nested structure
        final kennisTipe = notification['kennis_tipe'] as Map<String, dynamic>?;
        if (kennisTipe != null) {
          notification['kennis_tipe_naam'] = kennisTipe['kennis_tipe_naam'];
        }

        // Remove the nested kennis_tipe object to avoid confusion
        notification.remove('kennis_tipe');

        return notification;
      }).toList();
    } catch (e, st) {
      print('Fout in fetchUnreadNotifications: $e\n$st');
      return [];
    }
  }

  //Mark notification as read by kennis_id
  Future<void> markNotificationAsRead(String kennisId) async {
    try {
      await _sb
          .from('kennisgewings')
          .update({'kennis_gelees': true})
          .eq('kennis_id', kennisId);
    } catch (e, st) {
      print('Fout in markNotificationAsRead: $e\n$st');
    }
  }
}
