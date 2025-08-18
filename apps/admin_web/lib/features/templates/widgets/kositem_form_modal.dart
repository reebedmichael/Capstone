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
          key: formKey,
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
                        if (value == null || value.isEmpty)
                          return 'Prys is verpligtend';
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
                onChanged: onCategoryChanged,
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
                    onPressed: onPickImage,
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
