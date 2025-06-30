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
      home: const StudentMainScreen(),
      // Add subpage routes here if needed
    );
  }
}

/// Main screen that manages bottom navigation using IndexedStack
/// This approach maintains state for each tab and prevents navigation stack buildup
class StudentMainScreen extends StatefulWidget {
  const StudentMainScreen({super.key});

  @override
  State<StudentMainScreen> createState() => _StudentMainScreenState();
}

class _StudentMainScreenState extends State<StudentMainScreen> {
  int _currentIndex = 0;

  // All main tab screens - IndexedStack will maintain their state
  final List<Widget> _screens = const [
    StudentHomeScreen(),    // Home tab - welcome and quick actions
    MenuScreen(),          // Menu tab - browse and order food
    CartScreen(),          // Cart tab - review and checkout
    OrdersScreen(),        // Orders tab - order history and tracking
    WalletScreen(),        // Wallet tab - balance and transactions
    FeedbackScreen(),      // Feedback tab - ratings and reviews
    ProfileScreen(),       // Profile tab - user settings and info
  ];

  // Bottom navigation bar items configuration
  final List<BottomNavigationBarItem> _navItems = const [
    BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
    BottomNavigationBarItem(icon: Icon(Icons.restaurant_menu), label: 'Menu'),
    BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
    BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Orders'),
    BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
    BottomNavigationBarItem(icon: Icon(Icons.feedback), label: 'Feedback'),
    BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _navItems,
      ),
    );
  }
} 