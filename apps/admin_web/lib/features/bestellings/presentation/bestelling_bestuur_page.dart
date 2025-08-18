import 'package:flutter/material.dart';

class BestellingBestuurPage extends StatelessWidget {
  const BestellingBestuurPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 🔹 Top action row with dropdown, button, and search bar
        Row(
          children: [
            // Filter dropdown (currently only "Alle", you can expand later)
            DropdownButton<String>(
              items: const [
                DropdownMenuItem(value: 'alle', child: Text('Alle')),
                DropdownMenuItem(value: 'aktief', child: Text('Aktief')),
                DropdownMenuItem(value: 'voltooi', child: Text('Voltooi')),
              ],
              onChanged: (_) {},
              value: 'alle',
            ),
            const SizedBox(width: 12),

            // "Massa-aksie" button (bulk actions placeholder)
            OutlinedButton(
              onPressed: () {},
              child: const Text('Massa-aksie'),
            ),

            const Spacer(), // pushes search bar to the right

            // 🔹 Search bar field (you can wire up logic later)
            SizedBox(
              width: 250,
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Soek bestelling...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 🔹 Table stub (UI only for now)
        Expanded(
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Table header row
                  Row(
                    children: const [
                      Expanded(flex: 1, child: Text('ID', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Kliënt', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Datum', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Totale', style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(flex: 2, child: Text('Aksies', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const Divider(),

                  // Table row placeholder (repeat this in logic later)
                  Expanded(
                    child: ListView(
                      children: [
                        Row(
                          children: const [
                            Expanded(flex: 1, child: Text('#1001')),
                            Expanded(flex: 2, child: Text('Jan van der Merwe')),
                            Expanded(flex: 2, child: Text('In proses')),
                            Expanded(flex: 2, child: Text('17 Aug 2025')),
                            Expanded(flex: 2, child: Text('R250.00')),
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Icon(Icons.visibility, size: 18),
                                  SizedBox(width: 8),
                                  Icon(Icons.edit, size: 18),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(),
                        // 👉 add more rows later dynamically
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
