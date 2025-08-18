import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
  List<KositemTemplate> templates = [
    KositemTemplate(
      id: "1",
      naam: "Beesburger",
      bestanddele: ["Beesvleis", "Broodjie", "Kaas", "Tamatie", "Slaai"],
      allergene: ["Gluten", "Melk"],
      prys: 85.00,
      kategorie: "Hoofgereg",
    ),
    KositemTemplate(
      id: "2",
      naam: "Ontbyt Omelet",
      bestanddele: ["Eiers", "Kaas", "Uie", "Spinasie"],
      allergene: ["Eiers", "Melk"],
      prys: 55.00,
      kategorie: "Ontbyt",
    ),
    KositemTemplate(
      id: "3",
      naam: "Vrugteslaai",
      bestanddele: ["Appel", "Bessie", "Druiwe", "Piesang"],
      allergene: [],
      prys: 45.00,
      kategorie: "Ligte ete",
    ),
    KositemTemplate(
      id: "4",
      naam: "Koffie Latte",
      bestanddele: ["Koffie", "Melk", "Suiker"],
      allergene: ["Melk"],
      prys: 30.00,
      kategorie: "Drankie",
    ),
  ];

  bool toonVormModal = false;
  KositemTemplate? huidigeTemplate;
  bool isLoading = false;
  String suksesBoodskap = '';
  String foutBoodskap = '';

  final _formKey = GlobalKey<FormState>();
  final TextEditingController naamController = TextEditingController();
  final TextEditingController bestanddeleController = TextEditingController();
  final TextEditingController allergeneController = TextEditingController();
  final TextEditingController prysController = TextEditingController();
  String? selectedCategory;
  Uint8List? selectedImage;

  void resetVorm() {
    naamController.clear();
    bestanddeleController.clear();
    allergeneController.clear();
    prysController.clear();
    selectedCategory = null;
    selectedImage = null;
    huidigeTemplate = null;
  }

  void laaiTemplateInVorm(KositemTemplate template) {
    naamController.text = template.naam;
    bestanddeleController.text = template.bestanddele.join(', ');
    allergeneController.text = template.allergene.join(', ');
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
      setState(() {
        selectedImage = result.files.single.bytes;
      });
    }
  }

  void stoorTemplate() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      foutBoodskap = '';
      suksesBoodskap = '';
    });

    Future.delayed(const Duration(milliseconds: 500), () {
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

      if (huidigeTemplate != null) {
        final index = templates.indexWhere((t) => t.id == huidigeTemplate!.id);
        if (index != -1) {
          templates[index] = KositemTemplate(
            id: huidigeTemplate!.id,
            naam: naamController.text.trim(),
            bestanddele: bestanddeleLys,
            allergene: allergeneLys,
            prys: double.tryParse(prysController.text.trim()) ?? 0,
            kategorie: selectedCategory ?? '',
            prent: selectedImage,
          );
          suksesBoodskap = 'Templaat suksesvol gewysig';
        }
      } else {
        templates.add(
          KositemTemplate(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            naam: naamController.text.trim(),
            bestanddele: bestanddeleLys,
            allergene: allergeneLys,
            prys: double.tryParse(prysController.text.trim()) ?? 0,
            kategorie: selectedCategory ?? '',
            prent: selectedImage,
          ),
        );
        suksesBoodskap = 'Templaat suksesvol geskep';
      }

      setState(() {
        isLoading = false;
        toonVormModal = false;
        resetVorm();
      });

      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          suksesBoodskap = '';
          foutBoodskap = '';
        });
      });
    });
  }

  void verwyderTemplate(KositemTemplate template) {
    setState(() {
      templates.removeWhere((t) => t.id == template.id);
      suksesBoodskap = "Templaat '${template.naam}' is verwyder";
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        suksesBoodskap = '';
      });
    });
  }

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
              child: templates.isEmpty
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
                            if (bevestig == true) verwyderTemplate(template);
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
