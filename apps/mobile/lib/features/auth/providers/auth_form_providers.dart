import 'package:hooks_riverpod/hooks_riverpod.dart';

// Form field providers
final emailProvider = StateProvider<String>((ref) => '');
final passwordProvider = StateProvider<String>((ref) => '');
final firstNameProvider = StateProvider<String>((ref) => '');
final lastNameProvider = StateProvider<String>((ref) => '');
final confirmPasswordProvider = StateProvider<String>((ref) => '');

// UI state providers
final passwordVisibleProvider = StateProvider<bool>((ref) => false);
final confirmPasswordVisibleProvider = StateProvider<bool>((ref) => false);

// Loading state providers
final loginLoadingProvider = StateProvider<bool>((ref) => false);
final registerLoadingProvider = StateProvider<bool>((ref) => false);

// Form validation providers
final emailErrorProvider = StateProvider<String?>((ref) => null);
final passwordErrorProvider = StateProvider<String?>((ref) => null);
final firstNameErrorProvider = StateProvider<String?>((ref) => null);
final lastNameErrorProvider = StateProvider<String?>((ref) => null);
final confirmPasswordErrorProvider = StateProvider<String?>((ref) => null);

// Form validity providers
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

final registerFormValidProvider = Provider<bool>((ref) {
  final firstName = ref.watch(firstNameProvider);
  final lastName = ref.watch(lastNameProvider);
  final email = ref.watch(emailProvider);
  final password = ref.watch(passwordProvider);
  final confirmPassword = ref.watch(confirmPasswordProvider);
  final firstNameError = ref.watch(firstNameErrorProvider);
  final lastNameError = ref.watch(lastNameErrorProvider);
  final emailError = ref.watch(emailErrorProvider);
  final passwordError = ref.watch(passwordErrorProvider);
  final confirmPasswordError = ref.watch(confirmPasswordErrorProvider);
  
  return firstName.isNotEmpty && 
         lastName.isNotEmpty && 
         email.isNotEmpty && 
         password.isNotEmpty && 
         confirmPassword.isNotEmpty && 
         firstNameError == null && 
         lastNameError == null && 
         emailError == null && 
         passwordError == null && 
         confirmPasswordError == null;
});
