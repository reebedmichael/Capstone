import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'menu_management/menu_management_screen.dart';
import 'order_management/order_management_screen.dart';
import 'user_management/user_management_screen.dart';
import 'feedback_reports/feedback_reports_screen.dart';
import 'inventory/inventory_screen.dart';
import 'settings/settings_screen.dart';

/// Admin application for web platform
/// Provides comprehensive management interface for restaurant operations
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
        // Main admin dashboard with side navigation
        '/dashboard': (context) => const AdminDashboardScreen(),
        // Menu management - add, edit, delete menu items
        '/menu-management': (context) => const MenuManagementScreen(),
        // Order management - view and process orders
        '/order-management': (context) => const OrderManagementScreen(),
        // User management - manage students and staff
        '/user-management': (context) => const UserManagementScreen(),
        // Feedback and analytics - customer reviews and reports
        '/feedback-reports': (context) => const FeedbackReportsScreen(),
        // Inventory management - track stock levels
        '/inventory': (context) => const InventoryScreen(),
        // Settings - app configuration and admin preferences
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
} 