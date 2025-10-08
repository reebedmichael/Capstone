import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../constants/strings_af.dart';
import '../utils/validators.dart';
import '../constants/spacing.dart';
import '../providers/auth_form_providers.dart';

class NameFields extends ConsumerStatefulWidget {
  final String? initialFirstName;
  final String? initialLastName;

  const NameFields({super.key, this.initialFirstName, this.initialLastName});

  @override
  ConsumerState<NameFields> createState() => _NameFieldsState();
}

class _NameFieldsState extends ConsumerState<NameFields> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;

  @override
void initState() {
  super.initState();

  _firstNameController = TextEditingController(text: widget.initialFirstName ?? ref.read(firstNameProvider));
  _lastNameController = TextEditingController(text: widget.initialLastName ?? ref.read(lastNameProvider));

  // Defer provider updates until after first frame
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(firstNameProvider.notifier).state = _firstNameController.text;
    ref.read(lastNameProvider.notifier).state = _lastNameController.text;
  });
}


  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firstNameError = ref.watch(firstNameErrorProvider);
    final lastNameError = ref.watch(lastNameErrorProvider);

    return Column(
      children: [
        TextField(
          controller: _firstNameController,
          onChanged: (value) {
            ref.read(firstNameProvider.notifier).state = value;

            final error = Validators.validateRequired(value);
            ref.read(firstNameErrorProvider.notifier).state = error;
          },
          onSubmitted: (value) {
            final error = Validators.validateRequired(value);
            ref.read(firstNameErrorProvider.notifier).state = error;
          },
          decoration: InputDecoration(
            labelText: StringsAf.firstNameLabel,
            hintText: 'Jou voornaam',
            prefixIcon: const Icon(Icons.person_outline),
            errorText: firstNameError,
            errorMaxLines: 3,
          ),
          textInputAction: TextInputAction.next,
          autocorrect: false,
        ),
        Spacing.vGap16,
        TextField(
          controller: _lastNameController,
          onChanged: (value) {
            ref.read(lastNameProvider.notifier).state = value;

            final error = Validators.validateRequired(value);
            ref.read(lastNameErrorProvider.notifier).state = error;
          },
          onSubmitted: (value) {
            final error = Validators.validateRequired(value);
            ref.read(lastNameErrorProvider.notifier).state = error;
          },
          decoration: InputDecoration(
            labelText: StringsAf.lastNameLabel,
            hintText: 'Jou van',
            prefixIcon: const Icon(Icons.person_outline),
            errorText: lastNameError,
            errorMaxLines: 3,
          ),
          textInputAction: TextInputAction.next,
          autocorrect: false,
        )
      ],
    );
  }
}
