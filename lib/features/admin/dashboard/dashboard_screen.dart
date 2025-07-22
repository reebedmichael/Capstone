import 'package:flutter/material.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data
    final stats = [
      {'label': 'Totale Bestellings', 'value': 120},
      {'label': 'Aktiewe Bestellings', 'value': 15},
      {'label': 'Kansellasies', 'value': 3},
      {'label': 'Top Gebruiker', 'value': 'Jan Smit'},
      {'label': 'Gewildste Kos', 'value': 'Chicken Burger'},
    ];
    final ordersPerDay = [10, 15, 20, 12, 18, 25, 20];
    final days = ['Ma', 'Di', 'Wo', 'Do', 'Vr', 'Sa', 'So'];
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: stats.map((stat) => Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${stat['value']}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(stat['label'] as String, style: const TextStyle(fontSize: 16)),
                      ],
                    ),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 32),
              Card(
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bestellings per dag', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 180,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: List.generate(ordersPerDay.length, (i) {
                            final value = ordersPerDay[i];
                            return Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    height: value * 5.0,
                                    width: 24,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(days[i]),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text('// TODO: Vervang met regte chart widget en backend data'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
} 