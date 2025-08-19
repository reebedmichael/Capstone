import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/constants/strings_af.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/widgets/spys_primary_button.dart';
import '../../../../core/theme/app_colors.dart';
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
              AppColors.primary.withValues(alpha: 0.05),
              AppColors.secondary.withValues(alpha: 0.05),
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Text(
                      authError,
                      style: const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
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
                      ref.read(emailProvider.notifier).state = 'student@spys.co.za';
                      ref.read(passwordProvider.notifier).state = 'student123';
                      
                      ref.read(authErrorProvider.notifier).state = null;
                      ref.read(authLoadingProvider.notifier).state = true;

                      try {
                        final authService = ref.read(authServiceProvider);
                        await authService.signInWithEmail(
                          email: 'student@spys.co.za', 
                          password: 'student123'
                        );
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
                          color: AppColors.onSurfaceVariant,
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
                  shadowColor: AppColors.shadow,
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
                                color: AppColors.onSurfaceVariant,
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
                          side: BorderSide(color: AppColors.primary),
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
                            color: AppColors.primary,
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
