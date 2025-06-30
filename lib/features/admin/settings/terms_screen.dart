import 'package:flutter/material.dart';

/// Terms of service display screen
/// TODO: Implement real terms of service with:
/// - Full terms of service text
/// - Version history and updates
/// - Accept/decline functionality
/// - Legal compliance information
/// - Campus dining policies
/// - User agreement tracking
/// - Terms acceptance date
/// - Print/share functionality
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms of Service')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.description, size: 64, color: Colors.grey),
            SizedBox(height: 24),
            Text('Terms of Service - Coming Soon', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
} 