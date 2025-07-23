import 'package:flutter/material.dart';

class AdminTermsScreen extends StatelessWidget {
  const AdminTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms & Privacy',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 24),
            
            // Terms of Service Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terms of Service',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Acceptance of Terms\n'
                      'By using the Spys Admin platform, you agree to comply with and be bound by these Terms of Service.\n\n'
                      '2. User Responsibilities\n'
                      'Admin users are responsible for maintaining the confidentiality of their login credentials and for all activities under their account.\n\n'
                      '3. Data Management\n'
                      'Admin users must handle customer data responsibly and in compliance with applicable privacy laws.\n\n'
                      '4. Service Availability\n'
                      'We strive to maintain 99.9% uptime but cannot guarantee uninterrupted service.',
                      style: TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Privacy Policy Section
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy Policy',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '1. Data Collection\n'
                      'We collect information necessary to provide admin services, including login credentials and usage analytics.\n\n'
                      '2. Data Usage\n'
                      'Collected data is used solely for service provision, security, and improvement of the platform.\n\n'
                      '3. Data Protection\n'
                      'We implement industry-standard security measures to protect admin and customer data.\n\n'
                      '4. Data Sharing\n'
                      'We do not share personal data with third parties except as required by law.',
                      style: TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Contact Information
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Contact Information',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'For questions about these terms or privacy policy:\n\n'
                      'Email: legal@spys.co.za\n'
                      'Phone: +27 11 123 4567\n'
                      'Address: 123 Business Street, Cape Town, South Africa',
                      style: TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Last Updated
            Center(
              child: Text(
                'Last Updated: June 2024',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 
