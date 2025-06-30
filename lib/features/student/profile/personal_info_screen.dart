import 'package:flutter/material.dart';

/// Personal information management screen
/// TODO: Implement real personal info management with:
/// - Editable name, email, phone fields
/// - Profile picture upload
/// - Account verification status
/// - Student ID and academic information
/// - Save/cancel functionality with validation
class PersonalInfoScreen extends StatelessWidget {
  const PersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Personal Information')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.person, size: 64, color: Colors.grey),
            SizedBox(height: 24),
            Text('Personal Information - Coming Soon', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
} 