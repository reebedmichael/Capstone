import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../types/order.dart';

class DayItemsSummary extends StatelessWidget {
  final List<Order> orders;
  final String selectedDay;
  final String? selectedFoodItem;
  final void Function(String foodItem) onFoodItemClick;

  const DayItemsSummary({
    Key? key,
    required this.orders,
    required this.selectedDay,
    this.selectedFoodItem,
    required this.onFoodItemClick,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final itemsSummary = _computeItemsSummary();

    if (itemsSummary.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(LucideIcons.chefHat, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    selectedDay == "Afgehandelde Bestellings"
                        ? "Alle items van afgehandelde bestellings"
                        : "Items vir $selectedDay",
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Items
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: itemsSummary.map((item) {
                final isSelected = selectedFoodItem == item.name;
                final backgroundColor = isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceVariant;
                final textColor = isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface;

                return GestureDetector(
                  onTap: () => onFoodItemClick(item.name),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "×${item.totalQuantity}",
                          style: TextStyle(
                            color: isSelected
                                ? textColor.withOpacity(0.9)
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  List<_ItemSummary> _computeItemsSummary() {
    final Map<String, _ItemSummary> itemsMap = {};

    if (selectedDay == "Afgehandelde Bestellings") {
      // Only delivered orders
      for (final order in orders.where(
        (o) => o.status == OrderStatus.delivered,
      )) {
        for (final item in order.items) {
          itemsMap.update(
            item.name,
            (existing) => existing.copyWith(
              totalQuantity: existing.totalQuantity + item.quantity,
            ),
            ifAbsent: () =>
                _ItemSummary(name: item.name, totalQuantity: item.quantity),
          );
        }
      }
    } else {
      // Orders filtered by scheduledDay
      for (final order in orders) {
        for (final item in order.items.where(
          (i) => i.scheduledDay == selectedDay,
        )) {
          itemsMap.update(
            item.name,
            (existing) => existing.copyWith(
              totalQuantity: existing.totalQuantity + item.quantity,
            ),
            ifAbsent: () =>
                _ItemSummary(name: item.name, totalQuantity: item.quantity),
          );
        }
      }
    }

    final itemsList = itemsMap.values.toList();
    itemsList.sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));
    return itemsList;
  }
}

class _ItemSummary {
  final String name;
  final int totalQuantity;

  const _ItemSummary({required this.name, required this.totalQuantity});

  _ItemSummary copyWith({String? name, int? totalQuantity}) {
    return _ItemSummary(
      name: name ?? this.name,
      totalQuantity: totalQuantity ?? this.totalQuantity,
    );
  }
}
