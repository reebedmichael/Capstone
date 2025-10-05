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

    // 1. Total earnings today and yesterday
    final todayEarningsRes = await _sb
        .from('bestelling')
        .select('best_volledige_prys')
        .gte('best_geskep_datum', todayStr)
        .lte('best_geskep_datum', now.toIso8601String());

    final yesterdayEarningsRes = await _sb
        .from('bestelling')
        .select('best_volledige_prys')
        .gte('best_geskep_datum', yesterdayStr)
        .lt('best_geskep_datum', todayStr);

    final double todayEarnings = todayEarningsRes.fold<double>(
      0,
      (sum, row) => sum + (row['best_volledige_prys'] as num).toDouble(),
    );
    final double yesterdayEarnings = yesterdayEarningsRes.fold<double>(
      0,
      (sum, row) => sum + (row['best_volledige_prys'] as num).toDouble(),
    );

    // 2. Order counts today and yesterday
    final todayOrders = todayEarningsRes.length;
    final yesterdayOrders = yesterdayEarningsRes.length;

    // 3. Most popular item today
    final popularRes = await _sb
        .from('bestelling')
        .select('best_id')
        .gte('best_geskep_datum', todayStr)
        .lte('best_geskep_datum', now.toIso8601String());

    final bestIdsToday = (popularRes as List).map((r) => r['best_id']).toList();

    String? mostPopularItem;
    if (bestIdsToday.isNotEmpty) {
      final itemRes = await _sb
          .from('bestelling_kos_item')
          .select('kos_item_id')
          .inFilter('best_id', bestIdsToday);

      if (itemRes.isNotEmpty) {
        final counts = <dynamic, int>{};
        for (var row in itemRes) {
          final id = row['kos_item_id'];
          counts[id] = (counts[id] ?? 0) + 1;
        }

        // Find most frequent kos_item_id
        final sorted = counts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        final topItemId = sorted.first.key;

        final kosItemRes = await _sb
            .from('kos_item')
            .select('kos_item_naam')
            .eq('kos_item_id', topItemId)
            .maybeSingle();

        mostPopularItem = kosItemRes?['kos_item_naam'];
      }
    }

    // 4. Uncompleted orders today
    final uncompletedRes = await _sb
        .from('bestelling')
        .select('best_id')
        .gte('best_geskep_datum', todayStr)
        .lte('best_geskep_datum', now.toIso8601String());

    final bestIdsForStatus = (uncompletedRes as List)
        .map((r) => r['best_id'])
        .toList();

    int uncompletedOrders = 0;
    if (bestIdsForStatus.isNotEmpty) {
      final statusRes = await _sb
          .from('bestelling_kos_item')
          .select('best_kos_id')
          .inFilter('best_id', bestIdsForStatus);

      final bestKosIds = (statusRes as List)
          .map((r) => r['best_kos_id'])
          .toList();

      if (bestKosIds.isNotEmpty) {
        final statCountRes = await _sb
            .from('best_kos_item_statusse')
            .select('best_kos_stat_id, kos_stat_id')
            .inFilter('best_kos_id', bestKosIds);

        // Fetch status names
        final allStatuses = await _sb
            .from('kos_item_statusse')
            .select('kos_stat_id, kos_stat_naam');

        final afgehandelIds = allStatuses
            .where((s) => s['kos_stat_naam'] == 'Afgehandel')
            .map((s) => s['kos_stat_id'])
            .toSet();

        uncompletedOrders = statCountRes
            .where((s) => !afgehandelIds.contains(s['kos_stat_id']))
            .length;
      }
    }

    return {
      'todayEarnings': todayEarnings,
      'yesterdayEarnings': yesterdayEarnings,
      'todayOrders': todayOrders,
      'yesterdayOrders': yesterdayOrders,
      'mostPopularItem': mostPopularItem,
      'uncompletedOrders': uncompletedOrders,
    };
  }
}
