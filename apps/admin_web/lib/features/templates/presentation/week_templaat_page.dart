// lib/pages/week_templaat_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart'; // exports db + repos

import '../widgets/kos_item_templaat.dart';
import '../widgets/week_templaat_card.dart';
import '../widgets/week_form_modal.dart';
import '../widgets/delete_modal.dart';
import '../widgets/week_load_modal.dart';
import '../widgets/kos_item_detail.dart'; // <-- import your detail dialog

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

  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

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
    final rows = await kosRepo.getKosItems();
    templates = rows.map(_mapKosRowToTemplate).toList();
  }

  KositemTemplate _mapKosRowToTemplate(Map<String, dynamic> r) {
    return KositemTemplate.fromMap({
      'id': r['kos_item_id'],
      'naam': r['kos_item_naam'] ?? '',
      'beskrywing': r['kos_item_beskrywing'] ?? '',
      'kategorie': r['kategorie'] ?? '',
      'prys': (r['kos_item_koste'] ?? 0).toDouble(),
      'bestanddele': r['bestanddele'] ?? <String>[],
      'allergene': r['allergene'] ?? <String>[],
      'prent': r['kos_item_prentjie'],
      'kos_item_dieet_vereistes':
          r['kos_item_dieet_vereistes'] ?? <List<dynamic>>[],
    });
  }

  Future<void> _fetchWeekTemplates() async {
    final raw = await weekRepo.listWeekTemplatesRaw();

    List<Map<String, dynamic>> shaped = [];
    for (final row in raw) {
      final spyskaartId = row['spyskaart_id'];
      final naam = row['spyskaart_naam'] ?? '';
      final geskep = row['spyskaart_datum'];
      final beskrywing = row['spyskaart_beskrywing'] ?? '';

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

        final itemMap = {
          'id': kos['kos_item_id'],
          'naam': kos['kos_item_naam'] ?? '',
          'beskrywing': kos['kos_item_beskrywing'] ?? '',
          'kategorie': kos['kos_item_kategorie'] ?? '',
          'prys': (kos['kos_item_koste'] ?? 0).toDouble(),
          'bestanddele': kos['kos_item_bestandele'] ?? <String>[],
          'allergene': kos['kos_item_allergene'] ?? <String>[],
          'prent': kos['kos_item_prentjie'],
          'kos_item_dieet_vereistes':
              kos['kos_item_dieet_vereistes'] ?? <List<dynamic>>[],
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

    Future.delayed(
      const Duration(seconds: 3),
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
      const Duration(seconds: 3),
      () => mounted ? setState(() => successMessage = '') : null,
    );
  }

  void editTemplate(Map<String, dynamic> templaat) {
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

  // 🔄 Replaced _showItemDetails with reusable KositemDetailDialog
  void _showItemDetails(KositemTemplate item) {
    showDialog(
      context: context,
      builder: (context) => KositemDetailDialog(item: item),
    );
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

  List<Map<String, dynamic>> get filteredWeekTemplates {
    if (searchQuery.isEmpty) return weekTemplates;
    final q = searchQuery.toLowerCase();
    return weekTemplates.where((t) {
      final naam = (t['naam'] ?? '').toString().toLowerCase();
      final beskrywing = (t['beskrywing'] ?? '').toString().toLowerCase();
      return naam.contains(q) || beskrywing.contains(q);
    }).toList();
  }

  @override
  @override
  Widget build(BuildContext context) {
    // Loading state
    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(title: const Text('Week Templates')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Helper slivers list
    final List<Widget> slivers = [];

    // Top padding + header (search + success message)
    slivers.add(
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        sliver: SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Soek 'n spyskaart templaat...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                onChanged: (val) => setState(() => searchQuery = val),
              ),
              const SizedBox(height: 12),
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
            ],
          ),
        ),
      ),
    );

    // If empty: use SliverFillRemaining to center the empty state
    final filtered = filteredWeekTemplates;
    if (filtered.isEmpty) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text('Geen Week Templaaie'),
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
            ),
          ),
        ),
      );
    } else {
      // non-empty: render a SliverList
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final templaat = filtered[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: WeekTemplateCard(
                  templaat: templaat,
                  daeVanWeek: daeVanWeek
                      .map((m) => {'key': m['key']!, 'label': m['label']!})
                      .toList(),
                  onEdit: () => editTemplate(templaat),
                  onDelete: () {
                    activeTemplateId = templaat['id'];
                    setState(() => showDeleteModal = true);
                  },
                  onViewItem: (item) => _showItemDetails(item),
                ),
              );
            }, childCount: filtered.length),
          ),
        ),
      );
    }

    // Build scaffold with CustomScrollView
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          // Styled Header
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width < 600 ? 16 : 24,
              vertical: MediaQuery.of(context).size.width < 600 ? 12 : 16,
            ),
            child: MediaQuery.of(context).size.width < 600
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo and title section
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Center(
                              child: Text("📅", style: TextStyle(fontSize: 18)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Spyskaart Templaaie",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  "Bestuur en skep templaat spyskaarte",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.color,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Action buttons section
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text(
                                'Herlaai',
                                style: TextStyle(fontSize: 12),
                              ),
                              onPressed: _loadAll,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text(
                                'Skep Templaat',
                                style: TextStyle(fontSize: 12),
                              ),
                              onPressed: () {
                                resetForm();
                                setState(() => showFormModal = true);
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left section: logo + title + description
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text("📅", style: TextStyle(fontSize: 20)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Spyskaart Templaaie",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Text(
                                "Bestuur en skep templaat spyskaarte",
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Right section: action buttons
                      Row(
                        children: [
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
                        ],
                      ),
                    ],
                  ),
          ),
          // Main content
          Expanded(
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: slivers,
            ),
          ),
        ],
      ),
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
