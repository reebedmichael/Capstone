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
      final child = Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label),
            // if (chip != null) ...[
            //   const SizedBox(width: 8),
            //   Chip(label: Text(chip)),
            // ],
          ],
        ),
      );
      final button = active
          ? FilledButton(onPressed: () => onChange(key), child: child)
          : OutlinedButton(onPressed: () => onChange(key), child: child);

      return Expanded(child: button);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 500;

        if (isSmallScreen) {
          // Column layout for small screens
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              btn(
                'huidige',
                'Huidige Week',
                huidigeWeek != null ? 'Aktief' : null,
                aktieweWeek == 'huidige',
              ),
              const SizedBox(height: 12),
              btn(
                'volgende',
                'Volgende Week',
                volgendeWeek != null
                    ? (volgendeWeek!.status == 'konsep'
                          ? 'Beplanning'
                          : 'Goedgekeur')
                    : null,
                aktieweWeek == 'volgende',
              ),
            ],
          );
        } else {
          // Row layout for larger screens
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
                    ? (volgendeWeek!.status == 'konsep'
                          ? 'Beplanning'
                          : 'Goedgekeur')
                    : null,
                aktieweWeek == 'volgende',
              ),
            ],
          );
        }
      },
    );
  }
}
