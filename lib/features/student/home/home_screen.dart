import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/utils/color_utils.dart';

class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({super.key});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  int _currentIndex = 0;

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
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ],
      ),
      body: _buildBody(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          Navigator.pushNamed(context, _navigationItems[index].route);
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

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.paddingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppConstants.paddingSmall),
                  Text(
                    'What would you like to order today?',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: setOpacity(Theme.of(context).colorScheme.onSurface, 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          
          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  'Browse Menu',
                  Icons.restaurant_menu,
                  AppConstants.primaryColor,
                  () => Navigator.pushNamed(context, '/menu'),
                ),
              ),
              const SizedBox(width: AppConstants.paddingMedium),
              Expanded(
                child: _buildQuickActionCard(
                  'My Orders',
                  Icons.history,
                  AppConstants.secondaryColor,
                  () => Navigator.pushNamed(context, '/orders'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          
          // Popular Items
          Text(
            'Popular Items',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 10,
              itemBuilder: (context, index) {
                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: AppConstants.paddingMedium),
                  child: Card(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: setOpacity(AppConstants.primaryColor, 0.1),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(AppConstants.borderRadiusMedium),
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.restaurant,
                                size: 48,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(AppConstants.paddingMedium),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Item ${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '\$${(index + 1) * 5}.99',
                                style: TextStyle(
                                  color: AppConstants.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppConstants.paddingLarge),
          
          // Recent Orders
          Text(
            'Recent Orders',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppConstants.paddingMedium),
          Card(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: setOpacity(AppConstants.primaryColor, 0.1),
                    child: Icon(
                      Icons.shopping_bag,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                  title: Text('Order #${1000 + index}'),
                  subtitle: Text('Delivered • \$${(index + 1) * 8}.99'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.pushNamed(context, '/orders');
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.paddingLarge),
          child: Column(
            children: [
              Icon(
                icon,
                size: 48,
                color: color,
              ),
              const SizedBox(height: AppConstants.paddingMedium),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
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