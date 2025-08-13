import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/strings_af.dart';
import 'package:go_router/go_router.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.secondary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.screenHPad),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 12)],
                    ),
                    child: const Center(
                      child: Text('S', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Spacing.vGap24,
                  Text(StringsAf.appTitle, style: AppTypography.displayMedium.copyWith(color: AppColors.primary)),
                  Spacing.vGap8,
                  Text(StringsAf.appSubtitle, style: AppTypography.bodyMedium),
                  Spacing.vGap32,
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.go('/auth/login'),
                      child: const Text('Teken In'),
                    ),
                  ),
                  Spacing.vGap12,
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.go('/auth/register'),
                      child: const Text('Registreer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
