import 'package:capstone_mobile/locator.dart';
import 'package:capstone_mobile/shared/providers/auth_form_providers.dart';
import 'package:capstone_mobile/shared/constants/spacing.dart';
import 'package:capstone_mobile/shared/widgets/spys_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spys_api_client/spys_api_client.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString("gebr_id");

      if (id == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      final repository = sl<GebruikersRepository>();
      final data = await repository.kryGebruiker(id);

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
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
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
                padding: const EdgeInsets.all(16),
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
                                    style: TextStyle(color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
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

                    const SizedBox(height: 16),

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
                            //TODO:wil nie werk nie, ou ek het geen idee dit werk in admin
                            // LocationDropdown(initialValue: "Centurion"),
                            // Spacing.vGap16,
                            SpysPrimaryButton(
                              text: "Stoor",
                              onPressed: isFormValid
                                  ? () async {
                                      final gebRepository = sl<GebruikersRepository>();
                                      // final kamRepository = sl<KampusRepository>();
                                      // final newKampusID = await kamRepository.kryKampusID(location);

                                      final prefs = await SharedPreferences.getInstance();
                                      final id = prefs.getString("gebr_id");

                                      if (id != null) {
                                        await gebRepository.skepOfOpdateerGebruiker({
                                          "gebr_id": id,
                                          "gebr_naam": firstName,
                                          "gebr_van": lastName,
                                          "gebr_epos": email,
                                          "gebr_selfoon": cellphone,
                                          // "kampus_id": newKampusID,
                                        });

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Gebruiker Inligting Opgedateer!'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );

                                        // Reload updated user data
                                        _loadUserData();
                                      }
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
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
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
