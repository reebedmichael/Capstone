import 'package:flutter/material.dart';
import 'package:spys/l10n/app_localizations.dart';

class AdminAboutScreen extends StatefulWidget {
  const AdminAboutScreen({super.key});

  @override
  State<AdminAboutScreen> createState() => _AdminAboutScreenState();
}

class _AdminAboutScreenState extends State<AdminAboutScreen> {
  void _rateApp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gradeer die App'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Hoe sal jy hierdie admin app gradeer?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => 
                IconButton(
                  icon: const Icon(Icons.star, color: Colors.amber, size: 32),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Dankie vir jou ${index + 1}-ster gradering!')),
                    );
                  },
                )
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kanselleer'),
          ),
        ],
      ),
    );
  }

  void _sendFeedback(BuildContext context) {
    final feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stuur Terugvoer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vertel ons hoe ons die admin app kan verbeter:'),
            const SizedBox(height: 16),
            TextField(
              controller: feedbackController,
              decoration: const InputDecoration(
                labelText: 'Jou terugvoer',
                border: OutlineInputBorder(),
                hintText: 'Tik jou voorstelle hier...',
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kanselleer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Terugvoer gestuur! Dankie vir jou bydrae.')),
              );
            },
            child: const Text('Stuur'),
          ),
        ],
      ),
    );
  }

  void _showSystemInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stelsel Inligting'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('App Weergawe: 1.0.0'),
              Text('Database Weergawe: 2.3.1'),
              Text('API Weergawe: 1.2.0'),
              Text('Flutter Weergawe: 3.19.0'),
              Text('Platform: Universal'),
              SizedBox(height: 16),
              Text('Laaste Opdatering: 15 Junie 2024'),
              Text('Volgende Onderhoud: 22 Junie 2024'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sluit'),
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
      padding: const EdgeInsets.all(32),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // App Info Card
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 24),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.1),
                      Theme.of(context).primaryColor.withOpacity(0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.fastfood,
                      size: 64,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Spys Admin',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Weergawe: 1.0.0',
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      loc?.aboutSpysAdminDescription ?? 
                      'Die Spys Admin platform help jou om jou voedselbesigheid maklik en doeltreffend te bestuur. '
                      'Van menubestuur tot bestellings en gebruikersinteraksie - alles wat jy nodig het op een plek.',
                      style: textTheme.bodyLarge?.copyWith(height: 1.5),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Features Card
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kenmerk Oorsig',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildFeatureItem(Icons.dashboard, 'Dashboard', 'Oorsig van alle aktiwiteite en statistieke'),
                    _buildFeatureItem(Icons.restaurant_menu, 'Menu Bestuur', 'Voeg by, wysig en verwyder menu items'),
                    _buildFeatureItem(Icons.shopping_cart, 'Bestelling Bestuur', 'Monitor en bestuur alle bestellings'),
                    _buildFeatureItem(Icons.people, 'Gebruiker Bestuur', 'Beheer gebruikerstoegang en profiele'),
                    _buildFeatureItem(Icons.inventory, 'Voorraad Bestuur', 'Hou tred met voorraadvlakke'),
                    _buildFeatureItem(Icons.analytics, 'Terugvoer Analise', 'Analiseer kliënt terugvoer en verbeter diens'),
                  ],
                ),
              ),
            ),

            // Team Card
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc?.aboutSpysAdminTeam ?? 'Spys Admin Span',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      loc?.aboutSpysAdminTeamMembers ?? 
                      'Ons toegewyde span van ontwikkelaars en designers werk hard om die beste admin ervaring vir jou te skep. '
                      'Met jare se ondervinding in voedsel tegnologie, verstaan ons die uitdagings van die industrie.',
                      style: textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),

            // Support Card
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ondersteuning & Kontak',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildContactItem(Icons.email, 'E-pos', 'support@spys.co.za'),
                    _buildContactItem(Icons.phone, 'Telefoon', '+27 11 123 4567'),
                    _buildContactItem(Icons.schedule, 'Ondersteuning Ure', 'Ma-Vr: 08:00-17:00'),
                    _buildContactItem(Icons.location_on, 'Adres', '123 Business Street, Cape Town, 8001'),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rateApp(context),
                    icon: const Icon(Icons.star),
                    label: Text(loc?.rateThisApp ?? 'Gradeer die App'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _sendFeedback(context),
                    icon: const Icon(Icons.feedback),
                    label: Text(loc?.sendFeedback ?? 'Stuur Terugvoer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE64A19),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // System Info Button
            Center(
              child: TextButton.icon(
                onPressed: _showSystemInfo,
                icon: const Icon(Icons.info_outline),
                label: const Text('Stelsel Inligting'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'Laas Opdateer: Junie 2024',
                    style: textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '© 2024 Spys. Alle regte voorbehou.',
                    style: textTheme.bodySmall?.copyWith(
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
} 
