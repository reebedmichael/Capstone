import 'package:flutter/material.dart';

class InstellingsPage extends StatelessWidget {
  const InstellingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_back),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Instellings",
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(color: Theme.of(context).primaryColor)),
                    Text("Bestuur jou rekening en stelsel voorkeure",
                        style: Theme.of(context).textTheme.bodySmall),
                  ],
                )
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Success Alert (stub)
                  _buildSuccessAlert(context),

                  const SizedBox(height: 16),

                  // Tema Instellings
                  _buildCard(
                    context,
                    icon: Icons.dark_mode,
                    title: "Tema Voorkeure",
                    description: "Kies tussen lig en donker modus",
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text("Donker Modus",
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            Text("Skakel tussen lig en donker tema",
                                style: TextStyle(fontSize: 12)),
                          ],
                        ),
                        Switch(value: false, onChanged: (_) {}),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Taal Instellings
                  _buildCard(
                    context,
                    icon: Icons.language,
                    title: "Taal Voorkeure",
                    description: "Kies jou voorkeur taal vir die stelsel",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Stelsel Taal",
                            style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: "afrikaans",
                          items: const [
                            DropdownMenuItem(
                                value: "afrikaans", child: Text("Afrikaans")),
                            DropdownMenuItem(
                                value: "engels", child: Text("Engels")),
                          ],
                          onChanged: (_) {},
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Hierdie instelling sal plaaslik gestoor word en geld net vir hierdie sessie",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Wagwoord Verander
                  _buildCard(
                    context,
                    icon: Icons.lock,
                    title: "Verander Wagwoord",
                    description:
                        "Opdateer jou rekening wagwoord vir beter sekuriteit",
                    child: Column(
                      children: [
                        _buildPasswordField("Huidige Wagwoord"),
                        const SizedBox(height: 12),
                        _buildPasswordField("Nuwe Wagwoord"),
                        const SizedBox(height: 12),
                        _buildPasswordField("Bevestig Nuwe Wagwoord"),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: () {},
                            child: const Text("Verander Wagwoord"),
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sekuriteit Wenke
                  _buildCard(
                    context,
                    title: "Sekuriteit Wenke",
                    description:
                        "Belangrike inligting oor jou rekening sekuriteit",
                    child: Column(
                      children: [
                        _buildInfoTile(
                          context,
                          icon: Icons.info_outline,
                          color: Colors.blue,
                          text:
                              "Wagwoord Vereistes: Gebruik ten minste 8 karakters met 'n kombinasie van groot letters, klein letters en syfers.",
                        ),
                        const SizedBox(height: 12),
                        _buildInfoTile(
                          context,
                          icon: Icons.check_circle,
                          color: Colors.green,
                          text:
                              "Plaaslike Berging: Jou tema en taal voorkeure word plaaslik gestoor en sal behou word vir hierdie sessie.",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildCard(BuildContext context,
      {IconData? icon,
      required String title,
      required String description,
      required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(
            children: [
              if (icon != null) Icon(icon, size: 20),
              if (icon != null) const SizedBox(width: 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: 4),
          Text(description, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          child,
        ]),
      ),
    );
  }

  Widget _buildPasswordField(String label) {
    return TextField(
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          onPressed: () {},
          icon: const Icon(Icons.visibility_off),
        ),
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context,
      {required IconData icon, required Color color, required String text}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodySmall)),
        ],
      ),
    );
  }

  Widget _buildSuccessAlert(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text("Wagwoord suksesvol verander",
                style: TextStyle(color: Colors.green[700])),
          )
        ],
      ),
    );
  }
}
