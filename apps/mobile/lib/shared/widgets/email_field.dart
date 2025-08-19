import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../constants/strings_af.dart';
import '../utils/validators.dart';
import '../providers/auth_form_providers.dart';

class EmailField extends ConsumerWidget {
  final String? errorText;
  
  const EmailField({
    super.key,
    this.errorText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailError = ref.watch(emailErrorProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: (value) {
            ref.read(emailProvider.notifier).state = value;
            // Clear error when user starts typing
            final error = Validators.validateEmail(value);
            ref.read(emailErrorProvider.notifier).state = error;
          },
          onSubmitted: (value) {
            // Validate on submit
            final error = Validators.validateEmail(value);
            ref.read(emailErrorProvider.notifier).state = error;
          },
          decoration: InputDecoration(
            labelText: StringsAf.emailLabel,
            hintText: 'voorbeeld@email.com',
            prefixIcon: const Icon(Icons.email_outlined),
            errorText: errorText ?? emailError,
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
        ),
      ],
    );
  }
}
