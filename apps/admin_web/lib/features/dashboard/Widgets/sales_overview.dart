import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SalesOverview extends StatelessWidget {
  const SalesOverview({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Card(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Verkope Oorsig',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Weeklikse verkope prestasie',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                // Placeholder for SalesChart
                Container(
                  height: 320,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade100,
                  ),
                  child: const Center(child: Text('Verkope Grafiek')),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: ElevatedButton(
            onPressed: () => context.go('/verslae'),

            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text('Meer'),
          ),
        ),
      ],
    );
  }
}
