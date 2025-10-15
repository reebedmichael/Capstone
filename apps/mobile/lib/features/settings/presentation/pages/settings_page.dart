import 'package:capstone_mobile/features/app/presentation/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart';
import 'package:spys_api_client/src/notification_archive_service.dart';
import '../../../../shared/services/qr_service.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/providers/theme_provider.dart';
import '../../../../shared/widgets/simple_otp_dialog.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String language = 'af';
  bool isDeleting = false;
  bool _isTertiaryAdmin = false;
  bool _isLoadingAdminStatus = true;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _isLoadingAdminStatus = false);
        return;
      }

      final qrService = QrService(Supabase.instance.client);
      final isAdmin = await qrService.isTertiaryAdmin(user.id);
      
      setState(() {
        _isTertiaryAdmin = isAdmin;
        _isLoadingAdminStatus = false;
      });
    } catch (e) {
      setState(() => _isLoadingAdminStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text("Instellings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Appearance
          _buildCard(
            title: "Voorkoms",
            icon: Icons.wb_sunny,
            children: [
              Consumer(
                builder: (context, ref, child) {
                  final isDarkMode = ref.watch(isDarkModeProvider);
                  return SwitchListTile(
                    title: const Text("Donker Modus"),
                    subtitle: const Text("Verander na donker tema"),
                    value: isDarkMode,
                    onChanged: (val) {
                      ref.read(themeProvider.notifier).toggleTheme();
                    },
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text("Taal"),
                subtitle: const Text("Kies jou voorkeur taal"),
                trailing: DropdownButton<String>(
                  value: language,
                  items: const [
                    DropdownMenuItem(value: 'af', child: Text("Afrikaans")),
                    DropdownMenuItem(value: 'en', child: Text("English")),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => language = val);
                  },
                ),
              ),
            ],
          ),

          // Notifications - Functional notification controls
          _buildCard(
            title: "Kennisgewings",
            icon: Icons.notifications,
            children: [
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text("Kennisgewings Beheer"),
                subtitle: const Text("Bekyk en beheer jou kennisgewings"),
                onTap: () => context.go('/notifications'),
              ),
              ListTile(
                leading: const Icon(Icons.mark_email_read),
                title: const Text("Merk Alles as Gelees"),
                subtitle: const Text("Merk alle kennisgewings as gelees"),
                onTap: () => _markAllAsRead(),
              ),
              ListTile(
                leading: const Icon(Icons.archive),
                title: const Text("Argiveer Kennisgewings"),
                subtitle: const Text("Argiveer alle gelees kennisgewings"),
                onTap: () => _clearReadNotifications(),
              ),
            ],
          ),

          // Security
          _buildCard(
            title: "Sekuriteit",
            icon: Icons.security,
            children: [
              ListTile(
                leading: const Icon(Icons.vpn_key),
                title: const Text("Verander Wagwoord"),
                onTap: () => _handlePasswordReset(context),
              ),
            ],
          ),

          // Admin Tools (only for tertiary admins)
          if (_isTertiaryAdmin && !_isLoadingAdminStatus)
            _buildCard(
              title: "Admin Gereedskap",
              icon: Icons.admin_panel_settings,
              children: [
                ListTile(
                  leading: const Icon(Icons.qr_code_scanner),
                  title: const Text("Skandeer QR Kode"),
                  subtitle: const Text("Skandeer voedseel items vir afhaal"),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Admin",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  onTap: () => context.go('/scan'),
                ),
              ],
            ),


          // Help & Support
          _buildCard(
            title: "Hulp & Ondersteuning",
            icon: Icons.help,
            children: [
              ListTile(
                leading: const Icon(Icons.help),
                title: const Text("Hulp & FAQ"),
                onTap: () => context.go('/help'),
              ),
            ],
          ),

          

          // Danger Zone
          Card(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  title: Text(
                    "Gevaar Sone",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "Hierdie aksies kan nie ongedaan gemaak word nie. Wees versigtig.",
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
                  title: Text(
                    "Teken Uit",
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  onTap: () => context.go('/auth/login'),
                ),
                ListTile(
                  leading: Icon(Icons.delete, color: Theme.of(context).colorScheme.error),
                  title: Text(
                    isDeleting
                        ? "Klik weer om te bevestig"
                        : "Verwyder Rekening",
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  onTap: () {
                    if (isDeleting) {
                      _showConfirmationDialog(context);
                    } else {
                      setState(() => isDeleting = !isDeleting);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(
                  "Spys App Weergawe 1.0.0",
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                Text("© 2025 Akademia", style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 4),
    );
  }

  // Confirmation dialog method
  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Bevestig'),
          content: const Text('Is jy seker jy wil jou rekening verwyder?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Close the dialog if user cancels
                Navigator.of(context).pop();
              },
              child: const Text('Kanselleer'),
            ),
            TextButton(
              onPressed: () {
                // Navigate to the registration screen when confirmed
                Navigator.of(context).pop(); // Close the dialog
                context.go('/auth/register'); // Navigate to register screen
              },
              child: const Text('Ja'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _markAllAsRead() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        Fluttertoast.showToast(
          msg: 'Jy moet ingeteken wees',
          backgroundColor: Theme.of(context).colorScheme.error,
        );
        return;
      }

      final kennisgewingRepo = KennisgewingRepository(SupabaseDb(Supabase.instance.client));
      final success = await kennisgewingRepo.markeerAllesAsGelees(user.id);
      
      if (success) {
        Fluttertoast.showToast(
          msg: 'Alle kennisgewings gemerk as gelees',
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        );
      } else {
        Fluttertoast.showToast(
          msg: 'Kon nie kennisgewings merk nie',
          backgroundColor: Theme.of(context).colorScheme.secondary,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Fout: ${e.toString()}',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  Future<void> _clearReadNotifications() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        Fluttertoast.showToast(
          msg: 'Jy moet ingeteken wees',
          backgroundColor: Theme.of(context).colorScheme.error,
        );
        return;
      }

      // Get all read notifications and archive them locally
      final kennisgewingRepo = KennisgewingRepository(SupabaseDb(Supabase.instance.client));
      final readNotifications = await kennisgewingRepo.kryKennisgewings(user.id);
      
      final readNotificationIds = readNotifications
          .where((notification) => notification['kennis_gelees'] == true)
          .map((notification) => notification['kennis_id'].toString())
          .toList();
      
      if (readNotificationIds.isNotEmpty) {
        final success = await NotificationArchiveService.archiveNotifications(readNotificationIds);
        
        if (success) {
          Fluttertoast.showToast(
            msg: '${readNotificationIds.length} gelees kennisgewings geargiveer',
            backgroundColor: Theme.of(context).colorScheme.tertiary,
          );
        } else {
          Fluttertoast.showToast(
            msg: 'Fout met argiveer kennisgewings',
            backgroundColor: Theme.of(context).colorScheme.error,
          );
        }
      } else {
        Fluttertoast.showToast(
          msg: 'Geen gelees kennisgewings om te argiveer',
          backgroundColor: Theme.of(context).colorScheme.tertiary,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Fout: ${e.toString()}',
        backgroundColor: Theme.of(context).colorScheme.error,
      );
    }
  }

  Future<void> _handlePasswordReset(BuildContext context) async {
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (currentUser?.email == null) {
      _showToast("Geen e-pos adres gevind vir huidige gebruiker", Colors.red);
      return;
    }

    try {
      _showToast("Stuur herstel e-pos...", Colors.blue);

      final authService = AuthService();
      await authService.resetPassword(email: currentUser!.email!);

      _showToast("Herstel e-pos gestuur!", Colors.green);

      // Show OTP dialog after email is sent
      showDialog(
        context: context,
        builder: (context) => SimpleOtpDialog(
          email: currentUser.email!,
          onSuccess: () async {
            Navigator.of(context).pop();
            _showToast("Navigeer na wagwoord herstel bladsy...", Colors.blue);
            await Future.delayed(const Duration(milliseconds: 500));
            if (mounted) {
              context.go('/password-reset');
            }
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        ),
      );
      
    } catch (e) {
      _showToast("Fout met stuur van herstel e-pos: ${e.toString()}", Colors.red);
    }
  }

  void _showToast(String message, Color color) {
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: color,
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: Icon(icon),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...children,
        ],
      ),
    );
  }
}
