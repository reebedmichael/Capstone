import 'package:capstone_admin/core/theme/app_colors.dart';
import 'package:capstone_admin/core/theme/app_typography.dart';
import 'package:capstone_admin/shared/constants/spacing.dart';
import 'package:capstone_admin/shared/constants/strings_af_admin.dart';
import 'package:capstone_admin/shared/widgets/auth_header.dart';
import 'package:capstone_admin/shared/widgets/spys_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/auth_form_providers.dart';
import '../../../shared/providers/auth_providers.dart';
import '../../../shared/widgets/email_field.dart';
import '../../../shared/widgets/password_field.dart';

class TekenInPage extends ConsumerWidget {
  const TekenInPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authLoadingProvider);
    final isFormValid = ref.watch(loginFormValidProvider);
    final authError = ref.watch(authErrorProvider);

    return Scaffold(
      body: Center(
        child: Container(
          width: 600.0,
          height: double.infinity,
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
                    title: StringsAfAdmin.loginTitle,
                    subtitle: StringsAfAdmin.appTitle,
                  ),

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

                          // Error message
                          if (authError != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.error),
                              ),
                              child: Text(
                                authError,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.error,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          // Forgot password link
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(
                                      StringsAfAdmin.forgotPasswordDialogTitle,
                                    ),
                                    content: Text(
                                      StringsAfAdmin
                                          .forgotPasswordDialogMessage,
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: Text(StringsAfAdmin.dialogOk),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              child: Text(
                                StringsAfAdmin.forgotPassword,
                                style: AppTypography.linkText,
                              ),
                            ),
                          ),
                          Spacing.vGap24,

                          // Sign in button
                          SpysPrimaryButton(
                            text: StringsAfAdmin.signInCta,
                            isLoading: isLoading,
                            onPressed: isFormValid
                                ? () async {
                                    final email = ref.read(emailProvider);
                                    final password = ref.read(passwordProvider);

                                    // Clear any previous errors
                                    ref.read(authErrorProvider.notifier).state = null;
                                    ref.read(authLoadingProvider.notifier).state = true;

                                    try {
                                      final authService = ref.read(
                                        authServiceProvider,
                                      );
                                      await authService.signInWithEmail(
                                        email: email,
                                        password: password,
                                      );

                                      // User data is now managed by Supabase authentication
                                      // No need for manual SharedPreferences storage

                                      if (context.mounted) 
                                      {
                                        context.go("/dashboard");
                                      }
                                    } catch (e) {
                                      String errorMessage =
                                          'Teken in het gefaal';
                                      if (e.toString().contains(
                                        'Invalid login credentials',
                                      )) {
                                        errorMessage =
                                            'Verkeerde e-pos of wagwoord';
                                      } else if (e.toString().contains(
                                        'Email not confirmed',
                                      )) {
                                        errorMessage =
                                            'E-pos nog nie bevestig nie';
                                      }

                                      ref
                                              .read(authErrorProvider.notifier)
                                              .state =
                                          errorMessage;
                                    } finally {
                                      ref
                                              .read(
                                                authLoadingProvider.notifier,
                                              )
                                              .state =
                                          false;
                                    }
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Register section
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Quick Login Button (Demo)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          child: SpysPrimaryButton(
                            text: 'Vinnige Teken In (Demo)',
                            isLoading: isLoading,
                            onPressed: () async {
                              // Auto-fill demo credentials
                              ref.read(emailProvider.notifier).state =
                                  'prvanstaden.phillip@gmail.com';
                              ref.read(passwordProvider.notifier).state =
                                  '12345Qwerty';

                              // Clear any previous errors
                              ref.read(authErrorProvider.notifier).state = null;
                              ref.read(authLoadingProvider.notifier).state =
                                  true;

                              try {
                                final authService = ref.read(
                                  authServiceProvider,
                                );

                                await authService.signInWithEmail(
                                  email: 'prvanstaden.phillip@gmail.com',
                                  password: '12345Qwerty',
                                );

                                // User data is now managed by Supabase authentication
                                // No need for manual SharedPreferences storage

                                if (context.mounted) {
                                  context.go('/dashboard');
                                }
                              } catch (e) {
                                String errorMessage =
                                    'Demo teken in het gefaal';
                                if (e.toString().contains(
                                  'Invalid login credentials',
                                )) {
                                  errorMessage =
                                      'Demo rekening bestaan nie - registreer eers';
                                }

                                ref.read(authErrorProvider.notifier).state =
                                    errorMessage;
                              } finally {
                                ref.read(authLoadingProvider.notifier).state =
                                    false;
                              }
                            },
                          ),
                        ),

                        // Divider
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                StringsAfAdmin.orDivider,
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
                          StringsAfAdmin.noAccountQ,
                          style: AppTypography.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        Spacing.vGap12,

                        OutlinedButton(
                          onPressed: () => context.go('/registreer_admin'),
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
                            'Registreer As Admin',
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
      ),
    );
  }
}
