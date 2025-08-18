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
      child: DefaultTabController(
        length: widget.daeVanWeek.length,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                widget.activeTemplateId != null
                    ? 'Wysig Week Templaat'
                    : 'Skep Nuwe Week Templaat',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: widget.nameController,
                decoration: const InputDecoration(
                  labelText: 'Templaat Naam *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: widget.descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Beskrywing',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // 🗓 Tabs per dag
              TabBar(
                tabs: widget.daeVanWeek
                    .map((dag) => Tab(text: dag['label']))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: widget.daeVanWeek.map((dag) {
                    final dagKey = dag['key']!;
                    final index = widget.daeVanWeek.indexOf(dag);
                    return Column(
                      children: [
                        Expanded(
                          child: Scrollbar(
                            controller: _scrollControllers[index],
                            thumbVisibility: true,
                            child: ListView(
                              controller: _scrollControllers[index],
                              children: widget.formDays[dagKey]!
                                  .map(
                                    (food) => ListTile(
                                      title: Text(food.naam),
                                      subtitle: Text(
                                        "${food.kategorie} • R${food.prys.toStringAsFixed(2)}",
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: () {
                                          setState(() {
                                            widget.formDays[dagKey]!.remove(
                                              food,
                                            );
                                          });
                                        },
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ),
                        TextField(
                          controller: widget.searchControllers[dagKey],
                          decoration: InputDecoration(
                            hintText: 'Soek kos vir ${dag['label']}',
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                        SizedBox(
                          height: 150,
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
                      ],
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onCancel,
                      child: const Text('Kanselleer'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onSave,
                      child: Text(
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
