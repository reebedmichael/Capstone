import 'package:capstone_admin/features/bestellings/widgets/kampus_filter.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart'
    show SupabaseDb, KampusRepository;
import 'package:spys_api_client/src/admin_bestellings_repository.dart';
import '../../../shared/types/order.dart';
import '../../../shared/utils/status_utils.dart';
import '../../../shared/constants/order_constants.dart';
import '../../../shared/widgets/common_widgets.dart';
import '../widgets/order_search.dart';
import '../widgets/day_filter_orders.dart';
import '../widgets/day_item_summary.dart';
import '../widgets/order_card.dart';
import '../widgets/order_details.dart';
import '../widgets/bulk_actions.dart';

// Use shared constants

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
  String selectedDay = OrderConstants.getCurrentDayInAfrikaans();
  String selectedFoodItem = "";
  String selectedKampus = "Alle Aflaai Punte";
  List<String> kampusList = [];
  final Map<String, int> kampusOrderCounts = {};
  late final KampusRepository _kampusRepo;

  // Date filter for history view
  DateTime? fromDate;
  DateTime? toDate;
  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    _repo = AdminBestellingRepository(SupabaseDb(client));
    _kampusRepo = KampusRepository(SupabaseDb(client));
    _loadOrders();
    _loadKampusse();
  }

  Future<void> _loadKampusse() async {
    try {
      final rows = await _kampusRepo.kryKampusse();
      final loaded = rows
          .map((r) => r?['kampus_naam'] as String?)
          .whereType<String>()
          .toList();
      setState(() {
        kampusList = loaded;
      });
    } catch (e) {
      debugPrint("Kon nie kampusse laai nie: $e");
    }
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
      final id = (row['gebr_id'] as String?) ?? '1';
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
        final price = (it['kos_item_koste'] as num?)?.toDouble() ?? 1;
        final qty = (it['item_hoev'] as num?)?.toInt() ?? 1;
        final weekdag = (it['weekdag'] as String?) ?? '';
        final statusNames =
            (it['statusse'] as List?)?.whereType<String>().toList() ?? const [];
        final status = mapStatusFromNames(statusNames);
        final bestKosId = (it['best_kos_id']?.toString()) ?? '';

        // Parse best_datum to DateTime
        DateTime? bestDatum;
        try {
          final bestDatumRaw = it['best_datum'];
          if (bestDatumRaw != null) {
            bestDatum = DateTime.parse(bestDatumRaw.toString());
          }
        } catch (e) {
          debugPrint('Error parsing best_datum: $e');
          bestDatum = null;
        }

        scheduledDays.add(weekdag);
        items.add(
          OrderItem(
            id: bestKosId,
            name: name,
            price: price,
            quantity: qty,
            status: status,
            scheduledDay: weekdag,
            bestDatum: bestDatum, // Add the actual date
          ),
        );
      }

      // Derive overall status from items
      final overallStatus = _recalcOrderStatus(items);

      return Order(
        id: idStr,
        customerEmail: email,
        customerId: id,
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

  // Get all orders for the selected day (without food item filtering)
  List<Order> get allOrdersForDay {
    List<Order> baseOrders;
    // Geskiedenis (History) view: Show original orders that are fully completed or cancelled.
    if (selectedDay == "Geskiedenis") {
      baseOrders = orders
          .where(
            (order) =>
                order.status == OrderStatus.done ||
                order.status == OrderStatus.cancelled,
          )
          .toList();

      // Apply date filtering if dates are selected
      if (fromDate != null || toDate != null) {
        baseOrders = baseOrders.where((order) {
          final orderDate = DateTime(
            order.createdAt.year,
            order.createdAt.month,
            order.createdAt.day,
          );

          bool matchesFromDate = true;
          bool matchesToDate = true;

          if (fromDate != null) {
            final fromDateOnly = DateTime(
              fromDate!.year,
              fromDate!.month,
              fromDate!.day,
            );
            matchesFromDate =
                orderDate.isAtSameMomentAs(fromDateOnly) ||
                orderDate.isAfter(fromDateOnly);
          }

          if (toDate != null) {
            final toDateOnly = DateTime(
              toDate!.year,
              toDate!.month,
              toDate!.day,
            );
            matchesToDate =
                orderDate.isAtSameMomentAs(toDateOnly) ||
                orderDate.isBefore(toDateOnly);
          }

          return matchesFromDate && matchesToDate;
        }).toList();
      }

      // Sort by creation date (newest first)
      baseOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else {
      final List<Order> splitOrders = [];

      // Calculate the target date based on selected day
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final targetDate = _getDateForSelectedDay(selectedDay, today);

      for (final order in orders) {
        // 1. Filter items for the selected day using bestDatum if available, otherwise fallback to scheduledDay
        final dayItems = order.items.where((item) {
          // Use the actual bestDatum if available
          if (item.bestDatum != null) {
            final itemDate = DateTime(
              item.bestDatum!.year,
              item.bestDatum!.month,
              item.bestDatum!.day,
            );
            return itemDate.isAtSameMomentAs(targetDate);
          }
          // Fallback to scheduledDay if bestDatum is not available
          return item.scheduledDay == selectedDay;
        }).toList();

        if (dayItems.isEmpty) continue;

        // 2. Group these items by food name.
        final itemsByFoodType = <String, List<OrderItem>>{};
        for (final item in dayItems) {
          (itemsByFoodType[item.name] ??= []).add(item);
        }

        // 3. Create a new "split" order for each food group.
        itemsByFoodType.forEach((foodName, foodItems) {
          final foodTotalAmount = foodItems.fold<double>(
            0,
            (sum, item) => sum + item.price * item.quantity,
          );
          final foodOrderStatus = _recalcOrderStatus(foodItems);

          // Create a new, unique ID for this view from the original ID and food name.
          final splitOrderId = '${order.id}__$foodName';

          splitOrders.add(
            order.copyWith(
              id: splitOrderId,
              items: foodItems,
              totalAmount: foodTotalAmount,
              status: foodOrderStatus,
              scheduledDays: [selectedDay],
            ),
          );
        });
      }
      baseOrders = splitOrders;
    }
    if (selectedKampus != "Alle Aflaai Punte") {
      baseOrders = baseOrders
          .where((order) => order.deliveryPoint == selectedKampus)
          .toList();
    }

    // Apply search query to the list of split orders.
    final filteredOrders = baseOrders.where((order) {
      final originalOrderId = order.id.split('__').first;
      final matchesSearch =
          searchQuery.isEmpty ||
          order.customerEmail.toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          originalOrderId.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    // Sort orders: active orders first, then completed orders
    filteredOrders.sort((a, b) {
      final aIsCompleted =
          a.status == OrderStatus.done || a.status == OrderStatus.cancelled;
      final bIsCompleted =
          b.status == OrderStatus.done || b.status == OrderStatus.cancelled;

      // If one is completed and the other isn't, prioritize the active one
      if (aIsCompleted && !bIsCompleted) return 1;
      if (!aIsCompleted && bIsCompleted) return -1;

      // If both have the same completion status, sort by creation date (newest first)
      return b.createdAt.compareTo(a.createdAt);
    });

    return filteredOrders;
  }

  // Filtering logic: Splits orders by food item for the daily view.
  List<Order> get filteredOrders {
    // Get all orders for the day first
    final allOrders = allOrdersForDay;

    // Apply food item filter if one is selected
    if (selectedFoodItem.isNotEmpty) {
      return allOrders.where((order) {
        // Extract food name from split order ID
        final parts = order.id.split('__');
        if (parts.length >= 2) {
          final foodName = parts.sublist(1).join('__');
          return foodName == selectedFoodItem;
        }
        return false;
      }).toList();
    }

    return allOrders;
  }
  // === Status update handlers (Refactored for split orders) ===

  Future<void> handleUpdateOrderStatus(
    String splitOrderId,
    OrderStatus status,
  ) async {
    if (selectedDay == "Geskiedenis") return;

    final parts = splitOrderId.split('__');
    if (parts.length < 2) return; // Invalid ID format
    final originalOrderId = parts.first;
    final foodType = parts.sublist(1).join('__');

    try {
      // Find the original order and items to update
      final originalOrder = orders.firstWhere(
        (order) => order.id == originalOrderId,
      );
      final itemsToUpdate = originalOrder.items
          .where(
            (item) =>
                item.scheduledDay == selectedDay &&
                item.name == foodType &&
                getNextStatus(item.status) == status,
          )
          .toList();

      // Update each item in the database
      for (final item in itemsToUpdate) {
        final statusName = getDatabaseStatusName(status);
        await _repo.updateStatus(
          bestKosId: item.id,
          statusNaam: statusName,
          gebrId: originalOrder.customerId,
          refundAmount: item.price * item.quantity,
        );
      }

      // Update local state after successful database update
      setState(() {
        orders = orders.map((order) {
          if (order.id == originalOrderId) {
            final updatedItems = order.items.map((item) {
              if (item.scheduledDay == selectedDay &&
                  item.name == foodType &&
                  getNextStatus(item.status) == status) {
                return item.copyWith(status: status);
              }
              return item;
            }).toList();

            return order.copyWith(
              items: updatedItems,
              status: _recalcOrderStatus(updatedItems),
            );
          }
          return order;
        }).toList();
      });
    } catch (e) {
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout by opdatering: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> handleUpdateItemStatus(
    String splitOrderId,
    String itemId,
    OrderStatus status,
  ) async {
    final originalOrderId = splitOrderId.split('__').first;

    try {
      // Find the item to update
      final originalOrder = orders.firstWhere(
        (order) => order.id == originalOrderId,
      );
      final targetItem = originalOrder.items.firstWhere(
        (item) => item.id == itemId,
      );

      if (getNextStatus(targetItem.status) != status) return;

      // Update in database
      final statusName = getDatabaseStatusName(status);
      await _repo.updateStatus(
        bestKosId: itemId,
        statusNaam: statusName,
        gebrId: originalOrder.customerId,
        refundAmount: status == OrderStatus.cancelled
            ? targetItem.price * targetItem.quantity
            : null,
      );

      // Update local state after successful database update
      setState(() {
        orders = orders.map((order) {
          if (order.id == originalOrderId) {
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
    } catch (e) {
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout by opdatering: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> handleCancelOrder(String splitOrderId) async {
    if (selectedDay == "Geskiedenis") return;

    final parts = splitOrderId.split('__');
    if (parts.length < 2) return;
    final originalOrderId = parts.first;
    final foodType = parts.sublist(1).join('__');

    try {
      // Find the original order and items to cancel
      final originalOrder = orders.firstWhere(
        (order) => order.id == originalOrderId,
      );
      final itemsToCancel = originalOrder.items
          .where(
            (item) =>
                item.scheduledDay == selectedDay &&
                item.name == foodType &&
                canBeCancelled(item.status),
          )
          .toList();

      // Cancel each item in the database
      for (final item in itemsToCancel) {
        final statusName = getDatabaseStatusName(OrderStatus.cancelled);
        await _repo.updateStatus(
          bestKosId: item.id,
          statusNaam: statusName,
          gebrId:
              originalOrder.customerId, // Using actual customer ID for refund
          refundAmount: item.price * item.quantity, // Calculate refund amount
        );
      }

      // Update local state after successful database update
      setState(() {
        orders = orders.map((order) {
          if (order.id == originalOrderId) {
            final updatedItems = order.items.map((item) {
              if (item.scheduledDay == selectedDay &&
                  item.name == foodType &&
                  canBeCancelled(item.status)) {
                return item.copyWith(status: OrderStatus.cancelled);
              }
              return item;
            }).toList();

            return order.copyWith(
              items: updatedItems,
              status: _recalcOrderStatus(updatedItems),
            );
          }
          return order;
        }).toList();
      });
    } catch (e) {
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout by kansellasie: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> handleBulkUpdate(
    List<String> splitOrderIds,
    OrderStatus status,
  ) async {
    if (selectedDay == "Geskiedenis") return;

    final Map<String, Set<String>> updatesByOriginalId = {};

    for (final splitId in splitOrderIds) {
      final parts = splitId.split('__');
      if (parts.length < 2) continue;
      final originalId = parts.first;
      final foodType = parts.sublist(1).join('__');
      (updatesByOriginalId[originalId] ??= {}).add(foodType);
    }

    try {
      // Update all items in the database
      for (final order in orders) {
        if (updatesByOriginalId.containsKey(order.id)) {
          final foodTypesToUpdate = updatesByOriginalId[order.id]!;
          final itemsToUpdate = order.items
              .where(
                (item) =>
                    item.scheduledDay == selectedDay &&
                    foodTypesToUpdate.contains(item.name) &&
                    getNextStatus(item.status) == status,
              )
              .toList();

          for (final item in itemsToUpdate) {
            final statusName = getDatabaseStatusName(status);
            await _repo.updateStatus(
              bestKosId: item.id,
              statusNaam: statusName,
              gebrId: order.customerId,
              refundAmount: status == OrderStatus.cancelled
                  ? item.price * item.quantity
                  : null,
            );
          }
        }
      }

      // Update local state after successful database updates
      setState(() {
        orders = orders.map((order) {
          if (updatesByOriginalId.containsKey(order.id)) {
            final foodTypesToUpdate = updatesByOriginalId[order.id]!;

            final updatedItems = order.items.map((item) {
              if (item.scheduledDay == selectedDay &&
                  foodTypesToUpdate.contains(item.name) &&
                  getNextStatus(item.status) == status) {
                return item.copyWith(status: status);
              }
              return item;
            }).toList();

            return order.copyWith(
              items: updatedItems,
              status: _recalcOrderStatus(updatedItems),
            );
          }
          return order;
        }).toList();
      });
    } catch (e) {
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout by bulk opdatering: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // === Helpers ===

  DateTime _getDateForSelectedDay(String selectedDay, DateTime today) {
    // Map day names to weekday numbers
    final dayMap = {
      'Maandag': 1,
      'Dinsdag': 2,
      'Woensdag': 3,
      'Donderdag': 4,
      'Vrydag': 5,
      'Saterdag': 6,
      'Sondag': 7,
    };

    final selectedWeekday = dayMap[selectedDay];
    if (selectedWeekday == null) {
      return today; // Fallback to today if day not found
    }

    // Calculate the Monday of the current week
    final currentWeekday = today.weekday;
    final daysSinceMonday = currentWeekday - 1;
    final mondayOfWeek = today.subtract(Duration(days: daysSinceMonday));

    // Calculate the target date for the selected day
    final daysToAdd = selectedWeekday - 1;
    return mondayOfWeek.add(Duration(days: daysToAdd));
  }

  bool _isPreviousDay(String selectedDay) {
    if (selectedDay == "Geskiedenis") return false;

    final today = DateTime.now();
    final selectedDate = _getDateForSelectedDay(selectedDay, today);

    // Compare only the date part (year, month, day) to avoid time issues
    final todayDate = DateTime(today.year, today.month, today.day);
    final selectedDateOnly = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    return selectedDateOnly.isBefore(todayDate);
  }

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
      // Reset date filters when switching away from history
      if (day != "Geskiedenis") {
        fromDate = null;
        toDate = null;
      }
    });
  }

  Widget _buildDateFilter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Datum Filter',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Van Datum',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              fromDate ??
                              DateTime.now().subtract(const Duration(days: 30)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            fromDate = date;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              fromDate != null
                                  ? '${fromDate!.day}/${fromDate!.month}/${fromDate!.year}'
                                  : 'Kies datum',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tot Datum',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: toDate ?? DateTime.now(),
                          firstDate: fromDate ?? DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() {
                            toDate = date;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              toDate != null
                                  ? '${toDate!.day}/${toDate!.month}/${toDate!.year}'
                                  : 'Kies datum',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (fromDate != null || toDate != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      fromDate = null;
                      toDate = null;
                    });
                  },
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Skoon datum filter'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // === UI (No changes needed below this line) ===
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Styled Header
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width < 600 ? 16 : 24,
              vertical: MediaQuery.of(context).size.width < 600 ? 12 : 16,
            ),
            child: MediaQuery.of(context).size.width < 600
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo and title section
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text("📦", style: TextStyle(fontSize: 18)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Bestelling Bestuur",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  "Bestuur en volg al jou bestellings doeltreffend",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.color,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Action button section
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text(
                            'Herlaai',
                            style: TextStyle(fontSize: 12),
                          ),
                          onPressed: _loadOrders,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left section: logo + title + description
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text("📦", style: TextStyle(fontSize: 20)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Bestelling Bestuur",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Text(
                                "Bestuur en volg al jou bestellings doeltreffend",
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Right section: action buttons (if needed)
                      Row(
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Herlaai'),
                            onPressed: _loadOrders,
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          // Main content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Loading / Error
                  LoadingErrorWidget(
                    isLoading: _isLoading,
                    error: _error,
                    child: const SizedBox.shrink(),
                  ),

                  // Search
                  Row(
                    children: [
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isMobile =
                                MediaQuery.of(context).size.width < 600;

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
                                  placeholder: OrderConstants.getUiString(
                                    'searchPlaceholder',
                                  ),
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
                  DayFilters(
                    selectedDay: selectedDay,
                    onDayChange: handleDayChange,
                  ),

                  const SizedBox(height: 16),
                  KampusFilter(
                    selectedKampus: selectedKampus,
                    onKampusChange: (val) =>
                        setState(() => selectedKampus = val),
                    kampusList: kampusList,
                    // orderCounts: _buildKampusOrderCounts(),
                  ),
                  const SizedBox(height: 16),

                  // Date filter - only visible in history view
                  if (selectedDay == "Geskiedenis") ...[
                    _buildDateFilter(),
                    const SizedBox(height: 16),
                  ],

                  DayItemsSummary(
                    orders: filteredOrders,
                    selectedDay: selectedDay,
                    selectedFoodItem: selectedFoodItem,
                    onFoodItemClick: handleFoodItemClick,
                    allOrders: allOrdersForDay,
                  ),
                  const SizedBox(height: 32),
                  filteredOrders.isEmpty
                      ? Center(
                          child: Text(
                            OrderConstants.getUiString('noOrdersFound'),
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
                                        ? "${OrderConstants.getUiString('orderHistory')} (${filteredOrders.length})"
                                        : "${OrderConstants.getUiString('ordersForDay')} $selectedDay (${filteredOrders.length})",
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (selectedDay != "Geskiedenis")
                                  Row(
                                    children: [
                                      if (_isPreviousDay(selectedDay))
                                        ElevatedButton.icon(
                                          onPressed:
                                              _handleCleanupUnclaimedOrders,
                                          icon: const Icon(
                                            Icons.cleaning_services_outlined,
                                          ),
                                          label: const Text(
                                            'Merk aktiewe bestellings as gemis',
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                            foregroundColor: Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      if (_isPreviousDay(selectedDay))
                                        const SizedBox(width: 8),
                                      BulkActions(
                                        orders: filteredOrders,
                                        onBulkUpdate: handleBulkUpdate,
                                      ),
                                    ],
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
          ),
        ],
      ),
    );
  }

  Future<void> _handleCleanupUnclaimedOrders() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bevestig Status Opdateering'),
        content: const Text(
          'Is jy seker jy wil onopgehaalde bestellings merk as gemis? '
          'Hierdie aksie kan nie ongedaan gemaak word nie.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Kanselleer'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Bevestig'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Opruim onopgehaalde bestellings...'),
          ],
        ),
      ),
    );

    try {
      final result = await _repo.cancelUnclaimedOrders();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show result
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              result['success'] == true ? 'Opruiming Voltooi' : 'Fout',
            ),
            content: Text(result['message'] as String? ?? 'Onbekende fout'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (result['success'] == true) {
                    _loadOrders(); // Refresh the orders list
                  }
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Fout'),
            content: Text('Fout tydens opruiming: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

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
