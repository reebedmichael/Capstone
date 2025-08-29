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
    final hasImg = item.prentBytes != null || item.prentUrl != null;
    final beskrywing = (item.beskrywing ?? '').trim();
    final bestanddele = item.bestanddele;
    final allergene = item.allergene;
    final kategorie = item.kategorie;

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
            if (hasImg)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: item.prentBytes != null
                      ? Image.memory(item.prentBytes!, fit: BoxFit.cover)
                      : Image.network(item.prentUrl!, fit: BoxFit.contain),
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.naam,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'R${item.prys.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 6),

            // Kategorie + beskikbaar
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (kategorie.isNotEmpty) Chip(label: Text(kategorie)),
                if (!item.beskikbaar)
                  Chip(
                    backgroundColor: Colors.red.shade50,
                    label: const Text('Nie Beskikbaar'),
                  ),
              ],
            ),

            // Beskrywing (kort)
            if (beskrywing.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                beskrywing,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ],

            // Bestanddele (kort)
            if (bestanddele.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Bestanddele: ${bestanddele.join(', ')}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Theme.of(context).hintColor),
              ),
            ],

            // Allergene chips
            if (allergene.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: allergene
                    .map(
                      (a) => Chip(
                        backgroundColor: Colors.red.shade50,
                        label: Text(a),
                      ),
                    )
                    .toList(),
              ),
            ],

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
