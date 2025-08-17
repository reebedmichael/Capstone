import 'package:capstone_admin/shared/constants/spacing.dart';
import 'package:capstone_admin/shared/widgets/spys_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/providers/auth_form_providers.dart';
import '../../../shared/widgets/name_fields.dart';
import '../../../shared/widgets/email_field.dart';
import '../../../shared/widgets/cellphone_field.dart';
import '../../../shared/widgets/role_dropdown.dart';
import '../../../shared/widgets/location_dropdown.dart';
import '../../../shared/widgets/password_field.dart';

class ProfielPage extends ConsumerWidget {
  const ProfielPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(firstNameProvider);
    final surname = ref.watch(lastNameProvider);
    final email = ref.watch(emailProvider);
    final role = ref.watch(roleProvider).toString();
    final status = ref.watch(accountStatusProvider); // e.g. "aktief", "wag_goedkeuring"
    final createdDate = ref.watch(accountCreatedDateProvider);
    final lastActive = ref.watch(accountLastActiveProvider);
    final isFormValid = ref.watch(registerFormValidProvider);

    final initials = "${name.isNotEmpty ? name[0] : ''}${surname.isNotEmpty ? surname[0] : ''}".toUpperCase();

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
                  )
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
                                  Text("$name $surname",
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text(email,
                                      style: TextStyle(
                                          color: Colors.grey.shade600)),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 8,
                                    children: [
                                      Chip(
                                        label: Text(role),
                                        avatar: const Icon(Icons.shield, size: 16),
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
                                            Text("Lid sedert ${createdDate.toString().split(' ').first}"),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            )
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
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text("Huidige Rol: $role",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 4),
                            Text(
                              status == "aktief"
                                  ? "Jy het volledige toegang tot die stelsel"
                                  : "Beperkte toegang totdat rekening goedgekeur word",
                              style: TextStyle(color: Colors.grey.shade600),
                            )
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
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            Spacing.vGap20,

                            const NameFields(),
                            Spacing.vGap16,
                            const EmailField(),
                            Spacing.vGap16,
                            const CellphoneField(),
                            Spacing.vGap16,
                            const RoleDropdown(),
                            Spacing.vGap16,
                            const LocationDropdown(),
                            Spacing.vGap16,
                            const PasswordField(),
                            Spacing.vGap16,
                            const PasswordField(isConfirmPassword: true),
                            Spacing.vGap24,

                            SpysPrimaryButton(
                              text: "Stoor",
                              onPressed: isFormValid ? () {
                                // Save updated info
                              } : null,
                            )
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
                            const Text("Rekening Aktiwiteit",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            _buildActivityRow("Rekening geskep:", createdDate.toString().split(' ').first),
                            _buildActivityRow("Laaste aktiwiteit:", lastActive?.toString().split(' ').first ?? "Onbekend"),
                            _buildActivityRow("Rol:", role),
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
      )
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
