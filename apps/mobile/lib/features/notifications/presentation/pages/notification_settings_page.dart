import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/services/notification_service.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() => _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _isLoading = true;
  bool _notificationsEnabled = false;
  bool _pushNotificationsEnabled = false;
  
  // Per-category notification preferences
  bool _orderNotifications = true;
  bool _walletNotifications = true;
  bool _allowanceNotifications = true;
  bool _approvalNotifications = true;
  bool _generalNotifications = true;
  
  String? _fcmToken;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      // Check notification permission status
      final notificationStatus = await Permission.notification.status;
      _notificationsEnabled = notificationStatus.isGranted;
      
      // Check if user has FCM token (indicates push notifications are set up)
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userData = await Supabase.instance.client
            .from('gebruikers')
            .select('fcm_token')
            .eq('gebr_id', user.id)
            .maybeSingle();
        
        _fcmToken = userData?['fcm_token'];
        _pushNotificationsEnabled = _fcmToken != null && _fcmToken!.isNotEmpty;
      }
      
      // Load category preferences from shared preferences
      final prefs = await SharedPreferences.getInstance();
      _orderNotifications = prefs.getBool('notif_orders') ?? true;
      _walletNotifications = prefs.getBool('notif_wallet') ?? true;
      _allowanceNotifications = prefs.getBool('notif_allowance') ?? true;
      _approvalNotifications = prefs.getBool('notif_approval') ?? true;
      _generalNotifications = prefs.getBool('notif_general') ?? true;
    } catch (e) {
      print('Error loading notification settings: $e');
    }
    
    setState(() => _isLoading = false);
  }
  
  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    
    if (status.isGranted) {
      setState(() => _notificationsEnabled = true);
      _showSnackBar('Kennisgewings geaktiveer! 🎉', Colors.green);
      
      // Reinitialize notification service to set up FCM
      await NotificationService().initialize();
      await _loadSettings(); // Reload to check FCM token
    } else if (status.isDenied) {
      _showSnackBar('Toestemming geweier', Colors.orange);
    } else if (status.isPermanentlyDenied) {
      _showSettingsDialog();
    }
  }
  
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Toestemming Benodig'),
        content: const Text(
          'Kennisgewings is permanent geweier. '
          'Gaan na jou toestel se instellings om toestemmings te verander.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kanselleer'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              AppSettings.openAppSettings(type: AppSettingsType.notification);
            },
            child: const Text('Open Instellings'),
          ),
        ],
      ),
    );
  }
  
  void _openPhoneNotificationSettings() {
    AppSettings.openAppSettings(type: AppSettingsType.notification);
  }
  
  Future<void> _saveCategoryPreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
  
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/settings'),
          ),
          title: const Text('Kennisgewing Instellings'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/settings'),
        ),
        title: const Text('Kennisgewing Instellings'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // System Notifications Status
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _notificationsEnabled 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _notificationsEnabled 
                          ? Icons.notifications_active
                          : Icons.notifications_off,
                      color: _notificationsEnabled ? Colors.green : Colors.orange,
                    ),
                  ),
                  title: Text(
                    _notificationsEnabled 
                        ? 'Kennisgewings Geaktiveer'
                        : 'Kennisgewings Gedeaktiveer',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _notificationsEnabled
                        ? 'Jy ontvang tans kennisgewings'
                        : 'Aktiveer om kennisgewings te ontvang',
                  ),
                ),
                if (!_notificationsEnabled)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: FilledButton.icon(
                      onPressed: _requestNotificationPermission,
                      icon: const Icon(Icons.notifications_active),
                      label: const Text('Aktiveer Kennisgewings'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Push Notifications Status
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _pushNotificationsEnabled 
                          ? Colors.blue.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _pushNotificationsEnabled 
                          ? Icons.cloud_done
                          : Icons.cloud_off,
                      color: _pushNotificationsEnabled ? Colors.blue : Colors.grey,
                    ),
                  ),
                  title: Text(
                    _pushNotificationsEnabled 
                        ? 'Push Kennisgewings Aktief'
                        : 'Push Kennisgewings Nie Aktief',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    _pushNotificationsEnabled
                        ? 'Jy sal kennisgewings ontvang selfs as die app toe is'
                        : 'Teken aan om push kennisgewings te aktiveer',
                  ),
                ),
                if (_pushNotificationsEnabled)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Toestel geregistreer',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Quick Action: Phone Settings
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings, color: Colors.deepPurple),
              title: const Text('Konfigueer Toestel Kennisgewings'),
              subtitle: const Text('Open toestel instellings om kennisgewings te bestuur'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _openPhoneNotificationSettings,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              'Kennisgewing Kategorieë',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Category Preferences
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(FeatherIcons.shoppingBag, color: Colors.blue, size: 20),
                  ),
                  title: const Text('Bestelling Kennisgewings'),
                  subtitle: const Text('Status opdaterings van jou bestellings'),
                  value: _orderNotifications,
                  onChanged: (value) {
                    setState(() => _orderNotifications = value);
                    _saveCategoryPreference('notif_orders', value);
                    _showSnackBar(
                      value ? 'Bestelling kennisgewings aan' : 'Bestelling kennisgewings af',
                      value ? Colors.green : Colors.grey,
                    );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(FeatherIcons.creditCard, color: Colors.green, size: 20),
                  ),
                  title: const Text('Beursie Kennisgewings'),
                  subtitle: const Text('Balans opdaterings en transaksies'),
                  value: _walletNotifications,
                  onChanged: (value) {
                    setState(() => _walletNotifications = value);
                    _saveCategoryPreference('notif_wallet', value);
                    _showSnackBar(
                      value ? 'Beursie kennisgewings aan' : 'Beursie kennisgewings af',
                      value ? Colors.green : Colors.grey,
                    );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(FeatherIcons.gift, color: Colors.purple, size: 20),
                  ),
                  title: const Text('Toelae Kennisgewings'),
                  subtitle: const Text('Maandelikse toelae en toelaag opdaterings'),
                  value: _allowanceNotifications,
                  onChanged: (value) {
                    setState(() => _allowanceNotifications = value);
                    _saveCategoryPreference('notif_allowance', value);
                    _showSnackBar(
                      value ? 'Toelae kennisgewings aan' : 'Toelae kennisgewings af',
                      value ? Colors.green : Colors.grey,
                    );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(FeatherIcons.checkCircle, color: Colors.orange, size: 20),
                  ),
                  title: const Text('Goedkeuring Kennisgewings'),
                  subtitle: const Text('Rekening goedkeurings en status veranderinge'),
                  value: _approvalNotifications,
                  onChanged: (value) {
                    setState(() => _approvalNotifications = value);
                    _saveCategoryPreference('notif_approval', value);
                    _showSnackBar(
                      value ? 'Goedkeuring kennisgewings aan' : 'Goedkeuring kennisgewings af',
                      value ? Colors.green : Colors.grey,
                    );
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.teal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(FeatherIcons.info, color: Colors.teal, size: 20),
                  ),
                  title: const Text('Algemene Kennisgewings'),
                  subtitle: const Text('Sisteem aankondigings en opdaterings'),
                  value: _generalNotifications,
                  onChanged: (value) {
                    setState(() => _generalNotifications = value);
                    _saveCategoryPreference('notif_general', value);
                    _showSnackBar(
                      value ? 'Algemene kennisgewings aan' : 'Algemene kennisgewings af',
                      value ? Colors.green : Colors.grey,
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Information Card
          Card(
            color: Colors.blue.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Oor Kennisgewings',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Push kennisgewings werk selfs as die app toe is\n'
                    '• Jy kan kategorieë individueel beheer\n'
                    '• Toestel instellings oorheers app instellings\n'
                    '• Belangrike kennisgewings kan nie afgeskakel word nie',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

