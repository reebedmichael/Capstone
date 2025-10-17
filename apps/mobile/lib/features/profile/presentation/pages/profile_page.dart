import 'package:capstone_mobile/locator.dart';
import 'package:capstone_mobile/shared/providers/auth_form_providers.dart';
import 'package:capstone_mobile/shared/constants/spacing.dart';
import 'package:capstone_mobile/shared/utils/responsive_utils.dart';
import 'package:capstone_mobile/shared/widgets/spys_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spys_api_client/spys_api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/presentation/widgets/app_bottom_nav.dart';

import '../../../../shared/widgets/name_fields.dart';
import '../../../../shared/widgets/email_field.dart';
import '../../../../shared/widgets/cellphone_field.dart';
import '../../../../shared/widgets/location_dropdown.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool isLoading = false;
  bool isLoadingDiets = true;
  List<Map<String, dynamic>> _allDiets = const [];
  Set<String> _selectedDietIds = <String>{};
  
  Future<T> _retryWithBackoff<T>(Future<T> Function() action,
      {int maxAttempts = 3, Duration initialDelay = const Duration(milliseconds: 400)}) async {
    int attempt = 0;
    Duration delay = initialDelay;
    while (true) {
      attempt++;
      try {
        return await action();
      } catch (e) {
        if (attempt >= maxAttempts) rethrow;
        await Future.delayed(delay);
        delay *= 2;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return;
      }

      // Load user data directly from database like other pages
      final userData = await Supabase.instance.client
          .from('gebruikers')
          .select('''
            gebr_naam,
            gebr_van,
            gebr_epos,
            gebr_selfoon,
            beursie_balans,
            kampus:kampus_id(
              kampus_naam
            )
          ''')
          .eq('gebr_id', user.id)
          .maybeSingle();

      if (userData != null && mounted) {
        ref.read(firstNameProvider.notifier).state = userData['gebr_naam'] ?? '';
        ref.read(lastNameProvider.notifier).state = userData['gebr_van'] ?? '';
        ref.read(emailProvider.notifier).state = userData['gebr_epos'] ?? '';
        ref.read(cellphoneProvider.notifier).state = userData["gebr_selfoon"] ?? '';
        
        // Extract kampus name from joined data
        final kampusData = userData['kampus'] as Map<String, dynamic>?;
        ref.read(locationProvider.notifier).state = kampusData?['kampus_naam'] ?? '';
        
        // Extract wallet balance and convert to double
        final rawBalance = userData['beursie_balans'];
        final balance = rawBalance is num ? rawBalance.toDouble() : (double.tryParse('$rawBalance') ?? 0.0);
        ref.read(walletBalanceProvider.notifier).state = balance;
        
        await _loadDietData(user.id);
      } else {
        debugPrint("User data not found");
      }
    } catch (e) {
      debugPrint("Error loading user: $e");
    }
  }

  Future<void> _loadDietData(String userId) async {
    setState(() {
      isLoadingDiets = true;
    });
    List<Map<String, dynamic>> allDietsLocal = const [];
    Set<String> selectedLocal = <String>{};
    try {
      final client = Supabase.instance.client;
      // Run both reads in parallel with timeout + retry (helps flaky mobile networks)
      final results = await Future.wait([
        _retryWithBackoff(() => client
            .from('dieet_vereiste')
            .select('dieet_id, dieet_naam')
            .order('dieet_naam')
            .timeout(const Duration(seconds: 12))),
        _retryWithBackoff(() => client
            .from('gebruiker_dieet_vereistes')
            .select('dieet_id')
            .eq('gebr_id', userId)
            .timeout(const Duration(seconds: 12))),
      ]);

      final all = List<Map<String, dynamic>>.from(results[0] as List);
      final rows = List<Map<String, dynamic>>.from(results[1] as List);
      allDietsLocal = all;
      selectedLocal = rows.map<String>((e) => e['dieet_id'].toString()).toSet();
    } catch (e) {
      debugPrint('Kon nie dieet data laai nie: $e');
      allDietsLocal = const [];
      selectedLocal = <String>{};
    } finally {
      if (!mounted) return;
      setState(() {
        _allDiets = allDietsLocal;
        _selectedDietIds = selectedLocal;
        isLoadingDiets = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = ref.watch(firstNameProvider);
    final lastName = ref.watch(lastNameProvider);
    final email = ref.watch(emailProvider);
    final cellphone = ref.watch(cellphoneProvider);
    final location = ref.watch(locationProvider);
    final walletBalance = ref.watch(walletBalanceProvider);
    final isFormValid = ref.watch(profielFormValidProvider);

    final initials =
        "${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}"
            .toUpperCase();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Spacing.screenPadding(context).left,
                vertical: ResponsiveUtils.getResponsiveSpacing(context, mobile: 12, tablet: 16, desktop: 20),
              ),
              color: Theme.of(context).colorScheme.primary,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "My Profiel",
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 20, tablet: 24, desktop: 28),
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: Spacing.screenPadding(context).copyWith(
                  top: ResponsiveUtils.getResponsiveSpacing(context, mobile: 8, tablet: 12, desktop: 16),
                ),
                child: Column(
                  children: [
                    // Profile Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              child: Text(
                                initials,
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "$firstName $lastName",
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      "Ekstern",
                                      style: TextStyle(fontSize: 12, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Personal Information
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.person, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "Persoonlike Inligting",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Spacing.vGap20,
                            NameFields(initialFirstName: firstName, initialLastName: lastName),
                            Spacing.vGap16,
                            EmailField(initialEmail: email),
                            Spacing.vGap16,
                            CellphoneField(initialCellphone: cellphone),
                            Spacing.vGap16,
                            LocationDropdown(initialValue: location),
                            Spacing.vGap16,
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
                            SpysPrimaryButton(
                              text: "Stoor",
                              onPressed: isFormValid
                                  ? () async {
                                    final user = Supabase.instance.client.auth.currentUser;
                                    if (user == null) return;

                                    final gebRepository = sl<GebruikersRepository>();
                                    final kamRepository = sl<KampusRepository>();
                                    final newKampusID = await kamRepository.kryKampusID(location);

                                    await gebRepository.skepOfOpdateerGebruiker({
                                      "gebr_id": user.id,
                                      "gebr_naam": firstName,
                                      "gebr_van": lastName,
                                      "gebr_epos": email,
                                      "gebr_selfoon": cellphone,
                                      "kampus_id": newKampusID,
                                    });

                                    // Opdateer gebruiker se dieet vereistes
                                    try {
                                      final sb = Supabase.instance.client;
                                      await sb
                                          .from('gebruiker_dieet_vereistes')
                                          .delete()
                                          .eq('gebr_id', user.id);

                                      if (_selectedDietIds.isNotEmpty) {
                                        final inserts = _selectedDietIds
                                            .map((id) => {
                                                  'gebr_id': user.id,
                                                  'dieet_id': id,
                                                })
                                            .toList();
                                        await sb.from('gebruiker_dieet_vereistes').insert(inserts);
                                      }
                                    } catch (e) {
                                      debugPrint('Kon nie dieet vereistes stoor nie: $e');
                                    }

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            'Gebruiker Inligting Opgedateer!'),
                                      ),
                                    );

                                    // Reload updated user data
                                    _loadUserData();
                                  }
                                : null,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Account Settings (Wallet etc.)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  "Beursie Balans",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "Beskikbare fondse",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "R${walletBalance.toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    context.go('/wallet');
                                  },
                                  child: const Text("Bestuur"),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: const AppBottomNav(currentIndex: 3),
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
