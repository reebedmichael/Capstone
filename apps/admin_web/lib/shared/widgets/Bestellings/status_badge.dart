import 'package:flutter/material.dart';
import '../../types/order.dart';

class StatusConfig {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const StatusConfig({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });
}

class StatusBadge extends StatelessWidget {
  final OrderStatus status;

  const StatusBadge({super.key, required this.status});

  static const Map<OrderStatus, StatusConfig> statusConfig = {
    OrderStatus.pending: StatusConfig(
      label: "Bestelling ontvang",
      backgroundColor: Color(0xFFFFF9C4), // light yellow
      textColor: Colors.black,
    ),
    OrderStatus.preparing: StatusConfig(
      label: "Besig met Voorbereiding",
      backgroundColor: Color(0xFFBBDEFB), // light blue
      textColor: Color(0xFF1565C0), // deep blue
    ),
    OrderStatus.readyDelivery: StatusConfig(
      label: "Gereed vir aflewering",
      backgroundColor: Color.fromARGB(255, 211, 1, 253),
      textColor: Color.fromARGB(255, 18, 0, 31),
    ),

    OrderStatus.outForDelivery: StatusConfig(
      label: "Uit vir aflewering",
      backgroundColor: Color(0xFFE1BEE7), // light purple
      textColor: Color(0xFF6A1B9A), // deep purple
    ),
    OrderStatus.delivered: StatusConfig(
      label: "By afleweringspunt",
      backgroundColor: Color(0xFFE0E0E0), // light grey
      textColor: Color(0xFF424242), // dark grey
    ),
    OrderStatus.readyFetch: StatusConfig(
      label: "Reg vir afhaal",
      backgroundColor: Color(0xFFC8E6C9), // light green
      textColor: Color(0xFF2E7D32), // deep green
    ),
    OrderStatus.done: StatusConfig(
      label: "Afgehandel",
      backgroundColor: Color.fromARGB(255, 255, 255, 255), // light green
      textColor: Color.fromARGB(255, 1, 26, 0), // deep green
    ),
    OrderStatus.cancelled: StatusConfig(
      label: "Gekanselleer",
      backgroundColor: Color(0xFFEF9A9A), // light red
      textColor: Color(0xFFB71C1C), // deep red
    ),
  };

  @override
  Widget build(BuildContext context) {
    final config = statusConfig[status]!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: config.backgroundColor == Colors.transparent
            ? Border.all(color: Colors.black)
            : null,
      ),
      child: Text(
        config.label,
        style: TextStyle(
          color: config.textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
