import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ToelaeMainPage extends StatelessWidget {
  const ToelaeMainPage({super.key});

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
                    context.go('/toelae/gebruiker_tipes');
                  },
                  child: const Text("Gebruiker Tipes"),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    context.go('/toelae/bestuur');
                  },
                  child: const Text("Individueel"),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    context.go('/toelae/transaksies');
                  },
                  child: const Text("Transaksie Geskiedenis"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
