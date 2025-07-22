import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import 'package:spys/l10n/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  void _rateApp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.rateThisApp),
        content: Text(AppLocalizations.of(context)!.todoSkakelNaAppStoreOfGeeSterGradering),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.sluit),
          ),
        ],
      ),
    );
  }

  void _sendFeedback(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.sendFeedback),
        content: TextField(
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.jouTerugvoer,
            border: const OutlineInputBorder(),
          ),
          minLines: 2,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.kanselleer),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.terugvoerGestuurDummy)),
              );
            },
            child: Text(AppLocalizations.of(context)!.stuur),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text('Oor Spys', style: textTheme.titleLarge),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('App', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Card(
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spys App', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Text('Weergawe: 1.0.0', style: textTheme.bodyMedium?.copyWith(color: Colors.grey)),
                    const SizedBox(height: 12),
                    Text('Spys is ’n moderne kampus-etes en bestelplatform. Bestel kos, laai jou beursie op, en kry vinnige diens – alles in een app.', style: textTheme.bodyLarge),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Span', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Card(
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Spanlede', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('• Michael de Beer\n• Jane Doe\n• John Smith\n• Dummy User', style: textTheme.bodyLarge),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Kontak', style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            ),
            Card(
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kontak', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('E-pos: admin@spys.com\nTel: 012 345 6789', style: textTheme.bodyLarge),
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
                  label: Text(AppLocalizations.of(context)!.rateThisApp),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    textStyle: textTheme.titleMedium,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _sendFeedback(context),
                  icon: const Icon(Icons.feedback),
                  label: Text(AppLocalizations.of(context)!.sendFeedback),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    textStyle: textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(AppLocalizations.of(context)!.todoTermsOfServicePrivacyPolicyMeerSpanlede, style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey)),
            // TODO: Backend/data integrasie vir feedback/rating
          ],
        ),
      ),
    );
  }
} 