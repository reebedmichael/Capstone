// template_dialog.dart
import 'package:flutter/material.dart';
import 'models.dart';

class TemplateDialog extends StatelessWidget {
  final List<WeekTemplate> templates;
  final void Function(String) onSelect;
  const TemplateDialog({
    super.key,
    required this.templates,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Laai Week Templaat',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              if (templates.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.insert_drive_file,
                        size: 64,
                        color: Theme.of(context).hintColor,
                      ),
                      const SizedBox(height: 8),
                      const Text('Geen templates beskikbaar nie'),
                    ],
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: templates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final t = templates[i];
                      return InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          onSelect(t.id);
                        },
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        t.naam,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      if (t.beskrywing != null)
                                        Text(
                                          t.beskrywing!,
                                          style: TextStyle(
                                            color: Theme.of(context).hintColor,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.insert_drive_file),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Kanselleer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
