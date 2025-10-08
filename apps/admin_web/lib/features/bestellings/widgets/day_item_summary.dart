import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../shared/types/order.dart';
import '../../../shared/constants/order_constants.dart';

class DayItemsSummary extends StatelessWidget {
  final List<Order> orders;
  final String selectedDay;
  final String? selectedFoodItem;
  final void Function(String foodItem) onFoodItemClick;
  final List<Order> allOrders; // Add this to get all orders for the day

  const DayItemsSummary({
    super.key,
    required this.orders,
    required this.selectedDay,
    this.selectedFoodItem,
    required this.onFoodItemClick,
    required this.allOrders, // Add this parameter
  });

  @override
  Widget build(BuildContext context) {
    final itemsSummary = _computeItemsSummary();
    if (itemsSummary.isEmpty) return const SizedBox.shrink();

    final totalItems = itemsSummary.fold<int>(
      0,
      (sum, item) => sum + item.totalQuantity,
    );

    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Colors.orange.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Row(
                        children: [
                          Icon(
                            LucideIcons.chefHat,
                            size: 16,
                            color: Colors.orange.shade700,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isPastDay(selectedDay)
                                ? OrderConstants.getUiString('items')
                                : 'Aktiewe Items',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Text(
                          "$totalItems ${OrderConstants.getUiString('totalItems')}",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (selectedFoodItem != null && selectedFoodItem!.isNotEmpty)
                    Row(
                      children: [
                        Icon(
                          Icons.filter_alt,
                          size: 14,
                          color: Colors.orange.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          OrderConstants.getUiString('filtered'),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Items list (dynamic sizing)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: itemsSummary.map((item) {
                  final isSelected = selectedFoodItem == item.name;

                  return GestureDetector(
                    onTap: () => onFoodItemClick(item.name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.white,
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.grey.shade300,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: theme.colorScheme.primary.withOpacity(
                                    0.3,
                                  ),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : [],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary
                                      : Colors.grey.shade800,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? theme.colorScheme.onPrimary.withOpacity(
                                          0.2,
                                        )
                                      : Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  "${item.totalQuantity}",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? theme.colorScheme.onPrimary
                                        : Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (isSelected)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.onPrimary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: theme.colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              // Clear filter
              if (selectedFoodItem != null && selectedFoodItem!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextButton(
                    onPressed: () => onFoodItemClick(""),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.orange.shade600,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 30),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      OrderConstants.getUiString('clearFilter'),
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<_ItemSummary> _computeItemsSummary() {
    final Map<String, _ItemSummary> itemsMap = {};
    final isPastDay = _isPastDay(selectedDay);

    // Use allOrders instead of orders to always show all available items
    for (final order in allOrders) {
      for (final item in order.items.where(
        (i) => i.scheduledDay == selectedDay,
      )) {
        // For today and upcoming days, only show active items (not done or cancelled)
        // For past days, show all items
        if (!isPastDay &&
            (item.status == OrderStatus.done ||
                item.status == OrderStatus.cancelled)) {
          continue; // Skip completed items for today/upcoming days
        }

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

    final itemsList = itemsMap.values.toList();
    itemsList.sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));
    return itemsList;
  }

  bool _isPastDay(String selectedDay) {
    if (selectedDay == "Geskiedenis") return true;

    final today = DateTime.now();
    final selectedDate = _getDateForSelectedDay(selectedDay, today);

    // Compare only the date part (year, month, day) to avoid time issues
    final todayDate = DateTime(today.year, today.month, today.day);
    final selectedDateOnly = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );

    return selectedDateOnly.isBefore(todayDate);
  }

  DateTime _getDateForSelectedDay(String selectedDay, DateTime today) {
    // Map day names to weekday numbers
    final dayMap = {
      'Maandag': 1,
      'Dinsdag': 2,
      'Woensdag': 3,
      'Donderdag': 4,
      'Vrydag': 5,
      'Saterdag': 6,
      'Sondag': 7,
    };

    final selectedWeekday = dayMap[selectedDay];
    if (selectedWeekday == null) {
      return today; // Fallback to today if day not found
    }

    // Calculate the Monday of the current week
    final currentWeekday = today.weekday;
    final daysSinceMonday = currentWeekday - 1;
    final mondayOfWeek = today.subtract(Duration(days: daysSinceMonday));

    // Calculate the target date for the selected day
    final daysToAdd = selectedWeekday - 1;
    return mondayOfWeek.add(Duration(days: daysToAdd));
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
