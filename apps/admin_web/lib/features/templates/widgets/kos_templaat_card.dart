import 'package:flutter/material.dart';
import 'kos_item_templaat.dart';

class KositemTemplateCard extends StatelessWidget {
  final KositemTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const KositemTemplateCard({
    super.key,
    required this.template,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      child: Column(
        children: [
          if (template.prent != null)
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Image.network(template.prent!, fit: BoxFit.cover),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  Text(
                    template.naam,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Text('Beskrywing: ${template.beskrywing}'),
                  const SizedBox(height: 8),
                  Text('Kategorie: ${template.kategorie}'),
                  const SizedBox(height: 8),
                  Text('Prys: R${template.prys.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  const Text("Bestanddele:"),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: template.bestanddele
                        .map(
                          (b) => Chip(
                            label: Text(b),
                            backgroundColor: Colors.blue[100],
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  const Text("Allergene:"),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: template.allergene
                        .map(
                          (a) => Chip(
                            label: Text(a),
                            backgroundColor: Colors.red[100],
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  label: const Text('Wysig'),
                ),
              ),
              ElevatedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                label: const Text("Verwyder"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red.shade900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
