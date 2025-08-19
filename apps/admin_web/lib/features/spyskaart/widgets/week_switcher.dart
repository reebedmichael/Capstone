// week_switcher.dart
import 'package:flutter/material.dart';
import 'models.dart';

class WeekSwitcher extends StatelessWidget {
  final WeekSpyskaart? huidigeWeek;
  final WeekSpyskaart? volgendeWeek;
  final String aktieweWeek;
  final void Function(String) onChange;

  const WeekSwitcher({
    super.key,
    required this.huidigeWeek,
    required this.volgendeWeek,
    required this.aktieweWeek,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    Widget btn(String key, String label, String? chip, bool active) {
      final child = Row(
        children: [
          Text(label),
          if (chip != null) ...[
            const SizedBox(width: 8),
            Chip(label: Text(chip)),
          ],
        ],
      );
      return Expanded(
        child: active
            ? FilledButton(onPressed: () => onChange(key), child: child)
            : OutlinedButton(onPressed: () => onChange(key), child: child),
      );
    }

    return Row(
      children: [
        btn(
          'huidige',
          'Huidige Week',
          huidigeWeek != null ? 'Aktief' : null,
          aktieweWeek == 'huidige',
        ),
        const SizedBox(width: 12),
        btn(
          'volgende',
          'Volgende Week',
          volgendeWeek != null
              ? (volgendeWeek!.status == 'konsep' ? 'Konsep' : 'Goedgekeur')
              : null,
          aktieweWeek == 'volgende',
        ),
      ],
    );
  }
}
