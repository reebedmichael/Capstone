import 'package:flutter/material.dart';
import '../../../shared/types/order.dart';
import '../../../shared/constants/order_constants.dart';

class StatusUpdateConfirmationDialog extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final Future<void> Function() onConfirm;
  final List<Order> orders;
  final OrderStatus currentStatus;
  final OrderStatus newStatus;
  final bool isBulkUpdate;

  const StatusUpdateConfirmationDialog({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.onConfirm,
    required this.orders,
    required this.currentStatus,
    required this.newStatus,
    this.isBulkUpdate = false,
  });

  Future<void> _handleConfirm(BuildContext context) async {
    try {
      await onConfirm();
      // Don't call onClose() here as the onConfirm callback should handle navigation
    } catch (e) {
      // If there's an error, we should still close the dialog
      onClose();
      // Show error message to user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Update failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.update,
                      color: Theme.of(context).colorScheme.primary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isBulkUpdate
                              ? OrderConstants.getUiString(
                                  'confirmBulkStatusUpdate',
                                )
                              : OrderConstants.getUiString(
                                  'confirmStatusUpdate',
                                ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          OrderConstants.getUiString(
                            'statusUpdateIrreversible',
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Status Change Display
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Current Status
                        Column(
                          children: [
                            Text(
                              OrderConstants.getUiString('currentStatus'),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  currentStatus,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getStatusColor(currentStatus),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                OrderConstants.getStatusLabel(
                                  currentStatus.name,
                                ),
                                style: TextStyle(
                                  color: _getStatusColor(currentStatus),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Arrow
                        Icon(
                          Icons.arrow_forward,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),

                        // New Status
                        Column(
                          children: [
                            Text(
                              OrderConstants.getUiString('newStatus'),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  newStatus,
                                ).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _getStatusColor(newStatus),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                OrderConstants.getStatusLabel(newStatus.name),
                                style: TextStyle(
                                  color: _getStatusColor(newStatus),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Orders List
              if (orders.isNotEmpty) ...[
                Text(
                  isBulkUpdate
                      ? '${orders.length} bestelling${orders.length != 1 ? 's' : ''} sal opdateer word:'
                      : 'Bestelling wat opdateer sal word:',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                order.id,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            Text(
                              order.customerEmail,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Footer Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      onClose();
                    },
                    child: Text(OrderConstants.getUiString('cancel')),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: () async => await _handleConfirm(context),
                    child: Text(
                      isBulkUpdate
                          ? '${OrderConstants.getUiString('updateCount')} ${orders.length}'
                          : OrderConstants.getUiString('updateStatus'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.preparing:
        return Colors.blue;
      case OrderStatus.readyDelivery:
        return Colors.purple;
      case OrderStatus.outForDelivery:
        return Colors.indigo;
      case OrderStatus.readyFetch:
        return Colors.teal;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.done:
        return Colors.green.shade700;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.verstryk:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }
}

// Usage example
void showStatusUpdateConfirmationDialog(
  BuildContext context, {
  required List<Order> orders,
  required OrderStatus currentStatus,
  required OrderStatus newStatus,
  required Future<void> Function() onConfirm,
  bool isBulkUpdate = false,
}) {
  showDialog(
    context: context,
    builder: (_) => StatusUpdateConfirmationDialog(
      isOpen: true,
      onClose: () {},
      onConfirm: onConfirm,
      orders: orders,
      currentStatus: currentStatus,
      newStatus: newStatus,
      isBulkUpdate: isBulkUpdate,
    ),
  );
}
