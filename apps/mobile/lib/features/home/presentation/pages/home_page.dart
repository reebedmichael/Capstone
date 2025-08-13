import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../app/presentation/widgets/app_bottom_nav.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.05),
              AppColors.secondary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.screenHPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Spacing.vGap16,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Welkom!', style: AppTypography.headlineMedium),
                        Spacing.vGap4,
                        Text('Wat gaan jy vandag eet?', style: AppTypography.bodySmall),
                      ],
                    ),
                    IconButton(
                      onPressed: () => context.go('/notifications'),
                      icon: const Icon(Icons.notifications_outlined),
                    ),
                  ],
                ),
                Spacing.vGap16,
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Soek na kos, bestanddele...',
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                Spacing.vGap24,
                Text('Aanbevole items', style: AppTypography.titleLarge),
                Spacing.vGap12,
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        Spacing.hGap16,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dag se spesiaal', style: AppTypography.titleMedium),
                              Spacing.vGap4,
                              Text('Heerlike vars opsies', style: AppTypography.bodySmall),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go('/food-detail'),
                          child: const Text('Besigtig'),
                        ),
                      ],
                    ),
                  ),
                ),
                Spacing.vGap32,
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }
}
