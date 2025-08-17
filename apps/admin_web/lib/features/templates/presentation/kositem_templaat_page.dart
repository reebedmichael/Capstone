import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class KositemTemplate {
  final String id;
  final String naam;
  final List<String> bestanddele;
  final List<String> allergene;
  final double prys;
  final String kategorie;
  final Uint8List? prent;

  KositemTemplate({
    required this.id,
    required this.naam,
    required this.bestanddele,
    required this.allergene,
    required this.prys,
    required this.kategorie,
    this.prent,
  });
}

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
      prent: null,
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

    Future.delayed(const Duration(seconds: 3), () {
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
                  ? _buildEmptyState()
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 300,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 0.70,
                          ),
                      itemCount: templates.length,
                      itemBuilder: (context, index) =>
                          _buildTemplateCard(templates[index]),
                    ),
            ),
          ],
        ),
      ),
      bottomSheet: toonVormModal ? _buildModalForm() : null,
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.file_copy, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Geen Templates Nog Nie', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          const Text(
            'Skep jou eerste kositem templaat om vinniger nuwe items te kan byvoeg.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
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
    );
  }

  Widget _buildTemplateCard(KositemTemplate template) {
    return Card(
      elevation: 3,
      child: Column(
        children: [
          if (template.prent != null)
            SizedBox(
              height: 150,
              width: double.infinity,
              child: Image.memory(template.prent!, fit: BoxFit.cover),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  Text(
                    template.naam,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Kategorie: ${template.kategorie}'),
                  const SizedBox(height: 8),
                  Text('Prys: R${template.prys.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  const Text("Bestanddele:"),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: template.bestanddele
                        .map(
                          (b) => Chip(
                            label: Text(b),
                            backgroundColor: Colors.blue[100],
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  const Text("Allergene:"),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: template.allergene
                        .map(
                          (a) => Chip(
                            label: Text(a),
                            backgroundColor: Colors.red[100],
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    laaiTemplateInVorm(template);
                    setState(() => toonVormModal = true);
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Wysig'),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  final bevestig = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Bevestig verwydering"),
                      content: Text(
                        "Is jy seker jy wil '${template.naam}' verwyder?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Kanselleer"),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text("Verwyder"),
                        ),
                      ],
                    ),
                  );

                  if (bevestig == true) {
                    verwyderTemplate(template);
                  }
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text("Verwyder"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade100,
                  foregroundColor: Colors.red.shade900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModalForm() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: naamController,
                      decoration: const InputDecoration(
                        labelText: 'Kos Item Naam *',
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Naam is verpligtend'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: TextFormField(
                      controller: prysController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Prys (R) *',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Prys is verpligtend';
                        }
                        if (double.tryParse(value) == null ||
                            double.parse(value) <= 0) {
                          return 'Ongeldige prys';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                onChanged: (newValue) =>
                    setState(() => selectedCategory = newValue),
                decoration: const InputDecoration(labelText: 'Kategorie *'),
                validator: (value) => value == null || value.isEmpty
                    ? 'Kategorie is verpligtend'
                    : null,
                items:
                    [
                          'Hoofgereg',
                          'Ontbyt',
                          'Versnappering',
                          'Ligte ete',
                          'Drankie',
                        ]
                        .map(
                          (val) =>
                              DropdownMenuItem(value: val, child: Text(val)),
                        )
                        .toList(),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: bestanddeleController,
                decoration: const InputDecoration(
                  labelText: 'Bestanddele *',
                  hintText: 'Skei met kommas, bv. Brood, Botter, Konfyt',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Bestanddele is verpligtend'
                    : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: allergeneController,
                decoration: const InputDecoration(
                  labelText: 'Allergene',
                  hintText: 'Skei met kommas, bv. Gluten, Melk, Eiers',
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: kiesPrent,
                    icon: const Icon(Icons.upload),
                    label: const Text('Kies Prent'),
                  ),
                  const SizedBox(width: 16),
                  if (selectedImage != null)
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Image.memory(selectedImage!, fit: BoxFit.cover),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() => toonVormModal = false);
                        resetVorm();
                      },
                      child: const Text('Kanselleer'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: stoorTemplate,
                      child: Text(isLoading ? 'Stoor...' : 'Stoor'),
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
