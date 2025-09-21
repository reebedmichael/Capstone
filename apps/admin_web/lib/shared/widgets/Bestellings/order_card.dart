import 'package:flutter/material.dart';
import '../../types/order.dart';
import '../../utils/status_utils.dart';
import '../../constants/order_constants.dart';
import '../common_widgets.dart';
import 'cancel_confirmation.dart';
import 'status_badge.dart';

class OrderCard extends StatefulWidget {
  final Order order;
  final String? selectedDay;
  final bool isPastOrder;
  final void Function(Order order) onViewDetails;
  final Future<void> Function(String orderId, OrderStatus status)
  onUpdateStatus;
  final Future<void> Function(String orderId) onCancelOrder;

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
        LabeledRow(
          label: 'Items: ',
          child: Text(
            "$totalItems item${totalItems != 1 ? 's' : ''} / R${widget.order.totalAmount.toStringAsFixed(2)}",
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.right,
          ),
        ),
        const SizedBox(height: 20.0),
        LabeledRow(
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
        const SizedBox(height: 2),
        Row(
          children: [
            Text("Aflaai punt: "),
            Text(
              widget.order.deliveryPoint,
              style: TextStyle(color: const Color.fromARGB(255, 10, 67, 0)),
            ),
          ],
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
          ActionButton(
            onPressed: () async =>
                await widget.onUpdateStatus(widget.order.id, nextStatus),
            icon: Icons.arrow_forward,
            label: OrderConstants.getUiString('updateStatus'),
            isOutlined: true,
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
        ActionButton(
          onPressed: () => widget.onViewDetails(widget.order),
          icon: Icons.visibility,
          label: OrderConstants.getUiString('viewDetails'),
          isOutlined: true,
        ),
        if (canCancel && cancellableItemsCount > 0)
          ActionButton(
            onPressed: () => _showCancelDialog(
              context,
              widget.order.id,
              cancellableItemsCount,
            ),
            icon: Icons.delete,
            label: OrderConstants.getUiString('cancelOrder'),
            isOutlined: false,
            isDestructive: true,
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
        onConfirm: () async {
          await widget.onCancelOrder(orderId);
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
