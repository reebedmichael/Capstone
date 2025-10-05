import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  // Auth state changes stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

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

  // Create user in our gebruikers table
  Future<void> _createUserInDatabase({
    required User user,
    required String firstName,
    required String lastName,
    required String cellphone,
  }) async {
    try {
      // Use direct Supabase call instead of repository to avoid RLS issues
      // NEW: Create admin with is_aktief = false (requires approval)
      await _supabase.from('gebruikers').upsert({
        'gebr_id': user.id,
        'gebr_epos': user.email!,
        'gebr_naam': firstName,
        'gebr_van': lastName,
        'is_aktief': false, // NEW: Require approval for new admins
        // Set a default admin type - this will need Primary admin approval
        'admin_tipe_id': await _getDefaultAdminTypeId(),
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

  // Get default admin type ID (or create one if it doesn't exist)
  Future<String?> _getDefaultAdminTypeId() async {
    try {
      // Look for a "Pending" or "Standard" admin type
      final adminType = await _supabase
          .from('admin_tipes')
          .select('admin_tipe_id')
          .or('admin_tipe_naam.eq.Pending,admin_tipe_naam.eq.Standard')
          .limit(1)
          .maybeSingle();

      if (adminType != null) {
        return adminType['admin_tipe_id'];
      }

      // If no suitable admin type exists, create a "Pending" type
      final newType = await _supabase
          .from('admin_tipes')
          .insert({'admin_tipe_naam': 'Pending'})
          .select('admin_tipe_id')
          .single();

      return newType['admin_tipe_id'];
    } catch (e) {
      print('Warning: Could not get/create default admin type: $e');
      return null; // Allow registration to continue without admin type
    }
  }

  // Check if current user is approved (is_aktief = true)
  Future<bool> isCurrentUserApproved() async {
    if (currentUser == null) return false;

    try {
      final userProfile = await _supabase
          .from('gebruikers')
          .select('is_aktief, admin_tipe_id')
          .eq('gebr_id', currentUser!.id)
          .maybeSingle();

      if (userProfile == null) return false;

      // User must be active and have an admin type
      return userProfile['is_aktief'] == true &&
          userProfile['admin_tipe_id'] != null;
    } catch (e) {
      print('Error checking user approval status: $e');
      return false;
    }
  }

  // Check if current user is Primary admin
  Future<bool> isCurrentUserPrimary() async {
    if (currentUser == null) return false;

    try {
      final userProfile = await _supabase
          .from('gebruikers')
          .select('''
            is_aktief,
            admin_tipe:admin_tipe_id(admin_tipe_naam)
          ''')
          .eq('gebr_id', currentUser!.id)
          .maybeSingle();

      if (userProfile == null) return false;

      final adminTypeName = userProfile['admin_tipe']?['admin_tipe_naam'];
      return userProfile['is_aktief'] == true && adminTypeName == 'Primary';
    } catch (e) {
      print('Error checking primary admin status: $e');
      return false;
    }
  }

  // Get user profile from our database
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (currentUser == null) {
      print('DEBUG: AuthService - No current user');
      return null;
    }

    try {
      print(
        'DEBUG: AuthService - Fetching profile for user: ${currentUser!.id}',
      );
      // Fetch gebruiker with linked admin_tipes for role name
      final result = await _supabase
          .from('gebruikers')
          .select('''
            gebr_id,
            gebr_naam,
            gebr_van,
            gebr_epos,
            admin_tipe_id,
            admin_tipes:admin_tipe_id(admin_tipe_naam)
          ''')
          .eq('gebr_id', currentUser!.id)
          .maybeSingle();

      print('DEBUG: AuthService - Profile result: $result');
      return result;
    } catch (e) {
      print('DEBUG: AuthService - Error fetching profile: $e');
      return null;
    }
  }
}
