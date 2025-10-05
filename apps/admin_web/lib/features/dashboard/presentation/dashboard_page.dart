import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart';
import '../../../locator.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  String? _error;
  
  // Dashboard data
  int _aktieweBestellings = 0;
  double _afgelopeWeekVerkope = 0.0;
  int _nuweGebruikers = 0;
  String _gewildsteKos = 'Geen data';
  List<Map<String, dynamic>> _kennisgewings = [];
  int _totaleGebruikers = 0;
  double _totaleBeursieBalans = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final sb = Supabase.instance.client;
      
      // Load active orders
      final aktieweBestellingsData = await sb
          .from('bestelling')
          .select('best_id')
          .in_('best_status', ['Wag vir afhaal', 'In voorbereiding'])
          .eq('is_aktief', true);
      _aktieweBestellings = aktieweBestellingsData.length;

      // Load sales for last 7 days
      final weekAgo = DateTime.now().subtract(const Duration(days: 7));
      final verkopeData = await sb
          .from('bestelling')
          .select('best_volledige_prys')
          .gte('best_geskep_datum', weekAgo.toIso8601String())
          .eq('is_aktief', true);
      
      _afgelopeWeekVerkope = verkopeData.fold(0.0, (sum, order) {
        return sum + ((order['best_volledige_prys'] as num?)?.toDouble() ?? 0.0);
      });

      // Load new users (last 7 days)
      final nuweGebruikersData = await sb
          .from('gebruikers')
          .select('gebr_id')
          .gte('gebr_geskep_datum', weekAgo.toIso8601String())
          .eq('is_aktief', true);
      _nuweGebruikers = nuweGebruikersData.length;

      // Load total users
      final totaleGebruikersData = await sb
          .from('gebruikers')
          .select('gebr_id')
          .eq('is_aktief', true);
      _totaleGebruikers = totaleGebruikersData.length;

      // Load total wallet balance
      final beursieData = await sb
          .from('gebruikers')
          .select('beursie_balans')
          .eq('is_aktief', true);
      
      _totaleBeursieBalans = beursieData.fold(0.0, (sum, user) {
        return sum + ((user['beursie_balans'] as num?)?.toDouble() ?? 0.0);
      });

      // Load most popular food item
      final gewildsteKosData = await sb
          .from('bestelling_kos_item')
          .select('kos_item_id, kos_item:kos_item_id(kos_item_naam)')
          .eq('is_aktief', true);
      
      if (gewildsteKosData.isNotEmpty) {
        final Map<String, int> itemCounts = {};
        for (final item in gewildsteKosData) {
          final itemName = item['kos_item']?['kos_item_naam'] as String? ?? 'Onbekend';
          itemCounts[itemName] = (itemCounts[itemName] ?? 0) + 1;
        }
        
        if (itemCounts.isNotEmpty) {
          _gewildsteKos = itemCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key;
        }
      }

      // Load recent notifications
      final kennisgewingRepo = sl<KennisgewingRepository>();
      final user = sb.auth.currentUser;
      if (user != null) {
        _kennisgewings = await kennisgewingRepo.kryKennisgewings(user.id);
        // Take only the first 3
        _kennisgewings = _kennisgewings.take(3).toList();
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading dashboard: $_error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDashboardData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

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
                    value: '$_aktieweBestellings',
                    icon: Icons.receipt_long,
                    iconColor: Theme.of(context).colorScheme.primary,
                  ),
                  _StatCard(
                    title: 'Afgelope Week Verkope',
                    value: 'R${_afgelopeWeekVerkope.toStringAsFixed(2)}',
                    icon: Icons.payments_outlined,
                    iconColor: Theme.of(context).colorScheme.secondary,
                  ),
                  _StatCard(
                    title: 'Nuwe Gebruikers (7 dae)',
                    value: '$_nuweGebruikers',
                    icon: Icons.group_add,
                    iconColor: Colors.green,
                  ),
                  _StatCard(
                    title: 'Totale Gebruikers',
                    value: '$_totaleGebruikers',
                    icon: Icons.group_outlined,
                    iconColor: Theme.of(context).colorScheme.secondary,
                  ),
                  _StatCard(
                    title: 'Totale Beursie Balans',
                    value: 'R${_totaleBeursieBalans.toStringAsFixed(2)}',
                    icon: Icons.account_balance_wallet,
                    iconColor: Colors.orange,
                  ),
                  _StatCard(
                    title: 'Gewildste Kos',
                    value: _gewildsteKos,
                    icon: Icons.star_rate_rounded,
                    iconColor: Theme.of(context).colorScheme.primary,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Notifications section (only shows if we have any)
          if (_kennisgewings.isNotEmpty)
            _CardSection(
              title: 'Belangrike Kennisgewings',
              leadingIcon: Icons.warning_amber_rounded,
              iconColor: Colors.orange,
              actions: <Widget>[
                TextButton(
                  onPressed: () => context.go('/kennisgewings'),
                  child: const Text('Bekyk Alle Kennisgewings'),
                ),
                TextButton(
                  onPressed: _loadDashboardData,
                  child: const Text('Herlaai'),
                ),
              ],
              child: Column(
                children: _kennisgewings.map((Map<String, dynamic> k) {
                  final isGelees = k['kennis_gelees'] as bool? ?? false;
                  final tipe = k['kennisgewing_tipes']?['kennis_tipe_naam'] ?? 'info';
                  final Color dotColor = tipe == 'waarskuwing'
                      ? Colors.orange
                      : tipe == 'bestelling'
                          ? Colors.blue
                          : Colors.green;
                  
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
                        border: Border.all(
                          color: isGelees ? Colors.grey.shade300 : dotColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isGelees ? Colors.grey : dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  k['kennis_beskrywing'] as String? ?? 'Kennisgewing',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: isGelees ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatDate(DateTime.parse(k['kennis_geskep_datum'])),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            isGelees ? Icons.notifications_none : Icons.notifications_active,
                            color: isGelees ? Colors.grey : dotColor,
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
                OutlinedButton.icon(
                  onPressed: () => context.go('/db-test'),
                  icon: const Icon(Icons.storage_rounded),
                  label: const Text('DB Test'),
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
