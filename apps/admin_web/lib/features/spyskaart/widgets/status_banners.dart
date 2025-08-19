// status_banners.dart
import 'package:flutter/material.dart';

class StatusBanners extends StatelessWidget {
  final String sukses;
  final String fout;
  const StatusBanners({super.key, required this.sukses, required this.fout});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (sukses.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(child: Text(sukses)),
              ],
            ),
          ),
        if (fout.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text(fout)),
              ],
            ),
          ),
      ],
    );
  }
}
