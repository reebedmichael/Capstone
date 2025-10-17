import 'package:capstone_admin/features/templates/widgets/kos_item_detail.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:spys_api_client/spys_api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/kos_item_templaat.dart';
import '../widgets/kos_templaat_card.dart';
import '../widgets/kositem_empty_state.dart';
import '../widgets/kositem_form_modal.dart';
import '../widgets/delete_modal.dart';

class KositemTemplaatPage extends StatefulWidget {
  final String? initialEditKosItemId;
  const KositemTemplaatPage({super.key, this.initialEditKosItemId});

  @override
  State<KositemTemplaatPage> createState() => _KositemTemplaatPageState();
}

class _KositemTemplaatPageState extends State<KositemTemplaatPage> {
  List<KositemTemplate> templates = [];
  List<KositemTemplate> filteredTemplates = [];
  String searchQuery = "";
  String selectedFilter = "Alle";
  List<String> dietCategories = ["Alle"];
  bool isLoading = false;
  String suksesBoodskap = '';
  String foutBoodskap = '';

  bool toonVormModal = false;
  KositemTemplate? huidigeTemplate;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController naamController = TextEditingController();
  final TextEditingController bestanddeleController = TextEditingController();
  final TextEditingController allergeneController = TextEditingController();
  final TextEditingController prysController = TextEditingController();
  final TextEditingController beskrywingController = TextEditingController();
  List<String> selectedCategories = [];
  String? selectedImage;

  late final KosTemplaatRepository repo;
  late final DieetRepository dieetRepo;
  bool _handledInitialEdit = false;

  @override
  void initState() {
    super.initState();
    // Initialize repositories
    final supabaseClient = Supabase.instance.client;
    repo = KosTemplaatRepository(SupabaseDb(supabaseClient));
    dieetRepo = DieetRepository(SupabaseDb(supabaseClient));

    // Load initial data
    laaiTemplates();
    laaiDietCategories();
  }

  Future<void> laaiDietCategories() async {
    try {
      final rows = await dieetRepo.kryDieet();
      setState(() {
        dietCategories = ["Alle"]; // Reset and include the default "All" filter
        dietCategories.addAll(
          rows
              .where((row) => row['dieet_naam'] != null)
              .map((row) => row['dieet_naam'] as String)
              .toList(),
        );
      });
    } catch (e) {
      setState(() => foutBoodskap = "Kon nie dieet kategorieë laai nie: $e");
    }
  }

  Future<void> laaiTemplates() async {
    setState(() => isLoading = true);
    try {
      final rows = await repo.getKosItems();

      templates = rows.map((row) {
        final kosItemId = row['kos_item_id']?.toString() ?? '';

        // Extract dietary category names from the nested structure
        final dietEntries = (row['kos_item_dieet_vereistes'] as List?)
            ?.cast<Map<String, dynamic>>();

        final List<String> dietNames = [];
        if (dietEntries != null) {
          for (final entry in dietEntries) {
            final dieetObj = entry['dieet'];
            if (dieetObj != null &&
                dieetObj is Map &&
                dieetObj['dieet_naam'] != null) {
              dietNames.add(dieetObj['dieet_naam'].toString());
            }
          }
        }

        return KositemTemplate(
          id: kosItemId,
          naam: row['kos_item_naam'] ?? '',
          beskrywing: row['kos_item_beskrywing'] ?? '',
          bestanddele:
              (row['kos_item_bestandele'] as List?)?.cast<String>() ?? [],
          allergene: (row['kos_item_allergene'] as List?)?.cast<String>() ?? [],
          prys: (row['kos_item_koste'] as num?)?.toDouble() ?? 0.0,
          dieetKategorie: dietNames, // Use the parsed list of names
          prent: row['kos_item_prentjie'],
          likes: row['kos_item_likes'] as int? ?? 0,
        );
      }).toList();

      applyFilters(); // Apply search and filter criteria

      // If requested, open the edit modal for a specific item once
      if (!_handledInitialEdit && widget.initialEditKosItemId != null) {
        final match = templates.firstWhere(
          (t) => t.id == widget.initialEditKosItemId,
          orElse: () => KositemTemplate(
            id: '',
            naam: '',
            beskrywing: '',
            bestanddele: const [],
            allergene: const [],
            prys: 0.0,
            dieetKategorie: const [],
            prent: null,
            likes: 0,
          ),
        );
        if (match.id.isNotEmpty) {
          laaiTemplateInVorm(match);
          setState(() {
            toonVormModal = true;
            _handledInitialEdit = true;
          });
        }
      }
    } catch (e) {
      setState(() => foutBoodskap = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  void applyFilters() {
    setState(() {
      filteredTemplates = templates.where((template) {
        final searchLower = searchQuery.toLowerCase();
        // Updated search logic to include ingredients
        final matchesSearch =
            template.naam.toLowerCase().contains(searchLower) ||
            template.beskrywing.toLowerCase().contains(searchLower) ||
            template.bestanddele.any(
              (ing) => ing.toLowerCase().contains(searchLower),
            );

        final matchesFilter =
            selectedFilter == "Alle" ||
            template.dieetKategorie.contains(selectedFilter);
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  // **NEW**: Method to clear search and filter
  void _clearFilters() {
    setState(() {
      searchQuery = "";
      selectedFilter = "Alle";
      applyFilters();
    });
  }

  void resetVorm() {
    naamController.clear();
    bestanddeleController.clear();
    allergeneController.clear();
    beskrywingController.clear();
    prysController.clear();
    selectedCategories = [];
    selectedImage = null;
    huidigeTemplate = null;
  }

  void laaiTemplateInVorm(KositemTemplate template) {
    naamController.text = template.naam;
    beskrywingController.text = template.beskrywing;
    bestanddeleController.text = template.bestanddele.join(', ');
    allergeneController.text = template.allergene.join(', ');
    prysController.text = template.prys.toString();
    selectedCategories = List<String>.from(template.dieetKategorie);
    selectedImage = template.prent;
    huidigeTemplate = template;
  }

  Future<void> kiesPrent() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!;
      setState(() => isLoading = true);

      try {
        final fileName = naamController.text.trim().isEmpty
            ? 'kositem'
            : naamController.text.trim().replaceAll(' ', '_');

        final url = await repo.uploadKosItemPrent(bytes, fileName);
        setState(() => selectedImage = url);
      } catch (e) {
        setState(() => foutBoodskap = e.toString());
      } finally {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> stoorTemplate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      foutBoodskap = '';
      suksesBoodskap = '';
    });

    try {
      final bestanddeleLys = bestanddeleController.text
          .split(',')
          .map((b) => b.trim())
          .where((b) => b.isNotEmpty)
          .toList();

      final allergeneLys = allergeneController.text
          .split(',')
          .map((a) => a.trim())
          .where((a) => a.isNotEmpty)
          .toList();

      final kosItemData = {
        'kos_item_naam': naamController.text.trim(),
        'kos_item_bestandele': bestanddeleLys,
        'kos_item_beskrywing': beskrywingController.text.trim(),
        'kos_item_allergene': allergeneLys,
        'kos_item_koste': double.tryParse(prysController.text.trim()) ?? 0,
      };

      if (selectedImage != null && selectedImage!.isNotEmpty) {
        kosItemData['kos_item_prentjie'] = selectedImage!;
      }

      if (huidigeTemplate != null) {
        await repo.updateKosItem(
          huidigeTemplate!.id,
          kosItemData,
          selectedCategories,
        );
        suksesBoodskap = 'Templaat suksesvol gewysig';
      } else {
        await repo.addKosItem(kosItemData, selectedCategories);
        suksesBoodskap = 'Templaat suksesvol geskep';
      }

      await laaiTemplates();
      setState(() {
        toonVormModal = false;
        resetVorm();
      });

      Future.delayed(
        const Duration(seconds: 3),
        () => mounted ? setState(() => suksesBoodskap = '') : null,
      );
    } catch (e) {
      setState(() => foutBoodskap = e.toString());
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> verwyderTemplate(KositemTemplate template) async {
    try {
      await repo.softDeleteKosItem(template.id);
      await laaiTemplates();
      setState(
        () => suksesBoodskap = "Templaat '${template.naam}' is verwyder",
      );
      Future.delayed(
        const Duration(seconds: 3),
        () => mounted ? setState(() => suksesBoodskap = '') : null,
      );
    } catch (e) {
      setState(() => foutBoodskap = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                              child: Text(
                                "🍽️",
                                style: TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Kositems",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  "Bestuur en skep kositems vir die spyskaart",
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
                      // Action button section
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            resetVorm();
                            setState(() => toonVormModal = true);
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text(
                            'Skep Templaat',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        ),
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
                              child: Text(
                                "🍽️",
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Kositems",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Text(
                                "Bestuur en skep kositems vir die spyskaart",
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
                      // Right section: create button
                      ElevatedButton.icon(
                        onPressed: () {
                          resetVorm();
                          setState(() => toonVormModal = true);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Skep Templaat'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          // Main content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // **NEW**: Replaces the old search and filter buttons
                  _buildFilterControls(),
                  const SizedBox(height: 16),

                  if (suksesBoodskap.isNotEmpty)
                    _buildFeedbackMessage(
                      suksesBoodskap,
                      Colors.green,
                      Icons.check_circle,
                    ),
                  if (foutBoodskap.isNotEmpty)
                    _buildFeedbackMessage(
                      foutBoodskap,
                      Colors.red,
                      Icons.error,
                    ),

                  Expanded(
                    child: isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : templates.isEmpty
                        ? KositemEmptyState(
                            onCreate: () {
                              resetVorm();
                              setState(() => toonVormModal = true);
                            },
                          )
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 250,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 0.65,
                                ),
                            itemCount: filteredTemplates.length,
                            itemBuilder: (context, index) {
                              final template = filteredTemplates[index];
                              return KositemTemplateCard(
                                template: template,
                                onEdit: () {
                                  laaiTemplateInVorm(template);
                                  setState(() => toonVormModal = true);
                                },
                                onView: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => KositemDetailDialog(
                                      item: template,
                                      onEdit: () {
                                        laaiTemplateInVorm(template);
                                        setState(() => toonVormModal = true);
                                      },
                                    ),
                                  );
                                },
                                onDelete: () async {
                                  final bevestig = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => DeleteModal(
                                      onCancel: () =>
                                          Navigator.pop(context, false),
                                      onConfirm: () =>
                                          Navigator.pop(context, true),
                                    ),
                                  );
                                  if (bevestig == true) {
                                    verwyderTemplate(template);
                                  }
                                },
                                showLikes: true,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: toonVormModal
          ? KositemFormModal(
              formKey: _formKey,
              naamController: naamController,
              prysController: prysController,
              bestanddeleController: bestanddeleController,
              beskrywingController: beskrywingController,
              allergeneController: allergeneController,
              selectedCategories: selectedCategories,
              allCategories: dietCategories.where((c) => c != "Alle").toList(),
              selectedImage: selectedImage,
              isLoading: isLoading,
              onCancel: () {
                setState(() => toonVormModal = false);
                resetVorm();
              },
              onSave: stoorTemplate,
              onPickImage: kiesPrent,
              onCategoriesChanged: (newVal) => setState(() {
                selectedCategories = newVal;
              }),
            )
          : null,
    );
  }

  // **NEW**: Widget for the entire filter section
  Widget _buildFilterControls() {
    final theme = Theme.of(context);
    final bool isFiltered = searchQuery.isNotEmpty || selectedFilter != 'Alle';

    return Column(
      children: [
        Card(
          elevation: 2,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.orange.shade100, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Use a Row layout for wider screens
                if (constraints.maxWidth > 700) {
                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            Expanded(child: _buildSearchField()),
                            const SizedBox(width: 12),
                            Expanded(child: _buildCategoryFilter()),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (isFiltered) ...[
                        OutlinedButton(
                          onPressed: _clearFilters,
                          child: const Text('Maak Skoon'),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ],
                  );
                }
                // Use a Column layout for narrower screens
                return Column(
                  children: [
                    _buildSearchField(),
                    const SizedBox(height: 12),
                    _buildCategoryFilter(),
                    if (isFiltered) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _clearFilters,
                          child: const Text('Maak Filters Skoon'),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
        // **NEW**: Filter summary text
        if (isFiltered)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade800,
                  ),
                  children: [
                    TextSpan(
                      text: '${filteredTemplates.length}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const TextSpan(text: ' items gevind'),
                    if (searchQuery.isNotEmpty) ...[
                      const TextSpan(text: ' wat ooreenstem met "'),
                      TextSpan(
                        text: searchQuery,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: '"'),
                    ],
                    if (selectedFilter != 'Alle') ...[
                      const TextSpan(text: ' in die '),
                      TextSpan(
                        text: selectedFilter,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const TextSpan(text: ' kategorie'),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // **NEW**: Helper for building the search text field
  Widget _buildSearchField() {
    return TextField(
      onChanged: (value) {
        setState(() {
          searchQuery = value;
          applyFilters();
        });
      },
      decoration: InputDecoration(
        hintText: "Soek volgens naam, beskrywing...",
        prefixIcon: const Icon(Icons.search, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange.shade200),
        ),
        filled: true,
        fillColor: Colors.white70,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }

  // **NEW**: Helper for building the category dropdown
  Widget _buildCategoryFilter() {
    return DropdownButtonFormField<String>(
      value: selectedFilter,
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            selectedFilter = newValue;
            applyFilters();
          });
        }
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.filter_list, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.orange.shade200),
        ),
        filled: true,
        fillColor: Colors.white70,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 15,
        ),
      ),
      items: dietCategories.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
    );
  }

  Widget _buildFeedbackMessage(String message, Color color, IconData icon) {
    return Container(
      color: color.withOpacity(0.1),
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
