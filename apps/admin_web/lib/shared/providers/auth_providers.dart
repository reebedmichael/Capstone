import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Current user provider
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges.map((event) => event.session?.user);
});

// Is logged in provider
final isLoggedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider).value;
  return user != null;
});

// User profile provider
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.getUserProfile();
});

// Admin access gating
final hasAdminAccessProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.when(
    data: (profile) {
      if (profile == null) {
        print('DEBUG: Profile is null - denying access');
        return false;
      }
      
      final admin = profile['admin_tipes'] as Map<String, dynamic>?;
      final naam = (admin?['admin_tipe_naam'] as String?)?.trim() ?? '';
      
      print('DEBUG: Admin type name: "$naam"');
      print('DEBUG: Full profile: $profile');
      
      // Only block specific restricted admin types
      final restrictedTypes = {
        'Pending',
        'Tertiary', 
        'None',
      };
      
      // If no admin type or empty, allow access (default behavior)
      if (naam.isEmpty) {
        print('DEBUG: Empty admin type, allowing access');
        return true;
      }
      
      final isRestricted = restrictedTypes.contains(naam);
      print('DEBUG: Is restricted: $isRestricted for type: "$naam"');
      print('DEBUG: Restricted types: $restrictedTypes');
      
      // Block only the restricted types, allow all others
      final hasAccess = !isRestricted;
      print('DEBUG: Final access decision: $hasAccess');
      return hasAccess;
    },
    loading: () {
      print('DEBUG: Profile still loading - denying access temporarily');
      return false;
    },
    error: (error, stack) {
      print('DEBUG: Profile loading error: $error - denying access');
      return false;
    },
  );
});

// Auth loading state
final authLoadingProvider = StateProvider<bool>((ref) => false);

// Auth error state
final authErrorProvider = StateProvider<String?>((ref) => null);

// Clear auth error
final clearAuthErrorProvider = Provider<void>((ref) {
  ref.read(authErrorProvider.notifier).state = null;
});

// User approval status provider
final userApprovalProvider = FutureProvider<bool>((ref) async {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.when(
    data: (profile) {
      if (profile == null) return false;
      
      // Check if user is active (approved)
      final isActive = profile['is_aktief'] as bool? ?? false;
      
      // For admin users, also check if they have a valid admin type
      final admin = profile['admin_tipes'] as Map<String, dynamic>?;
      final adminTypeName = (admin?['admin_tipe_naam'] as String?)?.trim() ?? '';
      
      // If user has admin type, they need to be active AND not pending
      if (adminTypeName.isNotEmpty) {
        return isActive && adminTypeName != 'Pending';
      }
      
      // For regular users, just check if they're active
      return isActive;
    },
    loading: () => false,
    error: (error, stack) => false,
  );
});

// Primary admin check provider
final isPrimaryAdminProvider = FutureProvider<bool>((ref) async {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.when(
    data: (profile) {
      if (profile == null) return false;
      
      final admin = profile['admin_tipes'] as Map<String, dynamic>?;
      final adminTypeName = (admin?['admin_tipe_naam'] as String?)?.trim() ?? '';
      
      return adminTypeName == 'Primary';
    },
    loading: () => false,
    error: (error, stack) => false,
  );
});

// Current admin type provider
final currentAdminTypeProvider = FutureProvider<String?>((ref) async {
  final profileAsync = ref.watch(userProfileProvider);
  return profileAsync.when(
    data: (profile) {
      if (profile == null) return null;
      
      final admin = profile['admin_tipes'] as Map<String, dynamic>?;
      return (admin?['admin_tipe_naam'] as String?)?.trim();
    },
    loading: () => null,
    error: (error, stack) => null,
  );
});
