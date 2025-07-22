import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants.dart';
import '../../../core/utils/color_utils.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ondersteuning & Navrae'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.support_agent,
                    size: 60,
                    color: Colors.white,
                  ),
                  const SizedBox(height: AppConstants.paddingMedium),
                  Text(
                    'Hoe kan ons jou help?',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  Text(
                    'Ons span is hier om jou te help met enige vrae of probleme.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: setOpacity(Colors.white, 0.9),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: AppConstants.paddingLarge),
            
            // Contact Information Cards
            _buildContactCard(
              context,
              title: 'Bel Ons',
              subtitle: 'Praat direk met ons span',
              icon: Icons.phone,
              color: AppConstants.successColor,
              contactInfo: '+27 12 345 6789',
              actionText: 'Bel Nou',
              onTap: () => _makePhoneCall(context, '+27123456789'),
            ),
            
            const SizedBox(height: AppConstants.paddingMedium),
            
            _buildContactCard(
              context,
              title: 'Stuur E-pos',
              subtitle: 'Stuur ons \'n gedetailleerde boodskap',
              icon: Icons.email,
              color: AppConstants.primaryColor,
              contactInfo: 'support@spys.co.za',
              actionText: 'Stuur E-pos',
              onTap: () => _sendEmail(context, 'support@spys.co.za'),
            ),
            
            const SizedBox(height: AppConstants.paddingMedium),
            
            _buildContactCard(
              context,
              title: 'WhatsApp',
              subtitle: 'Kry vinnige hulp via WhatsApp',
              icon: Icons.message,
              color: AppConstants.successColor,
              contactInfo: '+27 82 123 4567',
              actionText: 'Open WhatsApp',
              onTap: () => _openWhatsApp(context, '+27821234567'),
            ),
            
            const SizedBox(height: AppConstants.paddingLarge),
            
            // Operating Hours
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          color: AppConstants.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: AppConstants.paddingSmall),
                        Text(
                          'Ons Ure',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    _buildOperatingHour('Maandag - Vrydag', '08:00 - 17:00'),
                    _buildOperatingHour('Saterdag', '09:00 - 13:00'),
                    _buildOperatingHour('Sondag', 'Gesluit'),
                    const SizedBox(height: AppConstants.paddingMedium),
                    Container(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      decoration: BoxDecoration(
                        color: setOpacity(AppConstants.warningColor, 0.1),
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: AppConstants.warningColor,
                            size: 20,
                          ),
                          const SizedBox(width: AppConstants.paddingSmall),
                          Expanded(
                            child: Text(
                              'Noodgevalle kan 24/7 gekontak word via WhatsApp',
                              style: TextStyle(
                                color: AppConstants.warningColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppConstants.paddingLarge),
            
            // FAQ Section
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.help,
                          color: AppConstants.primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: AppConstants.paddingSmall),
                        Text(
                          'Algemene Vrae',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    Text(
                      'Wanneer om admin te kontak:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingSmall),
                    _buildBulletPoint('Probleme met jou rekening of profiel'),
                    _buildBulletPoint('Bestellings wat nie afgelaai is nie'),
                    _buildBulletPoint('Betalingsprobleme of terugbetalings'),
                    _buildBulletPoint('Klagtes oor kos kwaliteit'),
                    _buildBulletPoint('Tegniese probleme met die app'),
                    _buildBulletPoint('Allergie-verwante navrae'),
                    const SizedBox(height: AppConstants.paddingMedium),
                    Text(
                      'Ons streef daarna om alle navrae binne 24 uur te beantwoord.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: AppConstants.paddingLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String contactInfo,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: setOpacity(color, 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingSmall),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingSmall),
                    Text(
                      contactInfo,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.borderRadiusSmall),
                  ),
                ),
                child: Text(actionText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOperatingHour(String day, String hours) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            hours,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 8),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppConstants.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  void _makePhoneCall(BuildContext context, String phoneNumber) {
    // TODO: Implement actual phone call functionality
    // For demo purposes, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demo: Sou nou $phoneNumber gebel het'),
        action: SnackBarAction(
          label: 'Kopieer',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: phoneNumber));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nommer gekopieer')),
            );
          },
        ),
      ),
    );
  }

  void _sendEmail(BuildContext context, String email) {
    // TODO: Implement actual email functionality
    // For demo purposes, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demo: Sou nou e-pos na $email gestuur het'),
        action: SnackBarAction(
          label: 'Kopieer',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: email));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('E-pos gekopieer')),
            );
          },
        ),
      ),
    );
  }

  void _openWhatsApp(BuildContext context, String phoneNumber) {
    // TODO: Implement actual WhatsApp functionality
    // For demo purposes, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Demo: Sou nou WhatsApp na $phoneNumber oopgemaak het'),
        action: SnackBarAction(
          label: 'Kopieer',
          onPressed: () {
            Clipboard.setData(ClipboardData(text: phoneNumber));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Nommer gekopieer')),
            );
          },
        ),
      ),
    );
  }
} 