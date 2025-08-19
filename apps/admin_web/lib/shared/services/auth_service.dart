import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // Ensure user exists in our gebruikers table
        try {
          await _ensureUserExists(response.user!);
        } catch (e) {
          // Log the error but don't fail the login
          print('Warning: Could not ensure user exists in database: $e');
        }
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String cellphone,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // Create user in our gebruikers table
        try {
          await _createUserInDatabase(
            user: response.user!,
            firstName: firstName,
            lastName: lastName,
            cellphone: cellphone,
          );
        } catch (e) {
          // Log the error but don't fail the signup
          print('Warning: Could not create user in database: $e');
        }
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // Create user in our gebruikers table
  Future<void> _createUserInDatabase({
    required User user,
    required String firstName,
    required String lastName,
    required String cellphone,
  }) async {
    try {
      // Use direct Supabase call instead of repository to avoid RLS issues
      await _supabase.from('gebruikers').upsert({
        'gebr_id': user.id,
        'gebr_epos': user.email!,
        'gebr_naam': firstName,
        'gebr_van': lastName,
        'is_aktief': true,
        // Note: We'll need to handle gebr_tipe_id properly later
      }, onConflict: 'gebr_id');
    } catch (e) {
      // If user creation fails, we should handle this appropriately
      // For now, just rethrow
      rethrow;
    }
  }

  // Ensure user exists in our gebruikers table
  Future<void> _ensureUserExists(User user) async {
    try {
      // Use direct Supabase call instead of repository to avoid RLS issues
      final existingUser = await _supabase
          .from('gebruikers')
          .select()
          .eq('gebr_id', user.id)
          .maybeSingle();
      
      if (existingUser == null) {
        // User doesn't exist in our table, create them
        await _createUserInDatabase(
          user: user,
          firstName: 'Unknown',
          lastName: 'User',
          cellphone: '',
        );
      }
    } catch (e) {
      // Handle error appropriately
      rethrow;
    }
  }

  // Get user profile from our database
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) return null;
    
    try {
      // Use direct Supabase call instead of repository to avoid RLS issues
      final result = await _supabase
          .from('gebruikers')
          .select()
          .eq('gebr_id', currentUser!.id)
          .maybeSingle();
      
      return result;
    } catch (e) {
      return null;
    }
  }

  // Listen to auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
