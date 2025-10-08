import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../core/theme/app_theme.dart';
import '../../../shared/providers/auth_providers.dart';
import '../../../shared/widgets/otp_verification_dialog.dart';

// Provider for managing password reset cooldown timer
final passwordResetCooldownProvider =
    StateNotifierProvider<PasswordResetCooldownNotifier, int>((ref) {
      return PasswordResetCooldownNotifier();
    });

class PasswordResetCooldownNotifier extends StateNotifier<int> {
  PasswordResetCooldownNotifier() : super(0);

  Timer? _timer;

  void startCooldown() {
    state = 30; // 30 seconds cooldown
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state > 0) {
        state = state - 1;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class InstellingsPage extends ConsumerWidget {
  const InstellingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);
    final isDarkMode = theme.themeMode == ThemeMode.dark;
    final cooldownSeconds = ref.watch(passwordResetCooldownProvider);

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Instellings",
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Bestuur jou rekening en stelsel voorkeure",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Tema Instellings
                  _buildCard(
                    context,
                    icon: Icons.dark_mode,
                    title: "Tema Voorkeure",
                    description: "Kies tussen lig en donker modus",
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Donker Modus",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "Skakel tussen lig en donker tema",
                              style: TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        Switch(
                          value: isDarkMode,
                          onChanged: (value) {
                            final newThemeMode = value
                                ? ThemeMode.dark
                                : ThemeMode.light;
                            ref
                                .read(appThemeProvider.notifier)
                                .setThemeMode(newThemeMode);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Taal Instellings
                  _buildCard(
                    context,
                    icon: Icons.language,
                    title: "Taal Voorkeure",
                    description: "Kies jou voorkeur taal vir die stelsel",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Stelsel Taal",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: "afrikaans",
                          items: const [
                            DropdownMenuItem(
                              value: "afrikaans",
                              child: Text("Afrikaans"),
                            ),
                            DropdownMenuItem(
                              value: "engels",
                              child: Text("Engels"),
                            ),
                          ],
                          onChanged: (_) {
                            // 🔹 Koppel aan app state vir taal
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "Hierdie instelling sal plaaslik gestoor word en geld net vir hierdie sessie",
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Wagwoord herstel
                  _buildCard(
                    context,
                    icon: Icons.lock_reset,
                    title: "Wagwoord herstel",
                    description:
                        "Klik hieronder om 'n herstel e-pos vir jou wagwoord te ontvang",
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: cooldownSeconds > 0
                            ? null
                            : () => _handlePasswordReset(context, ref),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cooldownSeconds > 0
                              ? Colors.grey
                              : Theme.of(context).primaryColor,
                        ),
                        child: cooldownSeconds > 0
                            ? Text("Wag ${cooldownSeconds}s")
                            : const Text("Stuur herstel e-pos"),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sekuriteit Wenke
                  _buildCard(
                    context,
                    title: "Sekuriteit Wenke",
                    description:
                        "Belangrike inligting oor jou rekening sekuriteit",
                    child: Column(
                      children: [
                        _buildInfoTile(
                          context,
                          icon: Icons.info_outline,
                          color: Colors.blue,
                          text:
                              "Wagwoord Vereistes: Gebruik ten minste 8 karakters met 'n kombinasie van groot letters, klein letters en syfers.",
                        ),
                        const SizedBox(height: 12),
                        _buildInfoTile(
                          context,
                          icon: Icons.check_circle,
                          color: Colors.green,
                          text:
                              "Plaaslike Berging: Jou tema en taal voorkeure word plaaslik gestoor en sal behou word vir hierdie sessie.",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    IconData? icon,
    required String title,
    required String description,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) Icon(icon, size: 20),
                if (icon != null) const SizedBox(width: 8),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePasswordReset(BuildContext context, WidgetRef ref) async {
    final authService = ref.read(authServiceProvider);
    final currentUser = authService.currentUser;

    if (currentUser?.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Geen e-pos adres gevind vir huidige gebruiker"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text("Stuur herstel e-pos..."),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      await authService.resetPassword(email: currentUser!.email!);

      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // Start cooldown timer
      ref.read(passwordResetCooldownProvider.notifier).startCooldown();

      // Show OTP verification dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => OtpVerificationDialog(
          email: currentUser.email!,
          onSuccess: () {
            // Navigate to password reset page
            context.go('/wagwoord_herstel');
          },
          onCancel: () {
            // Just close the dialog and stay on settings page
            Navigator.of(context).pop();
          },
          onLogout: () {
            // User was logged out due to too many failed attempts
            context.go('/teken_in');
          },
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Fout met stuur van herstel e-pos: ${e.toString()}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
