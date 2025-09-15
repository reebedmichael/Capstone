import 'package:flutter/material.dart';
import '../../types/order.dart';
import '../../utils/status_utils.dart';
import 'cancel_confirmation.dart';
import 'status_badge.dart';

class OrderCard extends StatefulWidget {
  final Order order;
  final String? selectedDay;
  final bool isPastOrder;
  final void Function(Order order) onViewDetails;
  final void Function(String orderId, OrderStatus status) onUpdateStatus;
  final void Function(String orderId) onCancelOrder;

  const OrderCard({
    super.key,
    required this.order,
    this.selectedDay,
    this.isPastOrder = false,
    required this.onViewDetails,
    required this.onUpdateStatus,
    required this.onCancelOrder,
  });

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final totalItems = order.items.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );
    final nextStatus = getNextStatus(order.status);
    final canProgressStatus = canProgress(order.status);
    final canCancel = canBeCancelled(order.status);
    final cancellableItemsCount = widget.selectedDay != null
        ? order.items
              .where(
                (item) =>
                    item.scheduledDay == widget.selectedDay &&
                    canBeCancelled(item.status),
              )
              .length
        : order.items.where((item) => canBeCancelled(item.status)).length;

    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                if (isWide) {
                  return _buildWideLayout(
                    context,
                    totalItems,
                    canProgressStatus,
                    nextStatus,
                    canCancel,
                    cancellableItemsCount,
                  );
                } else {
                  return _buildNarrowLayout(
                    context,
                    totalItems,
                    canProgressStatus,
                    nextStatus,
                    canCancel,
                    cancellableItemsCount,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the layout for wide screens (e.g., desktop or tablet in landscape).
  Widget _buildWideLayout(
    BuildContext context,
    int totalItems,
    bool canProgressStatus,
    OrderStatus? nextStatus,
    bool canCancel,
    int cancellableItemsCount,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 3, child: _buildOrderInfoSection(context)),
        Expanded(
          flex: 2,
          child: _buildItemsSummarySection(context, totalItems),
        ),
        Expanded(
          flex: 3,
          child: _buildStatusSection(context, canProgressStatus, nextStatus),
        ),
        Expanded(
          flex: 3,
          child: _buildActionsSection(
            context,
            canCancel,
            cancellableItemsCount,
          ),
        ),
      ],
    );
  }

  /// Builds the layout for narrow screens (e.g., mobile phones).
  Widget _buildNarrowLayout(
    BuildContext context,
    int totalItems,
    bool canProgressStatus,
    OrderStatus? nextStatus,
    bool canCancel,
    int cancellableItemsCount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOrderInfoSection(context),
        const Divider(height: 24.0),
        _MobileInfoRow(
          label: 'Items: ',
          child: Text(
            "$totalItems item${totalItems != 1 ? 's' : ''} / R${widget.order.totalAmount.toStringAsFixed(2)}",
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(height: 20.0),
        _MobileInfoRow(
          label: 'Status:',
          child: _buildStatusSection(context, canProgressStatus, nextStatus),
        ),
        const Divider(height: 24.0),
        _buildActionsSection(context, canCancel, cancellableItemsCount),
      ],
    );
  }

  /// Section for Order ID, Customer Email, and completed date.
  Widget _buildOrderInfoSection(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.order.id,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          widget.order.customerEmail,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        // if (widget.isPastOrder)
        //   Padding(
        //     padding: const EdgeInsets.only(top: 4),
        //     child: Text(
        //       "Afgehandel op: ${widget.order.createdAt.toLocal().toString().split(' ').first}",
        //       style: theme.textTheme.labelSmall?.copyWith(
        //         color: Colors.grey[600],
        //       ),
        //     ),
        //   ),
      ],
    );
  }

  /// Section for total items and amount.
  Widget _buildItemsSummarySection(BuildContext context, int totalItems) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$totalItems item${totalItems != 1 ? 's' : ''}",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          "R${widget.order.totalAmount.toStringAsFixed(2)}",
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }

  /// Section for the status badge and update button.
  Widget _buildStatusSection(
    BuildContext context,
    bool canProgressStatus,
    OrderStatus? nextStatus,
  ) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        StatusBadge(status: widget.order.status),
        if (canProgressStatus && nextStatus != null)
          OutlinedButton.icon(
            onPressed: () => widget.onUpdateStatus(widget.order.id, nextStatus),
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text("Opdateer"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
              visualDensity: VisualDensity.compact,
            ),
          ),
      ],
    );
  }

  /// Section for the view and cancel buttons.
  Widget _buildActionsSection(
    BuildContext context,
    bool canCancel,
    int cancellableItemsCount,
  ) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: () => widget.onViewDetails(widget.order),
          icon: const Icon(Icons.visibility, size: 16),
          label: const Text("Besigtig"),
          style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
        ),
        if (canCancel && cancellableItemsCount > 0)
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
            onPressed: () => _showCancelDialog(
              context,
              widget.order.id,
              cancellableItemsCount,
            ),
            icon: const Icon(Icons.delete, size: 16),
            label: const Text("Kanseleer"),
          ),
      ],
    );
  }

  void _showCancelDialog(
    BuildContext context,
    String orderId,
    int cancellableItemsCount,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CancelConfirmationDialog(
        isOpen: true,
        onClose: () => Navigator.of(context).pop(),
        onConfirm: () {
          widget.onCancelOrder(orderId);
          // Navigator.of(context).pop();
        },
        orderNumber: orderId,
        customerEmail: widget.order.customerEmail,
        selectedDay: widget.selectedDay,
        itemCount: cancellableItemsCount,
      ),
    );
  }
}

/// A helper widget to create a labeled row for the mobile layout.
class _MobileInfoRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _MobileInfoRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 16),
        Flexible(child: child),
      ],
    );
  }
}
