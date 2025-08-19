import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Dummy data to render the dashboard nicely
    final List<Map<String, dynamic>> kennisgewings = <Map<String, dynamic>>[
      {
        'id': 'k1',
        'beskrywing': 'Nuwe bestelling wag vir afhaal',
        'tipe': 'info',
        'datum': DateTime.now(),
      },
      {
        'id': 'k2',
        'beskrywing': 'Lae voorraad: Hoenderburgers',
        'tipe': 'waarskuwing',
        'datum': DateTime.now().subtract(const Duration(hours: 2)),
      },
      {
        'id': 'k3',
        'beskrywing': 'Verslag: Weeklikse verkope beskikbaar',
        'tipe': 'info',
        'datum': DateTime.now().subtract(const Duration(days: 1)),
      },
    ];

    final int aktieweBestellings = 8;
    final double afgelopeWeekVerkope = 4250.00;
    final int nuweGebruikers = 12;
    final String gewildsteKos = 'Vetkoek';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Stats grid
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int crossAxisCount = constraints.maxWidth > 1200
                  ? 4
                  : constraints.maxWidth > 800
                  ? 2
                  : 1;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 3.6,
                children: <Widget>[
                  _StatCard(
                    title: 'Aktiewe Bestellings',
                    value: '$aktieweBestellings',
                    icon: Icons.receipt_long,
                    iconColor: Theme.of(context).colorScheme.primary,
                  ),
                  _StatCard(
                    title: 'Afgelope Week Verkope',
                    value: 'R${afgelopeWeekVerkope.toStringAsFixed(2)}',
                    icon: Icons.payments_outlined,
                    iconColor: Theme.of(context).colorScheme.secondary,
                  ),
                  _StatCard(
                    title: 'Nuwe Gebruikers',
                    value: '$nuweGebruikers',
                    icon: Icons.group_outlined,
                    iconColor: Theme.of(context).colorScheme.secondary,
                  ),
                  _StatCard(
                    title: 'Gewildste Kos',
                    value: gewildsteKos,
                    icon: Icons.star_rate_rounded,
                    iconColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Notifications section (only shows if we have any)
          if (kennisgewings.isNotEmpty)
            _CardSection(
              title: 'Belangrike Kennisgewings',
              leadingIcon: Icons.warning_amber_rounded,
              iconColor: Colors.orange,
              actions: <Widget>[
                TextButton(
                  onPressed: () => context.go('/kennisgewings'),
                  child: const Text('Bekyk Alle Kennisgewings'),
                ),
              ],
              child: Column(
                children: kennisgewings.take(3).map((Map<String, dynamic> k) {
                  final Color dotColor = k['tipe'] == 'waarskuwing'
                      ? Colors.orange
                      : Colors.blue;
                  return InkWell(
                    onTap: () => context.go('/kennisgewings'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  k['beskrywing'] as String,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(k['datum'] as DateTime),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.notifications_none,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 24),

          // Navigation grid
          Text(
            'Bestuur Stelsel',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final int crossAxisCount = constraints.maxWidth > 1200
                  ? 3
                  : constraints.maxWidth > 800
                  ? 2
                  : 1;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.8,
                children: <Widget>[
                  _NavCard(
                    title: 'Kositems Bestuur',
                    description: 'Voeg by, wysig of verwyder kositems',
                    icon: Icons.menu_book_outlined,
                    onTap: () => context.go('/spyskaart'),
                  ),
                  _NavCard(
                    title: 'Week Spyskaart',
                    description:
                        'Bestuur huidige en volgende week se spyskaarte',
                    icon: Icons.calendar_month_outlined,
                    onTap: () => context.go('/week_spyskaart'),
                  ),
                  _NavCard(
                    title: 'Bestelling Bestuur',
                    description: 'Hanteer alle bestellings en status',
                    icon: Icons.receipt_long_outlined,
                    onTap: () => context.go('/bestellings'),
                  ),
                  _NavCard(
                    title: 'Gebruikers Bestuur',
                    description: 'Keur admins goed en bestuur rolle',
                    icon: Icons.verified_user_outlined,
                    onTap: () => context.go('/gebruikers'),
                  ),
                  _NavCard(
                    title: 'Verslae',
                    description: 'Bekyk verkope en analise data',
                    icon: Icons.bar_chart_outlined,
                    onTap: () => context.go('/verslae'),
                  ),
                  _NavCard(
                    title: 'Templates',
                    description: 'Bestuur kositem en week templates',
                    icon: Icons.article_outlined,
                    onTap: () => context.go('/templates/kositem'),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Quick actions
          _CardSection(
            title: 'Vinnige Aksies',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                OutlinedButton.icon(
                  onPressed: () => context.go('/spyskaart'),
                  icon: const Icon(Icons.add_box_outlined),
                  label: const Text('Voeg Nuwe Kos By'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/week_spyskaart'),
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: const Text('Bestuur Week Spyskaart'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/bestellings'),
                  icon: const Icon(Icons.receipt_long_outlined),
                  label: const Text('Bekyk Bestellings'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/gebruikers'),
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('Keur Admins Goed'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go('/verslae'),
                  icon: const Icon(Icons.bar_chart_outlined),
                  label: const Text('Genereer Verslag'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mrt',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    final String day = d.day.toString().padLeft(2, '0');
    final String hm =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '$day ${months[d.month - 1]} $hm';
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(
                    value,
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: iconColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardSection extends StatelessWidget {
  final String title;
  final IconData? leadingIcon;
  final Color? iconColor;
  final Widget child;
  final List<Widget>? actions;
  const _CardSection({
    required this.title,
    required this.child,
    this.leadingIcon,
    this.iconColor,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (leadingIcon != null) ...<Widget>[
                  Icon(leadingIcon, color: iconColor),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  const _NavCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
