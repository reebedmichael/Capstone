import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'home/home_screen.dart';
import 'menu/menu_screen.dart';
import 'cart/cart_screen.dart';
import 'orders/orders_screen.dart';
import 'wallet/wallet_screen.dart';
import 'feedback/feedback_screen.dart';
import 'profile/profile_screen.dart';

class StudentApp extends StatelessWidget {
  const StudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spys',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      initialRoute: '/home',
      routes: {
        '/home': (context) => const StudentHomeScreen(),
        '/menu': (context) => const MenuScreen(),
        '/cart': (context) => const CartScreen(),
        '/orders': (context) => const OrdersScreen(),
        '/wallet': (context) => const WalletScreen(),
        '/feedback': (context) => const FeedbackScreen(),
        '/profile': (context) => const ProfileScreen(),
      },
    );
  }
} 