import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart' show SupabaseDb;
import 'package:spys_api_client/src/admin_bestellings_repository.dart';
import '../../../shared/types/order.dart';
import '../../../shared/utils/status_utils.dart';
import '../../../shared/widgets/Bestellings/order_search.dart';
import '../../../shared/widgets/Bestellings/day_filter_orders.dart';
import '../../../shared/widgets/Bestellings/day_item_summary.dart';
import '../../../shared/widgets/Bestellings/order_card.dart';
import '../../../shared/widgets/Bestellings/order_details.dart';
import '../../../shared/widgets/Bestellings/bulk_actions.dart';

// const String CURRENT_DAY = "Donderdag";
String _getCurrentDayInAfrikaans() {
  const dayNames = {
    1: "Maandag",
    2: "Dinsdag",
    3: "Woensdag",
    4: "Donderdag",
    5: "Vrydag",
    6: "Saterdag",
    7: "Sondag",
  };

  return dayNames[DateTime.now().weekday] ?? "Onbekend";
}

class BestellingBestuurPage extends StatefulWidget {
  const BestellingBestuurPage({super.key});

  @override
  State<BestellingBestuurPage> createState() => _BestellingBestuurPageState();
}

class _BestellingBestuurPageState extends State<BestellingBestuurPage> {
  List<Order> orders = [];
  bool _isLoading = true;
  String? _error;
  late final AdminBestellingRepository _repo;
  String searchQuery = "";
  String selectedDay = _getCurrentDayInAfrikaans();
  String selectedFoodItem = "";

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _repo = AdminBestellingRepository(SupabaseDb(client));
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final rows = await _repo.getBestellings();
      final loaded = rows.map(_mapApiOrderToModel).whereType<Order>().toList();
      setState(() {
        orders
          ..clear()
          ..addAll(loaded);
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Map repository result to local UI model
  Order? _mapApiOrderToModel(Map<String, dynamic> row) {
    try {
      final bestId = row['best_id'];
      final idStr = bestId?.toString() ?? '';
      final email = (row['gebr_epos'] as String?) ?? 'onbekend@epos';
      final createdAtRaw = row['best_geskep_datum'];
      DateTime createdAt;
      try {
        createdAt = DateTime.parse(
          createdAtRaw?.toString() ?? DateTime.now().toIso8601String(),
        );
      } catch (_) {
        createdAt = DateTime.now();
      }
      final total = (row['best_volledige_prys'] as num?)?.toDouble() ?? 0.0;

      final itemsRaw =
          (row['kos_items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      final items = <OrderItem>[];
      final scheduledDays = <String>{};

      for (final it in itemsRaw) {
        final name = (it['kos_item_naam'] as String?) ?? 'Item';
        final qty = (it['item_hoev'] as num?)?.toInt() ?? 1;
        final weekdag = (it['weekdag'] as String?) ?? '';
        final statusNames =
            (it['statusse'] as List?)?.whereType<String>().toList() ?? const [];
        final status = _pickStatusFromNames(statusNames);
        final bestKosId = (it['best_kos_id']?.toString()) ?? '';
        scheduledDays.add(weekdag);
        items.add(
          OrderItem(
            id: bestKosId,
            name: name,
            quantity: qty,
            price: 0.0, // price not provided by API
            status: status,
            scheduledDay: weekdag,
          ),
        );
      }

      // Derive overall status from items
      final overallStatus = _recalcOrderStatus(items);

      return Order(
        id: idStr,
        customerEmail: email,
        items: items,
        scheduledDays: scheduledDays.where((d) => d.isNotEmpty).toList(),
        status: overallStatus,
        createdAt: createdAt,
        totalAmount: total,
        deliveryPoint: (row['kampus_naam'] as String?) ?? '',
      );
    } catch (_) {
      return null;
    }
  }

  OrderStatus _pickStatusFromNames(List<String> names) {
    // Precedence order from lowest to highest progression
    const precedence = <OrderStatus>[
      OrderStatus.pending,
      OrderStatus.preparing,
      OrderStatus.readyDelivery,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
      OrderStatus.readyFetch,
      OrderStatus.done,
      OrderStatus.cancelled,
    ];

    OrderStatus mapOne(String n) {
      final s = n.toLowerCase();
      if (s.contains('kansel') || s.contains('cancel'))
        return OrderStatus.cancelled;
      if (s.contains('afgehandel') || s == 'done') return OrderStatus.done;
      if (s.contains('afleweringspunt') ||
          s.contains('afgelewer') ||
          s.contains('delivered')) {
        return OrderStatus.delivered;
      }
      if (s.contains('uit vir aflewering') || s.contains('out for')) {
        return OrderStatus.outForDelivery;
      }
      if (s.contains('gereed vir aflewering') || s.contains('ready delivery')) {
        return OrderStatus.readyDelivery;
      }
      if (s.contains('reg vir afhaal') ||
          s.contains('ready fetch') ||
          s.contains('pickup')) {
        return OrderStatus.readyFetch;
      }
      if ((s.contains('voorbereiding')) || (s.contains('prepar')))
        return OrderStatus.preparing;
      if (s.contains('ontvang') || s.contains('pending'))
        return OrderStatus.pending;
      return OrderStatus.pending;
    }

    if (names.isEmpty) return OrderStatus.pending;
    final mapped = names.map(mapOne).toSet();
    // choose highest precedence (last index)
    OrderStatus best = OrderStatus.pending;
    int bestIdx = -1;
    for (final st in mapped) {
      final idx = precedence.indexOf(st);
      if (idx > bestIdx) {
        bestIdx = idx;
        best = st;
      }
    }
    return best;
  }

  // Filtering logic
  List<Order> get filteredOrders {
    if (selectedDay == "Geskiedenis") {
      return orders.where((order) => order.status == OrderStatus.done).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return orders
        .map((order) {
          final dayItems = order.items
              .where((item) => item.scheduledDay == selectedDay)
              .toList();

          var filteredDayItems = dayItems;
          if (selectedFoodItem.isNotEmpty) {
            filteredDayItems = filteredDayItems
                .where((item) => item.name == selectedFoodItem)
                .toList();
          }

          if (filteredDayItems.isEmpty) return null;

          final dayTotalAmount = filteredDayItems.fold<double>(
            0,
            (sum, item) => sum + item.price * item.quantity,
          );

          final statuses = filteredDayItems.map((i) => i.status).toList();
          OrderStatus dayStatus = OrderStatus.pending;

          if (statuses.every((s) => s == OrderStatus.done)) {
            dayStatus = OrderStatus.done;
          } else if (statuses.every((s) => s == OrderStatus.readyFetch)) {
            dayStatus = OrderStatus.readyFetch;
          } else if (statuses.every((s) => s == OrderStatus.delivered)) {
            dayStatus = OrderStatus.delivered;
          } else if (statuses.any((s) => s == OrderStatus.cancelled)) {
            dayStatus = OrderStatus.cancelled;
          } else if (statuses.any((s) => s == OrderStatus.outForDelivery)) {
            dayStatus = OrderStatus.outForDelivery;
          } else if (statuses.any((s) => s == OrderStatus.readyDelivery)) {
            dayStatus = OrderStatus.readyDelivery;
          } else if (statuses.any((s) => s == OrderStatus.preparing)) {
            dayStatus = OrderStatus.preparing;
          }

          return order.copyWith(
            items: filteredDayItems,
            totalAmount: dayTotalAmount,
            status: dayStatus,
            scheduledDays: [selectedDay],
          );
        })
        .whereType<Order>()
        .where(
          (order) =>
              searchQuery.isEmpty ||
              order.customerEmail.toLowerCase().contains(
                searchQuery.toLowerCase(),
              ) ||
              order.id.toLowerCase().contains(searchQuery.toLowerCase()),
        )
        .toList();
  }

  // === Status update handlers ===
  void handleUpdateOrderStatus(String orderId, OrderStatus status) {
    if (selectedDay == "Geskiedenis") return;

    setState(() {
      orders = orders.map((order) {
        if (order.id == orderId) {
          final currentDayItems = order.items
              .where((i) => i.scheduledDay == selectedDay)
              .toList();

          // Check if any items can be updated to the target status
          final canUpdateAny = currentDayItems.any(
            (i) => getNextStatus(i.status) == status,
          );

          if (!canUpdateAny) return order;

          final updatedItems = order.items
              .map(
                (i) =>
                    i.scheduledDay == selectedDay &&
                        getNextStatus(i.status) == status
                    ? i.copyWith(status: status)
                    : i,
              )
              .toList();

          return order.copyWith(
            items: updatedItems,
            status: _recalcOrderStatus(updatedItems),
          );
        }
        return order;
      }).toList();
    });
  }

  void handleUpdateItemStatus(
    String orderId,
    String itemId,
    OrderStatus status,
  ) {
    setState(() {
      orders = orders.map((order) {
        if (order.id == orderId) {
          final targetIndex = order.items.indexWhere((i) => i.id == itemId);
          if (targetIndex == -1) return order;
          final target = order.items[targetIndex];

          if (getNextStatus(target.status) != status) return order;

          final updatedItems = order.items
              .map((i) => i.id == itemId ? i.copyWith(status: status) : i)
              .toList();

          return order.copyWith(
            items: updatedItems,
            status: _recalcOrderStatus(updatedItems),
          );
        }
        return order;
      }).toList();
    });
  }

  void handleCancelOrder(String orderId) {
    if (selectedDay == "Geskiedenis") return;

    setState(() {
      orders = orders.map((order) {
        if (order.id == orderId) {
          final updatedItems = order.items.map((i) {
            if (i.scheduledDay == selectedDay && canBeCancelled(i.status)) {
              return i.copyWith(status: OrderStatus.cancelled);
            }
            return i;
          }).toList();

          return order.copyWith(
            items: updatedItems,
            status: _recalcOrderStatus(updatedItems),
          );
        }
        return order;
      }).toList();
    });
  }

  void handleBulkUpdate(List<String> orderIds, OrderStatus status) {
    if (selectedDay == "Geskiedenis") return;

    setState(() {
      orders = orders.map((order) {
        if (orderIds.contains(order.id)) {
          final updatedItems = order.items.map((i) {
            if (i.scheduledDay == selectedDay &&
                getNextStatus(i.status) == status) {
              return i.copyWith(status: status);
            }
            return i;
          }).toList();

          return order.copyWith(
            items: updatedItems,
            status: _recalcOrderStatus(updatedItems),
          );
        }
        return order;
      }).toList();
    });
  }

  // === Helpers ===
  OrderStatus _recalcOrderStatus(List<OrderItem> items) {
    if (items.every((i) => i.status == OrderStatus.done)) {
      return OrderStatus.done;
    } else if (items.every((i) => i.status == OrderStatus.readyFetch)) {
      return OrderStatus.readyFetch;
    } else if (items.every((i) => i.status == OrderStatus.delivered)) {
      return OrderStatus.delivered;
    } else if (items.every((i) => i.status == OrderStatus.cancelled)) {
      return OrderStatus.cancelled;
    } else if (items.any((i) => i.status == OrderStatus.outForDelivery)) {
      return OrderStatus.outForDelivery;
    } else if (items.any((i) => i.status == OrderStatus.readyDelivery)) {
      return OrderStatus.readyDelivery;
    } else if (items.any((i) => i.status == OrderStatus.preparing)) {
      return OrderStatus.preparing;
    }
    return OrderStatus.pending;
  }

  void handleFoodItemClick(String foodItem) {
    setState(() {
      if (selectedFoodItem == foodItem) {
        selectedFoodItem = "";
      } else {
        selectedFoodItem = foodItem;
      }
    });
  }

  void handleDayChange(String day) {
    setState(() {
      selectedDay = day;
      selectedFoodItem = "";
    });
  }

  // === UI ===
  @override
  Widget build(BuildContext context) {
    // final stats = _computeViewStats();

    return Scaffold(
      // backgroundColor: Theme.of(context).colorScheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              "Bestelling Bestuur",
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Bestuur en volg al jou restaurantbestellings doeltreffend.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 16),

            // Loading / Error
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
            ] else if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 16),
            ],

            // Search
            Row(
              children: [
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = MediaQuery.of(context).size.width < 600;

                      return Align(
                        alignment: Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isMobile
                                ? double.infinity
                                : 400, // 400px cap on bigger screens
                          ),
                          child: SearchBarWidget(
                            value: searchQuery,
                            onChange: (val) =>
                                setState(() => searchQuery = val),
                            placeholder:
                                "Soek vir kliënt e-pos of bestelling ID...",
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),

            //Day Filter
            const SizedBox(height: 12),
            DayFilters(selectedDay: selectedDay, onDayChange: handleDayChange),

            const SizedBox(height: 16),

            // // Summary stats (optional)
            // _buildSummaryCard(stats),
            const SizedBox(height: 16),

            DayItemsSummary(
              orders: orders,
              selectedDay: selectedDay,
              selectedFoodItem: selectedFoodItem,
              onFoodItemClick: handleFoodItemClick,
            ),
            const SizedBox(height: 32),
            filteredOrders.isEmpty
                ? Center(
                    child: Text(
                      "Geen bestellings",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(
                              selectedDay == "Geskiedenis"
                                  ? "Bestelling Geskiedenis (${filteredOrders.length})"
                                  : "Bestellings vir $selectedDay (${filteredOrders.length})",
                              style: Theme.of(context).textTheme.titleLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (selectedDay != "Geskiedenis")
                            BulkActions(
                              orders: filteredOrders,
                              onBulkUpdate: handleBulkUpdate,
                            ),
                        ],
                      ),
                      const SizedBox(height: 5),

                      // Orders list
                      for (var order in filteredOrders)
                        OrderCard(
                          order: order,
                          selectedDay: selectedDay != "Geskiedenis"
                              ? selectedDay
                              : null,
                          isPastOrder: selectedDay == "Geskiedenis",
                          onViewDetails: (order) =>
                              _showOrderDetails(context, order),
                          onUpdateStatus: handleUpdateOrderStatus,
                          onCancelOrder: handleCancelOrder,
                        ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  // Summary stats currently not displayed; method removed to avoid unused warnings.

  void _showOrderDetails(BuildContext context, Order order) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => OrderDetailsModal(
        order: order,
        selectedDay: selectedDay != "Geskiedenis" ? selectedDay : null,
        isOpen: true,
        onClose: () => Navigator.of(context).pop(),
        onUpdateItemStatus: handleUpdateItemStatus,
        onCancelOrder: handleCancelOrder,
      ),
    );
  }
}
