import 'package:flutter/material.dart';
import '../types/order.dart'; // <-- adjust path if needed
import '../utils/status_utils.dart'; // <-- must export getNextStatus(OrderStatus?), canProgress(OrderStatus)

typedef BulkUpdateCallback =
    void Function(List<String> orderIds, OrderStatus status);

class BulkActions extends StatefulWidget {
  final List<Order> orders;
  final String selectedDay;
  final BulkUpdateCallback onBulkUpdate;

  const BulkActions({
    Key? key,
    required this.orders,
    required this.selectedDay,
    required this.onBulkUpdate,
  }) : super(key: key);

  @override
  State<BulkActions> createState() => _BulkActionsState();
}

class _StatusOption {
  final OrderStatus value;
  final String label;
  final int count;
  final List<String> eligibleOrderIds;

  _StatusOption({
    required this.value,
    required this.label,
    required this.count,
    required this.eligibleOrderIds,
  });
}

class _BulkActionsState extends State<BulkActions> {
  final Set<String> _selectedOrders = {};
  OrderStatus? _bulkStatus;

  // Helper: map OrderStatus -> human label (adjust as you want)
  String _getStatusLabel(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Bestelling Ontvang';
      case OrderStatus.preparing:
        return 'Besig met Voorbereiding';
      case OrderStatus.readyDelivery:
        return 'Gereed vir aflewering';
      case OrderStatus.readyFetch:
        return 'Reg vir afhaal';
      case OrderStatus.outForDelivery:
        return 'Uit vir aflewering';
      case OrderStatus.delivered:
        return 'By afleweringspunt';
      case OrderStatus.done:
        return 'Afgehandel';
      case OrderStatus.cancelled:
        return 'Gekanselleer';
    }
  }

  // Compute eligibleOrders (same logic as your TS: assumes `orders` are already day-filtered if needed)
  List<Order> get _eligibleOrders {
    return widget.orders.where((o) => canProgress(o.status)).toList();
  }

  // NEW: Logic to determine dropdown options based on current selection.
  // If one order is selected, it shows only its next status.
  // Otherwise, it shows all possible next statuses.
  List<_StatusOption> get _dropdownOptions {
    if (_selectedOrders.length == 1) {
      final selectedId = _selectedOrders.first;
      final selectedOrder = _eligibleOrders.firstWhere(
        (o) => o.id == selectedId,
        orElse: () =>
            throw Exception('Selected order not found in eligible list'),
      );

      final nextStatus = getNextStatus(selectedOrder.status);
      if (nextStatus != null) {
        return [
          _StatusOption(
            value: nextStatus,
            label: _getStatusLabel(nextStatus),
            count: 1,
            eligibleOrderIds: [selectedId],
          ),
        ];
      }
      return []; // Selected order cannot progress further
    }
    // For 0 or >1 selections, show all available options
    return _calculateAllAvailableStatusOptions;
  }

  // Build all available status options from ALL eligibleOrders
  List<_StatusOption> get _calculateAllAvailableStatusOptions {
    final Map<OrderStatus, int> counts = {};
    final Map<OrderStatus, List<String>> idsMap = {};

    for (final order in _eligibleOrders) {
      final next = getNextStatus(order.status);
      if (next != null) {
        counts[next] = (counts[next] ?? 0) + 1;
        idsMap.putIfAbsent(next, () => []).add(order.id);
      }
    }

    return counts.entries
        .map(
          (e) => _StatusOption(
            value: e.key,
            label: _getStatusLabel(e.key),
            count: e.value,
            eligibleOrderIds: idsMap[e.key] ?? [],
          ),
        )
        .toList();
  }

  void _toggleOrder(String orderId) {
    setState(() {
      if (_selectedOrders.contains(orderId)) {
        _selectedOrders.remove(orderId);
      } else {
        _selectedOrders.add(orderId);
      }
    });
  }

  void _toggleAll() {
    setState(() {
      if (_bulkStatus != null) {
        final eligibleForStatus = _eligibleOrders
            .where((o) => getNextStatus(o.status) == _bulkStatus)
            .map((o) => o.id)
            .toList();
        final allEligibleSelected = eligibleForStatus.every(
          (id) => _selectedOrders.contains(id),
        );
        if (allEligibleSelected) {
          _selectedOrders.clear();
        } else {
          _selectedOrders
            ..clear()
            ..addAll(eligibleForStatus);
        }
      } else {
        if (_selectedOrders.length == _eligibleOrders.length) {
          _selectedOrders.clear();
        } else {
          _selectedOrders
            ..clear()
            ..addAll(_eligibleOrders.map((o) => o.id));
        }
      }
    });
  }

  void _handleBulkUpdate() {
    if (_selectedOrders.isNotEmpty && _bulkStatus != null) {
      widget.onBulkUpdate(_selectedOrders.toList(), _bulkStatus!);
      setState(() {
        _selectedOrders.clear();
        _bulkStatus = null;
      });
    }
  }

  void _handleStatusChange(OrderStatus? status) {
    setState(() {
      _bulkStatus = status;
      if (status == null) {
        _selectedOrders.clear();
      } else {
        final eligibleOrderIds = _eligibleOrders
            .where((o) => getNextStatus(o.status) == status)
            .map((o) => o.id)
            .toList();
        _selectedOrders
          ..clear()
          ..addAll(eligibleOrderIds);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final eligibleOrders = _eligibleOrders;
    if (eligibleOrders.isEmpty) return const SizedBox.shrink();

    // MODIFIED: Use the new dynamic getter for dropdown options
    final allOptions = _dropdownOptions;
    final theme = Theme.of(context);

    // MODIFIED: Ensure the selected status is valid for the current options.
    // This prevents an error if the options change after an order is selected.
    final isBulkStatusValid = allOptions.any((opt) => opt.value == _bulkStatus);
    final currentBulkStatus = isBulkStatusValid ? _bulkStatus : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Grootmaat aksies vir ${widget.selectedDay}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Select All Toggle
          Row(
            children: [
              TextButton.icon(
                onPressed: _toggleAll,
                icon: _buildSelectAllIcon(),
                label: Text(
                  _bulkStatus != null
                      ? 'Almal wat in aanmerking kom (${eligibleOrders.where((order) => getNextStatus(order.status) == _bulkStatus).length})'
                      : 'Almal (${eligibleOrders.length})',
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Optional helper line about auto-selected count
          if (_bulkStatus != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _selectedOrders.length == 1
                    ? 'Outomaties 1 bestelling gekies wat na ${_getStatusLabel(_bulkStatus!)} kan beweeg:'
                    : 'Outomaties ${_selectedOrders.length} bestellings gekies wat kan skuif na ${_getStatusLabel(_bulkStatus!)}:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),

          // Orders grid (uses Wrap for responsiveness)
          LayoutBuilder(
            builder: (context, constraints) {
              // We'll make each pill approx 280px wide max to mimic grid columns
              const double itemMaxWidth = 320;
              final int columns = (constraints.maxWidth / itemMaxWidth)
                  .floor()
                  .clamp(1, 3);

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: eligibleOrders.map((order) {
                  final canMoveToCurrentStatus =
                      _bulkStatus != null &&
                      getNextStatus(order.status) == _bulkStatus;
                  final disabledBecauseDifferentStatus =
                      _bulkStatus != null && !canMoveToCurrentStatus;
                  final isSelected = _selectedOrders.contains(order.id);
                  final isAutoSelected =
                      _bulkStatus != null && _selectedOrders.contains(order.id);

                  final buttonChild = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected
                            ? Icons.check_box
                            : Icons.check_box_outline_blank,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${order.id} - ${order.customerEmail}',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      if (isAutoSelected)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Outomaties',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  );

                  final button = SizedBox(
                    width: (constraints.maxWidth - (columns - 1) * 8) / columns,
                    child: OutlinedButton(
                      onPressed: disabledBecauseDifferentStatus
                          ? null
                          : () => _toggleOrder(order.id),
                      style: OutlinedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      child: buttonChild,
                    ),
                  );

                  // If selected -> use filled style (mimics variant="default")
                  return isSelected
                      ? SizedBox(
                          width:
                              (constraints.maxWidth - (columns - 1) * 8) /
                              columns,
                          child: ElevatedButton(
                            onPressed: disabledBecauseDifferentStatus
                                ? null
                                : () => _toggleOrder(order.id),
                            style: ElevatedButton.styleFrom(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            child: buttonChild,
                          ),
                        )
                      : button;
                }).toList(),
              );
            },
          ),

          const SizedBox(height: 12),

          // Bulk action controls (dropdown + update)
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 600; // adjust breakpoint

              if (isMobile) {
                // Mobile: stack vertically
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: Text(
                        'Kies die volgende stap om geskikte bestellings outomaties te kies:',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (allOptions.isNotEmpty) ...[
                      DropdownButton<OrderStatus?>(
                        value: currentBulkStatus,
                        hint: const Text('Kies volgende stap'),
                        isExpanded: true, // fill width on mobile
                        items: [
                          const DropdownMenuItem<OrderStatus?>(
                            value: null,
                            child: Text("Kies volgende stap"),
                          ),
                          ...allOptions.map((opt) {
                            return DropdownMenuItem<OrderStatus?>(
                              value: opt.value,
                              child: Text('${opt.label} (${opt.count})'),
                            );
                          }),
                        ],
                        onChanged: (v) => _handleStatusChange(v),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed:
                            (currentBulkStatus == null ||
                                _selectedOrders.isEmpty)
                            ? null
                            : _handleBulkUpdate,
                        child: Text(
                          'Opdateer ${_selectedOrders.length} bestelling${_selectedOrders.length != 1 ? 's' : ''}',
                        ),
                      ),
                    ] else
                      Text(
                        'Geen bestellings kan verder gevorder word nie',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                );
              } else {
                // Desktop/tablet: inline row
                return Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 15.0),
                        child: Text(
                          'Kies die volgende stap om geskikte bestellings outomaties te kies:',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    if (allOptions.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      DropdownButton<OrderStatus?>(
                        value: currentBulkStatus,
                        hint: const Text('Kies volgende stap'),
                        items: [
                          const DropdownMenuItem<OrderStatus?>(
                            value: null,
                            child: Text("Kies volgende stap"),
                          ),
                          ...allOptions.map((opt) {
                            return DropdownMenuItem<OrderStatus?>(
                              value: opt.value,
                              child: Text('${opt.label} (${opt.count})'),
                            );
                          }),
                        ],
                        onChanged: (v) => _handleStatusChange(v),
                      ),
                      const SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: ElevatedButton(
                          onPressed:
                              (currentBulkStatus == null ||
                                  _selectedOrders.isEmpty)
                              ? null
                              : _handleBulkUpdate,
                          child: Text(
                            'Opdateer ${_selectedOrders.length} bestelling${_selectedOrders.length != 1 ? 's' : ''}',
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 12),
                      Text(
                        'Geen bestellings kan verder gevorder word nie',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectAllIcon() {
    if (_bulkStatus != null) {
      final eligibleForStatus = _eligibleOrders.where(
        (order) => getNextStatus(order.status) == _bulkStatus,
      );
      final allEligibleSelected = eligibleForStatus.every(
        (o) => _selectedOrders.contains(o.id),
      );
      return Icon(
        allEligibleSelected ? Icons.check_box : Icons.check_box_outline_blank,
      );
    } else {
      return Icon(
        _selectedOrders.length == _eligibleOrders.length
            ? Icons.check_box
            : Icons.check_box_outline_blank,
      );
    }
  }
}

/// Small badge used in header (keeps visual parity with original TS `Badge variant="outline"`)
class _SimpleBadge extends StatelessWidget {
  final String text;

  const _SimpleBadge({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.fromBorderSide(
          BorderSide(color: cs.onSurface.withOpacity(0.12)),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: cs.onSurface),
      ),
    );
  }
}
