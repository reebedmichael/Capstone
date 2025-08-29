import 'package:flutter/material.dart';
import 'kos_item_templaat.dart';

class FormModal extends StatefulWidget {
  final String? activeTemplateId;
  final TextEditingController nameController;
  final TextEditingController descController;
  final Map<String, List<KositemTemplate>> formDays;
  final List<Map<String, String>> daeVanWeek;
  final List<KositemTemplate> templates;
  final Map<String, TextEditingController> searchControllers;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const FormModal({
    super.key,
    required this.activeTemplateId,
    required this.nameController,
    required this.descController,
    required this.formDays,
    required this.daeVanWeek,
    required this.templates,
    required this.searchControllers,
    required this.onCancel,
    required this.onSave,
  });

  @override
  State<FormModal> createState() => _FormModalState();
}

class _FormModalState extends State<FormModal> with TickerProviderStateMixin {
  late List<ScrollController> _scrollControllers;

  @override
  void initState() {
    super.initState();
    _scrollControllers = List.generate(
      widget.daeVanWeek.length,
      (_) => ScrollController(),
    );
  }

  @override
  void dispose() {
    for (var c in _scrollControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: DefaultTabController(
        length: widget.daeVanWeek.length,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Title
              Text(
                widget.activeTemplateId != null
                    ? 'Wysig Week Templaat'
                    : 'Skep Nuwe Week Templaat',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Form fields
              TextField(
                controller: widget.nameController,
                decoration: InputDecoration(
                  labelText: 'Templaat Naam *',
                  prefixIcon: const Icon(Icons.edit),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: widget.descController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Beskrywing',
                  prefixIcon: const Icon(Icons.notes),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tabs for days
              TabBar(
                isScrollable: true,
                indicatorColor: Theme.of(context).colorScheme.primary,
                tabs: widget.daeVanWeek
                    .map((dag) => Tab(text: dag['label']))
                    .toList(),
              ),
              const SizedBox(height: 12),

              // Day content
              Expanded(
                child: TabBarView(
                  children: widget.daeVanWeek.map((dag) {
                    final dagKey = dag['key']!;
                    final index = widget.daeVanWeek.indexOf(dag);
                    return Column(
                      children: [
                        // --- Selected items section ---
                        Expanded(
                          child: Scrollbar(
                            controller: _scrollControllers[index],
                            thumbVisibility: true,
                            child: ListView(
                              controller: _scrollControllers[index],
                              children: [
                                if (widget.formDays[dagKey]!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: Text(
                                      "Gekose items",
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                  ),
                                ...widget.formDays[dagKey]!.map(
                                  (food) => Card(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                    ),
                                    child: ListTile(
                                      title: Text(food.naam),
                                      subtitle: Text(
                                        "${food.kategorie} • R${food.prys.toStringAsFixed(2)}",
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.red,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            widget.formDays[dagKey]!.remove(
                                              food,
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // --- Search + suggestions section ---
                        const SizedBox(height: 8),
                        TextField(
                          controller: widget.searchControllers[dagKey],
                          decoration: InputDecoration(
                            hintText: 'Soek kos vir ${dag['label']}',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Card(
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListView(
                              children: widget.templates
                                  .where(
                                    (t) =>
                                        t.naam.toLowerCase().contains(
                                          widget.searchControllers[dagKey]!.text
                                              .toLowerCase(),
                                        ) &&
                                        !widget.formDays[dagKey]!.any(
                                          (f) => f.id == t.id,
                                        ),
                                  )
                                  .map(
                                    (t) => ListTile(
                                      title: Text(t.naam),
                                      subtitle: Text(
                                        "${t.kategorie} • R${t.prys.toStringAsFixed(2)}",
                                      ),
                                      onTap: () {
                                        setState(() {
                                          widget.formDays[dagKey]!.add(t);
                                          widget.searchControllers[dagKey]!
                                              .clear();
                                        });
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),

              // --- Bottom action buttons ---
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: widget.onCancel,
                      icon: const Icon(Icons.close),
                      label: const Text('Kanselleer'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.onSave,
                      icon: const Icon(Icons.save),
                      label: Text(
                        widget.activeTemplateId != null
                            ? 'Stoor Wysigings'
                            : 'Skep Templaat',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
