import 'package:hooks_riverpod/hooks_riverpod.dart';

// Form field providers
final firstNameProvider = StateProvider<String>((ref) => '');
final lastNameProvider = StateProvider<String>((ref) => '');
final emailProvider = StateProvider<String>((ref) => '');
final cellphoneProvider = StateProvider<String>((ref) => '');
final locationProvider = StateProvider<String>((ref) => '');
final userRollProvider = StateProvider<String>((ref) => '');
final adminRollProvider = StateProvider<String>((ref) => '');
final passwordProvider = StateProvider<String>((ref) => '');
final confirmPasswordProvider = StateProvider<String>((ref) => '');
final walletBalanceProvider = StateProvider<double>((ref) => 0.0);
final statusProvider = StateProvider<bool>((ref) => false);
final createdDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final lastActiveProvider = StateProvider<DateTime>((ref) => DateTime.now());

// UI state providers
final passwordVisibleProvider = StateProvider<bool>((ref) => false);
final confirmPasswordVisibleProvider = StateProvider<bool>((ref) => false);

// Loading state providers
final loginLoadingProvider = StateProvider<bool>((ref) => false);

// Form validation providers
final firstNameErrorProvider = StateProvider<String?>((ref) => null);
final lastNameErrorProvider = StateProvider<String?>((ref) => null);
final emailErrorProvider = StateProvider<String?>((ref) => null);
final cellphoneErrorProvider = StateProvider<String?>((ref) => null);
final passwordErrorProvider = StateProvider<String?>((ref) => null);
final confirmPasswordErrorProvider = StateProvider<String?>((ref) => null);

// Form validity providers - Login
final loginFormValidProvider = Provider<bool>((ref) {
  final email = ref.watch(emailProvider);
  final password = ref.watch(passwordProvider);

  final emailError = ref.watch(emailErrorProvider);
  final passwordError = ref.watch(passwordErrorProvider);

  return email.isNotEmpty &&
      password.isNotEmpty &&
      emailError == null &&
      passwordError == null;
});

// Form validity providers - Register
final registerFormValidProvider = Provider<bool>((ref) {
  final firstName = ref.watch(firstNameProvider);
  final lastName = ref.watch(lastNameProvider);
  final email = ref.watch(emailProvider);
  final cellphone = ref.watch(cellphoneProvider);
  final password = ref.watch(passwordProvider);
  final confirmPassword = ref.watch(confirmPasswordProvider);

  final firstNameError = ref.watch(firstNameErrorProvider);
  final lastNameError = ref.watch(lastNameErrorProvider);
  final emailError = ref.watch(emailErrorProvider);
  final cellphoneError = ref.watch(cellphoneErrorProvider);
  final passwordError = ref.watch(passwordErrorProvider);
  final confirmPasswordError = ref.watch(confirmPasswordErrorProvider);

  return firstName.isNotEmpty &&
      lastName.isNotEmpty &&
      email.isNotEmpty &&
      cellphone.isNotEmpty &&
      password.isNotEmpty &&
      confirmPassword.isNotEmpty &&
      firstNameError == null &&
      lastNameError == null &&
      cellphoneError == null &&
      emailError == null &&
      passwordError == null &&
      confirmPasswordError == null;
});

// Form validity providers - Password Reset
final passwordFormValidProvider = Provider<bool>((ref) {
  final password = ref.watch(passwordProvider);
  final confirmPassword = ref.watch(confirmPasswordProvider);

  final passwordError = ref.watch(passwordErrorProvider);
  final confirmPasswordError = ref.watch(confirmPasswordErrorProvider);

  return password.isNotEmpty &&
      confirmPassword.isNotEmpty &&
      passwordError == null &&
      confirmPasswordError == null &&
      password == confirmPassword;
});

// Form validity providers - Profiel
final profielFormValidProvider = Provider<bool>((ref) {
  final firstName = ref.watch(firstNameProvider);
  final lastName = ref.watch(lastNameProvider);
  final email = ref.watch(emailProvider);
  final cellphone = ref.watch(cellphoneProvider);

  final firstNameError = ref.watch(firstNameErrorProvider);
  final lastNameError = ref.watch(lastNameErrorProvider);
  final emailError = ref.watch(emailErrorProvider);
  final cellphoneError = ref.watch(cellphoneErrorProvider);

  return firstName.isNotEmpty &&
      lastName.isNotEmpty &&
      email.isNotEmpty &&
      cellphone.isNotEmpty &&
      firstNameError == null &&
      lastNameError == null &&
      cellphoneError == null &&
      emailError == null;
});
