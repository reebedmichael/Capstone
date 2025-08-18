import 'package:flutter/material.dart';

class GebruikersBestuurPage extends StatelessWidget {
  const GebruikersBestuurPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Titel
          Text("Gebruikers Bestuur",
              style: Theme.of(context).textTheme.headlineSmall),

          const SizedBox(height: 20),

          // 🔹 Rol-oorsig blok
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildStatCard("Primêre Admins", "3", Colors.blue),
              _buildStatCard("Sekondêre Admins", "5", Colors.green),
              _buildStatCard("Tersiêre Admins", "2", Colors.orange),
              _buildStatCard("Studente", "120", Colors.purple),
              _buildStatCard("Personeel", "45", Colors.teal),
            ],
          ),

          const SizedBox(height: 30),

          // 🔹 Statistiek blok
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBigStat("Totaal", "175"),
              _buildBigStat("Aktief", "160"),
              _buildBigStat("Wag goedkeuring", "15"),
            ],
          ),

          const SizedBox(height: 30),

          // 🔹 Tabel met mock gebruikers
          Text("Gebruikers Lys",
              style: Theme.of(context).textTheme.titleMedium),

          const SizedBox(height: 12),

          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                _buildUserRow("Jan Smit", "Student", "Aktief"),
                _buildUserRow("Pieter Botha", "Personeel", "Wag goedkeuring"),
                _buildUserRow("Marie Jacobs", "Sekondêre Admin", "Aktief"),
                _buildUserRow("Lerato Nkosi", "Primêre Admin", "Aktief"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔹 Klein statistiek kaart (rolle)
  Widget _buildStatCard(String title, String count, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        children: [
          Text(count,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  // 🔹 Groot statistiek kaart (totaal/aktief/goedkeuring)
  Widget _buildBigStat(String title, String count) {
    return Column(
      children: [
        Text(count,
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 16)),
      ],
    );
  }

  // 🔹 Gebruiker ry met aksie knoppies
  Widget _buildUserRow(String name, String role, String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            child: Icon(Icons.person),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(role, style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          ),
          Text(status,
              style: TextStyle(
                  color: status == "Aktief" ? Colors.green : Colors.orange)),
          const SizedBox(width: 12),
          // 🔹 Aksies
          Row(
            children: [
              IconButton(
                  icon: const Icon(Icons.check_circle, color: Colors.green),
                  onPressed: () {
                    // TODO: Goedkeur gebruiker logika
                  }),
              IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () {
                    // TODO: Verwyder gebruiker logika
                  }),
            ],
          ),
        ],
      ),
    );
  }
}
