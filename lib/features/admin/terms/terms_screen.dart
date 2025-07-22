import 'package:flutter/material.dart';

class AdminTermsScreen extends StatelessWidget {
  const AdminTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Terms & Privacy'), leading: BackButton()),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Terms of Service', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
            SizedBox(height: 16),
            Text('TODO: Volledige bepalings en privaatheidsbeleid hier.', style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
} 