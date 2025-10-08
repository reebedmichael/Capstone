import 'package:flutter/material.dart';

class KositemEmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const KositemEmptyState({super.key, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.file_copy, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Geen Templates Nog Nie', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          const Text(
            'Skep jou eerste kositem templaat om vinniger nuwe items te kan byvoeg.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Skep Nuwe Templaat'),
          ),
        ],
      ),
    );
  }
}
