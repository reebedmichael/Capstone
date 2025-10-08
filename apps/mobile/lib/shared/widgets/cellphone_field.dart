import 'package:capstone_mobile/shared/constants/strings_af.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../shared/utils/validators.dart';
import '../providers/auth_form_providers.dart';

class CellphoneField extends ConsumerStatefulWidget {
  final String? initialCellphone;
  final String? errorText;

  const CellphoneField({
    super.key,
    this.initialCellphone,
    this.errorText,
  });

  @override
  ConsumerState<CellphoneField> createState() => _CellphoneFieldState();
}

class _CellphoneFieldState extends ConsumerState<CellphoneField> {
  late TextEditingController _cellphoneController;

  @override
  void initState() {
    super.initState();

    _cellphoneController = TextEditingController(
      text: widget.initialCellphone ?? ref.read(cellphoneProvider),
    );

    // Defer provider update until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cellphoneProvider.notifier).state = _cellphoneController.text;
    });
  }

  @override
  void dispose() {
    _cellphoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cellphoneError = ref.watch(cellphoneErrorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _cellphoneController,
          onChanged: (value) {
            ref.read(cellphoneProvider.notifier).state = value;

            // Validate while typing
            final error = Validators.validateCellphone(value);
            ref.read(cellphoneErrorProvider.notifier).state = error;
          },
          onSubmitted: (value) {
            final error = Validators.validateCellphone(value);
            ref.read(cellphoneErrorProvider.notifier).state = error;
          },
          decoration: InputDecoration(
            labelText: StringsAf.cellphoneLabel,
            hintText: '012 345 6789',
            prefixIcon: const Icon(Icons.phone),
            errorText: widget.errorText ?? cellphoneError,
            errorMaxLines: 3,
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
