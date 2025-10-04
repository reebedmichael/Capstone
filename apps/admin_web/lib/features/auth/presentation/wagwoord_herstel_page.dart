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
      // Get query parameters from both the current URL and base URL
      // Hash-based routing puts query params in the base URL, not the hash fragment
      final uri = GoRouterState.of(context).uri;
      final baseUri = Uri.base;

      final queryParams = uri.queryParameters;
      final baseQueryParams = baseUri.queryParameters;

      // Check both locations for the parameters
      final accessToken =
          queryParams['access_token'] ?? baseQueryParams['access_token'];
      final refreshToken =
          queryParams['refresh_token'] ?? baseQueryParams['refresh_token'];
      final type = queryParams['type'] ?? baseQueryParams['type'];
      final code = queryParams['code'] ?? baseQueryParams['code'];

      print('DEBUG: Password reset session check');
      print('DEBUG: Current URI: $uri');
      print('DEBUG: Base URI: $baseUri');
      print('DEBUG: Query params: $queryParams');
      print('DEBUG: Base query params: $baseQueryParams');
      print('DEBUG: Code: $code');
      print('DEBUG: Access token: $accessToken');
      print('DEBUG: Type: $type');

      // Additional debugging - check if we can get the full URL
      print('DEBUG: Full base URI string: ${baseUri.toString()}');
      print('DEBUG: Hash fragment: ${baseUri.fragment}');

      final supabase = Supabase.instance.client;

      // Handle PKCE/code-based flow (current Supabase default)
      if (code != null) {
        print('DEBUG: Attempting to handle code: $code');

        // Try verifyOTP first (most common for password reset)
        try {
          print('DEBUG: Trying verifyOTP with recovery type');
          final response = await supabase.auth.verifyOTP(
            type: OtpType.recovery,
            token: code,
            email: '', // Email will be determined by Supabase from the token
          );

          print('DEBUG: verifyOTP successful, user: ${response.user?.email}');
          if (mounted) {
            setState(() {
              _isPasswordVerified = true;
              _isCheckingSession = false;
              _email = response.user?.email ?? '';
            });
          }
          return;
        } catch (e) {
          print('DEBUG: verifyOTP failed: $e');

          // Try alternative - maybe it's a sign-in OTP
          try {
            print('DEBUG: Trying verifyOTP with signin type');
            final response = await supabase.auth.verifyOTP(
              type: OtpType.email,
              token: code,
              email: '',
            );

            print(
              'DEBUG: verifyOTP signin successful, user: ${response.user?.email}',
            );
            if (mounted) {
              setState(() {
                _isPasswordVerified = true;
                _isCheckingSession = false;
                _email = response.user?.email ?? '';
              });
            }
            return;
          } catch (e1) {
            print('DEBUG: verifyOTP signin failed: $e1');
          }

          // Try recoverSession as fallback
          try {
            print('DEBUG: Trying recoverSession');
            final response = await supabase.auth.recoverSession(code);
            print(
              'DEBUG: recoverSession successful, user: ${response.user?.email}',
            );

            if (mounted) {
              setState(() {
                _isPasswordVerified = true;
                _isCheckingSession = false;
                _email = response.user?.email ?? '';
              });
            }
            return;
          } catch (e2) {
            print('DEBUG: recoverSession failed: $e2');

            // Try direct session exchange as last resort
            try {
              print('DEBUG: Trying exchangeCodeForSession');
              final response = await supabase.auth.exchangeCodeForSession(code);
              print(
                'DEBUG: exchangeCodeForSession successful, user: ${response.session.user.email}',
              );

              if (mounted) {
                setState(() {
                  _isPasswordVerified = true;
                  _isCheckingSession = false;
                  _email = response.session.user.email ?? '';
                });
              }
              return;
            } catch (e3) {
              print('DEBUG: exchangeCodeForSession failed: $e3');
              print(
                'DEBUG: All authentication methods failed, will redirect to login',
              );
            }
          }
        }
      }

      // Handle legacy token-based flow (fallback)
      if (accessToken != null && refreshToken != null && type == 'recovery') {
        try {
          final response = await supabase.auth.setSession(accessToken);

          if (response.user != null && mounted) {
            setState(() {
              _isPasswordVerified = true;
              _isCheckingSession = false;
              _email = response.user!.email ?? '';
            });
            return;
          }
        } catch (e) {
          print('Error setting session from access token: $e');
        }
      }

      // If we reach here, it's not a valid password reset session
      print(
        'DEBUG: No valid password reset session found, redirecting to login',
      );
      if (mounted) {
        setState(() {
          _isCheckingSession = false;
        });
        // Use a small delay to ensure the widget is fully built before redirecting
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          context.go('/teken_in');
        }
      }
    } catch (e) {
      print('Error verifying password reset session: $e');
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
    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wagwoord moet ten minste 6 karakters wees'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Clear any previous errors
      ref.read(authLoadingProvider.notifier).state = true;

      // Update password using Supabase auth
      final response = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

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
        errorMessage = 'Wagwoord moet ten minste 6 karakters wees';
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

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authLoadingProvider);
    final isFormValid = ref.watch(passwordFormValidProvider);

    if (_isCheckingSession) {
      // Show loading while checking the session
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Verifieer wagwoord herstel sessie...',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (!_isPasswordVerified) {
      // Show loading while verifying the session
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Verifieer wagwoord herstel sessie...',
                style: AppTypography.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Container(
          width: 600.0,
          height: double.infinity,
          padding: const EdgeInsets.all(Spacing.screenHPad),
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
          child: Center(
            child: SingleChildScrollView(
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
                      // back button
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          onPressed: () => context.go('/teken_in'),
                          icon: const Icon(Icons.arrow_left),
                        ),
                      ),

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
                          color: AppColors.secondary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      Spacing.vGap8,

                      Text(
                        'Kies \'n sterk wagwoord vir $_email',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.onSurfaceVariant,
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
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.3),
                          ),
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

                      // Update button
                      SpysPrimaryButton(
                        text: "Opdateer Wagwoord",
                        isLoading: isLoading,
                        onPressed: isFormValid
                            ? () => _handlePasswordUpdate(context, ref)
                            : null,
                      ),

                      Spacing.vGap24,

                      // Help text
                      Text(
                        "Jy sal na die aanmeld bladsy geredigeer word na suksesvolle opdatering",
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.onSurfaceVariant,
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
      ),
    );
  }
}
