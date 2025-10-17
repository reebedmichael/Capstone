import 'package:capstone_admin/features/bestellings/widgets/kampus_filter.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart'
    show SupabaseDb, KampusRepository;
import 'package:spys_api_client/src/admin_bestellings_repository.dart';
import '../../../shared/types/order.dart';
import '../../../shared/utils/status_utils.dart';
import '../../../shared/constants/order_constants.dart';
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

  // Track which orders are being updated
  final Set<String> _updatingOrders = {};

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
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Clear any existing cache to ensure fresh data
      _repo.clearCache();

      // Load both orders and kampus list in parallel for better performance
      final stopwatch = Stopwatch()..start();

      final ordersFuture = _repo.getBestellings(forceRefresh: true);
      final kampusFuture = _kampusRepo.kryKampusse();

      // Wait for both operations to complete in parallel
      final results = await Future.wait([ordersFuture, kampusFuture]);
      final rows = results[0];
      final kampusRows = results[1];

      stopwatch.stop();
      print(
        'Orders and kampus data loaded in ${stopwatch.elapsedMilliseconds}ms',
      );

      final loaded = (rows as List<Map<String, dynamic>>)
          .map(_mapApiOrderToModel)
          .whereType<Order>()
          .toList();
      final loadedKampusse = kampusRows
          .map((r) => r?['kampus_naam'] as String?)
          .whereType<String>()
          .toList();

      setState(() {
        orders
          ..clear()
          ..addAll(loaded);
        kampusList = loadedKampusse;
      });

      print('Total orders processed: ${loaded.length}');

      // Show success feedback
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text(
      //         'Bestellings suksesvol herlaai (${loaded.length} bestellings)',
      //       ),
      //       backgroundColor: Colors.green,
      //       duration: const Duration(seconds: 2),
      //     ),
      //   );
      // }
    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        _error = e.toString();
      });

      // Show error feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout by laai van bestellings: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
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
        bestNommer: (row['best_nommer'] as String?) ?? idStr,
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
    // Geskiedenis (History) view: Show original orders that are fully completed, cancelled, or verstryk.
    if (selectedDay == "Geskiedenis") {
      baseOrders = orders
          .where(
            (order) =>
                order.status == OrderStatus.done ||
                order.status == OrderStatus.cancelled ||
                order.status == OrderStatus.verstryk,
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
      final displayNumber = order.bestNommer ?? originalOrderId;
      final matchesSearch =
          searchQuery.isEmpty ||
          order.customerEmail.toLowerCase().contains(
            searchQuery.toLowerCase(),
          ) ||
          displayNumber.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesSearch;
    }).toList();

    // Sort orders: active orders first, then completed orders
    filteredOrders.sort((a, b) {
      final aIsCompleted =
          a.status == OrderStatus.done ||
          a.status == OrderStatus.cancelled ||
          a.status == OrderStatus.verstryk;
      final bIsCompleted =
          b.status == OrderStatus.done ||
          b.status == OrderStatus.cancelled ||
          b.status == OrderStatus.verstryk;

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

    // Add to updating orders set
    setState(() {
      _updatingOrders.add(splitOrderId);
    });

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

      if (itemsToUpdate.isNotEmpty) {
        // Use bulk update for better performance
        final bestKosIds = itemsToUpdate.map((item) => item.id).toList();
        final Map<String, double> refundAmounts = {};
        final Map<String, String> customerIds = {};

        for (final item in itemsToUpdate) {
          customerIds[item.id] = originalOrder.customerId;
          if (status == OrderStatus.cancelled) {
            refundAmounts[item.id] = item.price * item.quantity;
          }
        }

        final statusName = getDatabaseStatusName(status);
        await _repo.bulkUpdateStatus(
          bestKosIds: bestKosIds,
          statusNaam: statusName,
          refundAmounts: refundAmounts.isNotEmpty ? refundAmounts : null,
          customerIds: customerIds.isNotEmpty ? customerIds : null,
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
    } finally {
      // Remove from updating orders set
      if (mounted) {
        setState(() {
          _updatingOrders.remove(splitOrderId);
        });
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

      if (itemsToCancel.isNotEmpty) {
        // Use bulk update for better performance
        final bestKosIds = itemsToCancel.map((item) => item.id).toList();
        final Map<String, double> refundAmounts = {};
        final Map<String, String> customerIds = {};

        for (final item in itemsToCancel) {
          customerIds[item.id] = originalOrder.customerId;
          refundAmounts[item.id] = item.price * item.quantity;
        }

        final statusName = getDatabaseStatusName(OrderStatus.cancelled);
        await _repo.bulkUpdateStatus(
          bestKosIds: bestKosIds,
          statusNaam: statusName,
          refundAmounts: refundAmounts,
          customerIds: customerIds,
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

    // Add all split order IDs to updating orders set
    setState(() {
      _updatingOrders.addAll(splitOrderIds);
    });

    try {
      // Prepare data for bulk update
      final List<String> bestKosIds = [];
      final Map<String, double> refundAmounts = {};
      final Map<String, String> customerIds = {};

      for (final splitId in splitOrderIds) {
        final parts = splitId.split('__');
        if (parts.length < 2) continue;
        final originalOrderId = parts.first;
        final foodType = parts.sublist(1).join('__');

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

        // Add items to bulk update data
        for (final item in itemsToUpdate) {
          bestKosIds.add(item.id);
          customerIds[item.id] = originalOrder.customerId;

          if (status == OrderStatus.cancelled) {
            refundAmounts[item.id] = item.price * item.quantity;
          }
        }
      }

      // Execute bulk update
      final statusName = getDatabaseStatusName(status);
      await _repo.bulkUpdateStatus(
        bestKosIds: bestKosIds,
        statusNaam: statusName,
        refundAmounts: refundAmounts.isNotEmpty ? refundAmounts : null,
        customerIds: customerIds.isNotEmpty ? customerIds : null,
      );

      // Update local state after successful database updates
      setState(() {
        orders = orders.map((order) {
          final updatedItems = order.items.map((item) {
            if (bestKosIds.contains(item.id) &&
                getNextStatus(item.status) == status) {
              return item.copyWith(status: status);
            }
            return item;
          }).toList();

          return order.copyWith(
            items: updatedItems,
            status: _recalcOrderStatus(updatedItems),
          );
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
    } finally {
      // Remove all split order IDs from updating orders set
      if (mounted) {
        setState(() {
          _updatingOrders.removeAll(splitOrderIds);
        });
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

  OrderStatus _recalcOrderStatus(List<OrderItem> items) {
    if (items.every((i) => i.status == OrderStatus.done)) {
      return OrderStatus.done;
    } else if (items.every((i) => i.status == OrderStatus.verstryk)) {
      return OrderStatus.verstryk;
    } else if (items.every((i) => i.status == OrderStatus.cancelled)) {
      return OrderStatus.cancelled;
    } else if (items.every((i) => i.status == OrderStatus.readyFetch)) {
      return OrderStatus.readyFetch;
    } else if (items.every((i) => i.status == OrderStatus.delivered)) {
      return OrderStatus.delivered;
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
      // Set default date filters when switching to history view
      if (day == "Geskiedenis") {
        final now = DateTime.now();
        // Set default range to last 7 days (more practical for daily operations)
        fromDate = DateTime(now.year, now.month, now.day - 7);
        toDate = DateTime(now.year, now.month, now.day);
      } else {
        // Reset date filters when switching away from history
        fromDate = null;
        toDate = null;
      }
    });
  }

  Widget _buildQuickDateButton(String label, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
        ),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getDateIcon(label),
                  size: 14,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getDateIcon(String label) {
    switch (label) {
      case 'Laaste 7 dae':
        return Icons.date_range;
      case 'Laaste 30 dae':
        return Icons.calendar_month;
      case 'Laaste 6 maande':
        return Icons.calendar_view_month;
      case 'Laaste jaar':
        return Icons.calendar_today;
      default:
        return Icons.date_range;
    }
  }

  String _getDateRangeText() {
    if (fromDate != null && toDate != null) {
      if (fromDate!.isAtSameMomentAs(toDate!)) {
        return 'Geselekteerde datum: ${_formatDate(fromDate!)}';
      } else {
        return 'Datum reeks: ${_formatDate(fromDate!)} tot ${_formatDate(toDate!)}';
      }
    } else if (fromDate != null) {
      return 'Van datum: ${_formatDate(fromDate!)}';
    } else if (toDate != null) {
      return 'Tot datum: ${_formatDate(toDate!)}';
    }
    return '';
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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
                              DateTime.now().subtract(const Duration(days: 7)),
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
          const SizedBox(height: 12),
          // Show current date range
          if (fromDate != null || toDate != null) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.date_range,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getDateRangeText(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Vinnige datum keuses',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              // Quick date range buttons organized in groups
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  // Short-term options
                  _buildQuickDateButton('Laaste 7 dae', () {
                    final now = DateTime.now();
                    setState(() {
                      fromDate = DateTime(now.year, now.month, now.day - 7);
                      toDate = DateTime(now.year, now.month, now.day);
                    });
                  }),
                  _buildQuickDateButton('Laaste 30 dae', () {
                    final now = DateTime.now();
                    setState(() {
                      fromDate = DateTime(now.year, now.month, now.day - 30);
                      toDate = DateTime(now.year, now.month, now.day);
                    });
                  }),
                  // Long-term options
                  _buildQuickDateButton('Laaste 6 maande', () {
                    final now = DateTime.now();
                    final sixMonthsAgo = DateTime(
                      now.year,
                      now.month - 6,
                      now.day,
                    );
                    setState(() {
                      fromDate = sixMonthsAgo;
                      toDate = DateTime(now.year, now.month, now.day);
                    });
                  }),
                  _buildQuickDateButton('Laaste jaar', () {
                    final now = DateTime.now();
                    final oneYearAgo = DateTime(
                      now.year - 1,
                      now.month,
                      now.day,
                    );
                    setState(() {
                      fromDate = oneYearAgo;
                      toDate = DateTime(now.year, now.month, now.day);
                    });
                  }),
                ],
              ),
            ],
          ),
          if (fromDate != null || toDate != null) ...[
            const SizedBox(height: 8),
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
                          icon: _isLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.refresh, size: 18),
                          label: Text(
                            _isLoading ? 'Laai...' : 'Herlaai',
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: _isLoading ? null : _loadOrders,
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
                            icon: _isLoading
                                ? SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.refresh),
                            label: Text(_isLoading ? 'Laai...' : 'Herlaai'),
                            onPressed: _isLoading ? null : _loadOrders,
                          ),
                        ],
                      ),
                    ],
                  ),
          ),
          // Main content
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Laai bestellings...',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  )
                : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _loadOrders,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Probeer weer'),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
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
                                      isUpdating: _updatingOrders.contains(
                                        order.id,
                                      ),
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
