import 'dart:async';
import '../models/user.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _userController.add(null); // Emit null on startup
  }

  User? _currentUser;
  final StreamController<User?> _userController = StreamController<User?>.broadcast();

  Stream<User?> get userStream => _userController.stream;
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;

  // TODO: Backend integration - Replace with real API calls
  Future<LoginResult> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Mock validation
    if (email.isEmpty || password.isEmpty) {
      return LoginResult(success: false, error: 'E-pos en wagwoord is vereist');
    }

    if (!email.contains('@')) {
      return LoginResult(success: false, error: 'Ongeldige e-pos formaat');
    }

    if (password.length < 8) {
      return LoginResult(success: false, error: 'Wagwoord moet ten minste 8 karakters wees');
    }

    // Mock successful login with full dummy data
    _currentUser = User(
      id: '1',
      name: 'Demo Student',
      email: 'demo@spys.com',
      phone: '+27 82 123 4567',
      userType: 'student',
      walletBalance: 1234.56,
      addresses: ['123 Demo Street, Demo City', '456 Example Ave, Test Town'],
      allergies: ['Gluten', 'Peanuts'],
      termsAccepted: true,
      isActive: true,
      lastLogin: DateTime.now(),
      profileImageUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
    );

    _userController.add(_currentUser);
    return LoginResult(success: true);
  }

  Future<RegisterResult> register({
    required String email,
    required String password,
    required String confirmPassword,
    required String name,
    required String phone,
    required String userType,
    required List<String> allergies,
    required bool termsAccepted,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Mock validation
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      return RegisterResult(success: false, error: 'Alle vereiste velde moet ingevul word');
    }

    if (!email.contains('@')) {
      return RegisterResult(success: false, error: 'Ongeldige e-pos formaat');
    }

    if (password.length < 8) {
      return RegisterResult(success: false, error: 'Wagwoord moet ten minste 8 karakters wees');
    }

    if (password != confirmPassword) {
      return RegisterResult(success: false, error: 'Wagwoorde stem nie ooreen nie');
    }

    if (!termsAccepted) {
      return RegisterResult(success: false, error: 'Jy moet die bepalings en voorwaardes aanvaar');
    }

    // Mock email already exists check
    if (email == 'test@example.com') {
      return RegisterResult(success: false, error: 'Hierdie e-pos adres bestaan reeds');
    }

    // Mock successful registration
    _currentUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      phone: phone,
      userType: userType,
      walletBalance: 0.0,
      addresses: [],
      allergies: allergies,
      termsAccepted: termsAccepted,
      isActive: true,
      lastLogin: DateTime.now(),
    );

    _userController.add(_currentUser);
    return RegisterResult(success: true);
  }

  Future<void> logout() async {
    _currentUser = null;
    _userController.add(null);
  }

  Future<bool> forgotPassword(String email) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // TODO: Backend integration - Send password reset email
    return email.contains('@'); // Mock validation
  }

  Future<bool> updateProfile(User updatedUser) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    // TODO: Backend integration - Update user profile
    _currentUser = updatedUser;
    _userController.add(_currentUser);
    return true;
  }

  void dispose() {
    _userController.close();
  }
}

class LoginResult {
  final bool success;
  final String? error;

  LoginResult({required this.success, this.error});
}

class RegisterResult {
  final bool success;
  final String? error;

  RegisterResult({required this.success, this.error});
} 
