// lib/widgets/kos_item_detail.dart
import 'package:flutter/material.dart';
import 'kos_item_templaat.dart';

class KositemDetailDialog extends StatelessWidget {
  final KositemTemplate item;
  final VoidCallback? onEdit;

  const KositemDetailDialog({super.key, required this.item, this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500, // Set your desired maximum width here
          // maxHeight: 800,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Text(
                    item.naam,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Expanded(child: Container()),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                ],
              ),

              const SizedBox(height: 4),
              Text(
                "Bekyk gedetailleerde inligting oor hierdie kos item, insluitend bestanddele en pryse.",
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 16),

              // Image
              // Image with max height
              if (item.prent != null && item.prent!.isNotEmpty)
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: 300),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Image.network(item.prent!, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image, size: 64, color: Colors.grey),
                ),

              const SizedBox(height: 16),

              // Description
              if (item.beskrywing.isNotEmpty) ...[
                Text(
                  "Beskrywing",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.beskrywing,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
              ],

              // Price
              Text(
                "Prys",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                "R${item.prys.toStringAsFixed(2)}",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),

              // Categories
              // Categories
              if (item.dieetKategorie.isNotEmpty) ...[
                Text(
                  "Kategorieë",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.dieetKategorie
                      .map(
                        (cat) => Chip(
                          label: Text(
                            cat,
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primary,
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
              ],

              // Ingredients
              Text(
                "Bestanddele",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              if (item.bestanddele.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: item.bestanddele
                      .map(
                        (ingredient) => Chip(
                          label: Text(
                            ingredient,
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor: Colors.grey.shade100,
                        ),
                      )
                      .toList(),
                )
              else
                Text(
                  "Geen bestanddele gelys nie",
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),

              const SizedBox(height: 24),

              // Edit button (only shown if onEdit callback is provided)
              if (onEdit != null)
                Align(
                  alignment: Alignment.bottomLeft,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close detail dialog
                      onEdit!(); // Call the edit callback
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Wysig'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
