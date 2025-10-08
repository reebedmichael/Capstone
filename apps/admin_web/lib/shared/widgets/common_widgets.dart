import 'package:flutter/material.dart';

/// Common reusable widgets for order management

/// A labeled row widget commonly used in mobile layouts
class LabeledRow extends StatelessWidget {
  final String label;
  final Widget child;
  final CrossAxisAlignment crossAxisAlignment;

  const LabeledRow({
    super.key,
    required this.label,
    required this.child,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: crossAxisAlignment,
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

/// A simple info row for displaying key-value pairs
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final Color? highlightColor;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.highlight = false,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: highlight
                  ? (highlightColor ?? theme.colorScheme.primary)
                  : null,
              fontWeight: highlight ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact action button with icon and label
class ActionButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool isDestructive;
  final bool isOutlined;

  const ActionButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isDestructive = false,
    this.isOutlined = true,
  });

  @override
  Widget build(BuildContext context) {
    if (isOutlined) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: isDestructive ? Colors.red[700] : null,
          side: isDestructive ? BorderSide(color: Colors.red[700]!) : null,
          visualDensity: VisualDensity.compact,
        ),
      );
    } else {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: isDestructive ? Colors.red[700] : null,
          foregroundColor: isDestructive ? Colors.white : null,
          visualDensity: VisualDensity.compact,
        ),
      );
    }
  }
}

/// A loading/error state widget
class LoadingErrorWidget extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final Widget child;

  const LoadingErrorWidget({
    super.key,
    required this.isLoading,
    this.error,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return child;
  }
}

/// A responsive layout builder that switches between wide and narrow layouts
class ResponsiveLayout extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints)
  builder;

  const ResponsiveLayout({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return builder(context, constraints);
      },
    );
  }
}
