import 'package:flutter/material.dart';
import '../../constants/order_constants.dart';

class CancelConfirmationDialog extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final Future<void> Function() onConfirm;
  final String orderNumber;
  final String customerEmail;
  final String? selectedDay;
  final int? itemCount;

  const CancelConfirmationDialog({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.onConfirm,
    required this.orderNumber,
    required this.customerEmail,
    this.selectedDay,
    this.itemCount,
  });

  Future<void> _handleConfirm(BuildContext context) async {
    // Navigator.of(context).pop();
    await onConfirm();
    onClose();
    // Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
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
                      ).colorScheme.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.warning, color: Colors.red, size: 40),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          OrderConstants.getUiString('confirmCancellation'),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          OrderConstants.getUiString('irreversibleAction'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Order Details
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    _buildDetailRow(
                      "${OrderConstants.getUiString('orderId')} ",
                      orderNumber,
                      context,
                      highlight: true,
                    ),
                    _buildDetailRow(
                      "${OrderConstants.getUiString('client')} ",
                      customerEmail,
                      context,
                    ),
                    if (selectedDay != null) ...[
                      _buildDetailRow(
                        "${OrderConstants.getUiString('day')} ",
                        selectedDay!,
                        context,
                        highlight: true,
                        highlightColor: Theme.of(context).colorScheme.error,
                      ),
                      // if (itemCount != null)
                      //   _buildDetailRow(
                      //     "${OrderConstants.getUiString('itemsToCancel')} ",
                      //     "$itemCount item${itemCount != 1 ? 's' : ''}",
                      //     context,
                      //     highlight: true,
                      //     highlightColor: Theme.of(context).colorScheme.error,
                      //   ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Info text
              Text(
                selectedDay != null
                    ? "Slegs items geskeduleer vir $selectedDay sal gekanseleer word. Items vir ander dae sal aktief bly."
                    : "Alle items in hierdie bestelling sal gekanseleer word.",
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),

              const SizedBox(height: 20),

              // Footer Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      onClose();
                      // Navigator.of(context).pop();
                    },
                    child: Text(OrderConstants.getUiString('keepOrder')),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    onPressed: () async => await _handleConfirm(context),
                    child: Text(
                      selectedDay != null
                          ? "${OrderConstants.getUiString('cancelItems')} $selectedDay se items"
                          : "${OrderConstants.getUiString('cancelItems')} bestelling",
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

  Widget _buildDetailRow(
    String label,
    String value,
    BuildContext context, {
    bool highlight = false,
    Color? highlightColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // align texts at the top
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              softWrap: true,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: highlight
                    ? (highlightColor ?? Theme.of(context).colorScheme.primary)
                    : null,
                fontWeight: highlight ? FontWeight.w600 : null,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}

// Usage example
void showCancelConfirmationDialog(
  BuildContext context, {
  required String orderNumber,
  required String customerEmail,
  String? selectedDay,
  int? itemCount,
  required Future<void> Function() onConfirm,
}) {
  showDialog(
    context: context,
    builder: (_) => CancelConfirmationDialog(
      isOpen: true,
      onClose: () {},
      onConfirm: onConfirm,
      orderNumber: orderNumber,
      customerEmail: customerEmail,
      selectedDay: selectedDay,
      itemCount: itemCount,
    ),
  );
}
