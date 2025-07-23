import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../services/auth_service.dart';
import '../about/about_screen.dart';
import '../help/help_screen.dart';
import '../terms/terms_screen.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/locale_provider.dart';
import 'package:spys/l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  bool _darkMode = false;
  String _language = 'Afrikaans';
  bool _pushNotifications = true;
  bool _emailNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.settings),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        children: [
          Card(
            child: SwitchListTile(
              title: Text(AppLocalizations.of(context)!.dark_theme, style: Theme.of(context).textTheme.titleMedium),
              value: _darkMode,
              onChanged: (val) {
                setState(() {
                  _darkMode = val;
                });
                // TODO: Theme integration
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(val ? AppLocalizations.of(context)!.dark_theme : AppLocalizations.of(context)!.light_theme)),
                );
              },
              secondary: const Icon(Icons.brightness_6),
            ),
          ),
          const Divider(),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language),
              title: Text(AppLocalizations.of(context)!.language, style: Theme.of(context).textTheme.titleMedium),
              trailing: DropdownButton<String>(
                value: _language,
                items: [
                  DropdownMenuItem(value: 'Afrikaans', child: Text(AppLocalizations.of(context)!.afrikaans)),
                  DropdownMenuItem(value: 'English', child: Text(AppLocalizations.of(context)!.english)),
                ],
                onChanged: (val) {
                  setState(() {
                    _language = val ?? 'Afrikaans';
                  });
                  final provider = Provider.of<LocaleProvider>(context, listen: false);
                  provider.setLocale(Locale(_language == AppLocalizations.of(context)!.english ? 'en' : 'af'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${AppLocalizations.of(context)!.language}: ${_language == 'English' ? AppLocalizations.of(context)!.english : AppLocalizations.of(context)!.afrikaans}')),
                  );
                },
              ),
            ),
          ),
          const Divider(),
          Card(
            child: SwitchListTile(
              title: Text('Push Kennisgewings', style: Theme.of(context).textTheme.titleMedium),
              value: _pushNotifications,
              onChanged: (val) {
                setState(() {
                  _pushNotifications = val;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Push kennisgewings ${val ? 'aangeskakel' : 'afgeskakel'} (mock)')),
                );
              },
              secondary: const Icon(Icons.notifications_active),
            ),
          ),
          const Divider(),
          Card(
            child: SwitchListTile(
              title: Text('E-pos Kennisgewings', style: Theme.of(context).textTheme.titleMedium),
              value: _emailNotifications,
              onChanged: (val) {
                setState(() {
                  _emailNotifications = val;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('E-pos kennisgewings ${val ? 'aangeskakel' : 'afgeskakel'} (mock)')),
                );
              },
              secondary: const Icon(Icons.email),
            ),
          ),
          const Divider(),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppConstants.errorColor),
              title: Text('Teken uit', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppConstants.errorColor)),
              onTap: _showLogoutDialog,
            ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          // --- Info Section ---
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text('Oor Spys', style: Theme.of(context).textTheme.titleMedium),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: Text('Hulp & Vrae', style: Theme.of(context).textTheme.titleMedium),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HelpScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: Text('Bepalings & Privaatheid', style: Theme.of(context).textTheme.titleMedium),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TermsScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
