import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../services/auth_service.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/locale_provider.dart';
import 'package:spys/l10n/app_localizations.dart';

class AdminSettingsScreen extends StatefulWidget {
  final void Function(int) onNavItemSelected;
  const AdminSettingsScreen({super.key, required this.onNavItemSelected});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _authService = AuthService();
  bool _darkMode = false;
  bool _pushNotifications = true;
  bool _emailNotifications = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final currentLanguage = localeProvider.locale.languageCode == 'af' ? 'Afrikaans' : 'English';
    
    return ListView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      children: [
        // Language Settings Card
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(
                  loc?.language ?? 'Language', 
                  style: Theme.of(context).textTheme.titleMedium
                ),
                subtitle: Text(currentLanguage),
                trailing: Switch(
                  value: localeProvider.locale.languageCode == 'en',
                  onChanged: (value) {
                    final newLocale = value ? const Locale('en') : const Locale('af');
                    localeProvider.setLocale(newLocale);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          value 
                              ? 'Language changed to English' 
                              : 'Taal verander na Afrikaans'
                        ),
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 1),
              // Alternative language selection with dropdown
              ListTile(
                leading: const Icon(Icons.translate),
                title: Text(
                  'Select Language',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                trailing: DropdownButton<String>(
                  value: localeProvider.locale.languageCode,
                  underline: const SizedBox(),
                  items: [
                    DropdownMenuItem(
                      value: 'af',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Center(
                              child: Text(
                                'AF',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Afrikaans'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'en',
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 20,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: const Center(
                              child: Text(
                                'EN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('English'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      localeProvider.setLocale(Locale(value));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value == 'en' 
                                ? 'Language changed to English' 
                                : 'Taal verander na Afrikaans'
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Theme Settings Card
        Card(
          child: SwitchListTile(
            title: Text(loc?.dark_theme ?? 'Dark Theme', style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text(_darkMode ? 'Dark mode enabled' : 'Light mode enabled'),
            value: _darkMode,
            onChanged: (val) {
              setState(() {
                _darkMode = val;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(val ? (loc?.dark_theme ?? 'Dark Theme') : (loc?.light_theme ?? 'Light Theme'))),
              );
              // TODO: Backend integration for theme
            },
            secondary: Icon(_darkMode ? Icons.dark_mode : Icons.light_mode),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Notification Settings Card
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: Text('Push Notifications', style: Theme.of(context).textTheme.titleMedium),
                subtitle: const Text('Receive push notifications for orders and updates'),
                value: _pushNotifications,
                onChanged: (val) {
                  setState(() {
                    _pushNotifications = val;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Push notifications ${val ? 'enabled' : 'disabled'} (mock)')),
                  );
                  // TODO: Backend integration for push notifications
                },
                secondary: const Icon(Icons.notifications_active),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: Text('Email Notifications', style: Theme.of(context).textTheme.titleMedium),
                subtitle: const Text('Receive email notifications for important updates'),
                value: _emailNotifications,
                onChanged: (val) {
                  setState(() {
                    _emailNotifications = val;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Email notifications ${val ? 'enabled' : 'disabled'} (mock)')),
                  );
                  // TODO: Backend integration for email notifications
                },
                secondary: const Icon(Icons.email),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Account Management Card
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: AppConstants.errorColor),
                title: Text(
                  'Logout', 
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppConstants.errorColor
                  )
                ),
                subtitle: const Text('Sign out of your admin account'),
                onTap: _showLogoutDialog,
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Information Section
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text('About Spys Admin', style: Theme.of(context).textTheme.titleMedium),
                subtitle: const Text('Learn more about the admin dashboard'),
                onTap: () => widget.onNavItemSelected(6), // About screen index
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: Text('Help & FAQ', style: Theme.of(context).textTheme.titleMedium),
                subtitle: const Text('Get help and find answers to common questions'),
                onTap: () => widget.onNavItemSelected(7), // Help screen index
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text('Terms & Privacy', style: Theme.of(context).textTheme.titleMedium),
                subtitle: const Text('View terms of service and privacy policy'),
                onTap: () => widget.onNavItemSelected(8), // Terms screen index
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        const Text('// TODO: Backend integration for settings', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Teken uit'),
        content: const Text('Is jy seker jy wil uitteken?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kanselleer'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.logout();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Teken uit'),
          ),
        ],
      ),
    );
  }
} 
