import 'package:flutter/material.dart';

/// Admin profile management screen
/// TODO: Implement real admin profile management with:
/// - Admin account information display
/// - Role and permissions management
/// - Profile picture upload
/// - Contact information
/// - Department and campus assignment
/// - Admin activity log
/// - Account settings
/// - Password management
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Profile')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.admin_panel_settings, size: 64, color: Colors.grey),
            SizedBox(height: 24),
            Text('Admin Profile - Coming Soon', style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
} 