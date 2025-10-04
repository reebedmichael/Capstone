import 'package:capstone_mobile/features/app/presentation/widgets/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/services/qr_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool isDarkMode = false;
  String language = 'af';
  bool orderUpdates = true;
  bool menuAlerts = true;
  bool allowanceReminders = true;
  bool promotions = false;
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
              SwitchListTile(
                title: const Text("Donker Modus"),
                subtitle: const Text("Verander na donker tema"),
                value: isDarkMode,
                onChanged: (val) {
                  setState(() => isDarkMode = val);
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

          // Notifications
          _buildCard(
            title: "Kennisgewings",
            icon: Icons.notifications,
            children: [
              SwitchListTile(
                title: const Text("Bestelling Opdaterings"),
                subtitle: const Text(
                  "Ontvang kennisgewings oor jou bestellings",
                ),
                value: orderUpdates,
                onChanged: (val) => setState(() => orderUpdates = val),
              ),
              SwitchListTile(
                title: const Text("Spyskaart Kennisgewings"),
                subtitle: const Text("Nuwe items en spyskaart veranderinge"),
                value: menuAlerts,
                onChanged: (val) => setState(() => menuAlerts = val),
              ),
              SwitchListTile(
                title: const Text("Toelae Herinneringe"),
                subtitle: const Text(
                  "Maandelikse toelae en balans opdaterings",
                ),
                value: allowanceReminders,
                onChanged: (val) => setState(() => allowanceReminders = val),
              ),
              SwitchListTile(
                title: const Text("Promosies & Aanbiedinge"),
                subtitle: const Text("Spesiale aanbiedinge en afslag"),
                value: promotions,
                onChanged: (val) => setState(() => promotions = val),
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
                onTap: () {
                  Fluttertoast.showToast(
                    gravity: ToastGravity.TOP,
                    msg: 'Wagwoord verander e-pos gestuur!',
                  );
                },
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
                      color: Colors.purple.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Admin",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                  onTap: () => context.go('/scan'),
                ),
              ],
            ),

          // Quick Access
          _buildCard(
            title: "Vinnige Toegang",
            icon: Icons.flash_on,
            children: [
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text("My Profiel"),
                onTap: () => context.go('/profile'),
              ),
              ListTile(
                leading: const Icon(Icons.account_balance_wallet),
                title: const Text("Beursie"),
                onTap: () => context.go('/wallet'),
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long),
                title: const Text("My Bestellings"),
                onTap: () => context.go('/orders'),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text("Maandelikse Toelae"),
                onTap: () => context.go('/allowance'),
              ),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text("Kennisgewings"),
                onTap: () => context.go('/notifications'),
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

          // Data Management
          _buildCard(
            title: "Data Bestuur",
            icon: Icons.storage,
            children: [
              ListTile(
                leading: const Icon(Icons.download),
                title: const Text("Eksporteer My Data"),
                onTap: () {
                  Fluttertoast.showToast(
                    gravity: ToastGravity.TOP,
                    msg: "Jou data word ge-eksporteer. Jy sa 'n epos ontvang!",
                  );
                },
              ),
            ],
          ),

          // Danger Zone
          Card(
            color: Colors.red.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ListTile(
                  title: Text(
                    "Gevaar Sone",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "Hierdie aksies kan nie ongedaan gemaak word nie. Wees versigtig.",
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    "Teken Uit",
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => context.go('/auth/login'),
                ),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: Text(
                    isDeleting
                        ? "Klik weer om te bevestig"
                        : "Verwyder Rekening",
                    style: const TextStyle(color: Colors.red),
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
          const Center(
            child: Column(
              children: [
                Text(
                  "Spys App Weergawe 1.0.0",
                  style: TextStyle(color: Colors.grey),
                ),
                Text("© 2025 Akademia", style: TextStyle(color: Colors.grey)),
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
