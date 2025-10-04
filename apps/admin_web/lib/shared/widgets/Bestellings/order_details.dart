// order_details_modal.dart
import 'package:flutter/material.dart';
import '../../types/order.dart';
import '../../utils/status_utils.dart';
import '../../constants/order_constants.dart';
import 'cancel_confirmation.dart';
import 'status_badge.dart';

class OrderDetailsModal extends StatefulWidget {
  final Order order;
  final String? selectedDay;
  final bool isOpen;
  final VoidCallback onClose;
  final Future<void> Function(String orderId, String itemId, OrderStatus status)
  onUpdateItemStatus;
  final Future<void> Function(String orderId) onCancelOrder;

  const OrderDetailsModal({
    super.key,
    required this.order,
    this.selectedDay,
    required this.isOpen,
    required this.onClose,
    required this.onUpdateItemStatus,
    required this.onCancelOrder,
  });

  @override
  State<OrderDetailsModal> createState() => _OrderDetailsModalState();
}

class _OrderDetailsModalState extends State<OrderDetailsModal> {
  String? editingItem;

  Future<void> handleUpdateItemStatus(
    String itemId,
    OrderStatus newStatus,
  ) async {
    await widget.onUpdateItemStatus(widget.order.id, itemId, newStatus);
    setState(() => editingItem = null);
  }

  Future<void> handleProgressItem(
    String itemId,
    OrderStatus currentStatus,
  ) async {
    final nextStatus = getNextStatus(currentStatus);
    if (nextStatus != null) {
      await widget.onUpdateItemStatus(widget.order.id, itemId, nextStatus);
    }
  }

  Future<void> handleCancelOrder() async {
    await widget.onCancelOrder(widget.order.id);
    // setState(() => showCancelDialog = false);
  }

  @override
  Widget build(BuildContext context) {
    // Group items by day
    final itemsByDay = <String, List<OrderItem>>{};
    for (var item in widget.order.items) {
      itemsByDay.putIfAbsent(item.scheduledDay, () => []).add(item);
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
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
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        OrderConstants.getUiString('orderDetails'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${OrderConstants.getUiString('orderId')} ${widget.order.id}",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            "${OrderConstants.getUiString('client')} ${widget.order.customerEmail}",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            "Aflaai punt: ${widget.order.deliveryPoint}",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: itemsByDay.entries.map((entry) {
                      final day = entry.key;
                      final items = entry.value;
                      final isSelected = widget.selectedDay == day;

                      return Card(
                        color: isSelected
                            ? Theme.of(context).colorScheme.surface
                            : null,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    day,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      margin: const EdgeInsets.only(left: 8),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "Bekyk tans",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onPrimary,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Column(
                                children: [
                                  for (int i = 0; i < items.length; i++) ...[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        // Item Info
                                        Expanded(
                                          child: Row(
                                            children: [
                                              Text(
                                                items[i].name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "x ${items[i].quantity}",
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                "R${(items[i].price * items[i].quantity).toStringAsFixed(2)}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        // Status / Actions
                                        Row(
                                          children: [
                                            if (editingItem == items[i].id)
                                              DropdownButton<OrderStatus>(
                                                value: items[i].status,
                                                onChanged: (value) async {
                                                  if (value != null) {
                                                    await handleUpdateItemStatus(
                                                      items[i].id,
                                                      value,
                                                    );
                                                  }
                                                },
                                                items: OrderStatus.values
                                                    .map(
                                                      (status) =>
                                                          DropdownMenuItem(
                                                            value: status,
                                                            child: Text(
                                                              status.name,
                                                            ),
                                                          ),
                                                    )
                                                    .toList(),
                                              )
                                            else ...[
                                              StatusBadge(
                                                status: items[i].status,
                                              ),
                                              // if (canProgress(items[i].status))
                                              //   IconButton(
                                              //     icon: const Icon(
                                              //       Icons.arrow_forward,
                                              //     ),
                                              //     onPressed: () =>
                                              //         handleProgressItem(
                                              //           items[i].id,
                                              //           items[i].status,
                                              //         ),
                                              //   ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (i < items.length - 1)
                                      const Divider(height: 16),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // Footer
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${OrderConstants.getUiString('total')} R${widget.order.totalAmount.toStringAsFixed(2)}",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        if (widget.selectedDay != null &&
                            widget.selectedDay != "Alle")
                          Builder(
                            builder: (context) {
                              final dayItems = widget.order.items
                                  .where(
                                    (i) => i.scheduledDay == widget.selectedDay,
                                  )
                                  .toList();
                              final cancellableItems = dayItems
                                  .where((i) => canBeCancelled(i.status))
                                  .toList();

                              if (cancellableItems.isEmpty) {
                                return const SizedBox();
                              }

                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onError,
                                ),
                                onPressed: () => _showCancelDialog(
                                  context,
                                  cancellableItems.length,
                                ),
                                child: Text(
                                  "Kanseleer ${widget.selectedDay} se items (${cancellableItems.length})",
                                ),
                              );
                            },
                          ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: widget.onClose,
                          child: Text(OrderConstants.getUiString('close')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, int itemCount) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CancelConfirmationDialog(
        isOpen: true,
        onClose: () => Navigator.of(context).pop(),
        onConfirm: () async {
          await handleCancelOrder();
          Navigator.of(context).pop();
        },
        orderNumber: widget.order.id,
        customerEmail: widget.order.customerEmail,
        selectedDay: widget.selectedDay != "Alle" ? widget.selectedDay : null,
        itemCount: itemCount,
      ),
    );
  }
}
