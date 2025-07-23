import 'package:flutter/material.dart';
import '../../../core/constants.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bepalings & Privaatheid'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        leading: const BackButton(),
      ),
      body: const Padding(
        padding: EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bepalings van Diens', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 0.2)),
            SizedBox(height: 16),
            Text('TODO: Volledige bepalings en privaatheidsbeleid hier.', style: TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
} 
