import 'package:flutter/material.dart';
import 'package:spys/l10n/app_localizations.dart';

class AdminAboutScreen extends StatelessWidget {
  const AdminAboutScreen({super.key});

  void _rateApp(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('TODO: Rate this app')),);
  }

  void _sendFeedback(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('TODO: Send feedback')),);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: ListView(
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Spys Admin', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  Text('Weergawe: 1.0.0', style: textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                  const SizedBox(height: 12),
                  Text(loc?.aboutSpysAdminDescription ?? 'Description for Spys Admin.', style: textTheme.bodyLarge),
                ],
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc?.aboutSpysAdminTeam ?? 'Spys Admin Team', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(loc?.aboutSpysAdminTeamMembers ?? 'Team members info.', style: textTheme.bodyLarge),
                ],
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc?.aboutSpysAdminContact ?? 'Contact', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(loc?.aboutSpysAdminContactDetails ?? 'Contact details info.', style: textTheme.bodyLarge),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _rateApp(context),
                icon: const Icon(Icons.star),
                label: Text(loc?.rateThisApp ?? 'Rate this app'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  textStyle: textTheme.titleMedium,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _sendFeedback(context),
                icon: const Icon(Icons.feedback),
                label: Text(loc?.sendFeedback ?? 'Send feedback'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  textStyle: textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(loc?.aboutSpysAdminTerms ?? 'Terms of Service, Privacy Policy, More team members (TODO)', style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey)),
        ],
      ),
    );
  }
} 