import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../shared/constants/strings_af.dart';

// Default to "Leriba"
final locationProvider = StateProvider<String?>((ref) => 'Leriba');

class LocationDropdown extends ConsumerWidget {
  final String? errorText;

  const LocationDropdown({
    super.key,
    this.errorText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedLocation = ref.watch(locationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          value: selectedLocation ?? 'Leriba', // fallback safeguard
          decoration: InputDecoration(
            labelText: StringsAf.locationLabel, // Add in your StringsAf file
            prefixIcon: const Icon(Icons.location_on_outlined),
            errorText: errorText,
          ),
          items: const [
            DropdownMenuItem(
              value: 'Leriba',
              child: Text('Leriba'),
            ),
            DropdownMenuItem(
              value: 'Gerhardstraat',
              child: Text('Gerhardstraat'),
            ),
            DropdownMenuItem(
              value: 'Von Willich',
              child: Text('Von Willich'),
            ),
            DropdownMenuItem(
              value: 'Die Moot',
              child: Text('Die Moot'),
            ),
          ],
          onChanged: (value) {
            ref.read(locationProvider.notifier).state = value;
          },
        ),
      ],
    );
  }
}
