import 'package:capstone_admin/locator.dart';
import 'package:capstone_admin/shared/constants/spacing.dart';
import 'package:capstone_admin/shared/providers/auth_form_providers.dart';
import 'package:capstone_admin/shared/providers/auth_providers.dart';
import 'package:capstone_admin/shared/widgets/spys_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spys_api_client/spys_api_client.dart';
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
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString("gebr_id");

      final repository = sl<GebruikersRepository>();
      final data = await repository.kryGebruiker(id!);

      if (data != null) {
        setState(() {
          ref.read(firstNameProvider.notifier).state = data['gebr_naam'] ?? '';
          ref.read(lastNameProvider.notifier).state = data['gebr_van'] ?? '';
          ref.read(emailProvider.notifier).state = data['gebr_epos'] ?? '';
          ref.read(cellphoneProvider.notifier).state = data["gebr_selfoon"] ?? '';
          ref.read(statusProvider.notifier).state = data["is_aktief"] ?? false;
          ref.read(createdDateProvider.notifier).state = data["gebr_geskep_datum"];
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
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
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/dashboard'),
                  ),
                  const SizedBox(width: 8),
                  const Text(
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
                                    style: TextStyle(color: Colors.grey.shade600),
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
                                          status == true ? "Aktief" : "Wag Goedkeuring",
                                        ),
                                        backgroundColor: status == true
                                            ? Colors.green.shade50
                                            : Colors.orange.shade50,
                                      ),
                                      Chip(
                                        label: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.calendar_today, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              "Lid sedert ${createdDate?.toString().split(' ').first ?? "Onbekend"}",
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
                            NameFields(initialFirstName: firstName, initialLastName: lastName),

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
                                  ? () async
                                  {
                                    final gebRepository = sl<GebruikersRepository>();
                                    final kamRepository = sl<KampusRepository>();
                                    final newKampusID = await kamRepository.kryKampusID(location);
                                    //TODO:kyk of email en ander goed bots
                                    // final gebruikersMetEpos = await gebRepository.soekGebruikers(email);

                                    _loadUserData();
                                    
                                    if (context.mounted) 
                                    {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Registrasie suksesvol! Jy kan nou in teken.'),
                                          backgroundColor: Colors.green,
                                        ));

                                        debugPrint(firstName);

                                      final prefs = await SharedPreferences.getInstance();
                                      final id = prefs.getString("gebr_id");

                                      await gebRepository.skepOfOpdateerGebruiker(
                                        {
                                          //TODO: gebruik local id
                                          "gebr_id" : id,
                                          "gebr_naam" : firstName,
                                          "gebr_van" : lastName,
                                          "gebr_epos" : email,
                                          "gebr_selfoon" : cellphone,
                                          //TODO: hierdie werk nie
                                          "kampus_id" : newKampusID
                                        }
                                      );
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
                              createdDate?.toString().split(' ').first ?? "Onbekend",
                            ),
                            _buildActivityRow(
                              "Laaste aktiwiteit:",
                              lastActive?.toString().split(' ').first ?? "Onbekend",
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
}
