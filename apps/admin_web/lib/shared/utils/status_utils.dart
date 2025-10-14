import 'package:flutter/material.dart';
import '../types/order.dart';

/// Define the valid status progression flow
const Map<OrderStatus, OrderStatus?> statusProgression = {
  OrderStatus.pending: OrderStatus.preparing,
  OrderStatus.preparing: OrderStatus.readyDelivery,
  OrderStatus.readyDelivery: OrderStatus.outForDelivery,
  OrderStatus.outForDelivery: OrderStatus.delivered,
  OrderStatus.delivered: OrderStatus.readyFetch, // Ready Pickup
  OrderStatus.readyFetch: OrderStatus.done, // Final status
  OrderStatus.done: null,
  OrderStatus.cancelled: null, // Terminal status
};

/// Define which statuses can be cancelled
const List<OrderStatus> cancellableStatuses = [
  OrderStatus.pending,
  OrderStatus.preparing,
  OrderStatus.readyDelivery,
];

/// Get the next valid status in the progression flow
OrderStatus? getNextStatus(OrderStatus currentStatus) {
  return statusProgression[currentStatus];
}

/// Check if a status can be cancelled
bool canBeCancelled(OrderStatus status) {
  return cancellableStatuses.contains(status);
}

/// Check if a status can be progressed to the next step
bool canProgress(OrderStatus status) {
  return statusProgression[status] != null;
}

/// Get all possible statuses that can transition to the given status
List<OrderStatus> getPreviousStatuses(OrderStatus targetStatus) {
  return statusProgression.entries
      .where((entry) => entry.value == targetStatus)
      .map((entry) => entry.key)
      .toList();
}

/// Get status display info including color and label
class StatusInfo {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const StatusInfo({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });
}

StatusInfo getStatusInfo(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return const StatusInfo(
        label: "Bestelling Ontvang",
        backgroundColor: Color(0xFFFFF9C4), // light yellow
        textColor: Color(0xFFF57F17), // deep yellow
      );
    case OrderStatus.preparing:
      return const StatusInfo(
        label: "Besig met Voorbereiding",
        backgroundColor: Color(0xFFBBDEFB), // light blue
        textColor: Color(0xFF1565C0), // deep blue
      );
    case OrderStatus.readyDelivery:
      return const StatusInfo(
        label: "Gereed vir aflewering",
        backgroundColor: Color(0xFFC8E6C9), // light green
        textColor: Color(0xFF2E7D32), // deep green
      );
    case OrderStatus.outForDelivery:
      return const StatusInfo(
        label: "Uit vir aflewering",
        backgroundColor: Color(0xFFE1BEE7), // light purple
        textColor: Color(0xFF6A1B9A), // deep purple
      );
    case OrderStatus.delivered:
      return const StatusInfo(
        label: "By afleweringspunt",
        backgroundColor: Color(0xFFE0E0E0), // light grey
        textColor: Color(0xFF424242), // dark grey
      );
    case OrderStatus.readyFetch:
      return const StatusInfo(
        label: "Reg vir afhaal",
        backgroundColor: Color(0xFFC8E6C9), // light green
        textColor: Color(0xFF2E7D32), // deep green
      );
    case OrderStatus.done:
      return const StatusInfo(
        label: "Afgehandel",
        backgroundColor: Color(0xFFC8E6C9), // light green
        textColor: Color.fromARGB(255, 4, 126, 0), // deep green
      );
    case OrderStatus.cancelled:
      return const StatusInfo(
        label: "Gekanselleer",
        backgroundColor: Color(0xFFEF9A9A), // light red
        textColor: Color(0xFFB71C1C), // deep red
      );
    case OrderStatus.verstryk:
      return const StatusInfo(
        label: "Verstryk",
        backgroundColor: Color(0xFFFF6B6B), // Glitched red
        textColor: Colors.white,
      );
  }
}

/// Map OrderStatus enum to database status names
const Map<OrderStatus, String> statusToDatabaseName = {
  OrderStatus.pending: 'Bestelling Ontvang',
  OrderStatus.preparing: 'Besig met Voorbereiding',
  OrderStatus.readyDelivery: 'Gereed vir aflewering',
  OrderStatus.outForDelivery: 'Uit vir aflewering',
  OrderStatus.delivered: 'By afleweringspunt',
  OrderStatus.readyFetch: 'Reg vir afhaal',
  OrderStatus.done: 'Afgehandel',
  OrderStatus.cancelled: 'Gekanselleer',
  OrderStatus.verstryk: 'Verstryk',
};

/// Get database status name for an OrderStatus
String getDatabaseStatusName(OrderStatus status) {
  return statusToDatabaseName[status] ??
      statusToDatabaseName[OrderStatus.pending]!;
}

/// Map API status names to OrderStatus enum
OrderStatus mapStatusFromNames(List<String> names) {
  if (names.isEmpty) return OrderStatus.pending;

  // Precedence order from lowest to highest progression
  const precedence = <OrderStatus>[
    OrderStatus.pending,
    OrderStatus.preparing,
    OrderStatus.readyDelivery,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
    OrderStatus.readyFetch,
    OrderStatus.done,
    OrderStatus.cancelled,
    OrderStatus.verstryk, // Add verstryk to precedence
  ];

  OrderStatus mapOne(String n) {
    final s = n.toLowerCase();
    if (s.contains('verstryk') || s.contains('expired')) {
      return OrderStatus.verstryk;
    }
    if (s.contains('kansel') || s.contains('cancel')) {
      return OrderStatus.cancelled;
    }
    if (s.contains('afgehandel') || s == 'done') return OrderStatus.done;
    if (s.contains('afleweringspunt') ||
        s.contains('afgelewer') ||
        s.contains('delivered')) {
      return OrderStatus.delivered;
    }
    if (s.contains('uit vir aflewering') || s.contains('out for')) {
      return OrderStatus.outForDelivery;
    }
    if (s.contains('gereed vir aflewering') || s.contains('ready delivery')) {
      return OrderStatus.readyDelivery;
    }
    if (s.contains('reg vir afhaal') ||
        s.contains('ready fetch') ||
        s.contains('pickup')) {
      return OrderStatus.readyFetch;
    }
    if (s.contains('voorbereiding') || s.contains('prepar')) {
      return OrderStatus.preparing;
    }
    if (s.contains('ontvang') || s.contains('pending')) {
      return OrderStatus.pending;
    }
    return OrderStatus.pending;
  }

  final mapped = names.map(mapOne).toSet();
  // choose highest precedence (last index)
  OrderStatus best = OrderStatus.pending;
  int bestIdx = -1;
  for (final st in mapped) {
    final idx = precedence.indexOf(st);
    if (idx > bestIdx) {
      bestIdx = idx;
      best = st;
    }
  }
  return best;
}
