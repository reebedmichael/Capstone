import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/constants/strings_af.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/widgets/spys_primary_button.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

import '../../providers/auth_form_providers.dart';

import '../widgets/name_fields.dart';
import '../widgets/email_field.dart';
import '../widgets/cellphone_field.dart';
import '../widgets/role_dropdown.dart';
import '../widgets/location_dropdown.dart';
import '../widgets/password_field.dart';

class RegisterPage extends ConsumerWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFormValid = ref.watch(registerFormValidProvider);
    
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
                Spacing.vGap32,
                
                // Header with back button
                Row(
                  children: [
                    IconButton(
                      onPressed: () => context.go('/auth/login'),
                      icon: const Icon(Icons.arrow_back),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Registreer',
                      style: AppTypography.headlineSmall,
                    ),
                    const Spacer(),
                    const SizedBox(width: 48), // Balance the layout
                  ],
                ),
                
                Spacing.vGap24,
                
                // Registration Form Card
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
                          'Skep Jou Rekening',
                          style: AppTypography.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        Spacing.vGap8,
                        Text(
                          'Vul alle velde in om te begin',
                          style: AppTypography.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                        Spacing.vGap24,
                        // Name fields
                        const NameFields(),
                        Spacing.vGap16,
                        // Email field
                        const EmailField(),
                        Spacing.vGap16,
                        // Cellphone field
                        const CellphoneField(),
                        Spacing.vGap16,
                        // Role dropdown
                        const RoleDropdown(),
                        Spacing.vGap16,
                        // Location dropdown
                        const LocationDropdown(),
                        Spacing.vGap16,
                        // Password field
                        const PasswordField(),
                        Spacing.vGap16,
                        // Confirm password field
                        const PasswordField(isConfirmPassword: true),
                        Spacing.vGap24,
                        // Create account button
                        SpysPrimaryButton(
                          text: StringsAf.signUpCta,
                          onPressed: isFormValid ? () 
                          {
                            debugPrint('Registration attempted with email: ${ref.read(emailProvider)}');

                            context.go("/home");
                          } : null,
                        ),
                      ],
                    ),
                  ),
                ),
                
                Spacing.vGap24,
                
                // Login link
                Container(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        StringsAf.alreadyRegisteredQ,
                        style: AppTypography.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      Spacing.vGap8,
                      TextButton(
                        onPressed: () => context.go('/auth/login'),
                        child: Text(
                          StringsAf.goLogin,
                          style: AppTypography.linkText,
                        ),
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
