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
  Future<Map<String, dynamic>> fetchDashboardStats() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      final todayStr = today.toIso8601String();
      final yesterdayStr = yesterday.toIso8601String();

      // Execute all queries in parallel for better performance
      final results = await Future.wait([
        // 1. Today's food items with earnings (using best_datum)
        _sb
            .from('bestelling_kos_item')
            .select('kos_item_id, item_hoev, best_datum, best_kos_id')
            .gte('best_datum', todayStr)
            .lt('best_datum', now.toIso8601String()),

        // 2. Yesterday's food items with earnings (using best_datum)
        _sb
            .from('bestelling_kos_item')
            .select('kos_item_id, item_hoev, best_datum, best_kos_id')
            .gte('best_datum', yesterdayStr)
            .lt('best_datum', todayStr),

        // 3. Get all status types once
        _sb.from('kos_item_statusse').select('kos_stat_id, kos_stat_naam'),
      ]);

      final todayItemsRes = results[0] as List;
      final yesterdayItemsRes = results[1] as List;
      final allStatusesRes = results[2] as List;

      // Calculate earnings and order counts from food items
      final todayEarnings = await _computeEarningsFromItems(todayItemsRes);
      final yesterdayEarnings = await _computeEarningsFromItems(
        yesterdayItemsRes,
      );

      // Count distinct orders (best_kos_id) for today and yesterday
      final todayOrders = _countDistinctOrders(todayItemsRes);
      final yesterdayOrders = _countDistinctOrders(yesterdayItemsRes);

      // Get completed status IDs (both done and canceled)
      final completedStatusIds = allStatusesRes
          .where(
            (s) =>
                s['kos_stat_naam'] == 'Afgehandel' ||
                s['kos_stat_naam'] == 'Gekanseleer',
          )
          .map((s) => s['kos_stat_id'] as String?)
          .where((id) => id != null)
          .cast<String>()
          .toSet();

      // Execute remaining queries in parallel
      final remainingResults = await Future.wait([
        // Popular item calculation (using today's food items)
        _getMostPopularItem(todayItemsRes),

        // Uncompleted orders calculation (using today's food items)
        _getUncompletedOrdersCount(todayItemsRes, completedStatusIds),
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
    } catch (e, stackTrace) {
      print('Error in fetchDashboardStats: $e');
      print('Stack trace: $stackTrace');
      // Return default values in case of error
      return {
        'todayEarnings': 0.0,
        'yesterdayEarnings': 0.0,
        'todayOrders': 0,
        'yesterdayOrders': 0,
        'mostPopularItem': null,
        'uncompletedOrders': 0,
      };
    }
  }

  /// Compute earnings from food items by fetching their costs
  Future<double> _computeEarningsFromItems(List<dynamic> items) async {
    if (items.isEmpty) return 0.0;

    // Collect unique kos_item_ids
    final kosIds = items
        .map((r) => r['kos_item_id'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toSet()
        .toList();
    if (kosIds.isEmpty) return 0.0;

    try {
      final kosData = await _sb
          .from('kos_item')
          .select('kos_item_id, kos_item_koste')
          .inFilter('kos_item_id', kosIds);

      final kosRows = List<Map<String, dynamic>>.from(kosData);
      final Map<String, double> costById = {};
      for (final row in kosRows) {
        final id = row['kos_item_id']?.toString();
        final costRaw = row['kos_item_koste'];
        double cost = 0.0;
        if (costRaw is num)
          cost = costRaw.toDouble();
        else if (costRaw is String)
          cost = double.tryParse(costRaw) ?? 0.0;
        if (id != null) costById[id] = cost;
      }

      double total = 0.0;
      for (final it in items) {
        final id = it['kos_item_id']?.toString();
        final qtyRaw = it['item_hoev'];
        int qty = 0;
        if (qtyRaw is num)
          qty = qtyRaw.toInt();
        else if (qtyRaw is String)
          qty = int.tryParse(qtyRaw) ?? 0;
        final cost = (id != null && costById.containsKey(id))
            ? costById[id]!
            : 0.0;
        total += qty * cost;
      }
      return total;
    } catch (e) {
      print('Error computing earnings: $e');
      return 0.0;
    }
  }

  /// Count distinct orders from food items
  int _countDistinctOrders(List<dynamic> items) {
    final ids = items
        .map((r) => r['best_kos_id'] as String?)
        .where((x) => x != null)
        .cast<String>()
        .toSet()
        .length;
    return ids;
  }

  /// Helper method to get most popular item efficiently
  Future<String?> _getMostPopularItem(List<dynamic> todayItems) async {
    if (todayItems.isEmpty) return null;

    // Count occurrences of each kos_item_id efficiently
    final counts = <dynamic, int>{};
    for (var row in todayItems) {
      final id = row['kos_item_id'];
      final qty = row['item_hoev'] as int? ?? 0;
      if (id != null) {
        counts[id] = (counts[id] ?? 0) + qty;
      }
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
  /// Counts items that are NOT marked as done (Afgehandel) or canceled (Gekanseleer)
  Future<int> _getUncompletedOrdersCount(
    List<dynamic> todayItems,
    Set<String> completedStatusIds,
  ) async {
    if (todayItems.isEmpty) return 0;

    final bestKosIds = todayItems
        .map((r) => r['best_kos_id'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toList();

    if (bestKosIds.isEmpty) return 0;

    // Get statuses for these items
    final statCountRes = await _sb
        .from('best_kos_item_statusse')
        .select('kos_stat_id, best_kos_id')
        .inFilter('best_kos_id', bestKosIds);

    // Create quantity map
    final itemQtyMap = <String, int>{};
    for (var row in todayItems) {
      final bestKosId = row['best_kos_id'] as String?;
      final itemHoev = row['item_hoev'] as int?;
      if (bestKosId != null && itemHoev != null) {
        itemQtyMap[bestKosId] = itemHoev;
      }
    }

    // Count uncompleted items (not done and not canceled)
    int uncompletedOrders = 0;
    final processedItems = <String>{};

    for (var s in statCountRes) {
      final bestKosId = s['best_kos_id'] as String;
      final kosStatId = s['kos_stat_id'] as String;

      // Only process each item once
      if (processedItems.contains(bestKosId)) continue;
      processedItems.add(bestKosId);

      // If status is NOT completed (not done and not canceled), count the quantity
      if (!completedStatusIds.contains(kosStatId)) {
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
