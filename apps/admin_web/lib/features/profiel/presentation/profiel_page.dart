import 'package:capstone_admin/locator.dart';
import 'package:capstone_admin/shared/constants/spacing.dart';
import 'package:capstone_admin/shared/widgets/spys_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:spys_api_client/spys_api_client.dart';
import '../../../shared/widgets/name_fields.dart';
import '../../../shared/widgets/email_field.dart';
import '../../../shared/widgets/cellphone_field.dart';
import '../../../shared/widgets/location_dropdown.dart';
import 'package:go_router/go_router.dart';

class ProfielPage extends StatefulWidget {
  const ProfielPage({super.key});

  @override
  State<ProfielPage> createState() => _ProfielPageState();
}

class _ProfielPageState extends State<ProfielPage> {
  String firstName = '';
  String lastName = '';
  String email = '';
  String cellphone = '078 435 5301';
  String status = 'wag_goedkeuring';
  DateTime? createdDate;
  DateTime? lastActive;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final repository = sl<GebruikersRepository>();
      final data = await repository.kryGebruiker("fe08a973-bdd4-4618-b4ca-6754d510c9a5");

      if (data != null) {
        setState(() {
          firstName = data['gebr_naam'] ?? '';
          lastName = data['gebr_van'] ?? '';
          email = data['gebr_epos'] ?? '';
          status = data['is_aktief'] == true ? 'aktief' : 'wag_goedkeuring';
          createdDate = data['gebr_geskep_datum'] != null ? DateTime.parse(data['gebr_geskep_datum']) : null;
          lastActive = DateTime.now();
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
                                          status == "aktief" ? "Aktief" : "Wag Goedkeuring",
                                        ),
                                        backgroundColor: status == "aktief"
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
                            LocationDropdown(),

                            Spacing.vGap16,
                            SpysPrimaryButton(
                              text: "Stoor",
                              onPressed: true
                                  ? () {
                                      //TODO: Save updated info via repository
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
