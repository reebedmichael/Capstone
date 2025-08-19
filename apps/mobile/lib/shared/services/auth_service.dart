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
      await _supabase.from('gebruikers').upsert({
        'gebr_id': user.id,
        'gebr_epos': user.email!,
        'gebr_naam': firstName,
        'gebr_van': lastName,
        'gebr_selfoon': cellphone,
        'is_aktief': true,
        'gebr_tipe': 'student', // Default to student for mobile app
      }, onConflict: 'gebr_id');
    } catch (e) { 
      rethrow; 
    }
  }

  Future<void> _ensureUserExists(User user) async {
    try {
      final existingUser = await _supabase.from('gebruikers').select().eq('gebr_id', user.id).maybeSingle();
      if (existingUser == null) {
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
}
