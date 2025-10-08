// template_dialog.dart
import 'package:flutter/material.dart';
import 'models.dart';

class TemplateDialog extends StatefulWidget {
  final List<WeekTemplate> templates;
  final void Function(String) onSelect;

  const TemplateDialog({
    super.key,
    required this.templates,
    required this.onSelect,
  });

  @override
  State<TemplateDialog> createState() => _TemplateDialogState();
}

class _TemplateDialogState extends State<TemplateDialog> {
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filteredTemplates = widget.templates
        .where((t) => t.naam.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

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

              // 🔍 Search field
              TextField(
                decoration: const InputDecoration(
                  hintText: "Soek volgens naam...",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val;
                  });
                },
              ),
              const SizedBox(height: 12),

              if (filteredTemplates.isEmpty)
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
                    itemCount: filteredTemplates.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) {
                      final t = filteredTemplates[i];
                      return InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          widget.onSelect(t.id);
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
