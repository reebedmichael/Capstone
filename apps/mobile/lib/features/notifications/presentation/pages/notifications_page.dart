import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart';
import 'package:spys_api_client/src/notification_archive_service.dart';
import '../../../../shared/state/notification_badge.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _primaryTab = 'all'; // all | unread | read | archived
  String _secondaryTab = 'all'; // all | orders | menu | allowance

  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _globaleKennisgewings = [];
  List<String> _archivedNotificationIds = [];
  List<String> _deletedNotificationIds = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  Map<String, int> _statistieke = {
    'totaal': 0,
    'ongelees': 0,
    'gelees': 0,
    'geargiveer': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _primaryTab = 'all';
            break;
          case 1:
            _primaryTab = 'unread';
            break;
          case 2:
            _primaryTab = 'read';
            break;
          case 3:
            _primaryTab = 'archived';
            break;
        }
      });
    });
    _laaiKennisgewings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _laaiKennisgewings() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      if (!_isRefreshing) _isLoading = true;
    });

    try {
      final kennisgewingRepo = KennisgewingRepository(
        SupabaseDb(Supabase.instance.client),
      );

      // Laai gebruiker en globale kennisgewings
      final kennisgewings = await kennisgewingRepo.kryKennisgewings(user.id);
      final globale = await kennisgewingRepo.kryGlobaleKennisgewings();

      // Laai geargiveerde IDs vanaf lokale stoor
      final archivedIds =
          await NotificationArchiveService.getArchivedNotificationIds();
      final deletedIds =
          await NotificationArchiveService.getDeletedNotificationIds();

      setState(() {
        _notifications = kennisgewings;
        _globaleKennisgewings = globale;
        _archivedNotificationIds = archivedIds;
        _deletedNotificationIds = deletedIds;
        _isLoading = false;
        _isRefreshing = false;
      });

      // Calculate statistics from combined notifications
      final alleKennisgewings = _alleKennisgewings;
      final ongeleesKennisgewings = alleKennisgewings
          .where(
            (k) =>
                !(k['kennis_gelees'] ?? false) &&
                !(k['kennis_geargiveer'] ?? false),
          )
          .toList();
      final geleesKennisgewings = alleKennisgewings
          .where(
            (k) =>
                (k['kennis_gelees'] ?? false) &&
                !(k['kennis_geargiveer'] ?? false),
          )
          .toList();
      final geargiveerdeKennisgewings = alleKennisgewings
          .where((k) => (k['kennis_geargiveer'] ?? false))
          .toList();

      final stats = {
        'totaal': alleKennisgewings.length,
        'ongelees': ongeleesKennisgewings.length,
        'gelees': geleesKennisgewings.length,
        'geargiveer': geargiveerdeKennisgewings.length,
      };

      setState(() {
        _statistieke = stats;
      });

      // Update global notification badge
      NotificationBadgeState.unreadCount.value = stats['ongelees'] ?? 0;
    } catch (e) {
      print('Fout met laai kennisgewings: $e');
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    setState(() {
      _isRefreshing = true;
    });
    await _laaiKennisgewings();
  }

  Future<void> _markeerAsGelees(String kennisId) async {
    try {
      final kennisgewingRepo = KennisgewingRepository(
        SupabaseDb(Supabase.instance.client),
      );
      await kennisgewingRepo.markeerAsGelees(kennisId);

      // Herlaai kennisgewings
      await _laaiKennisgewings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kennisgewing gemerk as gelees'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Fout met markeer as gelees: $e');
    }
  }

  Future<void> _markeerAllesAsGelees() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final kennisgewingRepo = KennisgewingRepository(
        SupabaseDb(Supabase.instance.client),
      );
      await kennisgewingRepo.markeerAllesAsGelees(user.id);

      // Herlaai kennisgewings
      await _laaiKennisgewings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alle kennisgewings gemerk as gelees'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Fout met markeer alles as gelees: $e');
    }
  }

  Future<void> _herstelGeargiveerdeKennisgewing(String kennisId) async {
    try {
      await NotificationArchiveService.restoreNotification(kennisId);

      // Herlaai kennisgewings
      await _laaiKennisgewings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kennisgewing herstel'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Fout met herstel kennisgewing: $e');
    }
  }

  Future<void> _verwyderGeargiveerdeKennisgewing(String kennisId) async {
    try {
      await NotificationArchiveService.permanentlyDeleteNotification(kennisId);

      // Herlaai kennisgewings
      await _laaiKennisgewings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kennisgewing permanent verwyder'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      print('Fout met verwyder kennisgewing: $e');
    }
  }

  // Kombineer gebruiker en globale kennisgewings met lokale argief status
  List<Map<String, dynamic>> get _alleKennisgewings {
    final List<Map<String, dynamic>> alle = [];

    // Voeg gebruiker kennisgewings by (filter uit permanent verwyderde)
    for (var k in _notifications) {
      final kennisId = k['kennis_id']?.toString();
      if (kennisId != null && !_deletedNotificationIds.contains(kennisId)) {
        final isArchived = _archivedNotificationIds.contains(kennisId);
        alle.add({
          ...k,
          '_kennisgewing_soort': 'gebruiker',
          'kennis_geargiveer': isArchived,
        });
      }
    }

    // Voeg globale kennisgewings by (sonder gelees status)
    for (var k in _globaleKennisgewings) {
      alle.add({
        ...k,
        '_kennisgewing_soort': 'globaal',
        'kennis_gelees':
            false, // Globale kennisgewings het nie gelees status nie
        'kennis_geargiveer':
            false, // Globale kennisgewings kan nie geargiveer word nie
      });
    }

    // Sorteer op datum (nuutste eerste)
    alle.sort((a, b) {
      final dateA = DateTime.parse(
        a['kennis_geskep_datum'] ?? a['glob_kennis_geskep_datum'],
      );
      final dateB = DateTime.parse(
        b['kennis_geskep_datum'] ?? b['glob_kennis_geskep_datum'],
      );
      return dateB.compareTo(dateA);
    });

    return alle;
  }

  List<Map<String, dynamic>> get _gefilterdeKennisgewings {
    return _alleKennisgewings.where((kennisgewing) {
      // Primêre filter (alles/ongelees/gelees/geargiveer)
      final bool primereMatch =
          _primaryTab == 'all' ||
          (_primaryTab == 'unread' &&
              !(kennisgewing['kennis_gelees'] ?? false) &&
              !(kennisgewing['kennis_geargiveer'] ?? false)) ||
          (_primaryTab == 'read' &&
              (kennisgewing['kennis_gelees'] ?? false) &&
              !(kennisgewing['kennis_geargiveer'] ?? false)) ||
          (_primaryTab == 'archived' &&
              (kennisgewing['kennis_geargiveer'] ?? false));

      // Sekondere filter (tipe)
      final bool sekondereMatch =
          _secondaryTab == 'all' ||
          _getKennisgewingTipe(kennisgewing) == _secondaryTab;

      return primereMatch && sekondereMatch;
    }).toList();
  }

  String _getKennisgewingTipe(Map<String, dynamic> kennisgewing) {
    final tipeNaam =
        kennisgewing['kennisgewing_tipes']?['kennis_tipe_naam'] ?? 'info';

    // Map kennisgewing tipes na app tipes
    switch (tipeNaam.toLowerCase()) {
      case 'bestelling':
      case 'order':
        return 'order';
      case 'spyskaart':
      case 'menu':
        return 'menu';
      case 'toelaag':
      case 'allowance':
        return 'allowance';
      default:
        return 'algemeen';
    }
  }

  String _formatDate(DateTime date) {
    const months = [
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
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} '
        '${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return _formatDate(date);
    } else if (difference.inDays > 0) {
      return '${difference.inDays} dag${difference.inDays > 1 ? 'e' : ''} gelede';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} u${difference.inHours > 1 ? 'ur' : 'ur'} gelede';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min gelede';
    } else {
      return 'Nou net';
    }
  }

  Widget _compactStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'order':
        return Colors.blue;
      case 'menu':
        return Colors.green;
      case 'allowance':
        return Colors.orange;
      case 'algemeen':
        return Colors.purple;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _getFilterLabel(String filter) {
    switch (filter) {
      case 'order':
        return 'Bestellings';
      case 'menu':
        return 'Spyskaart';
      case 'allowance':
        return 'Toelaag';
      case 'algemeen':
        return 'Algemeen';
      default:
        return 'Alle tipes';
    }
  }

  void _toonKennisgewingDetail(Map<String, dynamic> kennisgewing) {
    final soort = kennisgewing['_kennisgewing_soort'] ?? 'gebruiker';
    final isGelees = kennisgewing['kennis_gelees'] ?? false;
    final tipe =
        kennisgewing['kennisgewing_tipes']?['kennis_tipe_naam'] ?? 'info';
    final titel =
        kennisgewing['kennis_titel'] ?? kennisgewing['glob_kennis_titel'] ?? '';
    final beskrywing =
        kennisgewing['kennis_beskrywing'] ??
        kennisgewing['glob_kennis_beskrywing'] ??
        'Kennisgewing';
    final datum = DateTime.parse(
      kennisgewing['kennis_geskep_datum'] ??
          kennisgewing['glob_kennis_geskep_datum'],
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header met ikoon en badge
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _getTipeKleur(tipe).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _getTipeKleur(tipe).withOpacity(0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _getTipeIkoon(tipe),
                            color: _getTipeKleur(tipe),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: soort == 'globaal'
                                          ? Colors.green.withOpacity(0.15)
                                          : Colors.blue.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: soort == 'globaal'
                                            ? Colors.green
                                            : Colors.blue,
                                      ),
                                    ),
                                    child: Text(
                                      soort == 'globaal'
                                          ? 'GLOBAAL'
                                          : 'PERSOONLIK',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: soort == 'globaal'
                                            ? Colors.green
                                            : Colors.blue,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (!isGelees && soort == 'gebruiker')
                                    Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: _getTipeKleur(tipe),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTimeAgo(datum),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Titel (as dit bestaan)
                    if (titel.isNotEmpty) ...[
                      Text(
                        titel,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Beskrywing
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: _getTipeKleur(tipe).withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getTipeKleur(tipe).withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _getTipeIkoon(tipe),
                                color: _getTipeKleur(tipe),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                tipe.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _getTipeKleur(tipe),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            beskrywing,
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(height: 1.6, fontSize: 16),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Meta inligting
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 18,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Gestuur op: ${_formatDate(datum)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          if (soort == 'gebruiker') ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  isGelees
                                      ? Icons.mark_email_read
                                      : Icons.mark_email_unread,
                                  size: 18,
                                  color: isGelees
                                      ? Colors.green
                                      : Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  isGelees ? 'Gelees' : 'Ongelees',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isGelees
                                        ? Colors.green
                                        : Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (!isGelees && soort == 'gebruiker') ...[
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _markeerAsGelees(kennisgewing['kennis_id']);
                        },
                        icon: const Icon(Icons.mark_email_read),
                        label: const Text('Markeer as Gelees'),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Maak Toe'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTipeIkoon(String tipe) {
    switch (tipe.toLowerCase()) {
      case 'waarskuwing':
        return Icons.warning_amber_rounded;
      case 'fout':
        return Icons.error_outline;
      case 'sukses':
        return Icons.check_circle_outline;
      case 'help':
        return Icons.help_outline;
      default:
        return Icons.info_outline;
    }
  }

  Color _getTipeKleur(String tipe) {
    switch (tipe.toLowerCase()) {
      case 'waarskuwing':
        return Colors.orange;
      case 'fout':
        return Colors.red;
      case 'sukses':
        return Colors.green;
      case 'help':
        return Colors.purple;
      default:
        return Colors.blue;
    }
  }

  DismissDirection _getDismissDirection(Map<String, dynamic> kennisgewing) {
    final isGelees = kennisgewing['kennis_gelees'] ?? false;
    final isGeargiveer = kennisgewing['kennis_geargiveer'] ?? false;
    final soort = kennisgewing['_kennisgewing_soort'] ?? '';

    if (isGeargiveer) {
      return DismissDirection.horizontal; // Allow both directions for archived
    } else if (isGelees || soort == 'globaal') {
      return DismissDirection.none;
    } else {
      return DismissDirection.endToStart;
    }
  }

  Widget _getDismissBackground(Map<String, dynamic> kennisgewing, String tipe) {
    final isGeargiveer = kennisgewing['kennis_geargiveer'] ?? false;

    if (isGeargiveer) {
      return Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_forever, color: Colors.red, size: 20),
      );
    } else {
      return Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: _getTipeKleur(tipe).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.mark_email_read,
          color: _getTipeKleur(tipe),
          size: 20,
        ),
      );
    }
  }

  void _handleDismiss(
    Map<String, dynamic> kennisgewing,
    DismissDirection direction,
  ) {
    final isGeargiveer = kennisgewing['kennis_geargiveer'] ?? false;
    final soort = kennisgewing['_kennisgewing_soort'] ?? '';

    if (isGeargiveer) {
      if (direction == DismissDirection.startToEnd) {
        // Restore archived notification
        _herstelGeargiveerdeKennisgewing(kennisgewing['kennis_id']);
      } else if (direction == DismissDirection.endToStart) {
        // Permanently delete archived notification
        _verwyderGeargiveerdeKennisgewing(kennisgewing['kennis_id']);
      }
    } else if (!(kennisgewing['kennis_gelees'] ?? false) &&
        soort == 'gebruiker') {
      // Mark as read for regular notifications
      _markeerAsGelees(kennisgewing['kennis_id']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
        title: const Text('Kennisgewings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          // Filter button
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
            onSelected: (value) {
              setState(() {
                _secondaryTab = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.select_all),
                    SizedBox(width: 12),
                    Text('Alle Tipes'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'order',
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart, color: Colors.blue),
                    SizedBox(width: 12),
                    Text('Bestellings'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'menu',
                child: Row(
                  children: [
                    Icon(Icons.restaurant_menu, color: Colors.green),
                    SizedBox(width: 12),
                    Text('Spyskaart'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'allowance',
                child: Row(
                  children: [
                    Icon(Icons.account_balance_wallet, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('Toelaag'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'algemeen',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.purple),
                    SizedBox(width: 12),
                    Text('Algemeen'),
                  ],
                ),
              ),
            ],
          ),
          if (_statistieke['ongelees']! > 0)
            IconButton(
              onPressed: _markeerAllesAsGelees,
              icon: const Icon(Icons.done_all),
              tooltip: 'Markeer alles as gelees',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Alle'),
                  if (_statistieke['totaal']! > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_statistieke['totaal']}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Ongelees'),
                  if (_statistieke['ongelees']! > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_statistieke['ongelees']}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onError,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Gelees'),
                  if (_statistieke['gelees']! > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.tertiary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_statistieke['gelees']}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onTertiary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Geargiveer'),
                  if (_statistieke['geargiveer']! > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.outline,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_statistieke['geargiveer']}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Compact statistics row
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _compactStatCard(
                              'Totaal',
                              '${_statistieke['totaal']}',
                              Icons.notifications,
                              Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _compactStatCard(
                              'Ongelees',
                              '${_statistieke['ongelees']}',
                              Icons.notifications_active,
                              Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _compactStatCard(
                              'Gelees',
                              '${_statistieke['gelees']}',
                              Icons.notifications_off,
                              Theme.of(context).colorScheme.tertiary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Filters section
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(
                              context,
                            ).colorScheme.shadow.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.filter_list,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Filter kennisgewings',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getFilterColor(
                                    _secondaryTab,
                                  ).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: _getFilterColor(
                                      _secondaryTab,
                                    ).withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _getFilterLabel(_secondaryTab),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: _getFilterColor(_secondaryTab),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButton<String>(
                            value: _secondaryTab,
                            isExpanded: true,
                            underline: const SizedBox(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                              fontSize: 15,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'all',
                                child: Text('Alle tipes'),
                              ),
                              DropdownMenuItem(
                                value: 'order',
                                child: Text('Bestellings'),
                              ),
                              DropdownMenuItem(
                                value: 'menu',
                                child: Text('Spyskaart'),
                              ),
                              DropdownMenuItem(
                                value: 'allowance',
                                child: Text('Toelaag'),
                              ),
                              DropdownMenuItem(
                                value: 'algemeen',
                                child: Text('Algemeen'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _secondaryTab = value ?? 'all';
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    // Notifications section
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.notifications,
                            color: Theme.of(context).colorScheme.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Kennisgewings',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_gefilterdeKennisgewings.length}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Notifications list
                    _gefilterdeKennisgewings.isEmpty
                        ? Container(
                            height: 250,
                            margin: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outline.withOpacity(0.1),
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Theme.of(context).colorScheme.primary
                                              .withOpacity(0.1),
                                          Theme.of(context).colorScheme.primary
                                              .withOpacity(0.05),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.notifications_none,
                                      size: 32,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Geen kennisgewings nie',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Jy sal hier kennisgewings sien wanneer daar nuus is',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _gefilterdeKennisgewings.length,
                            itemBuilder: (context, index) {
                              final kennisgewing =
                                  _gefilterdeKennisgewings[index];
                              final soort =
                                  kennisgewing['_kennisgewing_soort'] ??
                                  'gebruiker';
                              final tipe =
                                  kennisgewing['kennisgewing_tipes']?['kennis_tipe_naam'] ??
                                  'info';
                              final isGelees =
                                  kennisgewing['kennis_gelees'] ?? false;
                              final titel =
                                  kennisgewing['kennis_titel'] ??
                                  kennisgewing['glob_kennis_titel'] ??
                                  '';
                              final beskrywing =
                                  kennisgewing['kennis_beskrywing'] ??
                                  kennisgewing['glob_kennis_beskrywing'] ??
                                  'Kennisgewing';
                              final datum = DateTime.parse(
                                kennisgewing['kennis_geskep_datum'] ??
                                    kennisgewing['glob_kennis_geskep_datum'],
                              );

                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: Duration(
                                  milliseconds: 300 + (index * 50),
                                ),
                                curve: Curves.easeOut,
                                builder: (context, value, child) {
                                  return Opacity(
                                    opacity: value,
                                    child: Transform.translate(
                                      offset: Offset(0, 20 * (1 - value)),
                                      child: child,
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 6),
                                  child: Dismissible(
                                    key: Key(
                                      kennisgewing['kennis_id'] ??
                                          kennisgewing['glob_kennis_id'],
                                    ),
                                    direction: _getDismissDirection(
                                      kennisgewing,
                                    ),
                                    background: _getDismissBackground(
                                      kennisgewing,
                                      tipe,
                                    ),
                                    onDismissed: (direction) {
                                      _handleDismiss(kennisgewing, direction);
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        color: isGelees
                                            ? Theme.of(context)
                                                  .colorScheme
                                                  .surfaceVariant
                                                  .withOpacity(0.3)
                                            : _getTipeKleur(
                                                tipe,
                                              ).withOpacity(0.05),
                                        border: Border.all(
                                          color: isGelees
                                              ? Theme.of(context)
                                                    .colorScheme
                                                    .outline
                                                    .withOpacity(0.2)
                                              : _getTipeKleur(
                                                  tipe,
                                                ).withOpacity(0.2),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isGelees
                                                ? Colors.grey.withOpacity(0.05)
                                                : _getTipeKleur(
                                                    tipe,
                                                  ).withOpacity(0.1),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          onTap: () => _toonKennisgewingDetail(
                                            kennisgewing,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Row(
                                              children: [
                                                // Compact icon
                                                Container(
                                                  width: 36,
                                                  height: 36,
                                                  decoration: BoxDecoration(
                                                    color: _getTipeKleur(
                                                      tipe,
                                                    ).withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          18,
                                                        ),
                                                    border: Border.all(
                                                      color: _getTipeKleur(
                                                        tipe,
                                                      ).withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Stack(
                                                    children: [
                                                      Center(
                                                        child: Icon(
                                                          _getTipeIkoon(tipe),
                                                          color: _getTipeKleur(
                                                            tipe,
                                                          ),
                                                          size: 18,
                                                        ),
                                                      ),
                                                      if (!isGelees)
                                                        Positioned(
                                                          top: 4,
                                                          right: 4,
                                                          child: Container(
                                                            width: 8,
                                                            height: 8,
                                                            decoration:
                                                                BoxDecoration(
                                                                  color:
                                                                      _getTipeKleur(
                                                                        tipe,
                                                                      ),
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        titel.isNotEmpty
                                                            ? titel
                                                            : beskrywing,
                                                        style: TextStyle(
                                                          fontWeight: isGelees
                                                              ? FontWeight.w500
                                                              : FontWeight.w600,
                                                          fontSize: 14,
                                                          color: isGelees
                                                              ? Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .onSurface
                                                                    .withOpacity(
                                                                      0.7,
                                                                    )
                                                              : Theme.of(
                                                                      context,
                                                                    )
                                                                    .colorScheme
                                                                    .onSurface,
                                                          height: 1.2,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Row(
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal: 6,
                                                                  vertical: 2,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  _getTipeKleur(
                                                                    tipe,
                                                                  ).withOpacity(
                                                                    0.1,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    8,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              tipe.toUpperCase(),
                                                              style: TextStyle(
                                                                fontSize: 8,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    _getTipeKleur(
                                                                      tipe,
                                                                    ),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Icon(
                                                            Icons.access_time,
                                                            size: 12,
                                                            color: Theme.of(context)
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                          ),
                                                          const SizedBox(
                                                            width: 2,
                                                          ),
                                                          Text(
                                                            _formatTimeAgo(
                                                              datum,
                                                            ),
                                                            style: TextStyle(
                                                              fontSize: 10,
                                                              color: Theme.of(context)
                                                                  .colorScheme
                                                                  .onSurfaceVariant,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (!isGelees &&
                                                    soort == 'gebruiker') ...[
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      color: _getTipeKleur(
                                                        tipe,
                                                      ).withOpacity(0.1),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                    ),
                                                    child: IconButton(
                                                      onPressed: () =>
                                                          _markeerAsGelees(
                                                            kennisgewing['kennis_id'],
                                                          ),
                                                      icon: Icon(
                                                        Icons.mark_email_read,
                                                        color: _getTipeKleur(
                                                          tipe,
                                                        ),
                                                        size: 16,
                                                      ),
                                                      tooltip:
                                                          'Markeer as gelees',
                                                      constraints:
                                                          const BoxConstraints(
                                                            minWidth: 32,
                                                            minHeight: 32,
                                                          ),
                                                      padding: EdgeInsets.zero,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
