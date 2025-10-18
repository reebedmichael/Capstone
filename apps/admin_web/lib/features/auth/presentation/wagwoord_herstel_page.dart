import 'package:capstone_admin/core/theme/app_colors.dart';
import 'package:capstone_admin/core/theme/app_typography.dart';
import 'package:capstone_admin/shared/constants/spacing.dart';
import 'package:capstone_admin/shared/widgets/spys_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/auth_form_providers.dart';
import '../../../shared/providers/auth_providers.dart';
import '../../../shared/widgets/password_field.dart';

class WagwoordHerstelPage extends ConsumerStatefulWidget {
  const WagwoordHerstelPage({super.key});

  @override
  ConsumerState<WagwoordHerstelPage> createState() =>
      _WagwoordHerstelPageState();
}

class _WagwoordHerstelPageState extends ConsumerState<WagwoordHerstelPage> {
  bool _isPasswordVerified = false;
  bool _isCheckingSession = true;
  String _email = '';

  @override
  void initState() {
    super.initState();
    // Defer the session check until after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPasswordResetSession();
    });
  }

  Future<void> _checkPasswordResetSession() async {
    if (!mounted) return;

    try {
      final supabase = Supabase.instance.client;

      // Check if user is already authenticated (came from OTP verification)
      if (supabase.auth.currentUser != null) {
        print('DEBUG: User already authenticated from OTP verification');
        if (mounted) {
          setState(() {
            _isPasswordVerified = true;
            _isCheckingSession = false;
            _email = supabase.auth.currentUser!.email ?? '';
          });
        }
        return;
      }

      // If no authenticated user, redirect to login
      print('DEBUG: No authenticated user found, redirecting to login');
      if (mounted) {
        setState(() {
          _isCheckingSession = false;
        });
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          context.go('/teken_in');
        }
      }
    } catch (e) {
      print('Error checking password reset session: $e');
      // Redirect to login on error
      if (mounted) {
        setState(() {
          _isCheckingSession = false;
        });
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          context.go('/teken_in');
        }
      }
    }
  }

  Future<void> _handlePasswordUpdate(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final password = ref.read(passwordProvider);
    final confirmPassword = ref.read(confirmPasswordProvider);

    // Validate passwords match
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wagwoorde stem nie ooreen nie'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate password strength
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wagwoord moet ten minste 8 karakters wees'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Clear any previous errors
      ref.read(authLoadingProvider.notifier).state = true;

      // Update password using auth service
      final authService = ref.read(authServiceProvider);
      final response = await authService.updatePassword(password: password);

      if (response.user != null) {
        // Show success message
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Wagwoord suksesvol opgedateer! Jy sal nou geredigeer word na die aanmeld bladsy.',
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          // Wait a moment then redirect to login
          await Future.delayed(const Duration(seconds: 2));
          if (context.mounted) {
            context.go('/teken_in');
          }
        }
      }
    } catch (e) {
      // Show error message
      String errorMessage = 'Wagwoord opdatering het gefaal';
      if (e.toString().contains('Password should be at least')) {
        errorMessage = 'Wagwoord moet ten minste 8 karakters wees';
      } else if (e.toString().contains('New password should be different')) {
        errorMessage = 'Nuwe wagwoord moet verskil van die huidige een';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  // Helper that returns the full-screen gradient container wrapping the given child
  Widget _fullBackgroundScaffold({required Widget child}) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.05),
              AppColors.secondary.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);
    final isFormValid = ref.watch(passwordFormValidProvider);

    if (_isCheckingSession) {
      // Show loading while checking the session with full background
      return _fullBackgroundScaffold(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Verifieer wagwoord herstel sessie...',
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isPasswordVerified) {
      // Show message while verifying the session with full background
      return _fullBackgroundScaffold(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Verifieer wagwoord herstel sessie...',
                style: AppTypography.bodyMedium.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _fullBackgroundScaffold(
      child: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 8,
              shadowColor: AppColors.shadow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacing.screenHPad * 1.5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Spacing.vGap16,

                    // avatar / icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset,
                        size: 32,
                        color: AppColors.secondary,
                      ),
                    ),

                    Spacing.vGap16,

                    // Title
                    Text(
                      'Stel Nuwe Wagwoord',
                      style: AppTypography.headlineMedium.copyWith(
                        color: Theme.of(
                          context,
                        ).textTheme.headlineMedium?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    Spacing.vGap8,

                    Text(
                      'Kies \'n sterk wagwoord vir $_email',
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    Spacing.vGap24,

                    // Password fields
                    const PasswordField(),
                    Spacing.vGap16,
                    const PasswordField(isConfirmPassword: true),

                    Spacing.vGap24,

                    // Security tips
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.security,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Sekuriteit Wenke',
                                style: AppTypography.labelLarge.copyWith(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Gebruik ten minste 8 karakters\n'
                            '• Insluit groot letters, klein letters en syfers\n'
                            '• Maak gebruik van spesiaal karakters indien moontlik\n'
                            '• Vermy algemene woorde of persoonlike inligting',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Spacing.vGap24,

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isLoading
                                ? null
                                : () => context.go('/teken_in'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'Kanselleer',
                              style: AppTypography.labelLarge.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SpysPrimaryButton(
                            text: "Opdateer Wagwoord",
                            isLoading: isLoading,
                            onPressed: isFormValid
                                ? () => _handlePasswordUpdate(context, ref)
                                : null,
                          ),
                        ),
                      ],
                    ),

                    Spacing.vGap24,

                    // Help text
                    Text(
                      "Jy sal na die aanmeld bladsy geredigeer word na suksesvolle opdatering",
                      style: AppTypography.bodySmall.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
