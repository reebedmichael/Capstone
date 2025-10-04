import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart';
import '../../../../core/theme/app_colors.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final String _primaryTab = 'all'; // all | unread | read
  String _secondaryTab = 'all'; // all | orders | menu | allowance

  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  Map<String, int> _statistieke = {'totaal': 0, 'ongelees': 0, 'gelees': 0};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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

    try {
      final kennisgewingRepo = KennisgewingRepository(
        SupabaseDb(Supabase.instance.client),
      );

      // Laai kennisgewings
      final kennisgewings = await kennisgewingRepo.kryKennisgewings(user.id);

      // Laai statistieke
      final stats = await kennisgewingRepo.kryKennisgewingStatistieke(user.id);

      setState(() {
        _notifications = kennisgewings;
        _statistieke = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Fout met laai kennisgewings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markeerAsGelees(String kennisId) async {
    try {
      final kennisgewingRepo = KennisgewingRepository(
        SupabaseDb(Supabase.instance.client),
      );
      await kennisgewingRepo.markeerAsGelees(kennisId);

      // Herlaai kennisgewings
      await _laaiKennisgewings();
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
    } catch (e) {
      print('Fout met markeer alles as gelees: $e');
    }
  }

  List<Map<String, dynamic>> get _gefilterdeKennisgewings {
    return _notifications.where((kennisgewing) {
      // Primêre filter (alles/ongelees/gelees)
      final bool primereMatch =
          _primaryTab == 'all' ||
          (_primaryTab == 'unread' && !kennisgewing['kennis_gelees']) ||
          (_primaryTab == 'read' && kennisgewing['kennis_gelees']);

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
        return 'general';
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
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _toonKennisgewingDetail(Map<String, dynamic> kennisgewing) {
    final tipe = _getKennisgewingTipe(kennisgewing);
    final isGelees = kennisgewing['kennis_gelees'] ?? false;
    final datum = DateTime.parse(kennisgewing['kennis_geskep_datum']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _getTipeKleur(tipe).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getTipeKleur(tipe).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                _getTipeIkoon(tipe),
                color: _getTipeKleur(tipe),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kennisgewing Besonderhede',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    _formatDate(datum),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getTipeKleur(tipe).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getTipeKleur(tipe).withOpacity(0.2),
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
                        const Spacer(),
                        if (!isGelees)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _getTipeKleur(tipe),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      kennisgewing['kennis_beskrywing'] ?? 'Kennisgewing',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Gestuur op: ${_formatDate(datum)}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    isGelees ? Icons.mark_email_read : Icons.mark_email_unread,
                    size: 16,
                    color: isGelees ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isGelees ? 'Gelees' : 'Ongelees',
                    style: TextStyle(
                      fontSize: 14,
                      color: isGelees ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (!isGelees)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _markeerAsGelees(kennisgewing['kennis_id']);
              },
              icon: const Icon(Icons.mark_email_read),
              label: const Text('Markeer as Gelees'),
              style: TextButton.styleFrom(foregroundColor: _getTipeKleur(tipe)),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maak Toe'),
          ),
        ],
      ),
    );
  }

  IconData _getTipeIkoon(String tipe) {
    switch (tipe) {
      case 'order':
        return Icons.shopping_cart;
      case 'menu':
        return Icons.restaurant_menu;
      case 'allowance':
        return Icons.account_balance_wallet;
      default:
        return Icons.notifications;
    }
  }

  Color _getTipeKleur(String tipe) {
    switch (tipe) {
      case 'order':
        return Colors.blue;
      case 'menu':
        return Colors.green;
      case 'allowance':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kennisgewings'),
        actions: [
          if (_statistieke['ongelees']! > 0)
            IconButton(
              onPressed: _markeerAllesAsGelees,
              icon: const Icon(Icons.done_all),
              tooltip: 'Markeer alles as gelees',
            ),
          IconButton(
            onPressed: _laaiKennisgewings,
            icon: const Icon(Icons.refresh),
            tooltip: 'Herlaai',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Alle'),
            Tab(text: 'Ongelees'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Statistieke
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          'Totaal',
                          '${_statistieke['totaal']}',
                          Icons.notifications,
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          'Ongelees',
                          '${_statistieke['ongelees']}',
                          Icons.notifications_active,
                          Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _statCard(
                          'Gelees',
                          '${_statistieke['gelees']}',
                          Icons.notifications_off,
                          Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // Filters
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButton<String>(
                          value: _secondaryTab,
                          isExpanded: true,
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
                              value: 'general',
                              child: Text('Algemeen'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _secondaryTab = value ?? 'all';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Kennisgewings lys
                Expanded(
                  child: _gefilterdeKennisgewings.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_none,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Geen kennisgewings nie',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _gefilterdeKennisgewings.length,
                          itemBuilder: (context, index) {
                            final kennisgewing =
                                _gefilterdeKennisgewings[index];
                            final tipe = _getKennisgewingTipe(kennisgewing);
                            final isGelees =
                                kennisgewing['kennis_gelees'] ?? false;
                            final datum = DateTime.parse(
                              kennisgewing['kennis_geskep_datum'],
                            );

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: isGelees ? 1 : 3,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isGelees
                                      ? Colors.grey.withOpacity(0.3)
                                      : _getTipeKleur(tipe).withOpacity(0.3),
                                  width: isGelees ? 1 : 2,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () =>
                                    _toonKennisgewingDetail(kennisgewing),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: _getTipeKleur(
                                            tipe,
                                          ).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(
                                            25,
                                          ),
                                          border: Border.all(
                                            color: _getTipeKleur(
                                              tipe,
                                            ).withOpacity(0.3),
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          _getTipeIkoon(tipe),
                                          color: _getTipeKleur(tipe),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    kennisgewing['kennis_beskrywing'] ??
                                                        'Kennisgewing',
                                                    style: TextStyle(
                                                      fontWeight: isGelees
                                                          ? FontWeight.w500
                                                          : FontWeight.bold,
                                                      fontSize: 16,
                                                      color: isGelees
                                                          ? Colors.grey[700]
                                                          : Colors.black87,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (!isGelees)
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: _getTipeKleur(
                                                        tipe,
                                                      ),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatDate(datum),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                                const Spacer(),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: _getTipeKleur(
                                                      tipe,
                                                    ).withOpacity(0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                    border: Border.all(
                                                      color: _getTipeKleur(
                                                        tipe,
                                                      ).withOpacity(0.3),
                                                    ),
                                                  ),
                                                  child: Text(
                                                    tipe.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: _getTipeKleur(
                                                        tipe,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      if (!isGelees)
                                        IconButton(
                                          onPressed: () => _markeerAsGelees(
                                            kennisgewing['kennis_id'],
                                          ),
                                          icon: const Icon(
                                            Icons.mark_email_read,
                                          ),
                                          tooltip: 'Markeer as gelees',
                                          color: _getTipeKleur(tipe),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
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
}
