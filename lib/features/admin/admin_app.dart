import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dashboard/dashboard_screen.dart';
import 'menu_management/menu_management_screen.dart';
import 'order_management/order_management_screen.dart';
import 'user_management/user_management_screen.dart';
import 'feedback_reports/feedback_reports_screen.dart';
import 'inventory/inventory_screen.dart';
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
  final String title;
  final IconData icon;
  final Widget screen;
  const _AdminNavItem(this.title, this.icon, this.screen);
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
    final List<_AdminNavItem> navItems = [
      _AdminNavItem('Dashboard', Icons.dashboard, const AdminDashboardScreen()),
      _AdminNavItem('Menu', Icons.restaurant_menu, const MenuManagementScreen()),
      _AdminNavItem('Orders', Icons.shopping_cart, const OrderManagementScreen()),
      _AdminNavItem('Users', Icons.people, const UserManagementScreen()),
      _AdminNavItem('Feedback', Icons.analytics, const FeedbackReportsScreen()),
      _AdminNavItem('Inventory', Icons.inventory, const InventoryScreen()),
      _AdminNavItem('Settings', Icons.settings, AdminSettingsScreen(onNavItemSelected: _onNavItemSelected)),
      _AdminNavItem('About', Icons.info_outline, const AdminAboutScreen()),
      _AdminNavItem('Help', Icons.help_outline, const AdminHelpScreen()),
      _AdminNavItem('Terms', Icons.privacy_tip_outlined, const AdminTermsScreen()),
    ];

    final isWide = MediaQuery.of(context).size.width >= 900 || kIsWeb;

    Widget navRail = Container(
      color: Colors.grey[50],
      child: NavigationRail(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onNavItemSelected,
        labelType: NavigationRailLabelType.all,
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 16),
          child: CircleAvatar(
            radius: 28,
            backgroundColor: Theme.of(context).primaryColor,
            child: Icon(Icons.fastfood, color: Colors.white, size: 32),
          ),
        ),
        groupAlignment: -1.0,
        destinations: navItems
            .map((item) => NavigationRailDestination(
                  icon: Icon(item.icon, color: _selectedIndex == navItems.indexOf(item) ? Theme.of(context).primaryColor : Colors.grey[600]),
                  selectedIcon: Icon(item.icon, color: Theme.of(context).primaryColor, size: 28),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(item.title, style: TextStyle(fontWeight: _selectedIndex == navItems.indexOf(item) ? FontWeight.bold : FontWeight.normal)),
                  ),
                ))
            .toList(),
        selectedLabelTextStyle: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
        unselectedLabelTextStyle: TextStyle(color: Colors.grey[700]),
        minWidth: 60,
        minExtendedWidth: 180,
        elevation: 2,
      ),
    );

    Widget drawer = Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Icon(Icons.fastfood, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 12),
                Text('Admin Navigation', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
          ),
          for (int i = 0; i < navItems.length; i++)
            ListTile(
              leading: Icon(navItems[i].icon, color: _selectedIndex == i ? Theme.of(context).primaryColor : Colors.grey[700]),
              title: Text(navItems[i].title, style: TextStyle(fontWeight: _selectedIndex == i ? FontWeight.bold : FontWeight.normal)),
              selected: _selectedIndex == i,
              onTap: () {
                Navigator.pop(context);
                _onNavItemSelected(i);
              },
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
} 