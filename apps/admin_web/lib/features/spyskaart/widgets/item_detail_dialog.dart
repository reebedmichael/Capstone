import 'package:flutter/material.dart';
import 'models.dart';

class ItemDetailDialog extends StatelessWidget {
  final Kositem item;
  const ItemDetailDialog({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final hasImg = item.prentBytes != null || item.prentUrl != null;
    final beskrywing = (item.beskrywing ?? '').trim();

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Item Besonderhede',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (hasImg)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 220,
                      width: double.infinity,
                      child: item.prentBytes != null
                          ? Image.memory(item.prentBytes!, fit: BoxFit.cover)
                          : Image.network(item.prentUrl!, fit: BoxFit.cover),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.naam,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Text(
                      'R${item.prys.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (item.kategorie.isNotEmpty)
                      Chip(label: Text(item.kategorie)),
                    Chip(
                      label: Text(
                        item.beskikbaar ? 'Beskikbaar' : 'Nie Beskikbaar',
                      ),
                    ),
                  ],
                ),

                // Beskrywing
                if (beskrywing.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Beskrywing:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(beskrywing),
                ],

                // Bestanddele
                if (item.bestanddele.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Bestanddele:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(item.bestanddele.join(', ')),
                ],

                // Allergene
                if (item.allergene.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Allergene:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: item.allergene
                        .map(
                          (a) => Chip(
                            backgroundColor: Colors.red.shade50,
                            label: Text(a),
                          ),
                        )
                        .toList(),
                  ),
                ],

                const SizedBox(height: 16),
                Text(
                  'Geskep op: ${item.geskep.day}/${item.geskep.month}/${item.geskep.year}',
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Maak toe'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
