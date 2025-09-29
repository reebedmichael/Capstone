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

class LargeFoodChip extends StatelessWidget {
  final KositemTemplate food;
  final VoidCallback onDeleted;
  final double imageSize;

  const LargeFoodChip({
    Key? key,
    required this.food,
    required this.onDeleted,
    this.imageSize = 56,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () {
          // optional: open details
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          constraints: BoxConstraints(minHeight: imageSize + 8, maxWidth: 300),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Image
              ClipOval(
                child: food.prent != null && food.prent!.isNotEmpty
                    ? Image.network(
                        food.prent!,
                        width: imageSize,
                        height: imageSize,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => Container(
                          width: imageSize,
                          height: imageSize,
                          color: Colors.grey[200],
                          child: Icon(Icons.fastfood, size: imageSize * 0.45),
                        ),
                      )
                    : Container(
                        width: imageSize,
                        height: imageSize,
                        color: Colors.grey[200],
                        child: Icon(Icons.fastfood, size: imageSize * 0.45),
                      ),
              ),

              const SizedBox(width: 12),

              // Label (wraps instead of truncating)
              Expanded(
                child: Text(
                  food.naam,
                  style: const TextStyle(fontSize: 16),
                  softWrap: true,
                ),
              ),

              const SizedBox(width: 8),

              // Delete button
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onDeleted,
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.close, size: 20),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormModalState extends State<FormModal> {
  int _currentStep = 0;

  String _formatCategories(List<String> categories) {
    if (categories.isEmpty) return "Geen kategorieë";
    return categories.join(", ");
  }

  void _showSearchBottomSheet(String dagKey, String dagLabel) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Voeg kositems by vir $dagLabel",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: widget.searchControllers[dagKey],
                      decoration: InputDecoration(
                        hintText: 'Soek kositems...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
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
                                  "${_formatCategories(t.dieetKategorie)} • R${t.prys.toStringAsFixed(2)}",
                                ),
                                trailing: const Icon(Icons.add_circle_outline),
                                onTap: () {
                                  setState(() {
                                    widget.formDays[dagKey]!.add(t);
                                    widget.searchControllers[dagKey]!.clear();
                                  });
                                  Navigator.pop(context);
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGeneralInfoStep() {
    return Column(
      children: [
        const SizedBox(height: 12),
        TextField(
          controller: widget.nameController,
          decoration: InputDecoration(
            labelText: 'Templaat Naam *',
            prefixIcon: const Icon(Icons.edit),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: widget.descController,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: 'Beskrywing',
            prefixIcon: const Icon(Icons.notes),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDayMenusStep() {
    return DefaultTabController(
      length: widget.daeVanWeek.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: widget.daeVanWeek
                .map((dag) => Tab(text: dag['label']))
                .toList(),
          ),
          const SizedBox(height: 12),
          // fixed-height area for day editor (avoids layout issues in Step content)
          SizedBox(
            height: 320,
            child: TabBarView(
              children: widget.daeVanWeek.map((dag) {
                final dagKey = dag['key']!;
                final dagLabel = dag['label']!;
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Gekose items vir $dagLabel",
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: widget.formDays[dagKey]!
                            .map(
                              (food) => LargeFoodChip(
                                food: food,
                                imageSize: 56, // pick 48/56/64 etc.
                                onDeleted: () {
                                  setState(() {
                                    widget.formDays[dagKey]!.remove(food);
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text("Voeg kositems by"),
                          onPressed: () =>
                              _showSearchBottomSheet(dagKey, dagLabel),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Oorsig van die week",
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),

        // Constrain height so the Step content lays out correctly inside Stepper
        Container(
          height: 450,
          padding: const EdgeInsets.only(top: 6),
          child: ListView(
            children: widget.daeVanWeek.map((dag) {
              final dagKey = dag['key']!;
              final dagLabel = dag['label']!;
              final items = widget.formDays[dagKey]!;
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  title: Text(dagLabel),
                  subtitle: items.isNotEmpty
                      ? Text(items.map((f) => f.naam).join(", "))
                      : const Text("Geen items gekies"),
                  trailing: Text("${items.length}"),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header with title + close button in top right
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.activeTemplateId != null
                        ? "Wysig Week Templaat"
                        : "Skep Nuwe Week Templaat",
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: widget.onCancel,
                  tooltip: 'Sluit',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Stepper - expanded area
            Expanded(
              child: Stepper(
                type: StepperType.vertical,
                currentStep: _currentStep,
                onStepContinue: () {
                  if (_currentStep < 2) {
                    setState(() => _currentStep += 1);
                  } else {
                    widget.onSave();
                  }
                },
                onStepCancel: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep -= 1);
                  } else {
                    widget.onCancel();
                  }
                },
                // ✅ Allow tapping step headers
                onStepTapped: (int step) {
                  setState(() {
                    _currentStep = step;
                  });
                },
                controlsBuilder: (context, details) {
                  return Row(
                    children: [
                      if (_currentStep > 0)
                        OutlinedButton(
                          onPressed: details.onStepCancel,
                          child: const Text("Terug"),
                        ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        child: Text(
                          _currentStep == 2
                              ? (widget.activeTemplateId != null
                                    ? "Stoor Wysigings"
                                    : "Skep Templaat")
                              : "Volgende",
                        ),
                      ),
                    ],
                  );
                },
                steps: [
                  Step(
                    title: const Text("Algemene Inligting"),
                    content: _buildGeneralInfoStep(),
                    isActive: _currentStep == 0,
                    state: _currentStep > 0
                        ? StepState.complete
                        : StepState.indexed,
                  ),
                  Step(
                    title: const Text("Bestuur Kositems"),
                    content: _buildDayMenusStep(),
                    isActive: _currentStep == 1,
                    state: _currentStep > 1
                        ? StepState.complete
                        : StepState.indexed,
                  ),
                  Step(
                    title: const Text("Opsomming"),
                    content: _buildSummaryStep(),
                    isActive: _currentStep == 2,
                    state: _currentStep == 2
                        ? StepState.editing
                        : StepState.indexed,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
