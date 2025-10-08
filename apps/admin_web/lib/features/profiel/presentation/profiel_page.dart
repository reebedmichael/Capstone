import 'package:capstone_admin/locator.dart';
import 'package:capstone_admin/shared/constants/spacing.dart';
import 'package:capstone_admin/shared/providers/auth_form_providers.dart';
import 'package:capstone_admin/shared/widgets/spys_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spys_api_client/spys_api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/widgets/name_fields.dart';
import '../../../shared/widgets/email_field.dart';
import '../../../shared/widgets/cellphone_field.dart';
import '../../../shared/widgets/location_dropdown.dart';
import 'package:go_router/go_router.dart';

class ProfielPage extends ConsumerStatefulWidget {
  const ProfielPage({super.key});

  @override
  ConsumerState<ProfielPage> createState() => _ProfielPageState();
}

class _ProfielPageState extends ConsumerState<ProfielPage> {
  bool isLoading = true;

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
          ref.read(cellphoneProvider.notifier).state =
              data["gebr_selfoon"] ?? '';
          ref.read(statusProvider.notifier).state = data["is_aktief"] ?? false;
          ref.read(createdDateProvider.notifier).state =
              data["gebr_geskep_datum"];
          //TODO: gaan ons rerig hierdie gebruik? vvvv
          ref.read(lastActiveProvider.notifier).state = DateTime.now();
          ref.read(locationProvider.notifier).state = data["kampus_naam"];
          isLoading = false;
        });
      } else {
        debugPrint("Data not found");
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching user: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final firstName = ref.watch(firstNameProvider);
    final lastName = ref.watch(lastNameProvider);
    final email = ref.watch(emailProvider);
    final cellphone = ref.watch(cellphoneProvider);
    final status = ref.watch(statusProvider);
    final createdDate = ref.watch(createdDateProvider);
    final lastActive = ref.watch(lastActiveProvider);
    final location = ref.watch(locationProvider);

    final isFormValid = ref.watch(profielFormValidProvider);

    final initials =
        "${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}"
            .toUpperCase();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Overview
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
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      const Chip(
                                        label: Text("Ekstern"),
                                        avatar: Icon(Icons.shield, size: 16),
                                      ),
                                      Chip(
                                        label: Text(
                                          status == true
                                              ? "Aktief"
                                              : "Wag Goedkeuring",
                                        ),
                                        backgroundColor: status == true
                                            ? Colors.green.shade50
                                            : Colors.orange.shade50,
                                      ),
                                      Chip(
                                        label: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.calendar_today,
                                              size: 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "Lid sedert ${createdDate.toString().split(' ').first}",
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Role Information
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.security, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  "Rol en Toegangsregte",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              "Huidige Rol: Ekstern",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              status == "aktief"
                                  ? "Jy het volledige toegang tot die stelsel"
                                  : "Beperkte toegang totdat rekening goedgekeur word",
                              style: TextStyle(color: Colors.grey.shade600),
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
                              children: [
                                const Icon(Icons.person, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  "Persoonlike Inligting",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Spacing.vGap20,
                            NameFields(
                              initialFirstName: firstName,
                              initialLastName: lastName,
                            ),

                            Spacing.vGap16,
                            EmailField(initialEmail: email),

                            Spacing.vGap16,
                            CellphoneField(initialCellphone: cellphone),

                            Spacing.vGap16,
                            LocationDropdown(initialValue: location),

                            Spacing.vGap16,
                            SpysPrimaryButton(
                              text: "Stoor",
                              onPressed: isFormValid
                                  ? () async {
                                      final user = Supabase
                                          .instance
                                          .client
                                          .auth
                                          .currentUser;
                                      if (user == null) return;

                                      final gebRepository =
                                          sl<GebruikersRepository>();
                                      final kamRepository =
                                          sl<KampusRepository>();

                                      // Debug: Check available kampus options
                                      final availableKampusse =
                                          await kamRepository.kryKampusse();
                                      debugPrint(
                                        'Available kampusse: $availableKampusse',
                                      );

                                      final newKampusID = await kamRepository
                                          .kryKampusID(location);

                                      debugPrint('Location: "$location"');
                                      debugPrint(
                                        'Location length: ${location.length}',
                                      );
                                      debugPrint('Kampus ID: $newKampusID');

                                      if (newKampusID == null) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Kampus "$location" nie gevind nie. Kies \'n ander kampus.',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                        return;
                                      }

                                      //TODO:kyk of email en ander goed bots
                                      // final gebruikersMetEpos = await gebRepository.soekGebruikers(email);

                                      try {
                                        await gebRepository
                                            .skepOfOpdateerGebruiker({
                                              "gebr_id": user.id,
                                              "gebr_naam": firstName,
                                              "gebr_van": lastName,
                                              "gebr_epos": email,
                                              "gebr_selfoon": cellphone,
                                              "kampus_id": newKampusID,
                                            });

                                        // Reload user data after successful save
                                        await _loadUserData();

                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Gebruiker inligting suksesvol opgedateer.',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );

                                          // Force a complete page refresh to ensure all data is properly loaded
                                          setState(() {
                                            isLoading = true;
                                          });

                                          // Reload data one more time to ensure consistency
                                          await _loadUserData();
                                        }
                                      } catch (e) {
                                        debugPrint('Error updating user: $e');
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Fout met opdateer van gebruiker: $e',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Account Activity
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Rekening Aktiwiteit",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildActivityRow(
                              "Rekening geskep:",
                              createdDate.toString().split(' ').first,
                            ),
                            _buildActivityRow(
                              "Laaste aktiwiteit:",
                              lastActive.toString().split(' ').first,
                            ),
                            _buildActivityRow("Rol:", "Ekstern"),
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
    );
  }

  Widget _buildActivityRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final mediaWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = mediaWidth < 600;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: isSmallScreen ? 12 : 16,
      ),
      child: isSmallScreen
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo and title section
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/dashboard'),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text("👤", style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "My Profiel",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text(
                            "Bestuur jou persoonlike inligting",
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// Left section: back button + logo + title + description
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/dashboard'),
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text("👤", style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "My Profiel",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          "Bestuur jou persoonlike inligting",
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
