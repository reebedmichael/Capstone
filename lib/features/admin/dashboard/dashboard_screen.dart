import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/utils/color_utils.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      title: 'Dashboard',
      icon: Icons.dashboard,
      route: '/dashboard',
    ),
    NavigationItem(
      title: 'Menu Management',
      icon: Icons.restaurant_menu,
      route: '/menu-management',
    ),
    NavigationItem(
      title: 'Order Management',
      icon: Icons.shopping_cart,
      route: '/order-management',
    ),
    NavigationItem(
      title: 'User Management',
      icon: Icons.people,
      route: '/user-management',
    ),
    NavigationItem(
      title: 'Feedback & Reports',
      icon: Icons.analytics,
      route: '/feedback-reports',
    ),
    NavigationItem(
      title: 'Inventory',
      icon: Icons.inventory,
      route: '/inventory',
    ),
    NavigationItem(
      title: 'Settings',
      icon: Icons.settings,
      route: '/settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final String? currentRoute = ModalRoute.of(context)?.settings.name;
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Show side navigation only on larger screens
          final bool showSideNav = constraints.maxWidth > 768;
          
          return Row(
            children: [
              // Side Navigation (hidden on mobile)
              if (showSideNav)
                Container(
                  width: 280,
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(AppConstants.paddingLarge),
                        child: Row(
                          children: [
                            Icon(
                              Icons.restaurant,
                              size: 32,
                              color: AppConstants.primaryColor,
                            ),
                            const SizedBox(width: AppConstants.paddingMedium),
                            Text(
                              'Spys Admin',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppConstants.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(),
                      // Navigation Items
                      Expanded(
                        child: ListView.builder(
                          itemCount: _navigationItems.length,
                          itemBuilder: (context, index) {
                            final item = _navigationItems[index];
                            final isSelected = currentRoute == item.route;
                            return ListTile(
                              leading: Icon(
                                item.icon,
                                color: isSelected 
                                  ? AppConstants.primaryColor 
                                  : setOpacity(Theme.of(context).colorScheme.onSurface, 0.7),
                              ),
                              title: Text(
                                item.title,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected 
                                    ? AppConstants.primaryColor 
                                    : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              selected: isSelected,
                              selectedTileColor: setOpacity(AppConstants.primaryColor, 0.1),
                              onTap: () {
                                if (!isSelected) {
                                  Navigator.pushReplacementNamed(context, item.route);
                                }
                              },
                            );
                          },
                        ),
                      ),
                      // Footer
                      Container(
                        padding: const EdgeInsets.all(AppConstants.paddingMedium),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppConstants.primaryColor,
                              child: const Icon(Icons.person, color: Colors.white),
                            ),
                            const SizedBox(width: AppConstants.paddingMedium),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Admin User',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'admin@spys.com',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: setOpacity(Theme.of(context).colorScheme.onSurface, 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Logout - Coming Soon!')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              // Main Content
              Expanded(
                child: Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    children: [
                      // Top Bar
                      Container(
                        padding: const EdgeInsets.all(AppConstants.paddingLarge),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          boxShadow: [
                            BoxShadow(
                              color: setOpacity(Colors.black, 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Hamburger menu for mobile
                            if (!showSideNav)
                              IconButton(
                                icon: const Icon(Icons.menu),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Mobile menu - Coming Soon!')),
                                  );
                                },
                              ),
                            Text(
                              _navigationItems[0].title,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.notifications),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Notifications - Coming Soon!')),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.brightness_6),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Theme Toggle - Coming Soon!')),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      // Dashboard Content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AppConstants.paddingLarge),
                          child: _buildDashboardContent(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDashboardContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive grid: 1 column on mobile, 2 on tablet, 3 on desktop
        int crossAxisCount = 1;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 2;
        }
        
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: AppConstants.paddingLarge,
          mainAxisSpacing: AppConstants.paddingLarge,
          childAspectRatio: 1.2, // Better aspect ratio for cards
          children: [
            _buildStatCard(
              'Total Orders',
              '1,234',
              Icons.shopping_cart,
              AppConstants.primaryColor,
            ),
            _buildStatCard(
              'Active Users',
              '567',
              Icons.people,
              AppConstants.successColor,
            ),
            _buildStatCard(
              'Revenue',
              '\$12,345',
              Icons.attach_money,
              AppConstants.accentColor,
            ),
            _buildStatCard(
              'Menu Items',
              '89',
              Icons.restaurant_menu,
              AppConstants.secondaryColor,
            ),
            _buildStatCard(
              'Pending Orders',
              '23',
              Icons.pending,
              AppConstants.warningColor,
            ),
            _buildStatCard(
              'Feedback',
              '4.8★',
              Icons.star,
              AppConstants.accentColor,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: color,
            ),
            const SizedBox(height: AppConstants.paddingMedium),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: AppConstants.paddingSmall),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: setOpacity(Theme.of(context).colorScheme.onSurface, 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class NavigationItem {
  final String title;
  final IconData icon;
  final String route;

  NavigationItem({
    required this.title,
    required this.icon,
    required this.route,
  });
} 