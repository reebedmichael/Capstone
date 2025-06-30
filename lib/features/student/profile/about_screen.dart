import 'package:flutter/material.dart';

/// About screen with app information
/// TODO: Implement real about screen with:
/// - App version and build information
/// - Terms of service link
/// - Privacy policy link
/// - License information
/// - Developer credits
/// - Campus dining partnership info
/// - App features overview
/// - Contact information
/// - Social media links
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.info, size: 64, color: Colors.grey),
            SizedBox(height: 24),
            Text('About - Coming Soon', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
} 