import 'package:flutter/material.dart';
import 'home/home_screen.dart';
import 'menu/menu_screen.dart';
import 'cart/cart_screen.dart';
import 'orders/orders_screen.dart';
import 'wallet/wallet_screen.dart';
import 'feedback/feedback_screen.dart';
import 'profile/profile_screen.dart';
import 'notifications/notifications_screen.dart';
import 'support/support_screen.dart';
import 'settings/settings_screen.dart';

class StudentApp extends StatelessWidget {
  const StudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: '/home',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/home':
            return MaterialPageRoute(builder: (_) => const StudentHomeScreen());
          case '/menu':
            return MaterialPageRoute(builder: (_) => const MenuScreen());
          case '/cart':
            return MaterialPageRoute(builder: (_) => const CartScreen());
          case '/orders':
            return MaterialPageRoute(builder: (_) => const OrdersScreen());
          case '/order-detail':
            return MaterialPageRoute(builder: (_) => const OrdersScreen());
          case '/wallet':
            return MaterialPageRoute(builder: (_) => const WalletScreen());
          case '/feedback':
            return MaterialPageRoute(builder: (_) => const FeedbackScreen());
          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfileScreen());
          case '/notifications':
            return MaterialPageRoute(builder: (_) => const NotificationsScreen());
          case '/support':
            return MaterialPageRoute(builder: (_) => const SupportScreen());
          case '/settings':
            return MaterialPageRoute(builder: (_) => const SettingsScreen());
          default:
            return MaterialPageRoute(builder: (_) => const StudentHomeScreen());
        }
      },
    );
  }
} 