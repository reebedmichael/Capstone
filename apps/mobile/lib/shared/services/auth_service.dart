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
      // Get default values for new users
      final ekstern = await _supabase
          .from('gebruiker_tipes')
          .select('gebr_tipe_id')
          .ilike('gebr_tipe_naam', 'Ekstern')
          .limit(1)
          .maybeSingle();
      final adminNone = await _supabase
          .from('admin_tipes')
          .select('admin_tipe_id')
          .ilike('admin_tipe_naam', 'None')
          .limit(1)
          .maybeSingle();
      final firstKampus = await _supabase
          .from('kampus')
          .select('kampus_id')
          .order('kampus_naam', ascending: true)
          .limit(1)
          .maybeSingle();

      if (ekstern == null || adminNone == null || firstKampus == null) {
        throw Exception('Kon nie verstekwaardes laai nie');
      }

      // Create user as active with default values (same as register page was doing)
      await _supabase.from('gebruikers').upsert({
        'gebr_id': user.id, // CRITICAL: Use Supabase auth UID as gebr_id
        'gebr_epos': user.email!,
        'gebr_naam': firstName,
        'gebr_van': lastName,
        'gebr_selfoon': cellphone,
        'is_aktief': true, // Active by default for new registrations
        'beursie_balans': 0,
        'gebr_tipe_id': ekstern['gebr_tipe_id'],
        'admin_tipe_id': adminNone['admin_tipe_id'],
        'kampus_id': firstKampus['kampus_id'],
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
