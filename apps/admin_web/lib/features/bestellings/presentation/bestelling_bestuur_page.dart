import 'package:flutter/material.dart';

class BestellingBestuurPage extends StatefulWidget {
  const BestellingBestuurPage({super.key});

  @override
  State<BestellingBestuurPage> createState() => _BestellingBestuurPageState();
}

class _BestellingBestuurPageState extends State<BestellingBestuurPage> {
  // 🔹 Dummy bestelling data (later vervang met databasis resultate)
  final List<Map<String, dynamic>> bestellings = [
    {
      "id": "#1001",
      "klient": "Jan van der Merwe",
      "status": "In proses",
      "datum": "17 Aug 2025",
      "totale": "R250.00"
    },
    {
      "id": "#1002",
      "klient": "Marie Jacobs",
      "status": "Voltooi",
      "datum": "15 Aug 2025",
      "totale": "R180.00"
    },
    {
      "id": "#1003",
      "klient": "Peter Pieterse",
      "status": "Aktief",
      "datum": "16 Aug 2025",
      "totale": "R320.00"
    },
    {
      "id": "#1004",
      "klient": "Karin Koorts",
      "status": "In proses",
      "datum": "14 Aug 2025",
      "totale": "R90.00"
    },
    {
      "id": "#1005",
      "klient": "Hendrik Human",
      "status": "Wag Goedkeuring",
      "datum": "10 Aug 2025",
      "totale": "R450.00"
    },
  ];

  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    // 🔍 Filter logika op dummy data
    final filteredOrders = bestellings.where((order) {
      final q = searchQuery.toLowerCase();
      return order["id"].toLowerCase().contains(q) ||
          order["klient"].toLowerCase().contains(q) ||
          order["status"].toLowerCase().contains(q);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 🔹 Top action row
        Row(
          children: [
            DropdownButton<String>(
              items: const [
                DropdownMenuItem(value: 'alle', child: Text('Alle')),
                DropdownMenuItem(value: 'aktief', child: Text('Aktief')),
                DropdownMenuItem(value: 'voltooi', child: Text('Voltooi')),
              ],
              onChanged: (_) {
                // 👉 Jy kan later filter logika hier inbou
              },
              value: 'alle',
            ),
            const SizedBox(width: 12),

            ElevatedButton.icon(
              onPressed: () {
                // 👉 Voeg later filter logika hier in
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Filtreer funksie geklik")),
                );
              },
              icon: const Icon(Icons.filter_list),
              label: const Text('Filtreer'),
            ),

            const Spacer(),

            // 🔍 Soekveld
            SizedBox(
              width: 250,
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Soek bestelling...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                ),
                onChanged: (val) {
                  setState(() {
                    searchQuery = val;
                  });
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 🔹 Tabel met dummy data
        Expanded(
          child: Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Tabelkop
                  Row(
                    children: const [
                      Expanded(
                          flex: 1,
                          child: Text('ID',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 2,
                          child: Text('Kliënt',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 2,
                          child: Text('Status',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 2,
                          child: Text('Datum',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 2,
                          child: Text('Totale',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 2,
                          child: Text('Aksies',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                  const Divider(),

                  // 🔹 Lys van bestellings
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredOrders.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        return Row(
                          children: [
                            Expanded(flex: 1, child: Text(order["id"])),
                            Expanded(flex: 2, child: Text(order["klient"])),
                            Expanded(flex: 2, child: Text(order["status"])),
                            Expanded(flex: 2, child: Text(order["datum"])),
                            Expanded(flex: 2, child: Text(order["totale"])),
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility, size: 20),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                "Besigtig ${order["id"]}")),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                            content: Text(
                                                "Wysig ${order["id"]}")),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
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
