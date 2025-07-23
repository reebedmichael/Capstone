import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:spys/l10n/app_localizations.dart';
import '../../core/utils/locale_provider.dart';
import 'dashboard/dashboard_screen.dart';
import 'menu_management/menu_management_screen.dart';
import 'order_management/order_management_screen.dart';
import 'user_management/user_management_screen.dart';
import 'feedback_reports/feedback_reports_screen.dart';
import 'settings/settings_screen.dart';
import 'about/about_screen.dart';
import 'help/help_screen.dart';
import 'terms/terms_screen.dart';

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminNavItem {
  final String titleKey;
  final IconData icon;
  final Widget screen;
  const _AdminNavItem(this.titleKey, this.icon, this.screen);
}

class _AdminAppState extends State<AdminApp> {
  int _selectedIndex = 0;

  void _onNavItemSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    final List<_AdminNavItem> navItems = [
      const _AdminNavItem('dashboard', Icons.dashboard, AdminDashboardScreen()),
      const _AdminNavItem('menu', Icons.restaurant_menu, MenuManagementScreen()),
      const _AdminNavItem('orders', Icons.shopping_cart, OrderManagementScreen()),
      const _AdminNavItem('users', Icons.people, UserManagementScreen()),
      const _AdminNavItem('feedback', Icons.analytics, FeedbackReportsScreen()),
      _AdminNavItem('settings', Icons.settings, AdminSettingsScreen(onNavItemSelected: _onNavItemSelected)),
      const _AdminNavItem('about', Icons.info_outline, AdminAboutScreen()),
      const _AdminNavItem('help', Icons.help_outline, AdminHelpScreen()),
      const _AdminNavItem('terms', Icons.privacy_tip_outlined, AdminTermsScreen()),
    ];

    final isWide = MediaQuery.of(context).size.width >= 900 || kIsWeb;
    final localeProvider = Provider.of<LocaleProvider>(context);

    Widget navRail = Container(
      decoration: BoxDecoration(
        color: Theme.of(context).navigationRailTheme.backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with logo and language switch
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Logo
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        const Color(0xFFE64A19), // Dark orange accent
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.fastfood,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                // App title
                Text(
                  'Spys Admin',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                // Language switch button
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      final newLocale = localeProvider.locale.languageCode == 'af' 
                          ? const Locale('en') 
                          : const Locale('af');
                      localeProvider.setLocale(newLocale);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.language,
                            size: 14,
                            color: Theme.of(context).primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            localeProvider.locale.languageCode.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Navigation items
          Expanded(
            child: NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: _onNavItemSelected,
              labelType: NavigationRailLabelType.all,
              backgroundColor: Colors.transparent,
              groupAlignment: -1.0,
              minWidth: 80,
              minExtendedWidth: 200,
              destinations: navItems.map((item) {
                final isSelected = _selectedIndex == navItems.indexOf(item);
                return NavigationRailDestination(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Theme.of(context).primaryColor.withOpacity(0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.icon,
                      color: isSelected 
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).primaryColor.withOpacity(0.6),
                      size: isSelected ? 24 : 20,
                    ),
                  ),
                  selectedIcon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.icon,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      _getLocalizedTitle(item.titleKey, loc),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 11,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(16),
            child: Text(
              'v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).primaryColor.withOpacity(0.5),
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );

    Widget drawer = Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  const Color(0xFFFF5722), // Orange red gradient
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.fastfood,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Spys Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                // Language switch in drawer
                InkWell(
                  onTap: () {
                    final newLocale = localeProvider.locale.languageCode == 'af' 
                        ? const Locale('en') 
                        : const Locale('af');
                    localeProvider.setLocale(newLocale);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.language, size: 16, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          localeProvider.locale.languageCode.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (int i = 0; i < navItems.length; i++)
                  ListTile(
                    leading: Icon(
                      navItems[i].icon,
                      color: _selectedIndex == i 
                          ? Theme.of(context).primaryColor 
                          : Theme.of(context).primaryColor.withOpacity(0.7),
                    ),
                    title: Text(
                      _getLocalizedTitle(navItems[i].titleKey, loc),
                      style: TextStyle(
                        fontWeight: _selectedIndex == i ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    selected: _selectedIndex == i,
                    selectedTileColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    onTap: () {
                      Navigator.pop(context);
                      _onNavItemSelected(i);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      drawer: isWide ? null : drawer,
      body: Row(
        children: [
          if (isWide) navRail,
          Expanded(child: navItems[_selectedIndex].screen),
        ],
      ),
    );
  }

  String _getLocalizedTitle(String key, AppLocalizations? loc) {
    switch (key) {
      case 'dashboard':
        return loc?.dashboard ?? 'Dashboard';
      case 'menu':
        return loc?.menu ?? 'Menu';
      case 'orders':
        return loc?.orders ?? 'Orders';
      case 'users':
        return loc?.users ?? 'Users';
      case 'feedback':
        return loc?.feedback ?? 'Feedback';
      case 'settings':
        return loc?.settings ?? 'Settings';
      case 'about':
        return loc?.about ?? 'About';
      case 'help':
        return loc?.help ?? 'Help';
      case 'terms':
        return loc?.terms ?? 'Terms';
      default:
        return key;
    }
  }
} 
