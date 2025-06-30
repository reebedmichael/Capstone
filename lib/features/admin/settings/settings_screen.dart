import 'package:flutter/material.dart';
import '../../../core/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  bool _emailAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.paddingLarge),
                  child: ListView(
                    children: [
                      _buildSettingsSection(
                        'Appearance',
                        [
                          SwitchListTile(
                            title: const Text('Dark Mode'),
                            subtitle: const Text('Enable dark theme'),
                            value: _darkMode,
                            onChanged: (value) {
                              setState(() {
                                _darkMode = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildSettingsSection(
                        'Notifications',
                        [
                          SwitchListTile(
                            title: const Text('Push Notifications'),
                            subtitle: const Text('Receive push notifications'),
                            value: _notifications,
                            onChanged: (value) {
                              setState(() {
                                _notifications = value;
                              });
                            },
                          ),
                          SwitchListTile(
                            title: const Text('Email Alerts'),
                            subtitle: const Text('Receive email notifications'),
                            value: _emailAlerts,
                            onChanged: (value) {
                              setState(() {
                                _emailAlerts = value;
                              });
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildSettingsSection(
                        'Account',
                        [
                          ListTile(
                            leading: const Icon(Icons.person),
                            title: const Text('Profile'),
                            subtitle: const Text('Manage your profile'),
                            onTap: () {
                              // TODO: Navigate to profile
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.security),
                            title: const Text('Security'),
                            subtitle: const Text('Change password and security settings'),
                            onTap: () {
                              // TODO: Navigate to security
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.logout),
                            title: const Text('Logout'),
                            subtitle: const Text('Sign out of your account'),
                            onTap: () {
                              // TODO: Implement logout
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      _buildSettingsSection(
                        'About',
                        [
                          ListTile(
                            leading: const Icon(Icons.info),
                            title: const Text('Version'),
                            subtitle: const Text('1.0.0'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.description),
                            title: const Text('Terms of Service'),
                            onTap: () {
                              // TODO: Show terms
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.privacy_tip),
                            title: const Text('Privacy Policy'),
                            onTap: () {
                              // TODO: Show privacy policy
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
} 