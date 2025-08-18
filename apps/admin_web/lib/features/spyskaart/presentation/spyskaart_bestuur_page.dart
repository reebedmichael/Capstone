import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SpyskaartBestuurPage extends StatelessWidget {
  const SpyskaartBestuurPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilledButton(
                  onPressed: () {
                    context.go('/week_spyskaart');
                  },
                  child: const Text("Week Spyskaart"),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    context.go('/templates/week');
                  },
                  child: const Text("Week Templaat"),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    context.go('/templates/kositem');
                  },
                  child: const Text("Kositem Templaat"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
