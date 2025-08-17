import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/wallet/presentation/pages/wallet_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/help/presentation/pages/help_page.dart';
import '../../features/qr/presentation/pages/qr_page.dart';
import '../../features/feedback/presentation/pages/feedback_page.dart';
import '../../features/cart/presentation/pages/cart_page.dart';
import '../../features/food/presentation/pages/food_detail_page.dart';
import '../../features/allowance/presentation/pages/allowance_page.dart';
import '../../features/welcome/presentation/pages/welcome_page.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/auth/login',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomePage(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(path: '/home', builder: (context, state) => const HomePage()),
      GoRoute(path: '/orders', builder: (context, state) => const OrdersPage()),
      GoRoute(path: '/wallet', builder: (context, state) => const WalletPage()),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsPage(),
      ),
      GoRoute(path: '/help', builder: (context, state) => const HelpPage()),
      GoRoute(path: '/qr', builder: (context, state) => const QrPage()),
      GoRoute(
        path: '/feedback',
        builder: (context, state) => FeedbackPage(
          order: const {},
          onFeedbackUpdated: (Map<String, dynamic> updatedOrder) {},
        ),
      ),
      GoRoute(path: '/cart', builder: (context, state) => const CartPage()),
      GoRoute(
        path: '/food-detail',
        builder: (context, state) => const FoodDetailPage(),
      ),
      GoRoute(
        path: '/allowance',
        builder: (context, state) => const AllowancePage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              '404 - Bladsy nie gevind nie',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Die bladsy wat jy soek bestaan nie.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/auth/login'),
              child: const Text('Gaan terug na Teken In'),
            ),
          ],
        ),
      ),
    ),
  );
}
