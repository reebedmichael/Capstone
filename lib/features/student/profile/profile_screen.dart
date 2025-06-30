import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/utils/color_utils.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // TODO: Edit profile
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          children: [
            // Profile Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: setOpacity(AppConstants.primaryColor, 0.1),
                      child: Icon(
                        Icons.person,
                        size: 50,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    const Text(
                      'John Doe',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Student',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn('Orders', '15'),
                        _buildStatColumn('Reviews', '8'),
                        _buildStatColumn('Points', '1,250'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            
            // Menu Items
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Personal Information'),
                    subtitle: const Text('Name, email, phone'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to personal info
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.location_on),
                    title: const Text('Delivery Address'),
                    subtitle: const Text('Manage delivery addresses'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to addresses
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.payment),
                    title: const Text('Payment Methods'),
                    subtitle: const Text('Cards, wallet, etc.'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to payment methods
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.notifications),
                    title: const Text('Notifications'),
                    subtitle: const Text('Push, email, SMS'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to notifications
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('Security'),
                    subtitle: const Text('Password, privacy'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to security
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.help),
                    title: const Text('Help & Support'),
                    subtitle: const Text('FAQ, contact us'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to help
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.info),
                    title: const Text('About'),
                    subtitle: const Text('Version, terms, privacy'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      // TODO: Navigate to about
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppConstants.errorColor),
                    title: const Text(
                      'Logout',
                      style: TextStyle(color: AppConstants.errorColor),
                    ),
                    onTap: () {
                      // TODO: Implement logout
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Logout'),
                          content: const Text('Are you sure you want to logout?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                // TODO: Perform logout
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.errorColor,
                              ),
                              child: const Text('Logout'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppConstants.primaryColor,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
} 