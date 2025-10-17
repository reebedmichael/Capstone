import 'package:capstone_admin/core/theme/app_colors.dart';
import 'package:capstone_admin/core/theme/app_typography.dart';
import 'package:capstone_admin/shared/constants/spacing.dart';
import 'package:capstone_admin/shared/constants/strings_af_admin.dart';
import 'package:capstone_admin/shared/widgets/spys_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../shared/providers/auth_form_providers.dart';
import '../../../shared/providers/auth_providers.dart';
import '../../../shared/widgets/name_fields.dart';
import '../../../shared/widgets/email_field.dart';
import '../../../shared/widgets/cellphone_field.dart';
import '../../../shared/widgets/password_field.dart';

class RegistreerAdminPage extends ConsumerWidget {
  const RegistreerAdminPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFormValid = ref.watch(registerFormValidProvider);
    final isLoading = ref.watch(authLoadingProvider);
    final authError = ref.watch(authErrorProvider);

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
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              width: 600.0,
              padding: const EdgeInsets.all(Spacing.screenHPad),
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
                        child: const Center(
                          child: Text("👤", style: TextStyle(fontSize: 32)),
                        ),
                      ),

                      Spacing.vGap16,

                      // Title
                      Text(
                        'Registreer as Admin',
                        style: AppTypography.headlineMedium.copyWith(
                          color: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      Spacing.vGap8,

                      Text(
                        "Vul alle besonderhede in om 'n admin rekening aan te vra",
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      Spacing.vGap24,

                      // Form fields
                      const NameFields(),
                      Spacing.vGap16,
                      const EmailField(),
                      Spacing.vGap16,
                      const CellphoneField(),
                      Spacing.vGap16,
                      const PasswordField(),
                      Spacing.vGap16,
                      const PasswordField(isConfirmPassword: true),

                      Spacing.vGap16,

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

                      Spacing.vGap24,

                      // Submit button
                      SpysPrimaryButton(
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
                                ref.read(authErrorProvider.notifier).state =
                                    null;
                                ref.read(authLoadingProvider.notifier).state =
                                    true;

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

                                  final authService = ref.read(
                                    authServiceProvider,
                                  );
                                  final response = await authService
                                      .signUpWithEmail(
                                        email: email,
                                        password: password,
                                        firstName: firstName,
                                        lastName: lastName,
                                        cellphone: cellphone,
                                        createInDatabase:
                                            false, // We'll create the user manually with correct values
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
                                      ref
                                              .read(authErrorProvider.notifier)
                                              .state =
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
                                          'gebr_tipe_id':
                                              ekstern['gebr_tipe_id'],
                                          'admin_tipe_id':
                                              adminNone['admin_tipe_id'],
                                          'kampus_id': firstKampus['kampus_id'],
                                        }, onConflict: 'gebr_id')
                                        .select()
                                        .single();

                                    if (context.mounted) {
                                      // Show success message and redirect to pending approval
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Registrasie suksesvol! Bevestig jou e-pos en teken in.',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                      context.go('/teken_in');
                                    }
                                  }
                                } catch (e) {
                                  String errorMessage =
                                      'Registrasie het gefaal';
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

                      Spacing.vGap24,

                      // Divider
                      Divider(color: Theme.of(context).dividerColor),

                      Spacing.vGap16,

                      // Already registered
                      Column(
                        children: [
                          Text(
                            "Het jy reeds 'n rekening?",
                            style: AppTypography.bodyMedium.copyWith(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                          ),
                          Spacing.vGap8,
                          TextButton(
                            onPressed: () => context.go('/teken_in'),
                            child: Text(
                              StringsAfAdmin.goLogin,
                              style: AppTypography.linkText.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
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
