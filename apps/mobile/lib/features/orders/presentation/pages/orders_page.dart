import 'package:capstone_mobile/features/app/presentation/widgets/app_bottom_nav.dart';
import 'package:capstone_mobile/features/feedback/presentation/widgets/item_feedback_widget.dart';
import 'package:capstone_mobile/features/qr/presentation/pages/qr_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:capstone_mobile/core/theme/app_typography.dart';
import 'package:spys_api_client/spys_api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../locator.dart';
import '../../../../shared/state/order_refresh_notifier.dart';
import 'dart:math' as math;
import 'dart:async';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool refreshing = false;
  bool isLoading = true;

  List<Map<String, dynamic>> orders = [];
  StreamSubscription? _orderStatusSubscription;
  StreamSubscription? _globalRefreshSubscription;
  Map<String, DateTime> _kosItemIdToCutoff = {};
  Map<String, DateTime> _kosItemDayToCutoff = {}; // key: "<kos_item_id>|<dayLower>"
  String? _currentSpyskaartNaam;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadOrders();
    _loadCurrentWeekSpyskaartWeekdays();
    _setupOrderStatusListener();
    _setupGlobalRefreshListener();
  }

  @override
  void dispose() {
    _orderStatusSubscription?.cancel();
    _globalRefreshSubscription?.cancel();
    super.dispose();
  }

  DateTime _getCurrentWeekStart() {
    final now = DateTime.now();
    final weekday = now.weekday; // Monday = 1
    final daysToSubtract = weekday - 1;
    return DateTime(now.year, now.month, now.day - daysToSubtract);
  }

  Future<void> _loadCurrentWeekSpyskaartWeekdays() async {
    try {
      final weekStart = _getCurrentWeekStart();
      final spyskaartRepo = sl<SpyskaartRepository>();
      final spyskaart = await spyskaartRepo.getAktieweSpyskaart(weekStart);
      final Map<String, DateTime> cutoffMap = {};
      final Map<String, DateTime> cutoffByItemDay = {};
      final List<dynamic> items = (spyskaart?['spyskaart_kos_item'] as List? ?? []);
      for (final dynamic raw in items) {
        final Map<String, dynamic> row = Map<String, dynamic>.from(raw as Map);
        final Map<String, dynamic> kos = Map<String, dynamic>.from(row['kos_item'] ?? {});
        final String? kosItemId = kos['kos_item_id']?.toString();
        String? dayName = (row['week_dag_naam'] as String?);
        if (dayName == null || dayName.isEmpty) {
          final Map<String, dynamic>? weekDagMap = row['week_dag'] as Map<String, dynamic>?;
          dayName = weekDagMap != null ? weekDagMap['week_dag_naam'] as String? : null;
        }

        // Capture cutoff from the same spyskaart_kos_item record
        if (kosItemId != null) {
          final String? iso = row['spyskaart_kos_afsny_datum'] as String?;
          final DateTime? dt = iso != null ? DateTime.tryParse(iso) : null;
          if (dt != null) {
            if (!cutoffMap.containsKey(kosItemId) || dt.isBefore(cutoffMap[kosItemId]!)) {
              cutoffMap[kosItemId] = dt;
            }
            // Also capture per day mapping for precise correlation
            final String? dayLower = dayName?.toLowerCase();
            if (dayLower != null && dayLower.isNotEmpty) {
              cutoffByItemDay['$kosItemId|$dayLower'] = dt;
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          _kosItemIdToCutoff = cutoffMap;
          _kosItemDayToCutoff = cutoffByItemDay;
          _currentSpyskaartNaam = (spyskaart?['spyskaart_naam'] as String?)?.toString();
        });
      }
    } catch (e) {
      debugPrint('Error loading spyskaart weekdays: $e');
    }
  }

  void _setupOrderStatusListener() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Listen for changes to the user's orders
    _orderStatusSubscription = Supabase.instance.client
        .from('bestelling')
        .stream(primaryKey: ['best_id'])
        .eq('gebr_id', user.id)
        .listen((data) {
      // When orders change, refresh the orders
      debugPrint('Orders changed, refreshing...');
      _loadOrders();
      
    });

    // Note: Removed problematic stream listener for notifications
    // The global refresh notifier will handle updates instead
  }

  void _setupGlobalRefreshListener() {
    // Listen for global refresh events
    _globalRefreshSubscription = OrderRefreshNotifier().refreshStream.listen((_) {
      debugPrint('Global refresh triggered, reloading orders...');
      _loadOrders();
      
      if (mounted) {
        Fluttertoast.showToast(
          msg: 'Bestelling opdateer!',
          backgroundColor: Colors.green,
        );
      }
    });
  }

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')} "
        "${_monthName(date.month)} "
        "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  String _monthName(int month) {
    const months = [
      "Jan",
      "Feb",
      "Mrt",
      "Apr",
      "Mei",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Okt",
      "Nov",
      "Des",
    ];
    return months[month - 1];
  }

  String _weekdayNameAfrikaans(int weekday) {
    const days = ['Maandag', 'Dinsdag', 'Woensdag', 'Donderdag', 'Vrydag', 'Saterdag', 'Sondag'];
    return days[(weekday - 1).clamp(0, 6)];
  }

  DateTime? _computeCutoffFromBestDatum(String? bestDatumIso) {
    if (bestDatumIso == null || bestDatumIso.isEmpty) return null;
    final DateTime? bestDatumParsed = DateTime.tryParse(bestDatumIso);
    if (bestDatumParsed == null) return null;
    final DateTime bestLocal = bestDatumParsed;
    final DateTime prevDay = bestLocal.subtract(const Duration(days: 1));
    return DateTime(prevDay.year, prevDay.month, prevDay.day, 17, 0);
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    
    try {
      final user = Supabase.instance.client.auth.currentUser;
      debugPrint('Current user: ${user?.id}');
      
      if (user == null) {
        debugPrint('No user found');
        if (mounted) {
          setState(() {
            orders = [];
            isLoading = false;
          });
        }
        return;
      }

      // Try direct Supabase call first to see if the data exists
      final directData = await Supabase.instance.client
          .from('bestelling')
          .select('*')
          .eq('gebr_id', user.id)
          .order('best_geskep_datum', ascending: false);
      
      debugPrint('Direct Supabase data: $directData');
      
      // Also try repository method
      final bestellingRepository = sl<BestellingRepository>();
      final ordersData = await bestellingRepository.lysBestellings(user.id);
      
      debugPrint('Repository data: $ordersData');
      if (mounted) {
        setState(() {
          orders = ordersData;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
      if (mounted) {
        setState(() {
          orders = [];
          isLoading = false;
        });
        Fluttertoast.showToast(msg: 'Fout met laai van bestellings: $e');
      }
    }
  }

  

  void handleRefresh() {
    if (!mounted) return;
    setState(() => refreshing = true);
    _loadOrders().then((_) {
      if (mounted) {
        setState(() => refreshing = false);
      }
    });
  }

  Future<bool> cancelOrder(String orderId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return false;

      // Get the status ID for "Gekanselleer"
      final statusData = await Supabase.instance.client
          .from('kos_item_statusse')
          .select('kos_stat_id')
          .eq('kos_stat_naam', 'Gekanselleer')
          .single();

      // Get all bestelling_kos_item records for this order
      final orderItems = await Supabase.instance.client
          .from('bestelling_kos_item')
          .select('best_kos_id')
          .eq('best_id', orderId);

      // Update status for all items in the order
      for (final item in orderItems) {
        await Supabase.instance.client
            .from('best_kos_item_statusse')
            .insert({
              'best_kos_id': item['best_kos_id'],
              'kos_stat_id': statusData['kos_stat_id'],
            });
      }

      // Reload orders to get updated data
      await _loadOrders();
      
      Fluttertoast.showToast(msg: 'Bestelling gekanselleer');
      return true;
    } catch (e) {
      debugPrint('Error cancelling order: $e');
      Fluttertoast.showToast(msg: 'Fout met kansellasie van bestelling');
      return false;
    }
  }

  Future<bool> cancelOrderItem(String bestKosId) async {
    try {
      final sb = Supabase.instance.client;

      // 1) Lookup status id for 'Gekanselleer'
      final statusData = await sb
          .from('kos_item_statusse')
          .select('kos_stat_id')
          .eq('kos_stat_naam', 'Gekanselleer')
          .single();

      // 2) Load item details to compute refund and find parent order id
      final itemRow = await sb
          .from('bestelling_kos_item')
          .select('best_id, best_datum, item_hoev, kos_item_id, kos_item:kos_item_id(kos_item_koste)')
          .eq('best_kos_id', bestKosId)
          .maybeSingle();

      if (itemRow == null) {
        throw Exception('Kon nie item vind nie');
      }

      final String bestId = itemRow['best_id'].toString();
      final int qty = (itemRow['item_hoev'] as int?) ?? 1;
      final Map<String, dynamic> kosItemMap =
          Map<String, dynamic>.from(itemRow['kos_item'] ?? {});
      final num unitPrice = (kosItemMap['kos_item_koste'] as num?) ?? 0;
      final double cancelAmount = (unitPrice * qty).toDouble();

      // 2b) Enforce cutoff: compute from bestelling_kos_item.best_datum (previous day 17:00)
      try {
        final String? bestDatumIso = itemRow['best_datum'] as String?;
        final DateTime? computedCutoff = _computeCutoffFromBestDatum(bestDatumIso);
        if (computedCutoff != null && DateTime.now().isAfter(computedCutoff)) {
          Fluttertoast.showToast(msg: 'Kansellasie na afsny tyd is nie toegelaat nie');
          return false;
        }
        // Fallback to previous mapping if best_datum is missing or unparsable
        if (computedCutoff == null) {
          final String? kosItemIdStr = itemRow['kos_item_id']?.toString();
          if (kosItemIdStr != null) {
            if (_kosItemDayToCutoff.isEmpty && _kosItemIdToCutoff.isEmpty) {
              await _loadCurrentWeekSpyskaartWeekdays();
            }
            final DateTime? mappedCutoff = _kosItemIdToCutoff[kosItemIdStr];
            if (mappedCutoff != null && DateTime.now().isAfter(mappedCutoff)) {
              Fluttertoast.showToast(msg: 'Kansellasie na afsny tyd is nie toegelaat nie');
              return false;
            }
          }
        }
      } catch (_) {}

      // 3) Insert status row with updated timestamp
      await sb.from('best_kos_item_statusse').insert({
        'best_kos_id': bestKosId,
        'kos_stat_id': statusData['kos_stat_id'],
        'best_kos_wysig_datum': DateTime.now().toIso8601String(),
      });

      // 4) Subtract item value from bestelling.total
      final bestellingRow = await sb
          .from('bestelling')
          .select('best_volledige_prys')
          .eq('best_id', bestId)
          .single();

      final double currentTotal =
          (bestellingRow['best_volledige_prys'] as num?)?.toDouble() ?? 0.0;
      final double newTotal = math.max(0.0, currentTotal - cancelAmount);

      await sb
          .from('bestelling')
          .update({'best_volledige_prys': newTotal})
          .eq('best_id', bestId);

      // 5) Refund the item's value to the user's wallet
      final String? userId = sb.auth.currentUser?.id;
      if (userId != null && cancelAmount > 0) {
        final refunded = await sl<BeursieRepository>()
            .laaiBeursieOp(userId, cancelAmount, 'kansellasie');
        if (!refunded) {
          debugPrint('Kon nie beursie terugbetaling verwerk nie');
        }
      }

      await _loadOrders();
      Fluttertoast.showToast(msg: 'Item gekanselleer');
      return true;
    } catch (e) {
      debugPrint('Error cancelling item: $e');
      Fluttertoast.showToast(msg: 'Fout met kansellasie van item');
      return false;
    }
  }

  void handleCancelOrderItem(String bestKosId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Bevestig kansellasie'),
        content: const Text('Is jy seker jy wil hierdie item kanselleer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nee'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await cancelOrderItem(bestKosId);
            },
            child: const Text('Ja'),
          ),
        ],
      ),
    );
  }

  void handleCancelOrder(String orderId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Bevestig kansellasie"),
        content: const Text(
          "Is jy seker jy wil hierdie bestelling kanselleer? Die geld sal na jou beursie terugbetaal word.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Nee"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await cancelOrder(orderId);
            },
            child: const Text("Ja"),
          ),
        ],
      ),
    );
  }

  bool canCancelOrder(Map<String, dynamic> order) {
    final status = _getOrderStatus(order);
    // Only allow cancellation for orders that are NOT "Wag vir afhaal" and are in active statuses
    return status != 'Wag vir afhaal' && status != 'Afgehandel' && status != 'Gekanselleer';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Wag vir afhaal':
        return Theme.of(context).colorScheme.errorContainer;
      case 'In voorbereiding':
        return Theme.of(context).colorScheme.primaryContainer;
      case 'Afgehandel':
        return Theme.of(context).colorScheme.tertiaryContainer;
      case 'Gekanselleer':
        return Theme.of(context).colorScheme.errorContainer;
      case 'Verstryk':
        return Colors.red.shade100;
      default:
        return Theme.of(context).colorScheme.surfaceVariant;
    }
  }

  

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
        bottomNavigationBar: AppBottomNav(currentIndex: 1),
      );
    }

    bool hasVisibleForTab(Map<String, dynamic> order, bool forCompletedTab) {
      final List items = (order['bestelling_kos_item'] as List? ?? []);
      final today = DateTime.now();
      final todayDate = DateTime(today.year, today.month, today.day);
      
      for (final it in items) {
        final statuses = (it['best_kos_item_statusse'] as List? ?? []);
        final String? lastStatus = statuses.isNotEmpty
            ? ((statuses.last['kos_item_statusse'] as Map<String, dynamic>? ?? {})['kos_stat_naam'] as String?)
            : null;
        final bool isCompletedItem = lastStatus == 'Afgehandel' || lastStatus == 'Gekanselleer';
        
        // Check if this item is past its due date
        final bestDatumStr = it['best_datum'] as String?;
        bool isPastDue = false;
        if (bestDatumStr != null) {
          try {
            final bestDatum = DateTime.parse(bestDatumStr);
            final orderDate = DateTime(bestDatum.year, bestDatum.month, bestDatum.day);
            isPastDue = orderDate.isBefore(todayDate);
          } catch (e) {
            // If date parsing fails, don't consider it past due
            isPastDue = false;
          }
        }
        
        // Item should be in completed tab if it's completed OR past due
        final bool shouldBeInCompletedTab = isCompletedItem || isPastDue;
        
        if (!forCompletedTab && !shouldBeInCompletedTab) return true;
        if (forCompletedTab && shouldBeInCompletedTab) return true;
      }
      return false;
    }

    final activeOrders = orders.where((o) => hasVisibleForTab(o, false)).toList();
    final completedOrders = orders.where((o) => hasVisibleForTab(o, true)).toList();

    final displayedOrders = _tabController.index == 0 ? activeOrders : completedOrders;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bestellings'),
        actions: [
          IconButton(
            onPressed: refreshing ? null : handleRefresh,
            icon: refreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(FeatherIcons.refreshCcw),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => setState(() {}),
          tabs: [
            Tab(text: 'Bestellings (${activeOrders.length})'),
            Tab(text: 'Voltooi (${completedOrders.length})'),
          ],
        ),
      ),
      body: displayedOrders.isEmpty
          ? _buildEmptyState(_tabController.index == 0)
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: displayedOrders.length,
              itemBuilder: (_, index) {
                final order = displayedOrders[index];
                return _buildOrderCard(order);
              },
            ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }

  String _getOrderStatus(Map<String, dynamic> order) {
    try {
      final items = order['bestelling_kos_item'] as List? ?? [];
      if (items.isEmpty) return 'Wag vir afhaal';
      
      // Check if any item has a status
      for (final item in items) {
        final statuses = item['best_kos_item_statusse'] as List? ?? [];
        if (statuses.isNotEmpty) {
          final latestStatus = statuses.last;
          final statusInfo = latestStatus['kos_item_statusse'] as Map<String, dynamic>? ?? {};
          final statusName = statusInfo['kos_stat_naam'] as String? ?? '';
          if (statusName.isNotEmpty) {
            return statusName;
          }
        }
      }
      
      return 'Wag vir afhaal';
    } catch (e) {
      debugPrint('Error getting order status: $e');
      return 'Wag vir afhaal';
    }
  }


  String _getOrderTitle(Map<String, dynamic> order) {
    try {
      final items = order['bestelling_kos_item'] as List? ?? [];
      if (items.isEmpty) {
        final bestId = order['best_id']?.toString() ?? '';
        return 'Bestelling #${bestId.length > 8 ? bestId.substring(0, 8) : bestId}...';
      }
      
      // Get the first item's name
      final firstItem = items.first;
      final kosItem = firstItem['kos_item'] as Map<String, dynamic>? ?? {};
      final itemName = kosItem['kos_item_naam'] as String? ?? 'Onbekende item';
      
      if (items.length == 1) {
        return itemName;
      } else {
        return '$itemName + ${items.length - 1} ander';
      }
    } catch (e) {
      debugPrint('Error getting order title: $e');
      final bestId = order['best_id']?.toString() ?? '';
      return 'Bestelling #${bestId.length > 8 ? bestId.substring(0, 8) : bestId}...';
    }
  }

  String _getKampusName(Map<String, dynamic> order) {
    try {
      final kampus = order['kampus'] as Map<String, dynamic>?;
      return kampus?['kampus_naam'] as String? ?? 'Onbekende lokasie';
    } catch (e) {
      debugPrint('Error getting kampus name: $e');
      return 'Onbekende lokasie';
    }
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    // Only render this order if it has items visible in the current tab
    final List<dynamic> orderItems = (order['bestelling_kos_item'] as List? ?? []);
    bool anyVisible = false;
    DateTime? cutoffForTab; // earliest cutoff across items in this bestelling
    for (final item in orderItems) {
      final statuses = (item['best_kos_item_statusse'] as List? ?? []);
      final String? lastStatus = statuses.isNotEmpty
          ? ((statuses.last['kos_item_statusse'] as Map<String, dynamic>? ?? {})['kos_stat_naam'] as String?)
          : null;
      final bool isCompletedItem = lastStatus == 'Afgehandel' || lastStatus == 'Gekanselleer';
      if ((_tabController.index == 0 && !isCompletedItem) || (_tabController.index == 1 && isCompletedItem)) {
        anyVisible = true;
        // Compute cutoff based on the item's best_datum: previous day at 17:00
        final String? bestDatumIso = item['best_datum'] as String?;
        final DateTime? computed = _computeCutoffFromBestDatum(bestDatumIso);
        if (computed != null) {
          if (cutoffForTab == null || computed.isBefore(cutoffForTab)) {
            cutoffForTab = computed;
          }
        }
        // Do not break; ensure we find the earliest cutoff across visible items
      }
    }
    if (!anyVisible) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getOrderTitle(order),
                        style: AppTypography.labelLarge.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(FeatherIcons.clock, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            formatDate(DateTime.parse(order['best_geskep_datum'] ?? DateTime.now().toIso8601String())),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'R${order['best_volledige_prys'].toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            // Pickup
            Row(
              children: [
                const Icon(FeatherIcons.mapPin, size: 14),
                const SizedBox(width: 6),
                Text(
                  _getKampusName(order),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            if (_currentSpyskaartNaam != null && _currentSpyskaartNaam!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(FeatherIcons.bookOpen, size: 14),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _currentSpyskaartNaam!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            const SizedBox(height: 12),
            // Items
            Column(
              children: (order['bestelling_kos_item'] as List? ?? []).map<Widget>((item) {
                final food = item['kos_item'] ?? {};
                final statuses = (item['best_kos_item_statusse'] as List? ?? []);
                final String? lastStatus = statuses.isNotEmpty
                    ? ((statuses.last['kos_item_statusse'] as Map<String, dynamic>? ?? {})['kos_stat_naam'] as String?)
                    : null;
                // Extract last updated timestamp (best_kos_wysig_datum) if available
                DateTime? lastUpdated;
                if (statuses.isNotEmpty) {
                  final String? iso = statuses.last['best_kos_wysig_datum'] as String?;
                  if (iso != null) {
                    final parsed = DateTime.tryParse(iso);
                    if (parsed != null) {
                      lastUpdated = parsed;
                    }
                  }
                }
                final bool isCompletedItem = lastStatus == 'Afgehandel' || lastStatus == 'Gekanselleer';

                // Determine week day label solely from bestelling_kos_item.best_datum
                String? weekDagNaam;
                final String? bestDatumStr = item['best_datum'] as String?;
                final DateTime? bestDatum = bestDatumStr != null ? DateTime.tryParse(bestDatumStr) : null;
                if (bestDatum != null) {
                  weekDagNaam = _weekdayNameAfrikaans(bestDatum.weekday);
                }

                // Compute cutoff date from bestelling_kos_item.best_datum: previous day at 17:00
                DateTime? itemCutoff = _computeCutoffFromBestDatum(item['best_datum'] as String?);

                // Check if this item is past its due date
                final itemBestDatumStr = item['best_datum'] as String?;
                bool isPastDue = false;
                if (itemBestDatumStr != null) {
                  try {
                    final bestDatum = DateTime.parse(itemBestDatumStr);
                    final today = DateTime.now();
                    final orderDate = DateTime(bestDatum.year, bestDatum.month, bestDatum.day);
                    final todayDate = DateTime(today.year, today.month, today.day);
                    isPastDue = orderDate.isBefore(todayDate);
                  } catch (e) {
                    isPastDue = false;
                  }
                }
                
                // Item should be in completed tab if it's completed OR past due
                final bool shouldBeInCompletedTab = isCompletedItem || isPastDue;
                
                // Hide/show items according to current tab
                if (_tabController.index == 0 && shouldBeInCompletedTab) {
                  return const SizedBox.shrink();
                }
                if (_tabController.index == 1 && !shouldBeInCompletedTab) {
                  return const SizedBox.shrink();
                }
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child:
                                (food['kos_item_prentjie'] != null &&
                                    (food['kos_item_prentjie'] as String).isNotEmpty)
                                ? Image.network(
                                    food['kos_item_prentjie'] as String,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 48,
                                    height: 48,
                                    color: Theme.of(context).colorScheme.outline,
                                    alignment: Alignment.center,
                                    child: const Icon(Icons.fastfood, size: 20),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  food['kos_item_naam'] ?? '',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                Text(
                                  '${item['item_hoev'] ?? 1} x R${food['kos_item_koste']}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (weekDagNaam != null) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Dag: $weekDagNaam',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                if (itemCutoff != null) ...[
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      const Icon(FeatherIcons.calendar, size: 10),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Afsny: ${formatDate(itemCutoff)}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 2),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Text(
                                    'ID: ${item['best_kos_id'] ?? ''}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                    softWrap: false,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'R${((food['kos_item_koste'] as num? ?? 0.0) * (item['item_hoev'] as int? ?? 1)).toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isPastDue ? Colors.red.shade100 : _statusColor(lastStatus ?? ''),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      isPastDue ? 'Verstryk' : (lastStatus ?? 'Onbekend'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: _tabController.index == 1 ? Colors.white : null,
                                      ),
                                    ),
                                    if (lastUpdated != null) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        formatDate(lastUpdated),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: _tabController.index == 1 ? Colors.white : null,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              if (_tabController.index == 0 && !(cutoffForTab != null && DateTime.now().isAfter(cutoffForTab)) && !(lastStatus == 'Afgehandel' || lastStatus == 'Gekanselleer'))
                                OutlinedButton(
                                  onPressed: () {
                                    if (lastStatus == 'Afgehandel' || lastStatus == 'Gekanselleer') return;
                                    if (cutoffForTab != null && DateTime.now().isAfter(cutoffForTab)) return;
                                    // Hide cancel if the item's cutoff is in the past
                                    if (itemCutoff != null && DateTime.now().isAfter(itemCutoff)) {
                                      return;
                                    }
                                    final bestKosId = item['best_kos_id']?.toString();
                                    if (bestKosId != null) {
                                      handleCancelOrderItem(bestKosId);
                                    }
                                  },
                                  child: const Text('Kanselleer'),
                                ),
                            ],
                          ),
                        ],
                      ),
                      // Add feedback widget for completed items
                      if (isCompletedItem && lastStatus == 'Afgehandel') ...[
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        ItemFeedbackWidget(
                          bestellingKosItem: item,
                          onFeedbackUpdated: (updatedItem) {
                            // Update the item in the orders list
                            final orderIdx = orders.indexWhere(
                              (o) => o['best_id'] == order['best_id'],
                            );
                            if (orderIdx != -1) {
                              final itemIdx = (orders[orderIdx]['bestelling_kos_item'] as List).indexWhere(
                                (i) => i['best_kos_id'] == updatedItem['best_kos_id'],
                              );
                              if (itemIdx != -1) {
                                setState(() {
                                  (orders[orderIdx]['bestelling_kos_item'] as List)[itemIdx] = updatedItem;
                                });
                              }
                            }
                          },
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),


            // Order Actions
            const Divider(height: 20),
            Row(
              children: [
                if (_tabController.index == 0)
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : null,
                      ),
                      icon: const Icon(FeatherIcons.smartphone, size: 16),
                      label: const Text('Wys QR Kode'),
                      onPressed: () async {
                        final updatedOrder =
                            await Navigator.push<Map<String, dynamic>>(
                              context,
                              MaterialPageRoute(
                                builder: (context) => QrPage(order: order),
                              ),
                            );

                        if (updatedOrder != null) {
                          final idx = orders.indexWhere(
                            (o) => o['best_id'] == updatedOrder['best_id'],
                          );
                          if (idx != -1) {
                            setState(() {
                              orders[idx] = {...orders[idx], ...updatedOrder};
                            });
                          }
                        }
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool activeTab) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(FeatherIcons.package, size: 56, color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              'Geen ${activeTab ? 'aktiewe' : 'voltooide'} bestellings',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              activeTab
                  ? 'Jou aktiewe bestellings sal hier verskyn'
                  : 'Jou voltooide bestellings sal hier verskyn',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (activeTab)
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Begin Bestel'),
              ),
          ],
        ),
      ),
    );
  }
}
