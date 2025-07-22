import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../services/auth_service.dart';
import '../../../models/user.dart';
import '../../../services/notification_service.dart';
import '../../../models/notification.dart';
import '../menu/menu_screen.dart';
import '../cart/cart_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../../core/utils/color_utils.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;
  final _notificationService = NotificationService();

  final List<Widget> _screens = [
    StudentHomeScreenContent(),
    MenuScreen(),
    CartScreen(),
    OrdersScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
  }

  final List<BottomNavigationItem> _navigationItems = [
    BottomNavigationItem(
      icon: Icons.home,
      label: 'Home',
      route: '/home',
    ),
    BottomNavigationItem(
      icon: Icons.restaurant_menu,
      label: 'Menu',
      route: '/menu',
    ),
    BottomNavigationItem(
      icon: Icons.shopping_cart,
      label: 'Cart',
      route: '/cart',
    ),
    BottomNavigationItem(
      icon: Icons.history,
      label: 'Orders',
      route: '/orders',
    ),
    BottomNavigationItem(
      icon: Icons.account_circle,
      label: 'Profile',
      route: '/profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spys'),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          StreamBuilder<List<AppNotification>>(
            stream: _notificationService.notificationStream,
            builder: (context, snapshot) {
              final unreadCount = _notificationService.unreadCount;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      // Show notifications as a modal or overlay
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => NotificationsScreen()),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: AppConstants.errorColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: _navigationItems.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item.icon),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

// Extract the original home content to a separate widget
class StudentHomeScreenContent extends StatelessWidget {
  const StudentHomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return StreamBuilder<User?>(
      stream: authService.userStream,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return SingleChildScrollView(
          child: Column(
            children: [
              // Welcome Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.paddingLarge),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppConstants.borderRadiusLarge),
                    bottomRight: Radius.circular(AppConstants.borderRadiusLarge),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welkom, ${user?.name ?? 'Gebruiker'}!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingSmall),
                    Text(
                      'Wat gaan jy vandag eet?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: setOpacity(Colors.white, 0.9),
                      ),
                    ),
                    const SizedBox(height: AppConstants.paddingMedium),
                    // Quick Balance Display
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.paddingMedium,
                        vertical: AppConstants.paddingSmall,
                      ),
                      decoration: BoxDecoration(
                        color: setOpacity(Colors.white, 0.2),
                        borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                          const SizedBox(width: AppConstants.paddingSmall),
                          Text(
                            'Saldo: R${user?.walletBalance.toStringAsFixed(2) ?? '0.00'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppConstants.paddingLarge),
              
              // Promotional Banner
              Container(
                margin: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
                height: 120,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppConstants.accentColor, setOpacity(AppConstants.accentColor, 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -10,
                      child: Icon(
                        Icons.local_dining,
                        size: 100,
                        color: setOpacity(Colors.white, 0.2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppConstants.paddingMedium),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Probeer ons Maandag Burger!',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppConstants.paddingSmall),
                          Text(
                            '20% afslag - Net vir vandag!',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: setOpacity(Colors.white, 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppConstants.paddingLarge),
              
              // Quick Action Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppConstants.paddingMedium),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: AppConstants.paddingMedium,
                  mainAxisSpacing: AppConstants.paddingMedium,
                  childAspectRatio: 1.1,
                  children: [
                    _buildQuickActionCard(
                      context: context,
                      title: 'Spyskaart',
                      subtitle: 'Kyk wat beskikbaar is',
                      icon: Icons.restaurant_menu,
                      color: AppConstants.primaryColor,
                      onTap: () => Navigator.pushNamed(context, '/menu'),
                    ),
                    _buildQuickActionCard(
                      context: context,
                      title: 'My Bestellings',
                      subtitle: 'Kyk jou geskiedenis',
                      icon: Icons.history,
                      color: AppConstants.secondaryColor,
                      onTap: () => Navigator.pushNamed(context, '/orders'),
                    ),
                    _buildQuickActionCard(
                      context: context,
                      title: 'Beursie',
                      subtitle: 'Laai geld op',
                      icon: Icons.account_balance_wallet,
                      color: AppConstants.successColor,
                      onTap: () => Navigator.pushNamed(context, '/wallet'),
                    ),
                    _buildQuickActionCard(
                      context: context,
                      title: 'Profiel',
                      subtitle: 'Wysig besonderhede',
                      icon: Icons.person,
                      color: AppConstants.warningColor,
                      onTap: () => Navigator.pushNamed(context, '/profile'),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: AppConstants.paddingLarge),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.paddingMedium),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppConstants.paddingMedium),
                decoration: BoxDecoration(
                  color: setOpacity(color, 0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppConstants.paddingSmall),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BottomNavigationItem {
  final IconData icon;
  final String label;
  final String route;

  BottomNavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
} 