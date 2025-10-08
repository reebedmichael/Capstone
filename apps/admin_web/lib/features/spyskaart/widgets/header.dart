import 'package:flutter/material.dart';
import 'models.dart';

class HeaderWidget extends StatelessWidget {
  final VoidCallback? onBack;
  final String aktieweWeek;
  final WeekSpyskaart? volgendeWeek;
  final VoidCallback onOpenTemplate;
  final VoidCallback onSaveTemplate;
  final VoidCallback onOpenSend;

  const HeaderWidget({
    super.key,
    this.onBack,
    required this.aktieweWeek,
    required this.volgendeWeek,
    required this.onOpenTemplate,
    required this.onSaveTemplate,
    required this.onOpenSend,
  });

  @override
  Widget build(BuildContext context) {
    final isTemplateDisabled =
        (aktieweWeek == 'huidige' ||
        volgendeWeek == null ||
        (volgendeWeek != null &&
            DateTime.now().isAfter(volgendeWeek!.sperdatum)));

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600; // breakpoint for mobile

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Week Spyskaart Bestuur',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bestuur huidige en volgende week se spyskaarte',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: isTemplateDisabled ? null : onOpenTemplate,
                          icon: const Icon(Icons.file_copy),
                          label: const Text('Laai Templaat'),
                        ),
                        OutlinedButton.icon(
                          onPressed: onSaveTemplate,
                          icon: const Icon(Icons.save),
                          label: const Text('Stoor as Templaat'),
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Week Spyskaart Bestuur',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bestuur huidige en volgende week se spyskaarte',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: isTemplateDisabled ? null : onOpenTemplate,
                          icon: const Icon(Icons.file_copy),
                          label: const Text('Laai Templaat'),
                        ),
                        OutlinedButton.icon(
                          onPressed: onSaveTemplate,
                          icon: const Icon(Icons.save),
                          label: const Text('Stoor as Templaat'),
                        ),
                        // if (aktieweWeek == 'volgende' &&
                        //     volgendeWeek != null &&
                        //     volgendeWeek!.status == 'konsep')
                        //   FilledButton.icon(
                        //     onPressed: onOpenSend,
                        //     icon: const Icon(Icons.send),
                        //     label: const Text('Goedkeuring'),
                        //   ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }
}
