import 'package:capstone_mobile/features/app/presentation/widgets/app_bottom_nav.dart';
import 'package:capstone_mobile/features/feedback/presentation/pages/feedback_page.dart';
import 'package:capstone_mobile/features/qr/presentation/pages/qr_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:capstone_mobile/core/theme/app_typography.dart';
import 'package:spys_api_client/spys_api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../locator.dart';

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
        Fluttertoast.showToast(msg: "Bestellings opgedateer");
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
        return Colors.orange.shade100;
      case 'In voorbereiding':
        return Colors.blue.shade100;
      case 'Afgehandel':
        return Colors.green.shade100;
      case 'Gekanselleer':
        return Colors.red.shade100;
      default:
        return Colors.grey.shade200;
    }
  }

  Icon _statusIcon(String status) {
    switch (status) {
      case 'Wag vir afhaal':
        return const Icon(FeatherIcons.package, color: Colors.orange, size: 16);
      case 'In voorbereiding':
        return const Icon(FeatherIcons.clock, color: Colors.blue, size: 16);
      case 'Afgehandel':
        return const Icon(
          FeatherIcons.checkCircle,
          color: Colors.green,
          size: 16,
        );
      case 'Gekanselleer':
        return const Icon(FeatherIcons.circle, color: Colors.red, size: 16);
      default:
        return const Icon(FeatherIcons.package, size: 16);
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

    // Filter orders based on their actual status
    final activeOrders = orders.where((order) {
      final status = _getOrderStatus(order);
      return status != 'Afgehandel' && status != 'Gekanselleer';
    }).toList();
    
    final completedOrders = orders.where((order) {
      final status = _getOrderStatus(order);
      return status == 'Afgehandel' || status == 'Gekanselleer';
    }).toList();

    final displayedOrders = _tabController.index == 0
        ? activeOrders
        : completedOrders;

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

  Widget _buildOrderCard(Map<String, dynamic> order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                            formatDate(DateTime.parse(order['best_geskep_datum'])),
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
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _statusColor(_getOrderStatus(order)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _statusIcon(_getOrderStatus(order)),
                            const SizedBox(width: 6),
                            Text(
                              _getOrderStatus(order),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
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
                  'Kafetaria', // TODO: Get actual pickup location from database
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Items
            Column(
              children: (order['bestelling_kos_item'] as List? ?? []).map<Widget>((item) {
                final food = item['kos_item'] ?? {};
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
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
                                color: Colors.grey.shade300,
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
                          ],
                        ),
                      ),
                      Text(
                        'R${((food['kos_item_koste'] as num? ?? 0.0) * (item['item_hoev'] as int? ?? 1)).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            // Feedback for completed orders
            if (_getOrderStatus(order) == 'Afgehandel') ...[
              const Divider(height: 20),
              FeedbackPage(
                order: order,
                onFeedbackUpdated: (updatedOrder) {
                  final idx = orders.indexWhere(
                    (o) => o['best_id'] == updatedOrder['best_id'],
                  );
                  if (idx != -1) {
                    setState(() {
                      orders[idx] = updatedOrder;
                    });
                  }
                },
              ),
            ],

            // Order Actions
            const Divider(height: 20),
            Row(
              children: [
                if (_getOrderStatus(order) == 'Wag vir afhaal')
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
                const SizedBox(width: 8),
                // Only show cancel button in the "Bestellings" tab (index 0) and for cancellable orders
                if (_tabController.index == 0 && canCancelOrder(order))
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(FeatherIcons.alertCircle, size: 16),
                      label: const Text('Kanselleer'),
                      onPressed: () => handleCancelOrder(order['best_id']),
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
            const Icon(FeatherIcons.package, size: 56, color: Colors.grey),
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
              style: const TextStyle(color: Colors.grey),
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
