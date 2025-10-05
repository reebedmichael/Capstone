import 'package:capstone_mobile/locator.dart';
import 'package:capstone_mobile/shared/providers/auth_form_providers.dart';
import 'package:capstone_mobile/shared/constants/spacing.dart';
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
  bool isLoading = true;
  bool isLoadingDiets = true;
  List<Map<String, dynamic>> _allDiets = const [];
  Set<String> _selectedDietIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final repository = sl<GebruikersRepository>();
      final data = await repository.kryGebruiker(user.id);

      if (data != null) {
        setState(() {
          ref.read(firstNameProvider.notifier).state = data['gebr_naam'] ?? '';
          ref.read(lastNameProvider.notifier).state = data['gebr_van'] ?? '';
          ref.read(emailProvider.notifier).state = data['gebr_epos'] ?? '';
          ref.read(cellphoneProvider.notifier).state = data["gebr_selfoon"] ?? '';
          ref.read(locationProvider.notifier).state = data["kampus_naam"] ?? '';
          ref.read(walletBalanceProvider.notifier).state = data['beursie_balans'] ?? '';
          isLoading = false;
        });
        await _loadDietData(user.id);
      } else {
        debugPrint("User data not found");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading user: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loadDietData(String userId) async {
    try {
      setState(() {
        isLoadingDiets = true;
      });
      // Laai alle dieet keuses
      final all = await Supabase.instance.client
          .from('dieet_vereiste')
          .select('dieet_id, dieet_naam')
          .order('dieet_naam');
      // Laai gebruiker se huidige keuses
      final rows = await Supabase.instance.client
          .from('gebruiker_dieet_vereistes')
          .select('dieet_id')
          .eq('gebr_id', userId);

      final selected = rows
          .map<String>((e) => e['dieet_id'].toString())
          .toSet();

      setState(() {
        _allDiets = List<Map<String, dynamic>>.from(all);
        _selectedDietIds = selected;
        isLoadingDiets = false;
      });
    } catch (e) {
      debugPrint('Kon nie dieet data laai nie: $e');
      setState(() {
        _allDiets = const [];
        _selectedDietIds = <String>{};
        isLoadingDiets = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline)),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "My Profiel",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
                                      style: TextStyle(fontSize: 12),
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
                                      SnackBar(
                                        content: Text(
                                            'Gebruiker Inligting Opgedateer!'),
                                        backgroundColor: Theme.of(context).colorScheme.tertiary,
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
