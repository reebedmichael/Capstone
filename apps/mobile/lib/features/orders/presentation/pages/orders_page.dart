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
import 'dart:math' as math;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });
    _loadOrders();
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
      
      // If no orders found, create some test orders for debugging
      if (ordersData.isEmpty) {
        debugPrint('No orders found, creating test orders...');
        await _createTestOrders(user.id);
        // Reload after creating test orders
        final newOrdersData = await bestellingRepository.lysBestellings(user.id);
        debugPrint('After creating test orders: $newOrdersData');
        if (mounted) {
          setState(() {
            orders = newOrdersData;
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            orders = ordersData;
            isLoading = false;
          });
        }
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

  Future<void> _createTestOrders(String userId) async {
    try {
      // Get a kampus ID first
      final kampusData = await Supabase.instance.client
          .from('kampus')
          .select('kampus_id')
          .limit(1);
      
      if (kampusData.isEmpty) {
        debugPrint('No kampus found');
        return;
      }
      
      final kampusId = kampusData.first['kampus_id'];
      
      // Get some kos items
      final kosItemsData = await Supabase.instance.client
          .from('kos_item')
          .select('kos_item_id, kos_item_koste')
          .limit(2);
      
      if (kosItemsData.isEmpty) {
        debugPrint('No kos items found');
        return;
      }
      
      // Create test order 1
      final order1 = await Supabase.instance.client
          .from('bestelling')
          .insert({
            'gebr_id': userId,
            'kampus_id': kampusId,
            'best_volledige_prys': 45.00,
          })
          .select()
          .single();
      
      // Add items to order 1
      await Supabase.instance.client
          .from('bestelling_kos_item')
          .insert({
            'best_id': order1['best_id'],
            'kos_item_id': kosItemsData[0]['kos_item_id'],
          });
      
      // Create test order 2
      final order2 = await Supabase.instance.client
          .from('bestelling')
          .insert({
            'gebr_id': userId,
            'kampus_id': kampusId,
            'best_volledige_prys': 55.00,
          })
          .select()
          .single();
      
      // Add items to order 2
      if (kosItemsData.length > 1) {
        await Supabase.instance.client
            .from('bestelling_kos_item')
            .insert({
              'best_id': order2['best_id'],
              'kos_item_id': kosItemsData[1]['kos_item_id'],
            });
      }
      
      debugPrint('Test orders created successfully');
    } catch (e) {
      debugPrint('Error creating test orders: $e');
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
          .select('best_id, item_hoev, kos_item:kos_item_id(kos_item_koste)')
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
      for (final it in items) {
        final statuses = (it['best_kos_item_statusse'] as List? ?? []);
        final String? lastStatus = statuses.isNotEmpty
            ? ((statuses.last['kos_item_statusse'] as Map<String, dynamic>? ?? {})['kos_stat_naam'] as String?)
            : null;
        final bool isCompletedItem = lastStatus == 'Afgehandel' || lastStatus == 'Gekanselleer';
        if (!forCompletedTab && !isCompletedItem) return true;
        if (forCompletedTab && isCompletedItem) return true;
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
        // Track earliest cutoff among all items (based on kos_item -> spyskaart_kos_item)
        final kosItem = item['kos_item'] as Map<String, dynamic>? ?? {};
        final List skItems = (kosItem['spyskaart_kos_item'] as List? ?? []);
        for (final sk in skItems) {
          final String? iso = (sk['spyskaart_kos_afsny_datum'] as String?);
          if (iso == null) continue;
          final dt = DateTime.tryParse(iso);
          if (dt == null) continue;
          if (cutoffForTab == null || dt.isBefore(cutoffForTab)) cutoffForTab = dt;
        }
        break;
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
            const SizedBox(height: 8),
            if (cutoffForTab != null)
              Row(
                children: [
                  const Icon(FeatherIcons.calendar, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Afsny: ${formatDate(cutoffForTab)}',
                    style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
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

                // Compute cutoff date for this specific item via kos_item -> spyskaart_kos_item
                DateTime? itemCutoff;
                final List skItemsForThis = (food['spyskaart_kos_item'] as List? ?? []);
                for (final sk in skItemsForThis) {
                  final String? iso = (sk['spyskaart_kos_afsny_datum'] as String?);
                  if (iso == null) continue;
                  final dt = DateTime.tryParse(iso);
                  if (dt == null) continue;
                  if (itemCutoff == null || dt.isBefore(itemCutoff)) itemCutoff = dt;
                }

                // Hide/show items according to current tab
                if (_tabController.index == 0 && isCompletedItem) {
                  return const SizedBox.shrink();
                }
                if (_tabController.index == 1 && !isCompletedItem) {
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
                                const SizedBox(height: 2),
                                Text(
                                  'ID: ${item['best_kos_id'] ?? ''}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                  overflow: TextOverflow.ellipsis,
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
                                  color: _statusColor(lastStatus ?? ''),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      lastStatus ?? 'Onbekend',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                    if (lastUpdated != null) ...[
                                      const SizedBox(width: 6),
                                      Text(
                                        formatDate(lastUpdated),
                                        style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic),
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
