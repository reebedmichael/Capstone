import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'menu_management/menu_management_screen.dart';
import 'order_management/order_management_screen.dart';
import 'user_management/user_management_screen.dart';
import 'feedback_reports/feedback_reports_screen.dart';
import 'inventory/inventory_screen.dart';
import 'settings/settings_screen.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spys Admin',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/dashboard',
      routes: {
        '/dashboard': (context) => const AdminDashboardScreen(),
        '/menu-management': (context) => const MenuManagementScreen(),
        '/order-management': (context) => const OrderManagementScreen(),
        '/user-management': (context) => const UserManagementScreen(),
        '/feedback-reports': (context) => const FeedbackReportsScreen(),
        '/inventory': (context) => const InventoryScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
} 