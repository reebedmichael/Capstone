// item_card.dart
import 'package:flutter/material.dart';
import 'models.dart';

class ItemCard extends StatelessWidget {
  final Kositem item;
  final WeekSpyskaart spyskaart;
  final String dagKey;
  final bool canEdit;
  final VoidCallback onView;
  final VoidCallback onDelete;
  final String tipeWeek;

  const ItemCard({
    super.key,
    required this.item,
    required this.spyskaart,
    required this.dagKey,
    required this.canEdit,
    required this.onView,
    required this.onDelete,
    required this.tipeWeek,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.prentBytes != null || item.prentUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 120,
                  width: double.infinity,
                  child: item.prentBytes != null
                      ? Image.memory(item.prentBytes!, fit: BoxFit.cover)
                      : Image.network(item.prentUrl!, fit: BoxFit.cover),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.naam,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  'R${item.prys.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(item.kategorie)),
                if (!item.beskikbaar)
                  Chip(
                    backgroundColor: Colors.red.shade50,
                    label: const Text('Nie Beskikbaar'),
                  ),
              ],
            ),
            if (item.allergene.isNotEmpty)
              Wrap(
                spacing: 6,
                children: item.allergene
                    .map(
                      (a) => Chip(
                        backgroundColor: Colors.red.shade50,
                        label: Text(a),
                      ),
                    )
                    .toList(),
              ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onView,
                    icon: const Icon(Icons.remove_red_eye_outlined),
                    label: const Text('Beskou'),
                  ),
                ),
                const SizedBox(width: 8),
                if (canEdit && tipeWeek == 'volgende')
                  OutlinedButton(
                    onPressed: onDelete,
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
