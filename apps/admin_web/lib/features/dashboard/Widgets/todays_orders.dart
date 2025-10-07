import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart';
import 'package:spys_api_client/src/admin_bestellings_repository.dart';
import '../../../shared/types/order.dart';
import '../../../shared/utils/status_utils.dart';
import '../../../shared/constants/order_constants.dart';
import '../../bestellings/widgets/status_update_confirmation.dart';

class TodaysOrders extends StatefulWidget {
  const TodaysOrders({super.key});

  @override
  State<TodaysOrders> createState() => _TodaysOrdersState();
}

class _TodaysOrdersState extends State<TodaysOrders> {
  // Core data
  List<Order> _originalOrders = [];
  List<Order> _splitOrders = [];

  // UI state
  bool _isLoading = true;
  String? _error;
  String _selectedLocation = 'all';
  bool _isUpdating = false;

  // Configuration
  final List<String> _locations = ['Downtown', 'Uptown', 'Mall'];
  late final AdminBestellingRepository _repo;

  @override
  void initState() {
    super.initState();
    _initializeRepository();
    _loadOrders();
  }

  void _initializeRepository() {
    try {
      final client = Supabase.instance.client;
      _repo = AdminBestellingRepository(SupabaseDb(client));
    } catch (e) {
      _handleError('Failed to initialize repository: $e');
    }
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;

    _setLoadingState(true);

    try {
      final rows = await _repo.getBestellings();
      final todayString = OrderConstants.getCurrentDayInAfrikaans();

      // Map raw data to Order objects
      final orders = rows.map(_mapApiOrderToModel).whereType<Order>().toList();

      // Filter for today's orders
      final todayOrders = orders.where((order) {
        return _isOrderForToday(order, todayString);
      }).toList();

      if (mounted) {
        setState(() {
          _originalOrders = todayOrders;
          _splitOrders = _createSplitOrders(todayOrders, todayString);
        });
      }
    } catch (e) {
      _handleError('Failed to load orders: $e');
    } finally {
      _setLoadingState(false);
    }
  }

  bool _isOrderForToday(Order order, String todayString) {
    // Check if order was created today
    final today = DateTime.now();
    if (order.createdAt.year == today.year &&
        order.createdAt.month == today.month &&
        order.createdAt.day == today.day) {
      return true;
    }

    // Check if any items are scheduled for today
    return order.items.any((item) => item.scheduledDay == todayString);
  }

  List<Order> _createSplitOrders(List<Order> orders, String todayString) {
    final List<Order> splitOrders = [];

    for (final order in orders) {
      // Filter items for today that are not done or cancelled
      final todayItems = order.items
          .where(
            (item) =>
                item.scheduledDay == todayString &&
                item.status != OrderStatus.done &&
                item.status != OrderStatus.cancelled,
          )
          .toList();

      if (todayItems.isEmpty) continue;

      // Group items by food name
      final itemsByFood = <String, List<OrderItem>>{};
      for (final item in todayItems) {
        (itemsByFood[item.name] ??= []).add(item);
      }

      // Create split orders for each food group
      itemsByFood.forEach((foodName, foodItems) {
        final totalAmount = foodItems.fold<double>(
          0,
          (sum, item) => sum + (item.price * item.quantity),
        );

        splitOrders.add(
          order.copyWith(
            id: '${order.id}__$foodName',
            items: foodItems,
            totalAmount: totalAmount,
            status: _calculateOrderStatus(foodItems),
            scheduledDays: [todayString],
            originalOrderId: order.id,
            foodType: foodName,
          ),
        );
      });
    }

    return splitOrders;
  }

  OrderStatus _calculateOrderStatus(List<OrderItem> items) {
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

  List<Order> _getFilteredOrders() {
    List<Order> filtered = _splitOrders;

    if (_selectedLocation != 'all') {
      filtered = filtered
          .where((order) => order.deliveryPoint == _selectedLocation)
          .toList();
    }

    return filtered;
  }

  Map<OrderStatus, int> _getStatusCounts() {
    final Map<OrderStatus, int> counts = {};

    for (final order in _getFilteredOrders()) {
      for (final item in order.items) {
        counts[item.status] = (counts[item.status] ?? 0) + 1;
      }
    }

    return counts;
  }

  Future<void> _updateStatusForItems(OrderStatus currentStatus) async {
    if (_isUpdating) return;

    final nextStatus = getNextStatus(currentStatus);
    if (nextStatus == null) return;

    // Find items to update
    final itemsToUpdate = <Map<String, dynamic>>[];
    final ordersToUpdate = <Order>[];

    for (final order in _getFilteredOrders()) {
      final itemsWithStatus = order.items
          .where(
            (item) =>
                item.status == currentStatus &&
                getNextStatus(item.status) == nextStatus,
          )
          .toList();

      if (itemsWithStatus.isNotEmpty) {
        itemsToUpdate.addAll(
          itemsWithStatus.map((item) => {'item': item, 'order': order}),
        );
        ordersToUpdate.add(order);
      }
    }

    if (itemsToUpdate.isEmpty) return;

    // Show confirmation dialog
    if (!mounted) return;

    final navigator = Navigator.of(context);
    await showDialog(
      context: context,
      builder: (context) => StatusUpdateConfirmationDialog(
        isOpen: true,
        onClose: () => navigator.pop(),
        onConfirm: () async {
          try {
            await _performStatusUpdate(itemsToUpdate, nextStatus);
          } catch (e) {
            // Error handling is done in _performStatusUpdate
            // Re-throw to let the dialog handle it
            rethrow;
          } finally {
            // Always close the dialog after the operation completes
            if (mounted) navigator.pop();
          }
        },
        orders: ordersToUpdate,
        currentStatus: currentStatus,
        newStatus: nextStatus,
        isBulkUpdate: true,
      ),
    );
  }

  Future<void> _performStatusUpdate(
    List<Map<String, dynamic>> itemsToUpdate,
    OrderStatus newStatus,
  ) async {
    if (!mounted || _isUpdating) return;

    _setUpdatingState(true);

    try {
      // Update database
      for (final itemData in itemsToUpdate) {
        final item = itemData['item'] as OrderItem;
        final order = itemData['order'] as Order;

        await _repo.updateStatus(
          bestKosId: item.id,
          statusNaam: getDatabaseStatusName(newStatus),
          gebrId: order.customerId,
          refundAmount: item.price * item.quantity,
        );
      }

      // Update local state
      if (mounted) {
        _updateLocalState(itemsToUpdate, newStatus);
        _showSuccessMessage('Items successfully updated');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Update failed: $e');
      }
    } finally {
      _setUpdatingState(false);
    }
  }

  void _updateLocalState(
    List<Map<String, dynamic>> itemsToUpdate,
    OrderStatus newStatus,
  ) {
    final Map<String, Set<String>> updatesByOrderId = {};

    // Group updates by original order ID and food type
    for (final itemData in itemsToUpdate) {
      final order = itemData['order'] as Order;

      final parts = order.id.split('__');
      if (parts.length >= 2) {
        final originalId = parts.first;
        final foodType = parts.sublist(1).join('__');

        (updatesByOrderId[originalId] ??= {}).add(foodType);
      }
    }

    // Update original orders
    setState(() {
      _originalOrders = _originalOrders.map((order) {
        if (updatesByOrderId.containsKey(order.id)) {
          final foodTypesToUpdate = updatesByOrderId[order.id]!;
          final todayString = OrderConstants.getCurrentDayInAfrikaans();

          final updatedItems = order.items.map((item) {
            if (item.scheduledDay == todayString &&
                foodTypesToUpdate.contains(item.name) &&
                getNextStatus(item.status) == newStatus) {
              return item.copyWith(status: newStatus);
            }
            return item;
          }).toList();

          return order.copyWith(
            items: updatedItems,
            status: _calculateOrderStatus(updatedItems),
          );
        }
        return order;
      }).toList();

      // Recreate split orders
      _splitOrders = _createSplitOrders(
        _originalOrders,
        OrderConstants.getCurrentDayInAfrikaans(),
      );
    });
  }

  void _setLoadingState(bool loading) {
    if (mounted) {
      setState(() {
        _isLoading = loading;
        if (loading) _error = null;
      });
    }
  }

  void _setUpdatingState(bool updating) {
    if (mounted) {
      setState(() {
        _isUpdating = updating;
      });
    }
  }

  void _handleError(String message) {
    if (mounted) {
      setState(() {
        _error = message;
        _isLoading = false;
      });
    }
  }

  void _showSuccessMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showErrorMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Order? _mapApiOrderToModel(Map<String, dynamic> row) {
    try {
      final bestId = row['best_id']?.toString() ?? '';
      final email = (row['gebr_epos'] as String?) ?? 'unknown@email';
      final customerId = (row['gebr_id'] as String?) ?? '';
      final total = (row['best_volledige_prys'] as num?)?.toDouble() ?? 0.0;

      DateTime createdAt;
      try {
        createdAt = DateTime.parse(
          row['best_geskep_datum']?.toString() ??
              DateTime.now().toIso8601String(),
        );
      } catch (_) {
        createdAt = DateTime.now();
      }

      final itemsRaw =
          (row['kos_items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final items = <OrderItem>[];
      final scheduledDays = <String>{};

      for (final itemData in itemsRaw) {
        final name = (itemData['kos_item_naam'] as String?) ?? 'Item';
        final price = (itemData['kos_item_koste'] as num?)?.toDouble() ?? 0.0;
        final quantity = (itemData['item_hoev'] as num?)?.toInt() ?? 1;
        final weekdag = (itemData['weekdag'] as String?) ?? '';
        final statusNames =
            (itemData['statusse'] as List?)?.whereType<String>().toList() ?? [];
        final status = mapStatusFromNames(statusNames);
        final bestKosId = (itemData['best_kos_id']?.toString()) ?? '';

        scheduledDays.add(weekdag);
        items.add(
          OrderItem(
            id: bestKosId,
            name: name,
            price: price,
            quantity: quantity,
            status: status,
            scheduledDay: weekdag,
          ),
        );
      }

      return Order(
        id: bestId,
        customerEmail: email,
        customerId: customerId,
        items: items,
        scheduledDays: scheduledDays.where((d) => d.isNotEmpty).toList(),
        status: _calculateOrderStatus(items),
        createdAt: createdAt,
        totalAmount: total,
        deliveryPoint: (row['kampus_naam'] as String?) ?? '',
      );
    } catch (e) {
      debugPrint('Error mapping order: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingCard();
    }

    if (_error != null) {
      return _buildErrorCard();
    }

    return _buildOrdersCard();
  }

  Widget _buildLoadingCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading today\'s orders...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard() {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Error loading orders',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadOrders, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersCard() {
    final statusCounts = _getStatusCounts();
    final statusGroups = _buildStatusGroups(statusCounts);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            if (statusGroups.isEmpty)
              _buildEmptyState()
            else
              _buildStatusGroupsWidget(statusGroups),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Today\'s Orders',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                'Orders grouped by status with pickup point filtering',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _buildLocationDropdown(),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            if (mounted) {
              try {
                // Use push instead of go to avoid stack issues
                context.push('/bestellings');
              } catch (e) {
                debugPrint('Navigation error: $e');
                // Show a message instead of crashing
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to navigate to orders page'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              }
            }
          },
          child: const Text('More'),
        ),
      ],
    );
  }

  Widget _buildLocationDropdown() {
    return DropdownButton<String>(
      value: _selectedLocation,
      onChanged: (value) {
        if (value != null && mounted) {
          setState(() {
            _selectedLocation = value;
          });
        }
      },
      items: [
        DropdownMenuItem(
          value: 'all',
          child: Row(
            children: const [
              Icon(Icons.place, size: 16),
              SizedBox(width: 6),
              Text('All Locations'),
            ],
          ),
        ),
        ..._locations.map(
          (location) =>
              DropdownMenuItem(value: location, child: Text(location)),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        'No orders for this location',
        style: TextStyle(color: Colors.grey[600]),
      ),
    );
  }

  List<Map<String, dynamic>> _buildStatusGroups(
    Map<OrderStatus, int> statusCounts,
  ) {
    final groups = <Map<String, dynamic>>[];

    for (final status in OrderStatus.values) {
      final count = statusCounts[status] ?? 0;
      if (count > 0) {
        final statusInfo = getStatusInfo(status);
        groups.add({
          'status': status,
          'count': count,
          'color': statusInfo.textColor,
          'label': statusInfo.label,
        });
      }
    }

    return groups;
  }

  Widget _buildStatusGroupsWidget(List<Map<String, dynamic>> groups) {
    return Column(
      children: groups.map((group) {
        final status = group['status'] as OrderStatus;
        final count = group['count'] as int;
        final color = group['color'] as Color;
        final label = group['label'] as String;
        final nextStatus = getNextStatus(status);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '$count item${count == 1 ? '' : 's'}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$count', style: const TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),
                  if (nextStatus != null && !_isUpdating)
                    OutlinedButton.icon(
                      onPressed: () => _updateStatusForItems(status),
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: Text('Move to ${getStatusInfo(nextStatus).label}'),
                    ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
