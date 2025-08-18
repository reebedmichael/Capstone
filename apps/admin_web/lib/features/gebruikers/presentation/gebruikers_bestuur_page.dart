import 'package:flutter/material.dart';

class GebruikersBestuurPage extends StatefulWidget {
  const GebruikersBestuurPage({super.key});

  @override
  State<GebruikersBestuurPage> createState() => _GebruikersBestuurPageState();
}

class _GebruikersBestuurPageState extends State<GebruikersBestuurPage> {
  String searchQuery = '';
  String filterRole = 'Alle';

  // 🔹 Dummy data
  List<Map<String, String>> users = [
    {
      "name": "Jan Smit",
      "email": "jan@example.com",
      "phone": "0812345678",
      "role": "Student",
      "status": "Aktief",
      "registered": "01 Jan 2025"
    },
    {
      "name": "Pieter Botha",
      "email": "pieter@example.com",
      "phone": "0823456789",
      "role": "Personeel",
      "status": "Wag goedkeuring",
      "registered": "05 Feb 2025"
    },
    {
      "name": "Marie Jacobs",
      "email": "marie@example.com",
      "phone": "0834567890",
      "role": "Sekondêre Admin",
      "status": "Aktief",
      "registered": "10 Mar 2025"
    },
    {
      "name": "Lerato Nkosi",
      "email": "lerato@example.com",
      "phone": "0845678901",
      "role": "Primêre Admin",
      "status": "Aktief",
      "registered": "15 Apr 2025"
    },
  ];

  @override
  Widget build(BuildContext context) {
    // 🔹 Filtered users
    List<Map<String, String>> filteredUsers = users.where((user) {
      bool matchesSearch = user["name"]!
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
      bool matchesRole = filterRole == 'Alle' || user["role"] == filterRole;
      return matchesSearch && matchesRole;
    }).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🔹 Titel
          Text("Gebruikers Bestuur",
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),

          // 🔹 Rol-oorsig blok
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _buildStatCard("Primêre Admins", "1"),
              _buildStatCard("Sekondêre Admins", "1"),
              _buildStatCard("Tersiêre Admins", "0"),
              _buildStatCard("Studente", "1"),
              _buildStatCard("Personeel", "1"),
            ],
          ),

          const SizedBox(height: 30),

          // 🔹 Statistiek blok
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _buildBigStat("Totaal Gebruikers", "4"),
              _buildBigStat("Aktiewe Gebruikers", "3"),
              _buildBigStat("Wag Goedkeuring", "1"),
              _buildBigStat("Gedeaktiveer", "0"),
            ],
          ),

          const SizedBox(height: 30),

          // 🔹 Search en filter
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 250,
                child: TextField(
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Soek gebruiker...',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: filterRole,
                items: const [
                  DropdownMenuItem(value: 'Alle', child: Text('Alle')),
                  DropdownMenuItem(value: 'Student', child: Text('Student')),
                  DropdownMenuItem(value: 'Personeel', child: Text('Personeel')),
                  DropdownMenuItem(
                      value: 'Sekondêre Admin', child: Text('Sekondêre Admin')),
                  DropdownMenuItem(
                      value: 'Primêre Admin', child: Text('Primêre Admin')),
                ],
                onChanged: (value) {
                  setState(() {
                    filterRole = value!;
                  });
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 🔹 Gebruiker lys as cards
          Column(
            children: filteredUsers.map((user) => _buildUserCard(user)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count) {
    return Container(
      width: 140,
      height: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(count,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBigStat(String title, String count) {
    return Container(
      width: 150,
      height: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(count,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, String> user) {
    bool pendingApproval = user["status"] == "Wag goedkeuring";

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Naam en rol bo
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user["name"]!,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(user["role"]!,
                          style:
                              TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Ander info
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _infoColumn("E-pos", user["email"]!),
                  _infoColumn("Selfoon", user["phone"]!),
                  _infoColumn("Status", user["status"]!,
                      color: user["status"] == "Aktief" ? Colors.green : Colors.orange),
                  _infoColumn("Geregistreer", user["registered"]!),
                  if (pendingApproval)
                    Row(
                      children: [
                        IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text("${user["name"]} goedgekeur!")));
                            }),
                        IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text("${user["name"]} verwyder!")));
                            }),
                      ],
                    )
                  else
                    IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text("${user["name"]} verwyder!")));
                        }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoColumn(String title, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(fontSize: 14, color: color ?? Colors.black)),
        ],
      ),
    );
  }
}
