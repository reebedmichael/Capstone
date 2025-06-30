import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/utils/color_utils.dart';

class FeedbackReportsScreen extends StatelessWidget {
  const FeedbackReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback & Reports'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Feedback & Reports',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppConstants.paddingLarge),
            Expanded(
              child: Row(
                children: [
                  // Feedback Section
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.paddingLarge),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recent Feedback',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingMedium),
                            Expanded(
                              child: ListView.builder(
                                itemCount: 10,
                                itemBuilder: (context, index) {
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: AppConstants.paddingMedium),
                                    child: Padding(
                                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'User ${index + 1}',
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              const Spacer(),
                                              Row(
                                                children: List.generate(5, (starIndex) {
                                                  return Icon(
                                                    starIndex < 4 ? Icons.star : Icons.star_border,
                                                    color: AppConstants.accentColor,
                                                    size: 16,
                                                  );
                                                }),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: AppConstants.paddingSmall),
                                          Text('Great food quality and fast delivery!'),
                                          Text(
                                            '2 hours ago',
                                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                              color: setOpacity(Theme.of(context).colorScheme.onSurface, 0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppConstants.paddingLarge),
                  // Reports Section
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppConstants.paddingLarge),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Analytics',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppConstants.paddingMedium),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildAnalyticsCard('Average Rating', '4.8★', Icons.star),
                                  const SizedBox(height: AppConstants.paddingMedium),
                                  _buildAnalyticsCard('Total Reviews', '1,234', Icons.rate_review),
                                  const SizedBox(height: AppConstants.paddingMedium),
                                  _buildAnalyticsCard('Response Rate', '98%', Icons.reply),
                                  const SizedBox(height: AppConstants.paddingMedium),
                                  _buildAnalyticsCard('Satisfaction', '95%', Icons.sentiment_satisfied),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildAnalyticsCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingMedium),
        child: Row(
          children: [
            Icon(
              icon,
              color: AppConstants.primaryColor,
              size: 32,
            ),
            const SizedBox(width: AppConstants.paddingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.primaryColor,
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
} 