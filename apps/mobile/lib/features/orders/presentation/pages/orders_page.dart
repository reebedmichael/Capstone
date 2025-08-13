import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../app/presentation/widgets/app_bottom_nav.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});

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
                Text('My Bestellings', style: AppTypography.headlineMedium),
                Spacing.vGap16,
                Card(
                  child: ListTile(
                    title: const Text('Bestelling #12345'),
                    subtitle: const Text('Wag vir afhaal'),
                    trailing: TextButton(
                      onPressed: () => context.go('/qr'),
                      child: const Text('Wys QR'),
                    ),
                  ),
                ),
                Spacing.vGap12,
                Card(
                  child: ListTile(
                    title: const Text('Bestelling #12344'),
                    subtitle: const Text('Afgehaal'),
                    trailing: TextButton(
                      onPressed: () => context.go('/feedback'),
                      child: const Text('Terugvoer'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}
