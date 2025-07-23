import 'package:flutter/material.dart';

class FeedbackReportsScreen extends StatefulWidget {
  const FeedbackReportsScreen({super.key});

  @override
  State<FeedbackReportsScreen> createState() => _FeedbackReportsScreenState();
}

class _FeedbackReportsScreenState extends State<FeedbackReportsScreen> {
  List<Map<String, dynamic>> feedback = [
    {
      'id': 1,
      'gebruiker': 'Jan Smit',
      'sterre': 5,
      'kommentaar': 'Uitstekende diens! Kos was baie lekker en vinnige aflewering.',
      'datum': '2024-06-01',
      'kategorie': 'Diens',
      'status': 'Oop',
      'response': ''
    },
    {
      'id': 2,
      'gebruiker': 'Anna Jacobs',
      'sterre': 4,
      'kommentaar': 'Lekker kos, maar kon warmer gewees het.',
      'datum': '2024-06-02',
      'kategorie': 'Kos',
      'status': 'Beantwoord',
      'response': 'Dankie vir jou terugvoer! Ons sal verseker dat kos warmer bedien word.'
    },
    {
      'id': 3,
      'gebruiker': 'Piet Pienaar',
      'sterre': 3,
      'kommentaar': 'Kon vinniger wees met aflewering.',
      'datum': '2024-06-03',
      'kategorie': 'Aflewering',
      'status': 'Oop',
      'response': ''
    },
    {
      'id': 4,
      'gebruiker': 'Maria van der Merwe',
      'sterre': 2,
      'kommentaar': 'Burger was koud en friet was sag. Nie baie tevrede nie.',
      'datum': '2024-06-04',
      'kategorie': 'Kos',
      'status': 'Oop',
      'response': ''
    },
    {
      'id': 5,
      'gebruiker': 'John Smith',
      'sterre': 5,
      'kommentaar': 'Fantastiese app! Maklik om te gebruik en kos is altyd vars.',
      'datum': '2024-06-05',
      'kategorie': 'App',
      'status': 'Beantwoord',
      'response': 'Baie dankie vir die positiewe terugvoer!'
    },
  ];

  String selectedFilter = 'Alle';
  final filterOptions = ['Alle', 'Oop', 'Beantwoord'];
  final categories = ['Alle', 'Diens', 'Kos', 'Aflewering', 'App'];
  String selectedCategory = 'Alle';

  void _showFeedbackDetails(Map<String, dynamic> item, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Terugvoer #${item['id']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Gebruiker:', item['gebruiker'].toString()),
              _buildDetailRow('Datum:', item['datum'].toString()),
              _buildDetailRow('Kategorie:', item['kategorie'].toString()),
              _buildDetailRow('Status:', item['status'].toString()),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('Sterretelling: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...List.generate(5, (s) => Icon(
                    s < (item['sterre'] as int) ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 20,
                  )),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Kommentaar:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(item['kommentaar'].toString(), style: const TextStyle(fontSize: 15)),
              if (item['response'].toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Respons:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(item['response'].toString(), style: const TextStyle(fontSize: 15)),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sluit'),
          ),
          if (item['status'] == 'Oop')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showResponseDialog(item, index);
              },
              child: const Text('Reageer'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showResponseDialog(Map<String, dynamic> item, int index) {
    final responseController = TextEditingController(text: item['response']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reageer op Terugvoer #${item['id']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Van: ${item['gebruiker']}', style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Kommentaar: "${item['kommentaar']}"', style: const TextStyle(fontStyle: FontStyle.italic)),
              const SizedBox(height: 16),
              TextField(
                controller: responseController,
                decoration: const InputDecoration(
                  labelText: 'Jou respons',
                  border: OutlineInputBorder(),
                  hintText: 'Tik jou respons hier...',
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kanselleer'),
          ),
          ElevatedButton(
            onPressed: () {
              if (responseController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Respons kan nie leeg wees nie')),
                );
                return;
              }
              
              setState(() {
                feedback[index]['response'] = responseController.text;
                feedback[index]['status'] = 'Beantwoord';
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Respons gestuur na ${item['gebruiker']}')),
              );
              // TODO: Backend integration for response
            },
            child: const Text('Stuur Respons'),
          ),
        ],
      ),
    );
  }

  Color _getStarColor(int stars) {
    if (stars >= 4) return Colors.green;
    if (stars >= 3) return const Color(0xFFE64A19);
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    // Filter feedback based on selected filters
    final filteredFeedback = feedback.where((item) {
      final statusMatch = selectedFilter == 'Alle' || item['status'] == selectedFilter;
      final categoryMatch = selectedCategory == 'Alle' || item['kategorie'] == selectedCategory;
      return statusMatch && categoryMatch;
    }).toList();

    final weekStats = [3, 5, 2, 4, 6, 1, 2];
    final days = ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Sa', 'So'];
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Terugvoer', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Text('Status: ', style: Theme.of(context).textTheme.bodyMedium),
                  DropdownButton<String>(
                    value: selectedFilter,
                    items: filterOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => selectedFilter = val ?? 'Alle'),
                  ),
                  const SizedBox(width: 16),
                  Text('Kategorie: ', style: Theme.of(context).textTheme.bodyMedium),
                  DropdownButton<String>(
                    value: selectedCategory,
                    items: categories.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => selectedCategory = val ?? 'Alle'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Summary Cards
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('${feedback.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const Text('Totale Terugvoer'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  color: const Color(0xFFFFF3E0),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('${feedback.where((f) => f['status'] == 'Oop').length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const Text('Oop Items'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text((feedback.map((f) => f['sterre'] as int).reduce((a, b) => a + b) / feedback.length).toStringAsFixed(1), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        const Text('Gemiddelde Sterren'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: filteredFeedback.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final item = filteredFeedback[i];
                final originalIndex = feedback.indexOf(item);
                return Card(
                  elevation: 2,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStarColor(item['sterre'] as int),
                      child: Text(
                        '${item['sterre']}★',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(item['gebruiker'].toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['kommentaar'].toString(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Chip(
                              label: Text(item['kategorie'].toString(), style: const TextStyle(fontSize: 12)),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            const SizedBox(width: 8),
                            Chip(
                              label: Text(item['status'].toString(), style: const TextStyle(fontSize: 12)),
                              backgroundColor: item['status'] == 'Oop' ? const Color(0xFFFFE0B2) : const Color(0xFFC8E6C9),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ],
                        ),
                      ],
                    ),
                    isThreeLine: true,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'view':
                            _showFeedbackDetails(item, originalIndex);
                            break;
                          case 'respond':
                            if (item['status'] == 'Oop') {
                              _showResponseDialog(item, originalIndex);
                            }
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility, size: 20),
                              SizedBox(width: 8),
                              Text('Bekyk Details'),
                            ],
                          ),
                        ),
                        if (item['status'] == 'Oop')
                          const PopupMenuItem(
                            value: 'respond',
                            child: Row(
                              children: [
                                Icon(Icons.reply, size: 20),
                                SizedBox(width: 8),
                                Text('Reageer'),
                              ],
                            ),
                          ),
                      ],
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
                          height: (weekStats[i] as num).toDouble() * 15.0,
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
