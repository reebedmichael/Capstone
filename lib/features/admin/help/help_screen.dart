import 'package:flutter/material.dart';
import 'package:spys/l10n/app_localizations.dart';

class AdminHelpScreen extends StatefulWidget {
  const AdminHelpScreen({super.key});
  @override
  State<AdminHelpScreen> createState() => _AdminHelpScreenState();
}

class _AdminHelpScreenState extends State<AdminHelpScreen> {
  final _scrollController = ScrollController();

  void _scrollToTop() {
    _scrollController.animateTo(0, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
  }

  void _contactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.contactSupportTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context)!.contactSupportMessage),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.yourMessageLabel,
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
    final loc = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        controller: _scrollController,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text('Gereelde Vrae', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, letterSpacing: 0.2)),
          ),
          ExpansionTile(
            title: Text(loc?.howSeeActiveOrders ?? 'How to see active orders?', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(loc?.howSeeActiveOrdersDescription ?? 'Description for seeing active orders.', style: textTheme.bodyMedium),
              ),
            ],
          ),
          ExpansionTile(
            title: Text(loc?.howAddNewProducts ?? 'How to add new products?', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(loc?.howAddNewProductsDescription ?? 'Description for adding new products.', style: textTheme.bodyMedium),
              ),
            ],
          ),
          ExpansionTile(
            title: Text(loc?.howContactTechnicalSupport ?? 'How to contact technical support?', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(loc?.howContactTechnicalSupportDescription ?? 'Description for contacting technical support.', style: textTheme.bodyMedium),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton.icon(
              onPressed: _contactSupport,
              icon: const Icon(Icons.support_agent),
              label: Text(loc?.contactSupport ?? 'Contact Support'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: textTheme.titleMedium,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(loc?.todoMoreQuestions ?? 'More questions (TODO)', style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic, color: Colors.grey)),
          // TODO: Backend/data integrasie vir live chat
        ],
      ),
    );
  }
} 