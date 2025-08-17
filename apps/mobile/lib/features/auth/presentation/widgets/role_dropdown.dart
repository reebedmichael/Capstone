import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../shared/constants/strings_af.dart';

// Define a provider for the selected role
final roleProvider = StateProvider<String?>((ref) => 'Student');

class RoleDropdown extends ConsumerWidget {
  final String? errorText;

  const RoleDropdown({
    super.key,
    this.errorText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRole = ref.watch(roleProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: selectedRole,
          decoration: InputDecoration(
            labelText: StringsAf.roleLabel,
            prefixIcon: const Icon(Icons.person_outline),
            errorText: errorText,
          ),
          items: const [
            DropdownMenuItem(
              value: 'Student',
              child: Text('Student'),
            ),
            DropdownMenuItem(
              value: 'Personeel',
              child: Text('Personeel'),
            ),
            DropdownMenuItem(
              value: 'Ekstern',
              child: Text('Ekstern'),
            ),
          ],
          onChanged: (value) {
            ref.read(roleProvider.notifier).state = value;
          },
        ),
      ],
    );
  }
}
