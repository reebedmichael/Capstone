import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;
  bool get isLoggedIn => currentUser != null;

  Future<AuthResponse> signInWithEmail({required String email, required String password}) async {
    try {
      final response = await _supabase.auth.signInWithPassword(email: email, password: password);
      if (response.user != null) {
        try { 
          await _ensureUserExists(response.user!); 
        } catch (e) { 
          print('Warning: Could not ensure user exists in database: $e'); 
        }
      }
      return response;
    } catch (e) { 
      rethrow; 
    }
  }

  Future<AuthResponse> signUpWithEmail({
    required String email, 
    required String password, 
    required String firstName, 
    required String lastName, 
    required String cellphone
  }) async {
    try {
      final response = await _supabase.auth.signUp(email: email, password: password);
      if (response.user != null) {
        try {
          await _createUserInDatabase(
            user: response.user!, 
            firstName: firstName, 
            lastName: lastName, 
            cellphone: cellphone
          );
        } catch (e) { 
          print('Warning: Could not create user in database: $e'); 
        }
      }
      return response;
    } catch (e) { 
      rethrow; 
    }
  }

  Future<void> signOut() async { 
    await _supabase.auth.signOut(); 
  }

  Future<void> _createUserInDatabase({
    required User user, 
    required String firstName, 
    required String lastName, 
    required String cellphone
  }) async {
    try {
      // New workflow: Create users as Ekstern with is_aktief=false and Pending admin type
      // Primary admin will approve and assign proper user type
      await _supabase.from('gebruikers').upsert({
        'gebr_id': user.id,
        'gebr_epos': user.email!,
        'gebr_naam': firstName,
        'gebr_van': lastName,
        'gebr_selfoon': cellphone,
        'is_aktief': false, // Requires Primary admin approval
        'gebr_tipe_id': '4b2cadfb-90ee-4f89-931d-2b1e7abbc284', // Ekstern type ID
        'admin_tipe_id': 'f5fde633-eea3-4d58-8509-fb80a74f68a6', // Pending admin type ID
        'requested_admin_tipe_id': null, // Could be set if user requests specific admin role
      }, onConflict: 'gebr_id');
    } catch (e) { 
      rethrow; 
    }
  }

  Future<void> _ensureUserExists(User user) async {
    try {
      final existingUser = await _supabase.from('gebruikers').select().eq('gebr_id', user.id).maybeSingle();
      if (existingUser == null) {
        // Create as Ekstern user requiring approval
        await _createUserInDatabase(
          user: user, 
          firstName: 'Unknown', 
          lastName: 'User', 
          cellphone: ''
        );
      }
    } catch (e) { 
      rethrow; 
    }
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) return null;
    try {
      final result = await _supabase.from('gebruikers').select().eq('gebr_id', currentUser!.id).maybeSingle();
      return result;
    } catch (e) { 
      return null; 
    }
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Reset password - sends reset email to user
  Future<void> resetPassword({required String email}) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        // redirectTo: 'http://localhost:51322/wagwoord_herstel',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Verify OTP for password reset
  Future<AuthResponse> verifyOtpForPasswordReset({
    required String email,
    required String token,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.recovery,
        token: token,
        email: email,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Update password after OTP verification
  Future<UserResponse> updatePassword({required String password}) async {
    try {
      final response = await _supabase.auth.updateUser(
        UserAttributes(password: password),
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
