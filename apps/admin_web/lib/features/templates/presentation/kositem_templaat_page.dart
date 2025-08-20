import 'dart:typed_data';
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
  const KositemTemplaatPage({super.key});

  @override
  State<KositemTemplaatPage> createState() => _KositemTemplaatPageState();
}

class _KositemTemplaatPageState extends State<KositemTemplaatPage> {
  // final SpyskaartRepository repo = SpyskaartRepository(SupabaseDb());

  List<KositemTemplate> templates = [];
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
  String? selectedCategory;
  String? selectedImage;

  late final AdminSpyskaartRepository repo;

  @override
  void initState() {
    super.initState();
    repo = AdminSpyskaartRepository(SupabaseDb(Supabase.instance.client));
    laaiTemplates();
  }

  Future<void> laaiTemplates() async {
    setState(() => isLoading = true);
    try {
      final rows = await repo.getKosItems();
      templates = rows.map((row) {
        return KositemTemplate(
          id: row['kos_item_id'].toString(),
          naam: row['kos_item_naam'] ?? '',
          beskrywing: row['kos_item_beskrywing'] ?? '',
          bestanddele:
              (row['kos_item_bestandele'] as List?)?.cast<String>() ?? [],
          allergene: (row['kos_item_allergene'] as List?)?.cast<String>() ?? [],
          prys: (row['kos_item_koste'] as num?)?.toDouble() ?? 0.0,
          kategorie: row['kos_item_kategorie'] ?? '',
          prent: row['kos_item_prentjie'],
        );
      }).toList();
    } catch (e) {
      foutBoodskap = e.toString();
    }
    setState(() => isLoading = false);
  }

  void resetVorm() {
    naamController.clear();
    bestanddeleController.clear();
    allergeneController.clear();
    beskrywingController.clear();
    prysController.clear();
    selectedCategory = null;
    selectedImage = null;
    huidigeTemplate = null;
  }

  void laaiTemplateInVorm(KositemTemplate template) {
    naamController.text = template.naam;
    beskrywingController.text = template.beskrywing;
    bestanddeleController.text = template.bestanddele.join(', ');
    allergeneController.text = template.allergene.join(
      ', ',
    ); //////////////////////////////////////////////////////////////////////////////////////////
    prysController.text = template.prys.toString();
    selectedCategory = template.kategorie;
    selectedImage = template.prent;
    huidigeTemplate = template;
  }

  Future<void> kiesPrent() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (result != null && result.files.single.bytes != null) {
      final bytes = result.files.single.bytes!; // Uint8List

      setState(() => isLoading = true);

      try {
        final fileName = naamController.text.trim().isEmpty
            ? 'kositem'
            : naamController.text.trim().replaceAll(' ', '_');

        // upload en kry URL
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
        'kos_item_kategorie': selectedCategory ?? '',
        // 'kos_item_prentjie': selectedImage, // store URL not bytes
      };
      // slegs sit die prentjie key as ons 'n URL het (nuwe of reeds ingestel)
      if (selectedImage != null && selectedImage!.isNotEmpty) {
        kosItemData['kos_item_prentjie'] = selectedImage!;
      }
      if (huidigeTemplate != null) {
        await repo.updateKosItem(huidigeTemplate!.id, kosItemData);
        suksesBoodskap = 'Templaat suksesvol gewysig';
      } else {
        await repo.addKosItem(kosItemData);
        suksesBoodskap = 'Templaat suksesvol geskep';
      }

      await laaiTemplates();
      setState(() {
        toonVormModal = false;
        resetVorm();
      });
    } catch (e) {
      foutBoodskap = e.toString();
    }

    setState(() => isLoading = false);
  }

  Future<void> verwyderTemplate(KositemTemplate template) async {
    try {
      await repo.softDeleteKosItem(template.id);
      await laaiTemplates();
      setState(
        () => suksesBoodskap = "Templaat '${template.naam}' is verwyder",
      );
    } catch (e) {
      foutBoodskap = e.toString();
    }
  }
  //Hard delete
  // Future<void> verwyderTemplate(KositemTemplate template) async {
  //   try {
  //     await repo.deleteKosItem(template.id);
  //     await laaiTemplates();
  //     setState(
  //       () => suksesBoodskap = "Templaat '${template.naam}' is verwyder",
  //     );
  //   } catch (e) {
  //     foutBoodskap = e.toString();
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kositem Templates'),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              resetVorm();
              setState(() => toonVormModal = true);
            },
            icon: const Icon(Icons.add),
            label: const Text('Skep Nuwe Templaat'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (suksesBoodskap.isNotEmpty)
              _buildFeedbackMessage(
                suksesBoodskap,
                Colors.green,
                Icons.check_circle,
              ),
            if (foutBoodskap.isNotEmpty)
              _buildFeedbackMessage(foutBoodskap, Colors.red, Icons.error),
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
                            maxCrossAxisExtent: 300,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.70,
                          ),
                      itemCount: templates.length,
                      itemBuilder: (context, index) {
                        final template = templates[index];
                        return KositemTemplateCard(
                          template: template,
                          onEdit: () {
                            laaiTemplateInVorm(template);
                            setState(() => toonVormModal = true);
                          },
                          onDelete: () async {
                            final bevestig = await showDialog<bool>(
                              context: context,
                              builder: (context) => DeleteModal(
                                onCancel: () => Navigator.pop(context, false),
                                onConfirm: () => Navigator.pop(context, true),
                              ),
                            );
                            if (bevestig == true) {
                              verwyderTemplate(template);
                            }
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomSheet: toonVormModal
          ? KositemFormModal(
              formKey: _formKey,
              naamController: naamController,
              prysController: prysController,
              bestanddeleController: bestanddeleController,
              beskrywingController: beskrywingController,
              allergeneController: allergeneController,
              selectedCategory: selectedCategory,
              selectedImage: selectedImage,
              isLoading: isLoading,
              onCancel: () {
                setState(() => toonVormModal = false);
                resetVorm();
              },
              onSave: stoorTemplate,
              onPickImage: kiesPrent,
              onCategoryChanged: (newVal) =>
                  setState(() => selectedCategory = newVal),
            )
          : null,
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
