import 'dart:typed_data';
import 'package:flutter/material.dart';

class KositemFormModal extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController naamController;
  final TextEditingController prysController;
  final TextEditingController bestanddeleController;
  final TextEditingController allergeneController;
  final String? selectedCategory;
  final Uint8List? selectedImage;
  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback onPickImage;
  final Function(String?) onCategoryChanged;

  const KositemFormModal({
    super.key,
    required this.formKey,
    required this.naamController,
    required this.prysController,
    required this.bestanddeleController,
    required this.allergeneController,
    required this.selectedCategory,
    required this.selectedImage,
    required this.isLoading,
    required this.onCancel,
    required this.onSave,
    required this.onPickImage,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(16),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              Text('Kos Item', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Naam + Prys
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: naamController,
                              decoration: const InputDecoration(
                                labelText: 'Kos Item Naam *',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Naam is verpligtend'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: prysController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Prys (R) *',
                                border: OutlineInputBorder(),
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
                      const SizedBox(height: 16),

                      // Kategorie
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        onChanged: onCategoryChanged,
                        decoration: const InputDecoration(
                          labelText: 'Kategorie *',
                          border: OutlineInputBorder(),
                        ),
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
                                  (val) => DropdownMenuItem(
                                    value: val,
                                    child: Text(val),
                                  ),
                                )
                                .toList(),
                      ),
                      const SizedBox(height: 16),

                      // Bestanddele
                      TextFormField(
                        controller: bestanddeleController,
                        decoration: const InputDecoration(
                          labelText: 'Bestanddele *',
                          hintText:
                              'Skei met kommas, bv. Brood, Botter, Konfyt',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Bestanddele is verpligtend'
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Allergene
                      TextFormField(
                        controller: allergeneController,
                        decoration: const InputDecoration(
                          labelText: 'Allergene',
                          hintText: 'Skei met kommas, bv. Gluten, Melk, Eiers',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Image Picker
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: onPickImage,
                            icon: const Icon(Icons.upload),
                            label: const Text('Kies Prent'),
                          ),
                          const SizedBox(width: 16),
                          if (selectedImage != null)
                            SizedBox(
                              width: 80,
                              height: 80,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      child: const Text('Kanselleer'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: onSave,
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
