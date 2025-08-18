import 'package:flutter/material.dart';
// import 'kos_item_templaat.dart';

class LoadModal extends StatelessWidget {
  final List<Map<String, dynamic>> weekTemplates;
  final void Function(Map<String, dynamic> template) onSelect;

  const LoadModal({
    super.key,
    required this.weekTemplates,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Laai Bestaande Templaat'),
            const SizedBox(height: 16),
            if (weekTemplates.isEmpty)
              const Text('Geen templates beskikbaar nie')
            else
              ...weekTemplates.map(
                (t) => ListTile(
                  title: Text(t['naam']),
                  subtitle: Text(t['beskrywing']),
                  onTap: () => onSelect(t),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
