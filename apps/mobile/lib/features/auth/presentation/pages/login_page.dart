import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/constants/strings_af.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/widgets/spys_primary_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

import '../../../../shared/providers/auth_form_providers.dart';
import '../../../../shared/widgets/auth_header.dart';
import '../../../../shared/widgets/email_field.dart';
import '../../../../shared/widgets/password_field.dart';

class LoginPage extends ConsumerWidget 
{
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) 
  {
    final isLoading = ref.watch(loginLoadingProvider);
    final isFormValid = ref.watch(loginFormValidProvider);
    
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
                
                // Quick Login Button (Demo)
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  child: SpysPrimaryButton(
                    text: 'Vinnige Teken In',
                    isLoading: isLoading,
                    onPressed: () {
                      // Auto-fill demo credentials
                      ref.read(emailProvider.notifier).state = 'jan.smit@universiteit.ac.za';
                      ref.read(passwordProvider.notifier).state = 'password123';
                      
                      // Simulate login
                      ref.read(loginLoadingProvider.notifier).state = true;

                      Future.delayed(const Duration(seconds: 2), () 
                      {
                        ref.read(loginLoadingProvider.notifier).state = false;
                        debugPrint('Quick login with demo credentials');
                        if (!context.mounted) return;
                        context.go('/home');
                      });
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
                          onPressed: isFormValid ? () {
                            // Simulate login
                            ref.read(loginLoadingProvider.notifier).state = true;
                            
                            // Simulate API call delay
                            Future.delayed(const Duration(seconds: 2), () {
                              ref.read(loginLoadingProvider.notifier).state = false;
                              debugPrint('Login attempted with email: ${ref.read(emailProvider)}');
                            });
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
                        '© 2024 Spys - Universiteit Voedsel App',
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
