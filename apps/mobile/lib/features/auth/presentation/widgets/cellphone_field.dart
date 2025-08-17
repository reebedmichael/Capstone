import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../shared/constants/strings_af.dart';
import '../../../../shared/utils/validators.dart';
import '../../providers/auth_form_providers.dart';

class CellphoneField extends ConsumerWidget {
  final String? errorText;
  
  const CellphoneField({
    super.key,
    this.errorText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cellphoneError = ref.watch(cellphoneErrorProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: (value) {
            ref.read(cellphoneProvider.notifier).state = value;

            final error = Validators.validateCellphone(value);
            ref.read(cellphoneErrorProvider.notifier).state = error;
          },
          onSubmitted: (value) {
            // Validate on submit
            final error = Validators.validateCellphone(value);
            ref.read(cellphoneErrorProvider.notifier).state = error;
          },
          decoration: InputDecoration(
            labelText: StringsAf.cellphoneLabel,
            hintText: '012 345 6789',
            prefixIcon: const Icon(Icons.phone),
            errorText: errorText ?? cellphoneError,
          ),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          autocorrect: false,
          enableSuggestions: false,
        ),
      ],
    );
  }
}
