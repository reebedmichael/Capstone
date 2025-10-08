import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/constants/strings_af.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/widgets/spys_primary_button.dart';
import '../../../../core/theme/app_typography.dart';

import '../../../../shared/providers/auth_form_providers.dart';
import '../../../../shared/providers/auth_providers.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../shared/widgets/email_field.dart';
import '../../../../shared/widgets/password_field.dart';

class LoginPage extends ConsumerWidget 
{
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) 
  {
    final isLoading = ref.watch(authLoadingProvider);
    final isFormValid = ref.watch(loginFormValidProvider);
    final authError = ref.watch(authErrorProvider);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.screenHPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Spacing.vGap40,
                
                // Header with Logo and Brand
                const AuthHeader(
                  title: StringsAf.loginTitle,
                  subtitle: StringsAf.appTitle,
                ),
                
                // Error message
                if (authError != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Theme.of(context).colorScheme.error, width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_rounded,
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            authError,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Quick Login Button (Demo)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: SpysPrimaryButton(
                    text: 'Vinnige Teken In',
                    isLoading: isLoading,
                    onPressed: () async {
                      // Auto-fill demo credentials
                      ref.read(emailProvider.notifier).state = 'swanepoel.jacques.za@gmail.com';
                      ref.read(passwordProvider.notifier).state = 'Game4sloop';
                      
                      ref.read(authErrorProvider.notifier).state = null;
                      ref.read(authLoadingProvider.notifier).state = true;

                      try {
                        final authService = ref.read(authServiceProvider);
                        await authService.signInWithEmail(
                          email: 'swanepoel.jacques.za@gmail.com', 
                          password: 'Game4sloop'
                        );

                        // User data is now managed by Supabase authentication
                        // No need for manual SharedPreferences storage

                        if (context.mounted) { context.go('/home'); }
                      } catch (e) {
                        String errorMessage = 'Demo teken in het gefaal';
                        if (e.toString().contains('Invalid login credentials')) {
                          errorMessage = 'Demo rekening bestaan nie - registreer eers';
                        }
                        ref.read(authErrorProvider.notifier).state = errorMessage;
                      } finally {
                        ref.read(authLoadingProvider.notifier).state = false;
                      }
                    },
                  ),
                ),
                
                
                Spacing.vGap24,
                
                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        StringsAf.orDivider,
                        style: AppTypography.caption.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                
                Spacing.vGap24,
                
                // Login Form Card
                Card(
                  elevation: 8,
                  shadowColor: Theme.of(context).colorScheme.shadow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Form Title
                        Text(
                          'Teken In Met Jou Rekening',
                          style: AppTypography.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        Spacing.vGap8,
                        Text(
                          'Voer jou besonderhede in om toegang te kry',
                          style: AppTypography.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        Spacing.vGap24,
                        
                        // Email field
                        const EmailField(),
                        Spacing.vGap16,
                        
                        // Password field
                        const PasswordField(),
                        Spacing.vGap8,
                        
                        // Forgot password link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text(StringsAf.forgotPasswordDialogTitle),
                                  content: Text(StringsAf.forgotPasswordDialogMessage),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(),
                                      child: Text(StringsAf.dialogOk),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Text(
                              StringsAf.forgotPassword,
                              style: AppTypography.linkText,
                            ),
                          ),
                        ),
                        Spacing.vGap24,
                        
                        // Sign in button
                        SpysPrimaryButton(
                          text: StringsAf.signInCta,
                          isLoading: isLoading,
                          onPressed: isFormValid ? () async {
                            final email = ref.read(emailProvider);
                            final password = ref.read(passwordProvider);

                            ref.read(authErrorProvider.notifier).state = null;
                            ref.read(authLoadingProvider.notifier).state = true;

                            try {
                              final authService = ref.read(authServiceProvider);
                              await authService.signInWithEmail(email: email, password: password);

                              // User data is now managed by Supabase authentication
                              // No need for manual SharedPreferences storage

                              if (context.mounted) { context.go('/home'); }
                            } catch (e) {
                              String errorMessage = 'Teken in het gefaal';
                              if (e.toString().contains('Invalid login credentials')) {
                                errorMessage = 'Verkeerde e-pos of wagwoord';
                              } else if (e.toString().contains('Email not confirmed')) {
                                errorMessage = 'E-pos nog nie bevestig nie';
                              }
                              ref.read(authErrorProvider.notifier).state = errorMessage;
                            } finally {
                              ref.read(authLoadingProvider.notifier).state = false;
                            }
                          } : null,
                        ),
                      ],
                    ),
                  ),
                ),
                
                Spacing.vGap24,
                
                // Register section
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              StringsAf.orDivider,
                              style: AppTypography.caption.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      
                      Spacing.vGap16,
                      
                      // Register text and button
                      Text(
                        StringsAf.noAccountQ,
                        style: AppTypography.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      Spacing.vGap12,
                      
                      OutlinedButton(
                        onPressed: () => context.go('/auth/register'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Theme.of(context).colorScheme.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: Text(
                          'Registreer Hier',
                          style: AppTypography.labelLarge.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Footer
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        '© 2025 Spys - Universiteit Voedsel App',
                        style: AppTypography.caption,
                        textAlign: TextAlign.center,
                      ),
                      Spacing.vGap4,
                      Text(
                        'Veilig • Maklik • Vinnig',
                        style: AppTypography.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
