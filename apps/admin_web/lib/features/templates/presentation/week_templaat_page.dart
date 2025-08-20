// lib/pages/week_templaat_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart'; // exports db + repos

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
  // Repositories
  late final WeekTemplaatRepository weekRepo;
  late final KosTemplaatRepository kosRepo;

  // UI Modals
  bool showFormModal = false;
  bool showDeleteModal = false;
  bool showLoadModal = false;

  // Active/editing context
  String? activeTemplateId;
  String successMessage = '';

  // Form state
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

  // Search fields per day
  final Map<String, TextEditingController> searchControllers = {
    'maandag': TextEditingController(),
    'dinsdag': TextEditingController(),
    'woensdag': TextEditingController(),
    'donderdag': TextEditingController(),
    'vrydag': TextEditingController(),
    'saterdag': TextEditingController(),
    'sondag': TextEditingController(),
  };

  // UI resources
  final daeVanWeek = const [
    {'key': 'maandag', 'label': 'Maandag'},
    {'key': 'dinsdag', 'label': 'Dinsdag'},
    {'key': 'woensdag', 'label': 'Woensdag'},
    {'key': 'donderdag', 'label': 'Donderdag'},
    {'key': 'vrydag', 'label': 'Vrydag'},
    {'key': 'saterdag', 'label': 'Saterdag'},
    {'key': 'sondag', 'label': 'Sondag'},
  ];

  // Backed by DB now
  List<Map<String, dynamic>> weekTemplates = [];
  List<KositemTemplate> templates = [];

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    final db = SupabaseDb(client);
    weekRepo = WeekTemplaatRepository(db);
    kosRepo = KosTemplaatRepository(db);

    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await Future.wait([_fetchTemplatesForPicker(), _fetchWeekTemplates()]);
    setState(() => _loading = false);
  }

  Future<void> _fetchTemplatesForPicker() async {
    // Use your existing kos repo; returns active items
    final rows = await kosRepo.getKosItems();
    templates = rows.map(_mapKosRowToTemplate).toList();
  }

  KositemTemplate _mapKosRowToTemplate(Map<String, dynamic> r) {
    // DB columns (lowercased) per your schema; provide safe defaults for UI-only fields
    return KositemTemplate.fromMap({
      'id': r['kos_item_id'],
      'naam': r['kos_item_naam'] ?? '',
      'beskrywing': r['kos_item_beskrywing'] ?? '',
      'kategorie': r['kategorie'] ?? '',
      'prys': (r['kos_item_koste'] ?? 0).toDouble(),
      'bestanddele': r['bestanddele'] ?? <String>[],
      'allergene': r['allergene'] ?? <String>[],
      'prentjie': r['kos_item_prentjie'],
    });
  }

  /// Pulls raw spyskaarte + children and shapes into the UI structure the widgets expect:
  /// { id, naam, beskrywing, dae: { 'maandag': [KositemMap,...], ... }, geskep }
  Future<void> _fetchWeekTemplates() async {
    final raw = await weekRepo.listWeekTemplatesRaw();

    List<Map<String, dynamic>> shaped = [];
    for (final row in raw) {
      final spyskaartId = row['spyskaart_id'];
      final naam = row['spyskaart_naam'] ?? '';
      final geskep = row['spyskaart_datum'];
      final beskrywing =
          row['spyskaart_beskrywing'] ??
          ''; // will be null if column doesn't exist

      // Prepare day buckets
      final dae = {
        'maandag': <Map<String, dynamic>>[],
        'dinsdag': <Map<String, dynamic>>[],
        'woensdag': <Map<String, dynamic>>[],
        'donderdag': <Map<String, dynamic>>[],
        'vrydag': <Map<String, dynamic>>[],
        'saterdag': <Map<String, dynamic>>[],
        'sondag': <Map<String, dynamic>>[],
      };

      final kinders = List<Map<String, dynamic>>.from(
        (row['spyskaart_kos_item'] as List?) ?? const [],
      );

      for (final child in kinders) {
        final kos = Map<String, dynamic>.from(child['kos_item'] ?? {});
        final dag = Map<String, dynamic>.from(child['week_dag'] ?? {});
        final dagNaam = (dag['week_dag_naam'] ?? '').toString().toLowerCase();
        if (!dae.containsKey(dagNaam)) continue;

        // Map DB row -> KositemTemplate map shape for UI
        final itemMap = {
          'id': kos['kos_item_id'],
          'naam': kos['kos_item_naam'] ?? '',
          'beskrywing': kos['kos_item_beskrywing'] ?? '',
          'kategorie': kos['kos_item_kategorie'] ?? '',
          'prys': (kos['kos_item_koste'] ?? 0).toDouble(),
          'bestanddele': kos['kos_item_bestandele'] ?? <String>[],
          'allergene': kos['kos_item_allergene'] ?? <String>[],
          'prentjie': kos['kos_item_prentjie'],
        };

        dae[dagNaam]!.add(itemMap);
      }

      shaped.add({
        'id': spyskaartId,
        'naam': naam,
        'beskrywing': beskrywing,
        'dae': dae,
        'geskep': geskep,
      });
    }

    setState(() => weekTemplates = shaped);
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

  Future<void> saveTemplate() async {
    if (formNameController.text.trim().isEmpty) return;

    // Convert formDays -> Map<String, List<Map>> for repo
    final daeData = formDays.map(
      (dag, lys) => MapEntry(dag, lys.map((k) => k.toMap()).toList()),
    );

    if (activeTemplateId != null) {
      await weekRepo.updateWeekTemplate(
        spyskaartId: activeTemplateId!,
        naam: formNameController.text.trim(),
        beskrywing: formDescController.text.trim(),
        dae: daeData,
      );
      successMessage = 'Week templaat suksesvol gewysig';
    } else {
      await weekRepo.createWeekTemplate(
        naam: formNameController.text.trim(),
        beskrywing: formDescController.text.trim(),
        dae: daeData,
      );
      successMessage = 'Week templaat suksesvol bygevoeg';
    }

    await _fetchWeekTemplates();
    setState(() => showFormModal = false);

    // Auto-hide success banner
    Future.delayed(
      const Duration(seconds: 1),
      () => mounted ? setState(() => successMessage = '') : null,
    );
  }

  Future<void> deleteTemplate() async {
    if (activeTemplateId != null) {
      await weekRepo.deleteWeekTemplate(activeTemplateId!);
      successMessage = 'Week templaat suksesvol verwyder';
    }
    await _fetchWeekTemplates();
    setState(() {
      showDeleteModal = false;
      activeTemplateId = null;
    });

    Future.delayed(
      const Duration(seconds: 1),
      () => mounted ? setState(() => successMessage = '') : null,
    );
  }

  void editTemplate(Map<String, dynamic> templaat) {
    // Fill form from shaped templaat
    setState(() {
      formNameController.text = templaat['naam'] ?? '';
      formDescController.text = templaat['beskrywing'] ?? '';

      final daeMap = Map<String, dynamic>.from(templaat['dae'] ?? {});
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

  void loadTemplateIntoForm(Map<String, dynamic> templaat) {
    // Same behavior as your original code
    formNameController.text = templaat['naam'] ?? '';
    formDescController.text = templaat['beskrywing'] ?? '';

    final mapped = (templaat['dae'] as Map).map<String, List<KositemTemplate>>(
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
      activeTemplateId = templaat['id'];
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
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : Padding(
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
                                    (m) => {
                                      'key': m['key']!,
                                      'label': m['label']!,
                                    },
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
          );

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Week Templates'),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.folder_open),
            label: const Text('Laai Templaat'),
            onPressed: () async {
              // Ensure fresh data before showing load modal
              await _fetchWeekTemplates();
              setState(() => showLoadModal = true);
            },
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Herlaai'),
            onPressed: _loadAll,
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
      body: body,

      // EXACT same modal behavior: one open at a time via floatingActionButton trick
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
