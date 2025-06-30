import 'package:flutter/material.dart';

/// Help and support screen
/// TODO: Implement real help and support with:
/// - FAQ section with searchable content
/// - Contact support form
/// - Live chat integration
/// - Video tutorials
/// - Troubleshooting guides
/// - Campus dining policies
/// - Order cancellation/refund process
/// - Feedback submission
/// - Knowledge base articles
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.help, size: 64, color: Colors.grey),
            SizedBox(height: 24),
            Text('Help & Support - Coming Soon', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
} 