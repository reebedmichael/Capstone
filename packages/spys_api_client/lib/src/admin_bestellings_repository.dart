import 'package:supabase_flutter/supabase_flutter.dart';
import 'db.dart';
import 'kennisgewing_repository.dart';

/// AdminBestellingRepository
/// Voltooi Supabase/Dart backend funksies om bestellings saam met verwante data
/// (gebruiker e-pos, kampus naam, kos item name en statusse) te laai.
class AdminBestellingRepository {
  AdminBestellingRepository(this._db);
  final SupabaseDb _db;

  SupabaseClient get _sb => _db.raw;
  late final KennisgewingRepository _kennisgewingRepo = KennisgewingRepository(
    _db,
  );

  // Cache management
  List<Map<String, dynamic>>? _cachedBestellings;
  DateTime? _lastCacheUpdate;
  Duration _cacheValidityDuration = const Duration(minutes: 5);

  // Status ID cache for performance
  Map<String, String>? _statusIdCache;
  DateTime? _statusCacheUpdate;
  Duration _statusCacheValidityDuration = const Duration(hours: 1);

  /// Check if cache is valid (not expired)
  bool get _isCacheValid {
    if (_cachedBestellings == null || _lastCacheUpdate == null) return false;
    return DateTime.now().difference(_lastCacheUpdate!) <
        _cacheValidityDuration;
  }

  /// Check if status cache is valid (not expired)
  bool get _isStatusCacheValid {
    if (_statusIdCache == null || _statusCacheUpdate == null) return false;
    return DateTime.now().difference(_statusCacheUpdate!) <
        _statusCacheValidityDuration;
  }

  /// Clear the cache
  void clearCache() {
    _cachedBestellings = null;
    _lastCacheUpdate = null;
  }

  /// Clear the status cache
  void clearStatusCache() {
    _statusIdCache = null;
    _statusCacheUpdate = null;
  }

  /// Force refresh cache by clearing it
  void invalidateCache() {
    clearCache();
  }

  /// Set cache validity duration
  void setCacheValidityDuration(Duration duration) {
    _cacheValidityDuration = duration;
  }

  /// Get cached data if valid, otherwise return null
  List<Map<String, dynamic>>? getCachedBestellings() {
    return _isCacheValid ? _cachedBestellings : null;
  }

  /// Haal bestellings en assembles al die verwante data in `kos_items`.
  ///
  /// Returned `List<Map<String, dynamic>>` met elke bestelling se kern velde
  /// en 'n `kos_items` sleutel wat 'n lys van items met name en statusse bevat.
  ///
  /// Uses cache if available and valid to improve performance.
  /// Optimized with parallel fetching for better performance.
  Future<List<Map<String, dynamic>>> getBestellings({
    bool forceRefresh = false,
  }) async {
    // Return cached data if valid and not forcing refresh
    if (!forceRefresh && _isCacheValid) {
      print('Cache hit: Returning cached bestellings data');
      return _cachedBestellings!;
    }

    print('Cache miss or force refresh: Fetching fresh data from database');
    try {
      // Step 1: Load basic orders
      final rows = await _sb
          .from('bestelling')
          .select(
            '''best_id, best_geskep_datum, best_volledige_prys, gebr_id, kampus_id''',
          )
          .order('best_geskep_datum', ascending: false);

      if (rows.isEmpty) return <Map<String, dynamic>>[];

      // Collect IDs for batched queries
      final bestIds = <String>{};
      final gebrIds = <String>{};
      final kampusIds = <String>{};

      for (final r in rows) {
        if (r['best_id'] != null) bestIds.add(r['best_id'] as String);
        if (r['gebr_id'] != null) gebrIds.add(r['gebr_id'] as String);
        if (r['kampus_id'] != null) kampusIds.add(r['kampus_id'] as String);
      }

      // Step 2: PARALLEL FETCHING - Execute all data fetching operations concurrently
      print('Starting parallel data fetching...');
      final stopwatch = Stopwatch()..start();

      final futures = await Future.wait<dynamic>([
        // Fetch users map
        _fetchGebruikerMap(gebrIds.toList()),
        // Fetch campuses map
        _fetchKampusMap(kampusIds.toList()),
        // Fetch order food items
        _sb
            .from('bestelling_kos_item')
            .select(
              'best_kos_id, best_id, kos_item_id, item_hoev, best_datum, best_nommer',
            )
            .inFilter('best_id', bestIds.toList()),
      ]);

      final gebruikersMap = futures[0] as Map<String, String>;
      final kampusMap = futures[1] as Map<String, String>;
      final bestellingKosItems = futures[2] as List<Map<String, dynamic>>;

      print('Primary data fetched in ${stopwatch.elapsedMilliseconds}ms');

      // Process order items to extract additional IDs
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

      // Step 3: PARALLEL FETCHING - Fetch remaining data concurrently
      print('Starting secondary parallel data fetching...');
      final secondaryStopwatch = Stopwatch()..start();

      final secondaryFutures = await Future.wait<dynamic>([
        // Fetch food items map
        _fetchKosItemMap(kosItemIds.toList()),
        // Fetch status mappings
        _sb
            .from('best_kos_item_statusse')
            .select('best_kos_id, kos_stat_id')
            .inFilter('best_kos_id', bestKosIds.toList()),
      ]);

      final kosItemMap =
          secondaryFutures[0] as Map<String, Map<String, dynamic>>;
      final bestKosStatRows = secondaryFutures[1] as List<Map<String, dynamic>>;

      print(
        'Secondary data fetched in ${secondaryStopwatch.elapsedMilliseconds}ms',
      );

      // Process status mappings
      final Map<String, List<String>> statIdsByBestKosId = {};
      final kosStatIds = <String>{};

      for (final r in bestKosStatRows) {
        final bk = r['best_kos_id'] as String;
        final ks = r['kos_stat_id'] as String;
        statIdsByBestKosId.putIfAbsent(bk, () => []).add(ks);
        kosStatIds.add(ks);
      }

      // Step 4: Fetch status names (if any statuses exist)
      Map<String, String> kosStatMap = {};
      if (kosStatIds.isNotEmpty) {
        kosStatMap = await _fetchKosStatMap(kosStatIds.toList());
      }

      stopwatch.stop();
      print(
        'Total data fetching completed in ${stopwatch.elapsedMilliseconds}ms',
      );

      // Step 5: Assemble final results efficiently
      print('Assembling final results...');
      final assemblyStopwatch = Stopwatch()..start();

      final List<Map<String, dynamic>> results = [];

      for (final r in rows) {
        final bestId = r['best_id'] as String;
        final gebrId = r['gebr_id'] as String?;
        final kampusId = r['kampus_id'] as String?;

        // Extract best_nommer from the first item
        String? bestNommer;
        final items = itemsByBestId[bestId] ?? [];
        if (items.isNotEmpty) {
          bestNommer = items.first['best_nommer'] as String?;
        }

        final Map<String, dynamic> order = {
          'best_id': bestId,
          'best_nommer': bestNommer,
          'best_geskep_datum': r['best_geskep_datum'],
          'best_volledige_prys': r['best_volledige_prys'],
          'gebr_id': gebrId,
          'gebr_epos': gebrId != null ? gebruikersMap[gebrId] : null,
          'kampus_id': kampusId,
          'kampus_naam': kampusId != null ? kampusMap[kampusId] : null,
        };

        // Assemble food items efficiently
        final orderItems = itemsByBestId[bestId] ?? [];
        final List<Map<String, dynamic>> assembledItems = [];

        for (final it in orderItems) {
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

          final kosItemData = kosItemMap[kosItemId];

          assembledItems.add({
            'best_kos_id': bestKosId,
            'kos_item_id': kosItemId,
            'kos_item_naam': kosItemData?['naam'],
            'kos_item_koste': kosItemData?['koste'],
            'item_hoev': itemHoev,
            'best_datum': bestDatumRaw,
            'weekdag': weekdag,
            'statusse': statusNamen,
          });
        }

        order['kos_items'] = assembledItems;

        // Add weekday for creation date
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

      assemblyStopwatch.stop();
      print(
        'Result assembly completed in ${assemblyStopwatch.elapsedMilliseconds}ms',
      );

      // Cache the results
      _cachedBestellings = results;
      _lastCacheUpdate = DateTime.now();
      print('Cache updated: ${results.length} bestellings cached');
      print('Total operation completed in ${stopwatch.elapsedMilliseconds}ms');

      return results;
    } catch (e, st) {
      print('Fout in getBestellings: $e\n$st');
      return <Map<String, dynamic>>[];
    }
  }

  /// Kry status ID deur status naam (with caching for performance)
  Future<String?> getStatusIdByName(String statusName) async {
    // Check cache first
    if (_isStatusCacheValid && _statusIdCache != null) {
      final cachedId = _statusIdCache![statusName];
      if (cachedId != null) {
        return cachedId;
      }
    }

    try {
      // If not in cache, fetch from database
      final result = await _sb
          .from('kos_item_statusse')
          .select('kos_stat_id')
          .eq('kos_stat_naam', statusName)
          .single();

      final statusId = result['kos_stat_id'] as String?;

      // Update cache
      if (statusId != null) {
        _statusIdCache ??= {};
        _statusIdCache![statusName] = statusId;
        _statusCacheUpdate = DateTime.now();
      }

      return statusId;
    } catch (e) {
      print('Fout in getStatusIdByName: $e');
      return null;
    }
  }

  /// Load all status IDs into cache for bulk operations
  Future<void> _loadStatusCache() async {
    try {
      final results = await _sb
          .from('kos_item_statusse')
          .select('kos_stat_id, kos_stat_naam');

      _statusIdCache = {};
      for (final result in results) {
        final id = result['kos_stat_id'] as String?;
        final name = result['kos_stat_naam'] as String?;
        if (id != null && name != null) {
          _statusIdCache![name] = id;
        }
      }
      _statusCacheUpdate = DateTime.now();
    } catch (e) {
      print('Fout in _loadStatusCache: $e');
    }
  }

  /// Automatically mark unclaimed orders as verstryk that are past their delivery date
  Future<Map<String, dynamic>> markUnclaimedOrdersAsVerstryk() async {
    try {
      print('🧹 Starting automatic cleanup of unclaimed orders...');

      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);

      // Find all orders that are past their delivery date and not yet completed/cancelled
      final unclaimedOrders = await _sb
          .from('bestelling_kos_item')
          .select('''
            best_kos_id,
            best_id,
            best_datum,
            kos_item:kos_item_id(kos_item_naam),
            best_kos_item_statusse(
              kos_item_statusse:kos_stat_id(kos_stat_naam)
            )
          ''')
          .lt('best_datum', todayDate.toIso8601String());

      if (unclaimedOrders.isEmpty) {
        print('✅ No unclaimed orders found');
        return {
          'success': true,
          'cancelledCount': 0,
          'message': 'Geen onopgehaalde bestellings gevind nie',
        };
      }

      print('🔍 Found ${unclaimedOrders.length} potentially unclaimed orders');

      // Get the "Verstryk" status ID
      final verstrykStatusData = await _sb
          .from('kos_item_statusse')
          .select('kos_stat_id')
          .eq('kos_stat_naam', 'Verstryk')
          .maybeSingle();

      if (verstrykStatusData == null) {
        throw Exception('Kon nie "Verstryk" status vind nie');
      }

      final verstrykStatusId = verstrykStatusData['kos_stat_id'] as String;
      int verstrykCount = 0;
      List<String> verstrykItems = [];

      // Process each unclaimed order
      for (final order in unclaimedOrders) {
        final bestKosId = order['best_kos_id'] as String;
        final bestDatumStr = order['best_datum'] as String?;
        final kosItem = order['kos_item'] as Map<String, dynamic>?;
        final itemName =
            kosItem?['kos_item_naam'] as String? ?? 'Onbekende item';

        if (bestDatumStr == null) continue;

        try {
          final bestDatum = DateTime.parse(bestDatumStr);
          final orderDate = DateTime(
            bestDatum.year,
            bestDatum.month,
            bestDatum.day,
          );

          // Skip if order is not past its delivery date
          if (!orderDate.isBefore(todayDate)) continue;

          // Check if order is already completed, cancelled, or verstryk
          final statuses = order['best_kos_item_statusse'] as List? ?? [];
          bool isAlreadyProcessed = false;

          for (final status in statuses) {
            final statusInfo =
                status['kos_item_statusse'] as Map<String, dynamic>?;
            final statusName = statusInfo?['kos_stat_naam'] as String?;
            if (statusName == 'Afgehandel' ||
                statusName == 'Gekanselleer' ||
                statusName == 'Verstryk') {
              isAlreadyProcessed = true;
              break;
            }
          }

          if (isAlreadyProcessed) continue;

          // Mark the order item as verstryk
          await _sb.from('best_kos_item_statusse').insert({
            'best_kos_id': bestKosId,
            'kos_stat_id': verstrykStatusId,
            'best_kos_wysig_datum': DateTime.now().toIso8601String(),
          });

          // Process refund for verstryk order (similar to cancellation)
          await _processVerstrykRefund(bestKosId, order);

          verstrykCount++;
          verstrykItems.add(itemName);

          print(
            '✅ Marked unclaimed order as verstryk: $itemName (Order date: ${_formatDateForDisplay(orderDate)})',
          );
        } catch (e) {
          print('❌ Error processing order $bestKosId: $e');
        }
      }

      print('✅ Cleanup completed. Marked $verstrykCount orders as verstryk');

      return {
        'success': true,
        'verstrykCount': verstrykCount,
        'verstrykItems': verstrykItems,
        'message': verstrykCount > 0
            ? '$verstrykCount onopgehaalde bestelling(s) is outomaties as verstryk gemerk'
            : 'Geen onopgehaalde bestellings gevind nie',
      };
    } catch (e) {
      print('❌ Error during order cleanup: $e');
      return {
        'success': false,
        'message': 'Fout tydens outomatiese opruiming: $e',
      };
    }
  }

  /// Format date for display in Afrikaans
  String _formatDateForDisplay(DateTime date) {
    final months = [
      'Januarie',
      'Februarie',
      'Maart',
      'April',
      'Mei',
      'Junie',
      'Julie',
      'Augustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    final weekdays = [
      'Sondag',
      'Maandag',
      'Dinsdag',
      'Woensdag',
      'Donderdag',
      'Vrydag',
      'Saterdag',
    ];

    final weekday = weekdays[date.weekday % 7];
    final month = months[date.month - 1];

    return '$weekday ${date.day} $month ${date.year}';
  }

  /// Bulk update status for multiple items efficiently
  /// Processes all updates in a single transaction for better performance
  Future<void> bulkUpdateStatus({
    required List<String> bestKosIds,
    required String statusNaam,
    Map<String, double>? refundAmounts, // bestKosId -> refund amount
    Map<String, String>? customerIds, // bestKosId -> customer ID
  }) async {
    if (bestKosIds.isEmpty) return;

    try {
      // Step 1: Ensure status cache is loaded
      if (!_isStatusCacheValid) {
        await _loadStatusCache();
      }

      // Step 2: Get status ID from cache
      final statusId = _statusIdCache?[statusNaam];
      if (statusId == null) {
        throw Exception('Status "$statusNaam" nie gevind nie');
      }

      // Step 3: Prepare bulk update data
      final now = DateTime.now().toIso8601String();
      final bulkUpdateData = bestKosIds
          .map(
            (bestKosId) => {
              'best_kos_id': bestKosId,
              'kos_stat_id': statusId,
              'best_kos_wysig_datum': now,
            },
          )
          .toList();

      // Step 4: Execute bulk status update
      await _sb
          .from('best_kos_item_statusse')
          .upsert(bulkUpdateData, onConflict: 'best_kos_id');

      // Step 5: Handle bulk refunds for cancellations
      if (statusNaam == 'Gekanselleer' &&
          refundAmounts != null &&
          customerIds != null) {
        await _processBulkRefunds(refundAmounts, customerIds, bestKosIds);
      }

      // Step 6: Send bulk notifications
      if (customerIds != null) {
        await _sendBulkNotifications(customerIds, statusNaam, bestKosIds);
      }

      // Step 7: Invalidate cache
      invalidateCache();
    } catch (e) {
      print('Fout in bulkUpdateStatus: $e');
      rethrow;
    }
  }

  /// Process refund for a verstryk order
  Future<void> _processVerstrykRefund(
    String bestKosId,
    Map<String, dynamic> order,
  ) async {
    try {
      // Get order details to calculate refund amount
      final bestKosItemData = await _sb
          .from('bestelling_kos_item')
          .select('best_id, item_hoev, kos_item:kos_item_id(kos_item_koste)')
          .eq('best_kos_id', bestKosId)
          .single();

      final bestId = bestKosItemData['best_id'] as String;
      final itemHoev = (bestKosItemData['item_hoev'] as num?)?.toInt() ?? 1;
      final kosItem = bestKosItemData['kos_item'] as Map<String, dynamic>?;
      final itemPrice = (kosItem?['kos_item_koste'] as num?)?.toDouble() ?? 0.0;

      final refundAmount = itemPrice * itemHoev;

      if (refundAmount <= 0) return;

      // Get customer ID from the order
      final bestellingData = await _sb
          .from('bestelling')
          .select('gebr_id')
          .eq('best_id', bestId)
          .single();

      final customerId = bestellingData['gebr_id'] as String?;
      if (customerId == null) return;

      // Get transaction type ID for verstryk refund
      final transTipeData = await _sb
          .from('transaksie_tipe')
          .select('trans_tipe_id')
          .eq('trans_tipe_naam', 'admin verstryk')
          .maybeSingle();

      String transTipeId;
      if (transTipeData != null) {
        transTipeId = transTipeData['trans_tipe_id'] as String;
      } else {
        // Fallback to admin kanselasie if verstryk type doesn't exist
        final fallbackData = await _sb
            .from('transaksie_tipe')
            .select('trans_tipe_id')
            .eq('trans_tipe_naam', 'admin kanselasie')
            .single();
        transTipeId = fallbackData['trans_tipe_id'] as String;
      }

      // Update customer wallet
      final gebruikerData = await _sb
          .from('gebruikers')
          .select('beursie_balans')
          .eq('gebr_id', customerId)
          .single();

      final currentBalance =
          (gebruikerData['beursie_balans'] as num?)?.toDouble() ?? 0.0;
      final newBalance = currentBalance + refundAmount;

      await _sb
          .from('gebruikers')
          .update({'beursie_balans': newBalance})
          .eq('gebr_id', customerId);

      // Record transaction
      await _sb.from('beursie_transaksie').insert({
        'trans_geskep_datum': DateTime.now().toIso8601String(),
        'trans_bedrag': refundAmount,
        'trans_beskrywing':
            'Terugbetaling vir verstryk item (best_kos_id: $bestKosId).',
        'gebr_id': customerId,
        'trans_tipe_id': transTipeId,
      });

      print(
        '✅ Processed refund of R$refundAmount for verstryk order $bestKosId',
      );
    } catch (e) {
      print('❌ Error processing verstryk refund for $bestKosId: $e');
      // Don't rethrow - marking as verstryk should still succeed even if refund fails
    }
  }

  /// Process refunds for multiple cancellations efficiently
  Future<void> _processBulkRefunds(
    Map<String, double> refundAmounts,
    Map<String, String> customerIds,
    List<String> bestKosIds,
  ) async {
    // Group refunds by customer ID
    final Map<String, double> refundsByCustomer = {};
    final Map<String, List<String>> refundItemsByCustomer = {};

    for (final bestKosId in bestKosIds) {
      final customerId = customerIds[bestKosId];
      final refundAmount = refundAmounts[bestKosId];

      if (customerId != null && refundAmount != null && refundAmount > 0) {
        refundsByCustomer[customerId] =
            (refundsByCustomer[customerId] ?? 0) + refundAmount;
        (refundItemsByCustomer[customerId] ??= []).add(bestKosId);
      }
    }

    if (refundsByCustomer.isEmpty) return;

    // Get transaction type ID once
    final transTipeData = await _sb
        .from('transaksie_tipe')
        .select('trans_tipe_id')
        .eq('trans_tipe_naam', 'admin kanselasie')
        .single();

    final transTipeId = transTipeData['trans_tipe_id'];
    if (transTipeId == null) {
      throw Exception("Transaksie tipe 'admin kanselasie' nie gevind nie.");
    }

    // Process refunds for each customer
    final now = DateTime.now().toIso8601String();
    final List<Map<String, dynamic>> transactionsToInsert = [];
    final List<Map<String, dynamic>> walletUpdates = [];

    for (final customerId in refundsByCustomer.keys) {
      final totalRefund = refundsByCustomer[customerId]!;
      final items = refundItemsByCustomer[customerId]!;

      // Get current balance
      final gebruikerData = await _sb
          .from('gebruikers')
          .select('beursie_balans')
          .eq('gebr_id', customerId)
          .single();

      final currentBalance =
          (gebruikerData['beursie_balans'] as num?)?.toDouble() ?? 0.0;
      final newBalance = currentBalance + totalRefund;

      // Prepare wallet update
      walletUpdates.add({'gebr_id': customerId, 'beursie_balans': newBalance});

      // Prepare transaction record
      transactionsToInsert.add({
        'trans_geskep_datum': now,
        'trans_bedrag': totalRefund,
        'trans_beskrywing':
            'Bulk terugbetaling vir gekanselleerde items: ${items.join(', ')}',
        'gebr_id': customerId,
        'trans_tipe_id': transTipeId,
      });
    }

    // Execute bulk wallet updates
    for (final update in walletUpdates) {
      await _sb
          .from('gebruikers')
          .update({'beursie_balans': update['beursie_balans']})
          .eq('gebr_id', update['gebr_id']);
    }

    // Execute bulk transaction inserts
    if (transactionsToInsert.isNotEmpty) {
      await _sb.from('beursie_transaksie').insert(transactionsToInsert);
    }
  }

  /// Send notifications for multiple status changes efficiently
  Future<void> _sendBulkNotifications(
    Map<String, String> customerIds,
    String statusNaam,
    List<String> bestKosIds,
  ) async {
    // Get food item names for notifications
    final bestKosItemData = await _sb
        .from('bestelling_kos_item')
        .select('best_kos_id, kos_item:kos_item_id(kos_item_naam)')
        .inFilter('best_kos_id', bestKosIds);

    final Map<String, String> itemNamesByBestKosId = {};
    for (final item in bestKosItemData) {
      final bestKosId = item['best_kos_id'] as String;
      final kosItem = item['kos_item'] as Map<String, dynamic>?;
      final itemName = kosItem?['kos_item_naam'] as String? ?? 'Item';
      itemNamesByBestKosId[bestKosId] = itemName;
    }

    // Send notifications in parallel
    final notificationFutures = <Future>[];

    for (final bestKosId in bestKosIds) {
      final customerId = customerIds[bestKosId];
      if (customerId != null) {
        final itemName = itemNamesByBestKosId[bestKosId] ?? 'Item';
        final beskrywing = _getStatusBeskrywing(statusNaam, itemName);

        notificationFutures.add(
          _kennisgewingRepo.skepKennisgewing(
            gebrId: customerId,
            titel: 'Bestelling Status Opdatering',
            beskrywing: beskrywing,
            tipeNaam: 'bestelling_status',
            stuurEmail: false, // Don't send email for status updates
          ),
        );
      }
    }

    // Wait for all notifications to complete
    await Future.wait(notificationFutures);
  }

  /// Dateer die status van 'n `bestelling_kos_item` op.
  /// Automatically invalidates cache after successful update.
  Future<void> updateStatus({
    required String bestKosId, // GEWYSIG NA STRING
    required String statusNaam,
    String? gebrId, // GEWYSIG NA STRING
    double? refundAmount,
  }) async {
    try {
      //Step 1: Get status ID by name
      final statusId = await getStatusIdByName(statusNaam);
      if (statusId == null) {
        throw Exception('Status "$statusNaam" nie gevind nie');
      }
      print(gebrId);
      //Step 2: Update the item status
      await _sb
          .from('best_kos_item_statusse')
          .update({
            'kos_stat_id': statusId,
            'best_kos_wysig_datum': DateTime.now().toIso8601String(),
          })
          .eq('best_kos_id', bestKosId);

      //Step 3: Handle cancellation refunds
      if (statusNaam == 'Gekanselleer') {
        if (gebrId == null || refundAmount == null || refundAmount <= 0) {
          throw ArgumentError(
            'Vir kansellasie is `gebrId` en `refundAmount` verpligtend.',
          );
        }
        //Step 3: Find the transaction type
        final transTipeData = await _sb
            .from('transaksie_tipe')
            .select('trans_tipe_id')
            .eq('trans_tipe_naam', 'admin kanselasie')
            .single();
        if (transTipeData['trans_tipe_id'] == null) {
          throw Exception("Transaksie tipe 'admin kanselasie' nie gevind nie.");
        }

        final transTipeId = transTipeData['trans_tipe_id'];
        print(transTipeId);
        if (transTipeId == null) {
          throw Exception("Transaksie tipe 'admin kanselasie' nie gevind nie.");
        }
        //Step 4: Refund the user's wallet
        print('Looking for gebruiker with ID: $gebrId');

        // First check if the user exists
        final gebruikerCheck = await _sb
            .from('gebruikers')
            .select('gebr_id')
            .eq('gebr_id', gebrId)
            .maybeSingle();

        if (gebruikerCheck == null) {
          throw Exception('Gebruiker met ID $gebrId nie gevind nie');
        }

        final gebruikerData = await _sb
            .from('gebruikers')
            .select('gebr_id, beursie_balans')
            .eq('gebr_id', gebrId)
            .single();

        print('Found gebruiker: ${gebruikerData['gebr_id']}');
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

      // Step 4: Send notification to user about status change
      if (gebrId != null) {
        try {
          // Get the food item name for the notification
          final bestKosItemData = await _sb
              .from('bestelling_kos_item')
              .select('kos_item:kos_item_id(kos_item_naam)')
              .eq('best_kos_id', bestKosId)
              .maybeSingle();

          String kosItemNaam = 'Item';
          if (bestKosItemData != null && bestKosItemData['kos_item'] != null) {
            final kosItemMap =
                bestKosItemData['kos_item'] as Map<String, dynamic>;
            kosItemNaam = kosItemMap['kos_item_naam']?.toString() ?? 'Item';
          }

          // Create user-friendly status message
          String statusBeskrywing = _getStatusBeskrywing(
            statusNaam,
            kosItemNaam,
          );
          String tipeNaam = _getKennisgewingTipe(statusNaam);
          String titel = _getKennisgewingTitel(statusNaam);

          // Send notification (email disabled - Resend requires domain verification for production)
          await _kennisgewingRepo.skepKennisgewing(
            gebrId: gebrId,
            beskrywing: statusBeskrywing,
            tipeNaam: tipeNaam,
            titel: titel,
            stuurEmail: false, // Set to true when domain is verified on Resend
          );

          print(
            '✅ Notification and email sent to user $gebrId for status: $statusNaam',
          );
        } catch (e) {
          print('⚠️ Warning: Could not send notification/email: $e');
          // Don't rethrow - status update was successful, notification is secondary
        }
      }

      // Invalidate cache after successful update
      invalidateCache();
      print('Cache invalidated after status update');
    } catch (e, st) {
      print('Fout in updateStatus: $e\n$st');
      rethrow;
    }
  }

  /// Get a user-friendly description for the status change
  String _getStatusBeskrywing(String statusNaam, String kosItemNaam) {
    switch (statusNaam) {
      case 'In afwagting':
        return 'Jou bestelling vir "$kosItemNaam" is ontvang en word tans verwerk.';
      case 'In voorbereiding':
        return 'Jou "$kosItemNaam" word tans voorberei. Ons sal jou laat weet wanneer dit gereed is!';
      case 'Gereed vir aflewering':
        return 'Jou "$kosItemNaam" is gereed en sal binnekort afgelewer word.';
      case 'Onderweg vir aflewering':
        return 'Jou "$kosItemNaam" is onderweg! Verwag dit binnekort by jou aflaai punt.';
      case 'Gereed om opgehaal te word':
        return 'Jou "$kosItemNaam" is gereed om opgehaal te word by jou aflaai punt. Kom haal dit asseblief!';
      case 'Afgehandel':
        return 'Jou "$kosItemNaam" is suksesvol afgehandel. Geniet jou kos!';
      case 'Gekanselleer':
        return 'Jou bestelling vir "$kosItemNaam" is gekanselleer. Die geld is terugbetaal na jou beursie.';
      case 'Verstryk':
        return 'Jou bestelling vir "$kosItemNaam" is verstryk omdat dit nie opgehaal is nie. Die geld is terugbetaal na jou beursie.';
      default:
        return 'Jou bestelling vir "$kosItemNaam" se status is opgedateer na: $statusNaam';
    }
  }

  /// Get the notification type based on status
  String _getKennisgewingTipe(String statusNaam) {
    switch (statusNaam) {
      case 'Gekanselleer':
      case 'Verstryk':
        return 'waarskuwing';
      case 'Afgehandel':
      case 'Gereed om opgehaal te word':
        return 'sukses';
      case 'In afwagting':
      case 'In voorbereiding':
      case 'Gereed vir aflewering':
      case 'Onderweg vir aflewering':
        return 'info';
      default:
        return 'info';
    }
  }

  /// Get the notification title based on status
  String _getKennisgewingTitel(String statusNaam) {
    switch (statusNaam) {
      case 'In afwagting':
        return 'Bestelling Ontvang';
      case 'In voorbereiding':
        return 'Bestelling Word Voorberei';
      case 'Gereed vir aflewering':
        return 'Gereed vir Aflewering';
      case 'Onderweg vir aflewering':
        return 'Onderweg!';
      case 'Gereed om opgehaal te word':
        return 'Gereed om Op te Haal!';
      case 'Afgehandel':
        return 'Bestelling Voltooi';
      case 'Gekanselleer':
        return 'Bestelling Gekanselleer';
      case 'Verstryk':
        return 'Bestelling Verstryk';
      default:
        return 'Bestelling Status Opdatering';
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

  // Helper om kos_item id -> {naam, koste}
  Future<Map<String, Map<String, dynamic>>> _fetchKosItemMap(
    List<String> kosItemIds,
  ) async {
    if (kosItemIds.isEmpty) return {};
    final rows = await _sb
        .from('kos_item')
        .select('kos_item_id, kos_item_naam, kos_item_koste')
        .inFilter('kos_item_id', kosItemIds);

    final Map<String, Map<String, dynamic>> m = {};
    for (final r in rows) {
      if (r['kos_item_id'] != null) {
        m[r['kos_item_id'] as String] = {
          'naam': r['kos_item_naam'],
          'koste': r['kos_item_koste'],
        };
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
