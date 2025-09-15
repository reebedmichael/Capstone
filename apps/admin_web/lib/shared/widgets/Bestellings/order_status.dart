import 'package:flutter/material.dart';

/// Variant types matching your TS variants: 'default' | 'secondary' | 'destructive' | 'outline'
enum BadgeVariant { normal, secondary, destructive, outline }

class BadgeConfig {
  final String label;
  final BadgeVariant variant;
  const BadgeConfig({required this.label, required this.variant});
}

/// STATUS_CONFIG equivalent
const Map<String, BadgeConfig> STATUS_CONFIG = {
  'pending': BadgeConfig(
    label: 'Bestelling Ontvang',
    variant: BadgeVariant.outline,
  ),
  'preparing': BadgeConfig(
    label: 'Besig met Voorbereiding',
    variant: BadgeVariant.secondary,
  ),
  'readyDelivery': BadgeConfig(
    label: 'Gereed vir aflewering',
    variant: BadgeVariant.normal,
  ),
  'readyFetch': BadgeConfig(
    label: 'Reg vir afhaal',
    variant: BadgeVariant.normal,
  ),
  'outForDelivery': BadgeConfig(
    label: 'Uit vir aflewering',
    variant: BadgeVariant.normal,
  ),
  'delivered': BadgeConfig(
    label: 'By afleweringspunt',
    variant: BadgeVariant.normal,
  ),
  'done': BadgeConfig(label: 'Afehandel', variant: BadgeVariant.normal),
  'cancelled': BadgeConfig(
    label: 'Gekanselleer',
    variant: BadgeVariant.destructive,
  ),
};

/// Reusable Badge widget (equivalent to your ./ui/badge)
class Badge extends StatelessWidget {
  final String text;
  final BadgeVariant variant;
  final bool nowrap;

  const Badge({
    Key? key,
    required this.text,
    this.variant = BadgeVariant.normal,
    this.nowrap = true, // maps to whitespace-nowrap
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Map variants to colors/styles (uses theme where possible)
    Color? background;
    Color textColor;
    BorderSide? border;

    switch (variant) {
      case BadgeVariant.secondary:
        background = cs.surfaceVariant; // subtle filled look
        textColor = cs.onSurfaceVariant;
        border = BorderSide.none;
        break;
      case BadgeVariant.destructive:
        background = cs.error;
        textColor = cs.onError;
        border = BorderSide.none;
        break;
      case BadgeVariant.outline:
        background = Colors.transparent;
        textColor = cs.onSurface;
        border = BorderSide(color: cs.onSurface.withOpacity(0.12));
        break;
      case BadgeVariant.normal:
        background = cs.primary;
        textColor = cs.onPrimary;
        border = BorderSide.none;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
        border: border == null ? null : Border.fromBorderSide(border),
      ),
      // whitespace-nowrap: prevent wrapping; show ellipsis if too long
      child: Text(
        text,
        softWrap: !nowrap ? true : false,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// StatusBadge widget keeping the same API as your TS component.
/// Accepts the same string keys as your original `OrderStatus` union.
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({Key? key, required this.status}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config =
        STATUS_CONFIG[status] ??
        const BadgeConfig(label: 'Unknown', variant: BadgeVariant.outline);

    return Badge(
      text: config.label,
      variant: config.variant,
      nowrap: true, // maps to className="whitespace-nowrap"
    );
  }
}
