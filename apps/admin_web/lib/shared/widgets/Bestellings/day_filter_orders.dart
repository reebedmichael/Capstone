import 'package:flutter/material.dart';

const DAYS = [
  'Maandag',
  'Dinsdag',
  'Woensdag',
  'Donderdag',
  'Vrydag',
  'Saterdag',
  'Sondag',
];

const SPECIAL_FILTERS = ['Geskiedenis'];

class DayFilters extends StatelessWidget {
  final String selectedDay;
  final ValueChanged<String> onDayChange;

  const DayFilters({
    super.key,
    required this.selectedDay,
    required this.onDayChange,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A day filter is considered active if the selection is one of the weekdays.
    final bool isDayFilterActive = DAYS.contains(selectedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- NEW: Header row with title and conditional reset button ---
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Hierdie week",
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.hintColor,
              ),
            ),
            // Show the reset button only when a weekday is selected
            if (isDayFilterActive)
              TextButton.icon(
                onPressed: () {
                  // Reset the filter to the default "Historical View"
                  onDayChange(SPECIAL_FILTERS.first);
                },
                icon: const Icon(Icons.filter_list_off, size: 16),
                label: const Text('Bestelling Geskiedenis'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  foregroundColor: Colors.white,
                  backgroundColor: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Wrap for the day filter buttons
        Wrap(
          spacing: 20,
          runSpacing: 8,
          children: DAYS.map((option) {
            final bool isSelected = selectedDay == option;
            return ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 80, // ensures a minimum size
              ),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  backgroundColor: isSelected
                      ? theme.colorScheme.primary
                      : null,
                  foregroundColor: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  side: isSelected
                      ? BorderSide.none
                      : BorderSide(color: theme.dividerColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                // --- MODIFIED LOGIC HERE ---
                // Simply select the day. Reset is now handled by the button above.
                onPressed: () => onDayChange(option),
                child: Text(option),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
