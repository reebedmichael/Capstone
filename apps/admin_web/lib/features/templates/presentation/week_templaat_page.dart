import 'package:flutter/material.dart';

import '../widgets/kos_item_templaat.dart';
import '../widgets/week_templaat_card.dart';
import '../widgets/week_form_modal.dart';
import '../widgets/delete_modal.dart';
import '../widgets/week_load_modal.dart';

class WeekTemplaatPage extends StatefulWidget {
  const WeekTemplaatPage({super.key});

  @override
  State<WeekTemplaatPage> createState() => _WeekTemplaatPageState();
}

class _WeekTemplaatPageState extends State<WeekTemplaatPage> {
  bool showFormModal = false;
  bool showDeleteModal = false;
  bool showLoadModal = false;

  String? activeTemplateId;
  String successMessage = '';

  final formNameController = TextEditingController();
  final formDescController = TextEditingController();

  Map<String, List<KositemTemplate>> formDays = {
    'maandag': [],
    'dinsdag': [],
    'woensdag': [],
    'donderdag': [],
    'vrydag': [],
    'saterdag': [],
    'sondag': [],
  };

  final List<Map<String, dynamic>> weekTemplates = [];

  final Map<String, TextEditingController> searchControllers = {
    'maandag': TextEditingController(),
    'dinsdag': TextEditingController(),
    'woensdag': TextEditingController(),
    'donderdag': TextEditingController(),
    'vrydag': TextEditingController(),
    'saterdag': TextEditingController(),
    'sondag': TextEditingController(),
  };

  final daeVanWeek = const [
    {'key': 'maandag', 'label': 'Maandag'},
    {'key': 'dinsdag', 'label': 'Dinsdag'},
    {'key': 'woensdag', 'label': 'Woensdag'},
    {'key': 'donderdag', 'label': 'Donderdag'},
    {'key': 'vrydag', 'label': 'Vrydag'},
    {'key': 'saterdag', 'label': 'Saterdag'},
    {'key': 'sondag', 'label': 'Sondag'},
  ];

  final List<KositemTemplate> templates = [
    KositemTemplate(
      id: "1",
      naam: "Beesburger",
      bestanddele: ["Beesvleis", "Broodjie", "Kaas", "Tamatie", "Slaai"],
      beskrywing: "super!",
      allergene: ["Gluten", "Melk"],
      prys: 85.00,
      kategorie: "Hoofgereg",
    ),
    KositemTemplate(
      id: "2",
      naam: "Ontbyt Omelet",
      bestanddele: ["Eiers", "Kaas", "Uie", "Spinasie"],
      beskrywing: "super!",
      allergene: ["Eiers", "Melk"],
      prys: 55.00,
      kategorie: "Ontbyt",
    ),
    KositemTemplate(
      id: "3",
      naam: "Vrugteslaai",
      beskrywing: "super!",
      bestanddele: ["Appel", "Bessie", "Druiwe", "Piesang"],
      allergene: [],
      prys: 45.00,
      kategorie: "Ligte ete",
    ),
    KositemTemplate(
      id: "4",
      naam: "Koffie Latte",
      beskrywing: "super!",
      bestanddele: ["Koffie", "Melk", "Suiker"],
      allergene: ["Melk"],
      prys: 30.00,
      kategorie: "Drankie",
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (weekTemplates.isEmpty) {
      weekTemplates.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'naam': 'Week Spyskaart',
        'beskrywing': 'Voorbeeld week spyskaart met geregte',
        'dae': {
          'maandag': [templates[0].toMap()],
          'dinsdag': [templates[1].toMap()],
          'woensdag': [templates[2].toMap()],
          'donderdag': [templates[3].toMap()],
          'vrydag': [],
          'saterdag': [],
          'sondag': [],
        },
        'geskep': DateTime.now(),
      });
    }
  }

  void resetForm() {
    formNameController.clear();
    formDescController.clear();
    formDays.updateAll((key, value) => <KositemTemplate>[]);
    for (var c in searchControllers.values) {
      c.clear();
    }
    activeTemplateId = null;
  }

  void saveTemplate() {
    if (formNameController.text.trim().isEmpty) return;
    final daeData = formDays.map(
      (dag, kosLys) => MapEntry(dag, kosLys.map((k) => k.toMap()).toList()),
    );

    if (activeTemplateId != null) {
      final idx = weekTemplates.indexWhere((t) => t['id'] == activeTemplateId);
      if (idx != -1) {
        final ouGespep = weekTemplates[idx]['geskep'];
        weekTemplates[idx] = {
          'id': activeTemplateId,
          'naam': formNameController.text.trim(),
          'beskrywing': formDescController.text.trim(),
          'dae': daeData,
          'geskep': ouGespep,
          'gewysig': DateTime.now(),
        };
      }
      successMessage = 'Week templaat suksesvol gewysig';
    } else {
      weekTemplates.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'naam': formNameController.text.trim(),
        'beskrywing': formDescController.text.trim(),
        'dae': daeData,
        'geskep': DateTime.now(),
      });
      successMessage = 'Week templaat suksesvol bygevoeg';
    }

    setState(() => showFormModal = false);
    Future.delayed(
      const Duration(seconds: 3),
      () => mounted ? setState(() => successMessage = '') : null,
    );
  }

  void deleteTemplate() {
    if (activeTemplateId != null) {
      weekTemplates.removeWhere((t) => t['id'] == activeTemplateId);
      successMessage = 'Week templaat suksesvol verwyder';
    }
    setState(() {
      showDeleteModal = false;
      activeTemplateId = null;
    });
    Future.delayed(
      const Duration(seconds: 3),
      () => mounted ? setState(() => successMessage = '') : null,
    );
  }

  void editTemplate(Map<String, dynamic> templaat) {
    setState(() {
      formNameController.text = templaat['naam'];
      formDescController.text = templaat['beskrywing'];
      final daeMap = Map<String, dynamic>.from(templaat['dae']);
      formDays = daeMap.map<String, List<KositemTemplate>>((k, v) {
        final list = (v as List?) ?? const [];
        return MapEntry(
          k,
          list
              .map(
                (e) => KositemTemplate.fromMap(
                  Map<String, dynamic>.from(e as Map),
                ),
              )
              .toList(),
        );
      });
      activeTemplateId = templaat['id'] as String?;
      showFormModal = true;
    });
  }

  void loadTemplateIntoForm(Map<String, dynamic> t) {
    formNameController.text = t['naam'];
    formDescController.text = t['beskrywing'];

    final mapped = (t['dae'] as Map).map<String, List<KositemTemplate>>(
      (k, v) => MapEntry(
        k as String,
        (v as List<dynamic>)
            .map(
              (map) => KositemTemplate.fromMap(
                Map<String, dynamic>.from(map as Map),
              ),
            )
            .toList(),
      ),
    );

    setState(() {
      formDays = mapped;
      activeTemplateId = t['id'];
      showLoadModal = false;
      showFormModal = true;
    });
  }

  @override
  void dispose() {
    formNameController.dispose();
    formDescController.dispose();
    for (final c in searchControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Week Templates'),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.folder_open),
            label: const Text('Laai Templaat'),
            onPressed: () => setState(() => showLoadModal = true),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Skep Nuwe Templaat'),
            onPressed: () {
              resetForm();
              setState(() => showFormModal = true);
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (successMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  border: Border.all(color: Colors.green.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        successMessage,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: weekTemplates.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text('Geen Week Templates'),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Skep Eerste Templaat'),
                            onPressed: () {
                              resetForm();
                              setState(() => showFormModal = true);
                            },
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 4 / 3,
                          ),
                      itemCount: weekTemplates.length,
                      itemBuilder: (context, index) {
                        final templaat = weekTemplates[index];
                        return WeekTemplateCard(
                          templaat: templaat,
                          daeVanWeek: daeVanWeek
                              .map(
                                (m) => {'key': m['key']!, 'label': m['label']!},
                              )
                              .toList(),
                          onEdit: () => editTemplate(templaat),
                          onDelete: () {
                            activeTemplateId = templaat['id'];
                            setState(() => showDeleteModal = true);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      // Show one modal at a time (floatingActionButton trick preserved)
      floatingActionButton: showFormModal
          ? FormModal(
              activeTemplateId: activeTemplateId,
              nameController: formNameController,
              descController: formDescController,
              formDays: formDays,
              daeVanWeek: daeVanWeek
                  .map((m) => {'key': m['key']!, 'label': m['label']!})
                  .toList(),
              templates: templates,
              searchControllers: searchControllers,
              onCancel: () => setState(() => showFormModal = false),
              onSave: saveTemplate,
            )
          : showDeleteModal
          ? DeleteModal(
              onConfirm: deleteTemplate,
              onCancel: () => setState(() => showDeleteModal = false),
            )
          : showLoadModal
          ? LoadModal(
              weekTemplates: weekTemplates,
              onSelect: loadTemplateIntoForm,
            )
          : null,
    );
  }
}
