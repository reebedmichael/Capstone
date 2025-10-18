import 'dart:ui';
import 'package:capstone_admin/core/theme/app_colors.dart';
import 'package:capstone_admin/core/theme/app_typography.dart';
import 'package:capstone_admin/shared/widgets/spys_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/providers/auth_form_providers.dart';
import '../../../shared/providers/auth_providers.dart';
import '../../../shared/widgets/name_fields.dart';
import '../../../shared/widgets/email_field.dart';
import '../../../shared/widgets/cellphone_field.dart';
import '../../../shared/widgets/password_field.dart';

class RegistreerAdminPage extends HookConsumerWidget {
  const RegistreerAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFormValid = ref.watch(registerFormValidProvider);
    final isLoading = ref.watch(authLoadingProvider);
    final authError = ref.watch(authErrorProvider);
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 300),
    );

    // Fade + navigate helper
    Future<void> _fadeAndGo(String route) async {
      try {
        // animate forward (opacity will go from 1 -> 0)
        await animationController.forward();
        if (context.mounted) context.go(route);
      } finally {
        // reset so returning to this page will show full opacity
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
                          '../web/assets/Spys4.jpg', // your local image path
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
                                  'Registreer vandag',
                                  style: AppTypography.headlineSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Neem beheer oor Spys met hierdie omvattende administrasie platform',
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
                  // Form content with responsive padding and fade animation
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: animationController,
                      builder: (context, child) {
                        // opacity goes from 1 -> 0 when animationController.forward() is called
                        final opacity = 1.0 - animationController.value;
                        return Opacity(opacity: opacity, child: child);
                      },
                      child: _buildFormContent(
                        context,
                        ref,
                        isLoading,
                        isFormValid,
                        authError,
                        isDesktop,
                        // pass the fade navigation callback so internal buttons can use it
                        _fadeAndGo,
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

  Widget _buildFormContent(
    BuildContext context,
    WidgetRef ref,
    bool isLoading,
    bool isFormValid,
    String? authError,
    bool isDesktop,
    Future<void> Function(String route) onNavigate,
  ) {
    return SingleChildScrollView(
      child: Padding(
        // Adjust padding based on screen size
        padding: EdgeInsets.all(isDesktop ? 48 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),

            // Back button
            if (!isDesktop) ...[
              // Add a mobile-specific header with logo for small screens
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

            // Back button
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                onPressed: () => onNavigate('/teken_in'),
                icon: const Icon(Icons.arrow_back),
              ),
            ),
            const SizedBox(height: 16),

            // Header
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
            const SizedBox(height: 8),
            Text(
              'Skep Rekening',
              style: AppTypography.headlineSmall.copyWith(
                // color: const Color(0xFF374151), // gray-700
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Begin jou bestuursreis deur \'n administrateur rekening te skep.',
              style: AppTypography.bodyMedium.copyWith(
                color: const Color(0xFF6B7280), // gray-500
              ),
            ),
            const SizedBox(height: 48),

            // Form
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const NameFields(),
                const SizedBox(height: 24),
                const EmailField(),
                const SizedBox(height: 24),
                const CellphoneField(),
                const SizedBox(height: 24),
                const PasswordField(),
                const SizedBox(height: 24),
                const PasswordField(isConfirmPassword: true),
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

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: SpysPrimaryButton(
                    text: "Registreer",
                    isLoading: isLoading,
                    onPressed: isFormValid
                        ? () async {
                            final firstName = ref.read(firstNameProvider);
                            final lastName = ref.read(lastNameProvider);
                            final email = ref.read(emailProvider);
                            final cellphone = ref.read(cellphoneProvider);
                            final password = ref.read(passwordProvider);
                            final confirmPassword = ref.read(
                              confirmPasswordProvider,
                            );

                            // Validate passwords match
                            if (password != confirmPassword) {
                              ref.read(authErrorProvider.notifier).state =
                                  'Wagwoorde stem nie ooreen nie';
                              return;
                            }

                            // Clear any previous errors
                            ref.read(authErrorProvider.notifier).state = null;
                            ref.read(authLoadingProvider.notifier).state = true;

                            // Pre-check: abort if email already exists in gebruikers BEFORE signup
                            final preClient = Supabase.instance.client;
                            final existingBefore = await preClient
                                .from('gebruikers')
                                .select('gebr_id')
                                .ilike('gebr_epos', email)
                                .limit(1)
                                .maybeSingle();
                            if (existingBefore != null) {
                              ref.read(authErrorProvider.notifier).state =
                                  'E-pos adres bestaan reeds in die stelsel';
                              ref.read(authLoadingProvider.notifier).state =
                                  false;
                              return;
                            }

                            try {
                              final client = Supabase.instance.client;
                              final authService = ref.read(authServiceProvider);
                              final response = await authService
                                  .signUpWithEmail(
                                    email: email,
                                    password: password,
                                    firstName: firstName,
                                    lastName: lastName,
                                    cellphone: cellphone,
                                    createInDatabase: false,
                                  );

                              if (response.user != null) {
                                // Prevent duplicate email in gebruikers
                                final existingEmail = await client
                                    .from('gebruikers')
                                    .select('gebr_id')
                                    .ilike('gebr_epos', email)
                                    .limit(1)
                                    .maybeSingle();
                                if (existingEmail != null) {
                                  ref.read(authErrorProvider.notifier).state =
                                      'E-pos adres bestaan reeds in die stelsel';
                                  return;
                                }

                                // Resolve defaults (IDs) once
                                final ekstern = await client
                                    .from('gebruiker_tipes')
                                    .select('gebr_tipe_id')
                                    .ilike('gebr_tipe_naam', 'Ekstern')
                                    .limit(1)
                                    .maybeSingle();
                                final adminNone = await client
                                    .from('admin_tipes')
                                    .select('admin_tipe_id')
                                    .ilike('admin_tipe_naam', 'None')
                                    .limit(1)
                                    .maybeSingle();
                                final firstKampus = await client
                                    .from('kampus')
                                    .select('kampus_id')
                                    .order('kampus_naam', ascending: true)
                                    .limit(1)
                                    .maybeSingle();

                                if (ekstern == null ||
                                    adminNone == null ||
                                    firstKampus == null) {
                                  throw Exception(
                                    'Kon nie verstekwaardes laai nie (gebruiker_tipes/admin_tipes/kampus)',
                                  );
                                }

                                // Upsert gebruiker record with same defaults as mobile register_page
                                await client
                                    .from('gebruikers')
                                    .upsert({
                                      'gebr_id': response.user!.id,
                                      'gebr_epos': email,
                                      'gebr_naam': firstName,
                                      'gebr_van': lastName,
                                      'gebr_selfoon': cellphone,
                                      'is_aktief': true,
                                      'beursie_balans': 0,
                                      'gebr_tipe_id': ekstern['gebr_tipe_id'],
                                      'admin_tipe_id':
                                          adminNone['admin_tipe_id'],
                                      'kampus_id': firstKampus['kampus_id'],
                                    }, onConflict: 'gebr_id')
                                    .select()
                                    .single();

                                if (context.mounted) {
                                  // fade then go to sign in with registration success parameter
                                  await onNavigate('/teken_in?registered=true');
                                }
                              }
                            } catch (e) {
                              String errorMessage = 'Registrasie het gefaal';
                              if (e.toString().contains(
                                'User already registered',
                              )) {
                                errorMessage =
                                    'E-pos adres is reeds geregistreer';
                              } else if (e.toString().contains(
                                'Password should be at least',
                              )) {
                                errorMessage =
                                    'Wagwoord moet ten minste 6 karakters wees';
                              } else if (e.toString().contains(
                                'Invalid email',
                              )) {
                                errorMessage = 'Ongeldige e-pos adres';
                              } else if (e is PostgrestException) {
                                errorMessage =
                                    'Data stoor het gefaal: ${e.message}';
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

                // Already registered
                Center(
                  child: Column(
                    children: [
                      Text(
                        "Is jy klaar gerigistreer?",
                        style: AppTypography.bodyMedium.copyWith(
                          color: const Color(0xFF6B7280), // gray-500
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => onNavigate('/teken_in'),
                        child: Text(
                          'Teken hier in',
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
