import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../constants/strings_af_admin.dart';
import '../utils/validators.dart';
import '../providers/auth_form_providers.dart';

class EmailField extends ConsumerStatefulWidget {
  final String? initialEmail;
  final String? errorText;

  const EmailField({
    super.key,
    this.initialEmail,
    this.errorText,
  });

  @override
  ConsumerState<EmailField> createState() => _EmailFieldState();
}

class _EmailFieldState extends ConsumerState<EmailField> {
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();

    _emailController =
        TextEditingController(text: widget.initialEmail ?? ref.read(emailProvider));

    // Defer provider update until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(emailProvider.notifier).state = _emailController.text;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emailError = ref.watch(emailErrorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _emailController,
          onChanged: (value) {
            ref.read(emailProvider.notifier).state = value;

            // Clear or set error while typing
            final error = Validators.validateEmail(value);
            ref.read(emailErrorProvider.notifier).state = error;
          },
          onSubmitted: (value) {
            final error = Validators.validateEmail(value);
            ref.read(emailErrorProvider.notifier).state = error;
          },
          decoration: InputDecoration(
            labelText: StringsAfAdmin.emailLabel,
            hintText: 'voorbeeld@email.com',
            prefixIcon: const Icon(Icons.email_outlined),
            errorText: widget.errorText ?? emailError,
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
