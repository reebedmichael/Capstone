import 'package:flutter/material.dart';

class KampusFilter extends StatelessWidget {
  final String selectedKampus;
  final Function(String) onKampusChange;
  final List<String> kampusList;
  // final Map<String, int> orderCounts;

  const KampusFilter({
    Key? key,
    required this.selectedKampus,
    required this.onKampusChange,
    required this.kampusList,
    // required this.orderCounts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final allKampus = ["Alle Aflaai Punte", ...kampusList];
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with icon and title
        Row(
          children: [
            const Icon(Icons.location_on, size: 18, color: Colors.deepOrange),
            const SizedBox(width: 6),
            Text(
              "Aflaai Punte",
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.hintColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Buttons row
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: allKampus.map((point) {
            final isSelected = selectedKampus == point;

            return GestureDetector(
              onTap: () => onKampusChange(point),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? theme.colorScheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.grey.shade300,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.onPrimary.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      point,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
