import 'package:flutter/material.dart';

class KositemFormModal extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController naamController;
  final TextEditingController prysController;
  final TextEditingController bestanddeleController;
  final TextEditingController allergeneController;
  final TextEditingController beskrywingController;

  /// Multi-select dieet categories
  final List<String> selectedCategories;
  final List<String> allCategories;

  final String? selectedImage;
  final bool isLoading;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final VoidCallback onPickImage;
  final Function(List<String>) onCategoriesChanged;

  const KositemFormModal({
    super.key,
    required this.formKey,
    required this.naamController,
    required this.prysController,
    required this.bestanddeleController,
    required this.allergeneController,
    required this.beskrywingController,
    required this.selectedCategories,
    required this.allCategories,
    required this.selectedImage,
    required this.isLoading,
    required this.onCancel,
    required this.onSave,
    required this.onPickImage,
    required this.onCategoriesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFFF3E0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.orangeAccent, width: 0.5),
                  ),
                ),
                child: Text(
                  'Voeg Nuwe Kos Item By',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [Colors.orange, Colors.deepOrange],
                      ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Naam & Prys
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: naamController,
                              label: "Kos Item Naam *",
                              validator: (v) => v == null || v.isEmpty
                                  ? "Naam is verpligtend"
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: prysController,
                              label: "Prys (R) *",
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return "Prys is verpligtend";
                                }
                                if (double.tryParse(v) == null ||
                                    double.parse(v) <= 0) {
                                  return "Ongeldige prys";
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _buildTextField(
                        controller: beskrywingController,
                        label: "Beskrywing",
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // --- Categories: multi-select chips with validation ---
                      Text(
                        "Kategorieë *",
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.black),
                      ),
                      const SizedBox(height: 8),
                      FormField<List<String>>(
                        initialValue: selectedCategories,
                        validator: (val) => val == null || val.isEmpty
                            ? 'Kategorie is verpligtend'
                            : null,
                        builder: (state) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: allCategories.map((cat) {
                                  final isSelected = state.value!.contains(cat);
                                  return FilterChip(
                                    label: Text(cat),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      final newList = List<String>.from(
                                        state.value!,
                                      );
                                      if (selected) {
                                        if (!newList.contains(cat)) {
                                          newList.add(cat);
                                        }
                                      } else {
                                        newList.remove(cat);
                                      }
                                      state.didChange(newList);
                                      onCategoriesChanged(newList);
                                    },
                                    selectedColor: Colors.deepOrange,
                                    showCheckmark: true,
                                  );
                                }).toList(),
                              ),
                              if (state.hasError)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    state.errorText ?? '',
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      _buildTextField(
                        controller: bestanddeleController,
                        label: "Bestanddele *",
                        hint: "Skei met kommas, bv. Brood, Botter, Konfyt",
                        validator: (v) => v == null || v.isEmpty
                            ? "Bestanddele is verpligtend"
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // _buildTextField(
                      //   controller: allergeneController,
                      //   label: "Allergene",
                      //   hint: "Skei met kommas, bv. Gluten, Melk, Eiers",
                      // ),
                      // const SizedBox(height: 16),

                      // Image Picker
                      Text(
                        "Kos Prent",
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(color: Colors.black),
                      ),
                      const SizedBox(height: 8),
                      if (selectedImage != null && selectedImage!.isNotEmpty)
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                selectedImage!,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed:
                                    onPickImage, // keep existing callback (parent should clear image)
                              ),
                            ),
                          ],
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: onPickImage,
                          icon: const Icon(Icons.upload),
                          label: const Text("Laai Prent Op"),
                        ),
                      const SizedBox(height: 24),

                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          border: Border.all(color: Colors.orange.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "💡 Wenke: Velde gemerk met * is verpligtend. "
                          "Laai ’n hoë kwaliteit prentjie op om jou kositem aantreklik te maak.",
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Footer buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.orangeAccent, width: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: onCancel,
                        child: const Text("Kanselleer"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                        child: Text(isLoading ? "Stoor..." : "Stoor"),
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
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.black),
        hintStyle: const TextStyle(color: Colors.black54),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      validator: validator,
    );
  }
}
