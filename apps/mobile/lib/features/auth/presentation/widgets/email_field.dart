import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../shared/constants/strings_af.dart';
import '../../../../shared/utils/validators.dart';
import '../../providers/auth_form_providers.dart';

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
            if (emailError != null) {
              ref.read(emailErrorProvider.notifier).state = null;
            }
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
