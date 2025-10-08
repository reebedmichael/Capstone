import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';

class AdminAccessGuard extends ConsumerWidget {
  final Widget child;
  
  const AdminAccessGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(currentUserProvider);
    
    return authState.when(
      data: (user) {
        if (user != null) {
          // User is authenticated, check admin access
          return _checkAdminAccess(context, ref);
        } else {
          // Redirect to login if not authenticated
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              context.go('/teken_in');
            }
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) {
        // Redirect to login on error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go('/teken_in');
          }
        });
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  Widget _checkAdminAccess(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authServiceProvider);
    
    return FutureBuilder<Map<String, dynamic>?>(
      future: authService.getUserProfile(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          print('DEBUG: AdminAccessGuard - Profile error: ${snapshot.error}');
          // On error, redirect to waiting page for safety
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && GoRouterState.of(context).uri.path != '/wag_goedkeuring') {
              context.go('/wag_goedkeuring');
            }
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final profile = snapshot.data;
        if (profile == null) {
          print('DEBUG: AdminAccessGuard - No profile found');
          // No profile, redirect to waiting page
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && GoRouterState.of(context).uri.path != '/wag_goedkeuring') {
              context.go('/wag_goedkeuring');
            }
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final admin = profile['admin_tipes'] as Map<String, dynamic>?;
        final adminTypeName = (admin?['admin_tipe_naam'] as String?)?.trim() ?? '';
        
        print('DEBUG: AdminAccessGuard - Admin type: "$adminTypeName"');

        // Check if admin type is restricted
        final restrictedTypes = {'Pending', 'Tertiary', 'None'};
        final isRestricted = restrictedTypes.contains(adminTypeName);
        
        print('DEBUG: AdminAccessGuard - Is restricted: $isRestricted');

        if (isRestricted) {
          print('DEBUG: AdminAccessGuard - Redirecting to waiting page');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted && GoRouterState.of(context).uri.path != '/wag_goedkeuring') {
              context.go('/wag_goedkeuring');
            }
          });
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        } else {
          print('DEBUG: AdminAccessGuard - Allowing access');
          return child;
        }
      },
    );
  }
}
