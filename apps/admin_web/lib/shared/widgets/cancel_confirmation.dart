import 'package:flutter/material.dart';

class CancelConfirmationDialog extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final VoidCallback onConfirm;
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

  void _handleConfirm(BuildContext context) {
    // Navigator.of(context).pop();
    onConfirm();
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
                          "Bevestig Kanselasie",
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Hierdie aksie kan nie ongedaan gemaak word nie.",
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
                      "Bestelling:",
                      orderNumber,
                      context,
                      highlight: true,
                    ),
                    _buildDetailRow("Kliënt:", customerEmail, context),
                    if (selectedDay != null) ...[
                      _buildDetailRow(
                        "Dag:",
                        selectedDay!,
                        context,
                        highlight: true,
                        highlightColor: Theme.of(context).colorScheme.error,
                      ),
                      if (itemCount != null)
                        _buildDetailRow(
                          "Items om te kanseleer:",
                          "$itemCount item${itemCount != 1 ? 's' : ''}",
                          context,
                          highlight: true,
                          highlightColor: Theme.of(context).colorScheme.error,
                        ),
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
                    child: const Text("Hou bestelling"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    onPressed: () => _handleConfirm(context),
                    child: Text(
                      selectedDay != null
                          ? "Kanseleer $selectedDay se items"
                          : "Kanseleer bestelling",
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: highlight
                  ? (highlightColor ?? Theme.of(context).colorScheme.primary)
                  : null,
              fontWeight: highlight ? FontWeight.w600 : null,
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
  required VoidCallback onConfirm,
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
