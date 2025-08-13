import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/constants/spacing.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

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
                Text('Hulp & Ondersteuning', style: AppTypography.headlineMedium),
                Spacing.vGap16,
                const Card(child: ListTile(title: Text('FAQ'), subtitle: Text('Vrae en antwoorde kom later'))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
