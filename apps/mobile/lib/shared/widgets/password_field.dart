import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../constants/strings_af.dart';
import '../utils/validators.dart';
import '../providers/auth_form_providers.dart';

class PasswordField extends ConsumerStatefulWidget {
  final bool isConfirmPassword;

  const PasswordField({
    super.key,
    this.isConfirmPassword = false,
  });

  @override
  ConsumerState<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends ConsumerState<PasswordField> {
  @override
  Widget build(BuildContext context) {
    final password = ref.watch(passwordProvider);
    final passwordVisible = ref.watch(passwordVisibleProvider);
    final confirmPasswordVisible = ref.watch(confirmPasswordVisibleProvider);
    final passwordError = ref.watch(passwordErrorProvider);
    final confirmPasswordError = ref.watch(confirmPasswordErrorProvider);

    final currentVisible =
        widget.isConfirmPassword ? confirmPasswordVisible : passwordVisible;
    final currentError =
        widget.isConfirmPassword ? confirmPasswordError : passwordError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: (value) {
            String? error;
            if (widget.isConfirmPassword) {
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
            if (widget.isConfirmPassword) {
              error = Validators.validateConfirmPassword(value, password);
              ref.read(confirmPasswordErrorProvider.notifier).state = error;
            } else {
              error = Validators.validatePasswordRegister(value);
              ref.read(passwordErrorProvider.notifier).state = error;
            }
          },
          decoration: InputDecoration(
            labelText: widget.isConfirmPassword
                ? StringsAf.confirmPasswordLabel
                : StringsAf.passwordLabel,
            hintText: widget.isConfirmPassword
                ? 'Bevestig jou wagwoord'
                : 'Voer jou wagwoord in',
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                currentVisible ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                if (widget.isConfirmPassword) {
                  ref
                      .read(confirmPasswordVisibleProvider.notifier)
                      .state = !currentVisible;
                } else {
                  ref
                      .read(passwordVisibleProvider.notifier)
                      .state = !currentVisible;
                }
              },
            ),
            errorText: currentError,
            errorMaxLines: 3,
          ),
          obscureText: !currentVisible,
          textInputAction: widget.isConfirmPassword
              ? TextInputAction.done
              : TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
        ),
      ],
    );
  }
}
