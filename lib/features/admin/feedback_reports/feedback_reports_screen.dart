import 'package:flutter/material.dart';

class FeedbackReportsScreen extends StatelessWidget {
  const FeedbackReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final feedback = [
      {'gebruiker': 'Jan Smit', 'sterre': 5, 'kommentaar': 'Uitstekende diens!', 'datum': '2024-06-01'},
      {'gebruiker': 'Anna Jacobs', 'sterre': 4, 'kommentaar': 'Lekker kos.', 'datum': '2024-06-02'},
      {'gebruiker': 'Piet Pienaar', 'sterre': 3, 'kommentaar': 'Kon vinniger wees.', 'datum': '2024-06-03'},
    ];
    final weekStats = [3, 5, 2, 4, 6, 1, 2];
    final days = ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Sa', 'So'];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Terugvoer', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: feedback.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final item = feedback[i];
                return Card(
                  child: ListTile(
                    title: Text(item['gebruiker'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${item['kommentaar'] ?? ''}\n${item['datum'] ?? ''}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(5, (s) => Icon(
                        s < (item['sterre'] is int ? item['sterre'] as int : int.tryParse(item['sterre'].toString()) ?? 0)
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      )),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          const Text('Weeklikse Terugvoer Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (int i = 0; i < weekStats.length; i++)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: (weekStats[i] is num ? weekStats[i].toInt() : int.tryParse(weekStats[i].toString()) ?? 0) * 15.0,
                          width: 18,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 4),
                        Text(days[i]),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text('// TODO: Vervang met regte chart widget en backend data', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
        ],
      ),
    );
  }
} 