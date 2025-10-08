import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../shared/providers/theme_provider.dart' as shared_theme;

class AppBottomNav extends ConsumerWidget {
  final int currentIndex;
  const AppBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isDark = ref.watch(shared_theme.isDarkModeProvider);
    final MaterialStateProperty<TextStyle?> labelStyle =
        MaterialStateProperty.resolveWith<TextStyle?>((states) {
      if (isDark) {
        return const TextStyle(color: Colors.white);
      }
      return null; // use theme defaults in light mode
    });

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        labelTextStyle: labelStyle,
      ),
      child: NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        switch (index) {
          case 0:
            context.go('/home');
            break;
          case 1:
            context.go('/orders');
            break;
          case 2:
            context.go('/wallet');
            break;
          case 3:
            context.go('/profile');
            break;
          case 4:
            context.go('/settings');
            break;
        }
      },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Tuis'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Bestellings'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Beursie'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profiel'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Instellings'),
        ],
      ),
    );
  }
}
