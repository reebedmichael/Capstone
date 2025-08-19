// week_info_card.dart
import 'package:flutter/material.dart';
import 'models.dart';

class WeekInfoCard extends StatelessWidget {
  final String aktieweWeek;
  final WeekSpyskaart? huidige;
  final WeekSpyskaart? volgende;

  const WeekInfoCard({
    super.key,
    required this.aktieweWeek,
    required this.huidige,
    required this.volgende,
  });

  String _format(DateTime d) {
    const months = [
      'Januarie',
      'Februarie',
      'Maart',
      'April',
      'Mei',
      'Junie',
      'Julie',
      'Augustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final sp = aktieweWeek == 'huidige' ? huidige : volgende;
    if (sp == null) return const SizedBox();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        aktieweWeek == 'huidige'
                            ? Icons.check_circle
                            : Icons.edit,
                        color: aktieweWeek == 'huidige'
                            ? Colors.green
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        aktieweWeek == 'huidige'
                            ? 'Huidige Week Spyskaart'
                            : 'Volgende Week Spyskaart',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${_format(sp.weekBegin)} tot ${_format(sp.weekEinde)}'),
                  const SizedBox(height: 6),
                  if (aktieweWeek == 'huidige')
                    Text(
                      '• Jy kan items byvoeg, maar nie verwyder nie',
                      style: const TextStyle(color: Colors.green),
                    ),
                  if (aktieweWeek == 'volgende')
                    Text(
                      sp.status == 'konsep'
                          ? '• Konsep - wysigings volgens sperdatum'
                          : '• Goedgekeur',
                    ),
                ],
              ),
            ),
            if (aktieweWeek == 'volgende')
              Column(
                children: [
                  Chip(
                    label: Text(
                      sp.status == 'konsep' ? 'Konsep' : 'Goedgekeur',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Chip(label: Text('Sperdatum: ${_format(sp.sperdatum)}')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
