import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../constants/strings_af.dart';
import '../utils/validators.dart';
import '../constants/spacing.dart';
import '../providers/auth_form_providers.dart';

class NameFields extends ConsumerWidget {
  const NameFields({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firstNameError = ref.watch(firstNameErrorProvider);
    final lastNameError = ref.watch(lastNameErrorProvider);
    
    return Column(
      children: [
        TextField(
            onChanged: (value) {
              ref.read(firstNameProvider.notifier).state = value;

              final error = Validators.validateRequired(value);
              ref.read(firstNameErrorProvider.notifier).state = error;
            },
            onSubmitted: (value) {
              // Validate on submit
              final error = Validators.validateRequired(value);
              ref.read(firstNameErrorProvider.notifier).state = error;
            },
            decoration: InputDecoration(
              labelText: StringsAf.firstNameLabel,
              hintText: 'Jou voornaam',
              prefixIcon: const Icon(Icons.person_outline),
              errorText: firstNameError,
            ),
            textInputAction: TextInputAction.next,
            autocorrect: false,
        ),
        Spacing.vGap16,
        TextField(
            onChanged: (value) {
              ref.read(lastNameProvider.notifier).state = value;
              
              final error = Validators.validateRequired(value);
              ref.read(lastNameErrorProvider.notifier).state = error;
            },
            onSubmitted: (value) {
              // Validate on submit
              final error = Validators.validateRequired(value);
              ref.read(lastNameErrorProvider.notifier).state = error;
            },
            decoration: InputDecoration(
              labelText: StringsAf.lastNameLabel,
              hintText: 'Jou van',
              prefixIcon: const Icon(Icons.person_outline),
              errorText: lastNameError,
            ),
            textInputAction: TextInputAction.next,
            autocorrect: false,
          ),
      ],
    );
  }
}
