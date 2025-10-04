import 'package:capstone_mobile/locator.dart';
import 'package:capstone_mobile/shared/constants/strings_af.dart';
import 'package:capstone_mobile/shared/providers/auth_form_providers.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:spys_api_client/spys_api_client.dart';

class LocationDropdown extends ConsumerStatefulWidget {
  final String? errorText;
  final String? initialValue;

  const LocationDropdown({super.key, this.errorText, this.initialValue});

  @override
  ConsumerState<LocationDropdown> createState() => _LocationDropdownState();
}

class _LocationDropdownState extends ConsumerState<LocationDropdown> {
  bool _isLoading = true;
  List<String> _locations = const [];

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final kampusRepository = sl<KampusRepository>();
      final data = await kampusRepository.kryKampusse();
      // data: List<Map<String, dynamic>?> where each map has {"kampus_naam": "..."} already selected

      final names =
          (data ?? const [])
              .where((m) => m != null && m['kampus_naam'] != null)
              .map((m) => m!['kampus_naam'].toString().trim())
              .where((s) => s.isNotEmpty)
              .toSet() // de-dupe defensively
              .toList()
            ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      if (!mounted) return;
      setState(() {
        _locations = names;
        _isLoading = false;
      });

      // After first frame, reconcile provider with initial value & loaded options.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final current = ref.read(locationProvider);

        String? next;
        if (current.isNotEmpty && _locations.contains(current)) {
          next = current; // keep current if valid
        } else if (widget.initialValue != null &&
            widget.initialValue!.isNotEmpty &&
            _locations.contains(widget.initialValue)) {
          next = widget.initialValue; // prefer provided initial if valid
        } else if (_locations.isNotEmpty) {
          next = _locations.first; // fallback to first option
        } else {
          next = ""; // nothing to select
        }

        if (next != current) {
          ref.read(locationProvider.notifier).state = next ?? "";
        }
      });
    } catch (e) {
      debugPrint("Error fetching locations: $e");
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedLocation = ref.watch(locationProvider);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Ensure the dropdown's value is one of the items or null (to avoid assertion errors).
    final value =
        (selectedLocation.isNotEmpty && _locations.contains(selectedLocation))
        ? selectedLocation
        : null;

    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: StringsAf.locationLabel,
        prefixIcon: const Icon(Icons.location_on_outlined),
        errorText: widget.errorText,
      ),
      items: _locations
          .map(
            (name) => DropdownMenuItem<String>(value: name, child: Text(name)),
          )
          .toList(),
      onChanged: (val) {
        ref.read(locationProvider.notifier).state = val ?? "";
      },
    );
  }
}
