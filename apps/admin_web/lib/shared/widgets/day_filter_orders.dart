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

const SPECIAL_FILTERS = ['Afgehandelde Bestellings'];

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day Filters
        _buildSection(
          context,
          title: "Dae van week",
          options: DAYS,
          minWidth: 80,
        ),

        const SizedBox(height: 16),

        // Special Filters
        _buildSection(
          context,
          title: "Historiese Uitsig",
          options: SPECIAL_FILTERS,
          minWidth: 100,
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<String> options,
    required double minWidth,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).hintColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 20,
          runSpacing: 8,
          children: options.map((option) {
            final bool isSelected = selectedDay == option;
            return ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: minWidth, // ensures a minimum size
              ),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 12,
                  ),
                  backgroundColor: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                  foregroundColor: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface,
                  side: isSelected
                      ? BorderSide.none
                      : BorderSide(color: Theme.of(context).dividerColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                ),
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
