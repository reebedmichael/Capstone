import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/constants/strings_af.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/widgets/spys_primary_button.dart';
import '../../../../core/theme/app_typography.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/providers/auth_form_providers.dart';
import '../../../../shared/providers/auth_providers.dart';

import '../../../../shared/widgets/name_fields.dart';
import '../../../../shared/widgets/email_field.dart';
import '../../../../shared/widgets/cellphone_field.dart';
import '../../../../shared/widgets/location_dropdown.dart';
import '../../../../shared/widgets/password_field.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  bool isLoadingDiets = true;
  List<Map<String, dynamic>> _allDiets = const [];
  Set<String> _selectedDietIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadDietData();
  }

  Future<void> _loadDietData() async {
    setState(() {
      isLoadingDiets = true;
    });
    try {
      final rows = await Supabase.instance.client
          .from('dieet_vereiste')
          .select('dieet_id, dieet_naam')
          .order('dieet_naam');
      setState(() {
        _allDiets = List<Map<String, dynamic>>.from(rows as List);
        isLoadingDiets = false;
      });
    } catch (_) {
      setState(() {
        _allDiets = const [];
        isLoadingDiets = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFormValid = ref.watch(registerFormValidProvider);
    final isLoading = ref.watch(authLoadingProvider);
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
                Spacing.vGap32,
                
                // Header with back button
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        ref.read(emailProvider.notifier).state = '';
                        ref.read(passwordProvider.notifier).state = '';

                        ref.read(emailErrorProvider.notifier).state = null;
                        ref.read(passwordErrorProvider.notifier).state = null;

                        context.go('/auth/login');
                      },
                      icon: const Icon(Icons.arrow_back),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
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
                        // Location dropdown
                        const LocationDropdown(),
                        Spacing.vGap16,
                        // Diet requirements selection
                        _DietMultiSelect(
                          isLoading: isLoadingDiets,
                          allDiets: _allDiets,
                          selectedDietIds: _selectedDietIds,
                          onChanged: (ids) {
                            setState(() {
                              _selectedDietIds = ids;
                            });
                          },
                        ),
                        Spacing.vGap16,
                        // Password field
                        const PasswordField(),
                        Spacing.vGap16,
                        // Confirm password field
                        const PasswordField(isConfirmPassword: true),
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

                        Spacing.vGap24,
                        // Create account button
                        SpysPrimaryButton(
                          text: "Registreer",
                          isLoading: isLoading,
                          onPressed: isFormValid ? () async {
                            final firstName = ref.read(firstNameProvider);
                            final lastName = ref.read(lastNameProvider);
                            final email = ref.read(emailProvider);
                            final cellphone = ref.read(cellphoneProvider);
                            final password = ref.read(passwordProvider);
                            final confirmPassword = ref.read(confirmPasswordProvider);

                            if (password != confirmPassword) {
                              ref.read(authErrorProvider.notifier).state = 'Wagwoorde stem nie ooreen nie';
                              return;
                            }

                            ref.read(authErrorProvider.notifier).state = null;
                            ref.read(authLoadingProvider.notifier).state = true;

                            // Pre-check: abort if email already exists in gebruikers BEFORE signup (prevents upsert in auth service)
                            final preClient = Supabase.instance.client;
                            final existingBefore = await preClient
                              .from('gebruikers')
                              .select('gebr_id')
                              .ilike('gebr_epos', email)
                              .limit(1)
                              .maybeSingle();
                            if (existingBefore != null) {
                              ref.read(authErrorProvider.notifier).state = 'E-pos adres bestaan reeds in die stelsel';
                              ref.read(authLoadingProvider.notifier).state = false;
                              return;
                            }

                            try {
                              final authService = ref.read(authServiceProvider);
                              final response = await authService.signUpWithEmail(
                                email: email, 
                                password: password, 
                                firstName: firstName, 
                                lastName: lastName, 
                                cellphone: cellphone
                              );

                              if (response.user != null) {
                                // Link selected diet requirements to the new gebruiker
                                try {
                                  final userId = response.user!.id;
                                  if (_selectedDietIds.isNotEmpty) {
                                    final inserts = _selectedDietIds
                                        .map((id) => {
                                              'gebr_id': userId,
                                              'dieet_id': id,
                                            })
                                        .toList();
                                    await Supabase.instance.client
                                        .from('gebruiker_dieet_vereistes')
                                        .insert(inserts);
                                  }
                                } catch (_) {}

                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Registrasie suksesvol! Bevestig jou e-pos en teken in.'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  context.go('/auth/login');
                                }
                              }
                            } catch (e) {
                              String errorMessage = 'Registrasie het gefaal';
                              if (e.toString().contains('User already registered')) {
                                errorMessage = 'E-pos adres is reeds geregistreer';
                              } else if (e.toString().contains('Password should be at least')) {
                                errorMessage = 'Wagwoord moet ten minste 6 karakters wees';
                              } else if (e.toString().contains('Invalid email')) {
                                errorMessage = 'Ongeldige e-pos adres';
                              } else if (e is PostgrestException) {
                                errorMessage = 'Data stoor het gefaal: ${e.message}';
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

class _DietMultiSelect extends StatelessWidget {
  const _DietMultiSelect({
    required this.isLoading,
    required this.allDiets,
    required this.selectedDietIds,
    required this.onChanged,
  });

  final bool isLoading;
  final List<Map<String, dynamic>> allDiets;
  final Set<String> selectedDietIds;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.restaurant_menu, size: 20),
            SizedBox(width: 8),
            Text(
              "Dieet Vereistes",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const LinearProgressIndicator(minHeight: 2)
        else ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allDiets.map((d) {
              final id = d['dieet_id'].toString();
              final naam = d['dieet_naam'].toString();
              final isSelected = selectedDietIds.contains(id);
              return FilterChip(
                label: Text(naam),
                labelStyle: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.onSurface,
                ),
                selected: isSelected,
                onSelected: (sel) {
                  final next = Set<String>.from(selectedDietIds);
                  if (sel) {
                    next.add(id);
                  } else {
                    next.remove(id);
                  }
                  onChanged(next);
                },
              );
            }).toList(),
          ),
          if (allDiets.isEmpty)
            Text(
              'Geen dieet opsies beskikbaar nie',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
        ],
      ],
    );
  }
}
