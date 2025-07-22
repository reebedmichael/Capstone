import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import 'package:spys/l10n/app_localizations.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});
  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _scrollController = ScrollController();

  void _scrollToTop() {
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  void _contactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.contactSupport),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.sendMessageOrContactAdmin),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.yourMessage,
                border: const OutlineInputBorder(),
              ),
              minLines: 2,
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)!.messageSentDummy)),
              );
            },
            child: Text(AppLocalizations.of(context)!.send),
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
        title: Text('Hulp & Vrae', style: textTheme.titleLarge),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          controller: _scrollController,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text('Gereelde Vrae', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.2)),
            ),
            ExpansionTile(
              title: Text(AppLocalizations.of(context)!.howToPlaceOrder, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(AppLocalizations.of(context)!.goToSpysCard, style: textTheme.bodyMedium),
                ),
              ],
            ),
            ExpansionTile(
              title: Text(AppLocalizations.of(context)!.howToLoadMyWallet, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(AppLocalizations.of(context)!.goToWallet, style: textTheme.bodyMedium),
                ),
              ],
            ),
            ExpansionTile(
              title: Text(AppLocalizations.of(context)!.whoToContactForHelp, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(AppLocalizations.of(context)!.useSupportScreenOrEmail, style: textTheme.bodyMedium),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton.icon(
                onPressed: _contactSupport,
                icon: const Icon(Icons.support_agent),
                label: Text(AppLocalizations.of(context)!.contactSupport),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: textTheme.titleMedium,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(AppLocalizations.of(context)!.addMoreQuestions, style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey)),
            // TODO: Backend/data integrasie vir live chat
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _scrollToTop,
        backgroundColor: AppConstants.primaryColor,
        tooltip: AppLocalizations.of(context)!.scrollToTop,
        child: const Icon(Icons.arrow_upward),
      ),
    );
  }
} 