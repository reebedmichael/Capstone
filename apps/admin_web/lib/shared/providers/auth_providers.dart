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

// User approval status provider
final userApprovalProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.isCurrentUserApproved();
});

// Primary admin status provider
final isPrimaryAdminProvider = FutureProvider<bool>((ref) async {
  final authService = ref.watch(authServiceProvider);
  return await authService.isCurrentUserPrimary();
});

// Current admin type provider
final currentAdminTypeProvider = FutureProvider<String?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final userProfile = await authService.getUserProfile();
  return userProfile?['admin_tipe']?['admin_tipe_naam'];
});

// Auth loading state
final authLoadingProvider = StateProvider<bool>((ref) => false);

// Auth error state
final authErrorProvider = StateProvider<String?>((ref) => null);

// Clear auth error
final clearAuthErrorProvider = Provider<void>((ref) {
  ref.read(authErrorProvider.notifier).state = null;
});
