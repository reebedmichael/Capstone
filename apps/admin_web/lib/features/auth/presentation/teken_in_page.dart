import 'package:capstone_admin/core/theme/app_colors.dart';
import 'package:capstone_admin/core/theme/app_typography.dart';
import 'package:capstone_admin/shared/widgets/spys_primary_button.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/providers/auth_form_providers.dart';
import '../../../shared/providers/auth_providers.dart';
import '../../../shared/widgets/email_field.dart';
import '../../../shared/widgets/password_field.dart';
import '../../../shared/widgets/email_input_dialog.dart';

class TekenInPage extends HookConsumerWidget {
  const TekenInPage({super.key});

  Future<void> _checkAdminTypeAndRedirect(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final authService = ref.read(authServiceProvider);
      final profile = await authService.getUserProfile();

      if (profile == null) {
        print('DEBUG: No profile found, redirecting to dashboard');
        context.go('/dashboard');
        return;
      }

      final admin = profile['admin_tipes'] as Map<String, dynamic>?;
      final adminTypeName =
          (admin?['admin_tipe_naam'] as String?)?.trim() ?? '';

      print('DEBUG: Admin type name: "$adminTypeName"');

      // Check if admin type is restricted
      final restrictedTypes = {'Pending', 'Tertiary', 'None'};
      final isRestricted = restrictedTypes.contains(adminTypeName);

      print('DEBUG: Is restricted: $isRestricted');

      if (isRestricted) {
        print('DEBUG: Redirecting to waiting page');
        context.go('/wag_goedkeuring');
      } else {
        print('DEBUG: Redirecting to dashboard');
        context.go('/dashboard');
      }
    } catch (e) {
      print('DEBUG: Error checking admin type: $e');
      // On error, allow access to dashboard
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(authLoadingProvider);
    final isFormValid = ref.watch(loginFormValidProvider);
    final authError = ref.watch(authErrorProvider);
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 600),
    );

    // Check if user just registered
    final uri = GoRouterState.of(context).uri;
    final justRegistered = uri.queryParameters['registered'] == 'true';

    // helper to fade out the form, run an async action, then reset animation
    Future<void> _fadeAndRun(Future<void> Function() action) async {
      try {
        await animationController.forward();
        await action();
      } finally {
        animationController.reset();
      }
    }

    // Get screen width to determine layout
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1024; // Breakpoint for desktop view

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Row(
          children: [
            // Left Page - Image Panel (Only show on desktop)
            if (isDesktop)
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFB45309),
                        const Color(0xFFC2410C),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Background Image
                      Positioned.fill(
                        child: Image.asset(
                          '../web/assets/Spys.jpg', // your local image path
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFB45309),
                              child: const Center(
                                child: Icon(
                                  Icons.restaurant,
                                  size: 100,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Gradient overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.2),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Content overlay
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.all(32),
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.utensilsCrossed,
                                  size: 48,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Bestuur met uitnemendheid',
                                  style: AppTypography.headlineSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Stroomlyn Spys met kragtige administrasie-instrumente',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Book spine shadow
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withValues(alpha: 0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Right Page - Form Panel (Animated)
            Expanded(
              flex: isDesktop ? 1 : 2,
              child: Stack(
                children: [
                  // Form content with responsive padding & fade animation
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: animationController,
                      builder: (context, child) {
                        // opacity goes from 1 -> 0 when animationController.forward() is called
                        final opacity = 1.0 - animationController.value;
                        return Opacity(opacity: opacity, child: child);
                      },
                      // pass the fade helper into the form so internal buttons can use it
                      child: _buildFormContent(
                        context,
                        ref,
                        isLoading,
                        isFormValid,
                        authError,
                        isDesktop,
                        _fadeAndRun,
                        justRegistered,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add onFadeAndRun parameter so the form can trigger the fade animation
  Widget _buildFormContent(
    BuildContext context,
    WidgetRef ref,
    bool isLoading,
    bool isFormValid,
    String? authError,
    bool isDesktop,
    Future<void> Function(Future<void> Function() action) onFadeAndRun,
    bool justRegistered,
  ) {
    return SingleChildScrollView(
      child: Padding(
        // Adjust padding based on screen size
        padding: EdgeInsets.all(isDesktop ? 48 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            // Show mobile-specific header when not desktop
            if (!isDesktop) ...[
              Center(
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.utensilsCrossed,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Spys Admin',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            // Header (desktop version)
            if (isDesktop)
              Row(
                children: [
                  Icon(
                    LucideIcons.utensilsCrossed,
                    size: 40,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Spys Admin',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  ),
                ],
              ),

            // Rest of form content with adjusted spacing
            const SizedBox(height: 8),
            Text(
              'Welkom Terug',
              style: AppTypography.headlineSmall,
              textAlign: isDesktop ? TextAlign.left : TextAlign.center,
            ),

            const SizedBox(height: 8),
            Text(
              'Teken in om voort te gaan.',
              style: AppTypography.bodyMedium.copyWith(
                color: const Color(0xFF6B7280), // gray-500
              ),
            ),
            const SizedBox(height: 48),

            // Registration success message
            if (justRegistered)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Registrasie suksesvol! Bevestig jou e-pos en teken in.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Form
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Email field
                const EmailField(),
                const SizedBox(height: 24),

                const PasswordField(),
                const SizedBox(height: 16),

                // Remember me and forgot password
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(),
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const EmailInputDialog(),
                        );
                      },
                      child: Text(
                        'Wagwoord vergeet?',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

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

                // Sign in button
                SizedBox(
                  width: double.infinity,
                  height: isDesktop ? 48 : 56, // Larger touch target on mobile
                  child: SpysPrimaryButton(
                    text: 'Teken In',
                    isLoading: isLoading,
                    onPressed: isFormValid
                        ? () async {
                            final email = ref.read(emailProvider);
                            final password = ref.read(passwordProvider);

                            // Clear any previous errors
                            ref.read(authErrorProvider.notifier).state = null;
                            ref.read(authLoadingProvider.notifier).state = true;

                            try {
                              final authService = ref.read(authServiceProvider);
                              await authService.signInWithEmail(
                                email: email,
                                password: password,
                              );

                              if (context.mounted) {
                                // fade then check / redirect
                                await onFadeAndRun(() async {
                                  await _checkAdminTypeAndRedirect(
                                    context,
                                    ref,
                                  );
                                });
                              }
                            } catch (e) {
                              String errorMessage = 'Teken in het gefaal';
                              if (e.toString().contains(
                                'Invalid login credentials',
                              )) {
                                errorMessage = 'Verkeerde e-pos of wagwoord';
                              } else if (e.toString().contains(
                                'Email not confirmed',
                              )) {
                                errorMessage = 'E-pos nog nie bevestig nie';
                              }

                              ref.read(authErrorProvider.notifier).state =
                                  errorMessage;
                            } finally {
                              ref.read(authLoadingProvider.notifier).state =
                                  false;
                            }
                          }
                        : null,
                  ),
                ),
                const SizedBox(height: 32),

                // Quick Login Buttons
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: SpysPrimaryButton(
                    text: 'Vinnige Teken In (Phillip)',
                    isLoading: isLoading,
                    onPressed: () async {
                      ref.read(emailProvider.notifier).state =
                          'prvanstaden.phillip@gmail.com';
                      ref.read(passwordProvider.notifier).state = 'Qwerty12345';

                      ref.read(authErrorProvider.notifier).state = null;
                      ref.read(authLoadingProvider.notifier).state = true;

                      try {
                        final authService = ref.read(authServiceProvider);
                        await authService.signInWithEmail(
                          email: 'prvanstaden.phillip@gmail.com',
                          password: 'Qwerty12345',
                        );

                        if (context.mounted) {
                          await onFadeAndRun(() async {
                            await _checkAdminTypeAndRedirect(context, ref);
                          });
                        }
                      } catch (e) {
                        String errorMessage = 'Demo teken in het gefaal';
                        if (e.toString().contains(
                          'Invalid login credentials',
                        )) {
                          errorMessage =
                              'Demo rekening bestaan nie - registreer eers';
                        }
                        ref.read(authErrorProvider.notifier).state =
                            errorMessage;
                      } finally {
                        ref.read(authLoadingProvider.notifier).state = false;
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: SpysPrimaryButton(
                    text: 'Vinnige Teken In (Bob)',
                    isLoading: isLoading,
                    onPressed: () async {
                      ref.read(emailProvider.notifier).state =
                          'swanepoel.jacques.za@gmail.com';
                      ref.read(passwordProvider.notifier).state = 'Game4sloop';

                      ref.read(authErrorProvider.notifier).state = null;
                      ref.read(authLoadingProvider.notifier).state = true;

                      try {
                        final authService = ref.read(authServiceProvider);
                        await authService.signInWithEmail(
                          email: 'swanepoel.jacques.za@gmail.com',
                          password: 'Game4sloop',
                        );

                        if (context.mounted) {
                          await onFadeAndRun(() async {
                            await _checkAdminTypeAndRedirect(context, ref);
                          });
                        }
                      } catch (e) {
                        String errorMessage = 'Jacques teken in het gefaal';
                        if (e.toString().contains(
                          'Invalid login credentials',
                        )) {
                          errorMessage =
                              'Jacques rekening bestaan nie - registreer eers';
                        }
                        ref.read(authErrorProvider.notifier).state =
                            errorMessage;
                      } finally {
                        ref.read(authLoadingProvider.notifier).state = false;
                      }
                    },
                  ),
                ),
                const SizedBox(height: 32),

                // Divider
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OF',
                        style: AppTypography.caption.copyWith(
                          color: const Color(0xFF9CA3AF), // gray-400
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 32),

                // Register section
                Center(
                  child: Column(
                    children: [
                      Text(
                        "Het nog nie 'n rekening nie?",
                        style: AppTypography.bodyMedium.copyWith(
                          color: const Color(0xFF6B7280), // gray-500
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () async {
                          await onFadeAndRun(() async {
                            context.go('/registreer_admin');
                          });
                        },
                        child: Text(
                          'Registreer hier',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
