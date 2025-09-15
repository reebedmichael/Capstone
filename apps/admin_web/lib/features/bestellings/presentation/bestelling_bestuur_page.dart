import 'package:flutter/material.dart';
import '../../../shared/types/order.dart' as types;
import '../../../shared/utils/status_utils.dart';
import 'mock_orders.dart';
import '../../../shared/widgets/Bestellings/order_search.dart';
import '../../../shared/widgets/Bestellings/day_filter_orders.dart';
import '../../../shared/widgets/Bestellings/day_item_summary.dart';
import '../../../shared/widgets/Bestellings/order_card.dart';
import '../../../shared/widgets/Bestellings/order_details.dart';
import '../../../shared/widgets/Bestellings/bulk_actions.dart';
import '../../../shared/widgets/Bestellings/status_badge.dart';

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
  List<types.Order> orders = List.from(mockOrders);
  String searchQuery = "";
  String selectedDay = _getCurrentDayInAfrikaans();
  String selectedFoodItem = "";

  // Filtering logic
  List<types.Order> get filteredOrders {
    if (selectedDay == "Alle") {
      return orders.toList()
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
          types.OrderStatus dayStatus = types.OrderStatus.pending;

          if (statuses.every((s) => s == types.OrderStatus.done)) {
            dayStatus = types.OrderStatus.done;
          } else if (statuses.every((s) => s == types.OrderStatus.readyFetch)) {
            dayStatus = types.OrderStatus.readyFetch;
          } else if (statuses.every((s) => s == types.OrderStatus.delivered)) {
            dayStatus = types.OrderStatus.delivered;
          } else if (statuses.any((s) => s == types.OrderStatus.cancelled)) {
            dayStatus = types.OrderStatus.cancelled;
          } else if (statuses.any(
            (s) => s == types.OrderStatus.outForDelivery,
          )) {
            dayStatus = types.OrderStatus.outForDelivery;
          } else if (statuses.any(
            (s) => s == types.OrderStatus.readyDelivery,
          )) {
            dayStatus = types.OrderStatus.readyDelivery;
          } else if (statuses.any((s) => s == types.OrderStatus.preparing)) {
            dayStatus = types.OrderStatus.preparing;
          }

          return order.copyWith(
            items: filteredDayItems,
            totalAmount: dayTotalAmount,
            status: dayStatus,
            scheduledDays: [selectedDay],
          );
        })
        .whereType<types.Order>()
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
  void handleUpdateOrderStatus(String orderId, types.OrderStatus status) {
    if (selectedDay == "Alle") return;

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
    types.OrderStatus status,
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
    if (selectedDay == "Alle") return;

    setState(() {
      orders = orders.map((order) {
        if (order.id == orderId) {
          final updatedItems = order.items.map((i) {
            if (i.scheduledDay == selectedDay && canBeCancelled(i.status)) {
              return i.copyWith(status: types.OrderStatus.cancelled);
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

  void handleBulkUpdate(List<String> orderIds, types.OrderStatus status) {
    if (selectedDay == "Alle") return;

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
  types.OrderStatus _recalcOrderStatus(List<types.OrderItem> items) {
    if (items.every((i) => i.status == types.OrderStatus.done)) {
      return types.OrderStatus.done;
    } else if (items.every((i) => i.status == types.OrderStatus.readyFetch)) {
      return types.OrderStatus.readyFetch;
    } else if (items.every((i) => i.status == types.OrderStatus.delivered)) {
      return types.OrderStatus.delivered;
    } else if (items.every((i) => i.status == types.OrderStatus.cancelled)) {
      return types.OrderStatus.cancelled;
    } else if (items.any((i) => i.status == types.OrderStatus.outForDelivery)) {
      return types.OrderStatus.outForDelivery;
    } else if (items.any((i) => i.status == types.OrderStatus.readyDelivery)) {
      return types.OrderStatus.readyDelivery;
    } else if (items.any((i) => i.status == types.OrderStatus.preparing)) {
      return types.OrderStatus.preparing;
    }
    return types.OrderStatus.pending;
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
    final stats = _computeViewStats();

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

            // Search + Badge
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

            // // Summary stats
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
                              selectedDay == "Alle"
                                  ? "Alle Bestellings (${filteredOrders.length})"
                                  : "Bestellings vir $selectedDay (${filteredOrders.length})",
                              style: Theme.of(context).textTheme.titleLarge,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (selectedDay != "Alle")
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
                          selectedDay: selectedDay != "Alle"
                              ? selectedDay
                              : null,
                          isPastOrder: selectedDay == "Alle",
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

  Map<String, dynamic> _computeViewStats() {
    if (selectedDay == "Alle") {
      final deliveredOrders = filteredOrders;
      final totalOrders = deliveredOrders.length;
      final totalItems = deliveredOrders.fold<int>(
        0,
        (sum, o) => sum + o.items.length,
      );

      return {
        "totalOrders": totalOrders,
        "totalItems": totalItems,
        "statusCounts": {types.OrderStatus.delivered: totalItems},
      };
    }

    var dayItems = orders
        .expand((o) => o.items.where((i) => i.scheduledDay == selectedDay))
        .toList();

    if (selectedFoodItem.isNotEmpty) {
      dayItems = dayItems.where((i) => i.name == selectedFoodItem).toList();
    }

    final totalItems = dayItems.length;
    final totalOrders = filteredOrders.length;

    final Map<types.OrderStatus, int> statusCounts = {};
    for (final item in dayItems) {
      statusCounts[item.status] = (statusCounts[item.status] ?? 0) + 1;
    }

    return {
      "totalOrders": totalOrders,
      "totalItems": totalItems,
      "statusCounts": statusCounts,
    };
  }

  void _showOrderDetails(BuildContext context, types.Order order) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => OrderDetailsModal(
        order: order,
        selectedDay: selectedDay != "Alle" ? selectedDay : null,
        isOpen: true,
        onClose: () => Navigator.of(context).pop(),
        onUpdateItemStatus: handleUpdateItemStatus,
        onCancelOrder: handleCancelOrder,
      ),
    );
  }
}
