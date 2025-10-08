import 'package:flutter/material.dart';
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
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
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
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.shadow.withOpacity(0.3), blurRadius: 12)],
                    ),
                    child: Center(
                      child: Text('S', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 40, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  Spacing.vGap24,
                  Text(StringsAf.appTitle, style: AppTypography.displayMedium.copyWith(color: Theme.of(context).colorScheme.primary)),
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
