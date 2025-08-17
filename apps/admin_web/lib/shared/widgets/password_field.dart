import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../constants/strings_af_admin.dart';
import '../utils/validators.dart';
import '../providers/auth_form_providers.dart';

class PasswordField extends ConsumerWidget {
  final String? errorText;
  final bool isConfirmPassword;
  final String? confirmPasswordValue;
  
  const PasswordField({
    super.key,
    this.errorText,
    this.isConfirmPassword = false,
    this.confirmPasswordValue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final password = ref.watch(passwordProvider);
    final passwordVisible = ref.watch(passwordVisibleProvider);
    final confirmPasswordVisible = ref.watch(confirmPasswordVisibleProvider);
    final passwordError = ref.watch(passwordErrorProvider);
    final confirmPasswordError = ref.watch(confirmPasswordErrorProvider);
    
    final currentVisible = isConfirmPassword ? confirmPasswordVisible : passwordVisible;
    final currentError = isConfirmPassword ? confirmPasswordError : passwordError;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: (value) {
            String? error;
            if (isConfirmPassword) {
              ref.read(confirmPasswordProvider.notifier).state = value;

              error = Validators.validateConfirmPassword(value, password);
              ref.read(confirmPasswordErrorProvider.notifier).state = error;
            } else {
              ref.read(passwordProvider.notifier).state = value;
              
              error = Validators.validatePasswordRegister(value);
              ref.read(passwordErrorProvider.notifier).state = error;
            }
          },
          onSubmitted: (value) {
            // Validate on submit
            String? error;
            if (isConfirmPassword) {
              error = Validators.validateConfirmPassword(value, password);
              ref.read(confirmPasswordErrorProvider.notifier).state = error;
            } else {
              error = Validators.validatePasswordRegister(value);
              ref.read(passwordErrorProvider.notifier).state = error;
            }
          },
          decoration: InputDecoration(
            labelText: isConfirmPassword ? StringsAfAdmin.confirmPasswordLabel : StringsAfAdmin.passwordLabel,
            hintText: isConfirmPassword ? 'Bevestig jou wagwoord' : 'Voer jou wagwoord in',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                currentVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                if (isConfirmPassword) {
                  ref.read(confirmPasswordVisibleProvider.notifier).state = !currentVisible;
                } else {
                  ref.read(passwordVisibleProvider.notifier).state = !currentVisible;
                }
              },
            ),
            errorText: errorText ?? currentError,
          ),
          obscureText: !currentVisible,
          textInputAction: isConfirmPassword ? TextInputAction.done : TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
        ),
      ],
    );
  }
}
