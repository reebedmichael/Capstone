import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../services/auth_service.dart';
import '../about/about_screen.dart';
import '../help/help_screen.dart';
import '../terms/terms_screen.dart';
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
  String _language = 'Afrikaans';
  bool _pushNotifications = true;
  bool _emailNotifications = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      children: [
        Card(
          child: SwitchListTile(
            title: Text(loc?.dark_theme ?? 'Dark Theme', style: Theme.of(context).textTheme.titleMedium),
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
            secondary: const Icon(Icons.brightness_6),
          ),
        ),
        const Divider(),
        Card(
          child: ListTile(
            leading: const Icon(Icons.language),
            title: Text(loc?.language ?? 'Language', style: Theme.of(context).textTheme.titleMedium),
            trailing: DropdownButton<String>(
              value: _language,
              items: [
                DropdownMenuItem(value: 'Afrikaans', child: Text(loc?.afrikaans ?? 'Afrikaans')),
                DropdownMenuItem(value: 'English', child: Text(loc?.english ?? 'English')),
              ],
              onChanged: (val) {
                setState(() {
                  _language = val ?? 'Afrikaans';
                });
                final provider = Provider.of<LocaleProvider>(context, listen: false);
                provider.setLocale(Locale(_language == (loc?.english ?? 'English') ? 'en' : 'af'));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${loc?.language ?? 'Language'}: ${_language == 'English' ? (loc?.english ?? 'English') : (loc?.afrikaans ?? 'Afrikaans')}')),
                );
                // TODO: Backend integration for language
              },
            ),
          ),
        ),
        const Divider(),
        Card(
          child: SwitchListTile(
            title: Text('Push Notifications', style: Theme.of(context).textTheme.titleMedium),
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
        ),
        const Divider(),
        Card(
          child: SwitchListTile(
            title: Text('Email Notifications', style: Theme.of(context).textTheme.titleMedium),
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
        ),
        const Divider(),
        Card(
          child: ListTile(
            leading: const Icon(Icons.logout, color: AppConstants.errorColor),
            title: Text('Logout', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppConstants.errorColor)),
            onTap: _showLogoutDialog,
          ),
        ),
        const SizedBox(height: 32),
        // --- Info Section ---
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text('About Spys Admin', style: Theme.of(context).textTheme.titleMedium),
                onTap: () => widget.onNavItemSelected(7),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: Text('Help & FAQ', style: Theme.of(context).textTheme.titleMedium),
                onTap: () => widget.onNavItemSelected(8),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text('Terms & Privacy', style: Theme.of(context).textTheme.titleMedium),
                onTap: () => widget.onNavItemSelected(9),
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
              Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
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