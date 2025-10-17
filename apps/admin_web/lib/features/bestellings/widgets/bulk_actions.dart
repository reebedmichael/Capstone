import 'package:flutter/material.dart';
import '../../../shared/types/order.dart';
import '../../../shared/utils/status_utils.dart';
import '../../../shared/constants/order_constants.dart';
import 'status_update_confirmation.dart';

typedef BulkUpdateCallback =
    Future<void> Function(List<String> orderIds, OrderStatus status);

/// A widget for performing bulk status updates on a list of orders.
class BulkActions extends StatefulWidget {
  final List<Order> orders;
  final BulkUpdateCallback onBulkUpdate;

  const BulkActions({
    super.key,
    required this.orders,
    required this.onBulkUpdate,
  });

  @override
  State<BulkActions> createState() => _BulkActionsState();
}

/// Represents a single option in the status dropdown menu.
class _StatusOption {
  final OrderStatus value;
  final String label;
  final int count;

  _StatusOption({
    required this.value,
    required this.label,
    required this.count,
  });
}

class _BulkActionsState extends State<BulkActions> {
  final Set<String> _selectedOrders = {};
  OrderStatus? _bulkStatus;
  bool _isUpdating = false;

  /// Helper to map OrderStatus enum to a human-readable label.
  String _getStatusLabel(OrderStatus status) {
    return OrderConstants.getStatusLabel(status.name);
  }

  /// Filters the input orders to only those that can progress to a new status.
  List<Order> get _eligibleOrders =>
      widget.orders.where((o) => canProgress(o.status)).toList();

  /// Computes all possible next status options based on the eligible orders.
  List<_StatusOption> get _allAvailableStatusOptions {
    final Map<OrderStatus, int> counts = {};

    for (final order in _eligibleOrders) {
      final next = getNextStatus(order.status);
      if (next != null) {
        counts[next] = (counts[next] ?? 0) + 1;
      }
    }

    return counts.entries
        .map(
          (e) => _StatusOption(
            value: e.key,
            label: _getStatusLabel(e.key),
            count: e.value,
          ),
        )
        .toList();
  }

  /// Handles the bulk update action, calling the callback and resetting state.
  Future<void> _handleBulkUpdate() async {
    if (_selectedOrders.isNotEmpty && _bulkStatus != null) {
      // Get the orders that will be updated
      final ordersToUpdate = widget.orders
          .where((order) => _selectedOrders.contains(order.id))
          .toList();

      if (ordersToUpdate.isEmpty) return;

      // Show confirmation dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => StatusUpdateConfirmationDialog(
            isOpen: true,
            onClose: () => Navigator.of(context).pop(),
            onConfirm: () async {
              setState(() {
                _isUpdating = true;
              });

              try {
                // Close the dialog immediately when update starts
                if (mounted) {
                  Navigator.of(context).pop();
                }

                await widget.onBulkUpdate(
                  _selectedOrders.toList(),
                  _bulkStatus!,
                );
                setState(() {
                  _selectedOrders.clear();
                  _bulkStatus = null;
                });
              } catch (e) {
                // Re-throw to let the parent handle it
                rethrow;
              } finally {
                if (mounted) {
                  setState(() {
                    _isUpdating = false;
                  });
                }
              }
            },
            orders: ordersToUpdate,
            currentStatus: ordersToUpdate
                .first
                .status, // Assuming all have same current status
            newStatus: _bulkStatus!,
            isBulkUpdate: true,
          ),
        );
      }
    }
  }

  /// Handles dropdown value changes. Auto-selects all eligible orders for the chosen status.
  void _handleStatusChange(OrderStatus? status) {
    setState(() {
      _bulkStatus = status;
      _selectedOrders.clear(); // Always clear previous selections first

      if (status != null) {
        // Find all orders that can be moved to the selected status
        final eligibleOrderIds = _eligibleOrders
            .where((o) => getNextStatus(o.status) == status)
            .map((o) => o.id);

        // Auto-select them
        _selectedOrders.addAll(eligibleOrderIds);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_eligibleOrders.isEmpty) {
      return const SizedBox.shrink(); // Render nothing if no actions are possible
    }

    final allOptions = _allAvailableStatusOptions;
    final theme = Theme.of(context);

    // Ensure the selected status is still a valid option
    final isBulkStatusValid = allOptions.any((opt) => opt.value == _bulkStatus);
    final currentBulkStatus = isBulkStatusValid ? _bulkStatus : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            OrderConstants.getUiString('bulkUpdate'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          if (allOptions.isNotEmpty) ...[
            // Dropdown Menu
            SizedBox(
              width: 220, // Constrained width
              height: 40, // Compact height
              child: DropdownButtonFormField<OrderStatus?>(
                value: currentBulkStatus,
                hint: Text(OrderConstants.getUiString('selectAction')),
                isExpanded: true,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(),
                  // isDense: true,
                ),
                items: [
                  DropdownMenuItem<OrderStatus?>(
                    value: null,
                    child: Text(OrderConstants.getUiString('selectAction')),
                  ),
                  ...allOptions.map((opt) {
                    return DropdownMenuItem<OrderStatus?>(
                      value: opt.value,
                      child: Text('${opt.label} (${opt.count})'),
                    );
                  }),
                ],
                onChanged: _handleStatusChange,
              ),
            ),
            const SizedBox(width: 12),

            // Conditional "Update" Button or "No eligible orders" message
            if (currentBulkStatus != null)
              if (_selectedOrders.isNotEmpty)
                Stack(
                  children: [
                    ElevatedButton(
                      onPressed: _isUpdating
                          ? null
                          : () async => await _handleBulkUpdate(),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        '${OrderConstants.getUiString('updateCount')} ${_selectedOrders.length}',
                      ),
                    ),
                    if (_isUpdating)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                  ],
                )
              else
                Expanded(
                  child: Text(
                    OrderConstants.getUiString('noEligibleOrders'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
          ] else ...[
            // "No actions available" message
            Expanded(
              child: Text(
                OrderConstants.getUiString('noActionsAvailable'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
