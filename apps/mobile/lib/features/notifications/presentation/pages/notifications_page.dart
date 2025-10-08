import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int _currentTabIndex = 0; // 0 = Alle, 1 = Ongelees
  String _tipeFilter = 'all'; // all | info | waarskuwing | sukses | fout

  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _globaleKennisgewings = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  Map<String, int> _statistieke = {'totaal': 0, 'ongelees': 0, 'gelees': 0};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
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

      // Laai beide gebruiker en globale kennisgewings
      final kennisgewings = await kennisgewingRepo.kryKennisgewings(user.id);
      final globale = await kennisgewingRepo.kryGlobaleKennisgewings();

      // Laai statistieke
      final stats = await kennisgewingRepo.kryKennisgewingStatistieke(user.id);

      setState(() {
        _notifications = kennisgewings;
        _globaleKennisgewings = globale;
        _statistieke = stats;
        _isLoading = false;
        _isRefreshing = false;
      });
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

  // Kombineer beide gebruiker en globale kennisgewings
  List<Map<String, dynamic>> get _alleKennisgewings {
    final List<Map<String, dynamic>> alle = [];
    
    // Voeg gebruiker kennisgewings by
    for (var k in _notifications) {
      alle.add({
        ...k,
        '_kennisgewing_soort': 'gebruiker',
      });
    }
    
    // Voeg globale kennisgewings by (sonder gelees status)
    for (var k in _globaleKennisgewings) {
      alle.add({
        ...k,
        '_kennisgewing_soort': 'globaal',
        'kennis_gelees': false, // Globale kennisgewings het nie gelees status nie
      });
    }
    
    // Sorteer op datum (nuutste eerste)
    alle.sort((a, b) {
      final dateA = DateTime.parse(
        a['kennis_geskep_datum'] ?? a['glob_kennis_geskep_datum']
      );
      final dateB = DateTime.parse(
        b['kennis_geskep_datum'] ?? b['glob_kennis_geskep_datum']
      );
      return dateB.compareTo(dateA);
    });
    
    return alle;
  }

  List<Map<String, dynamic>> get _gefilterdeKennisgewings {
    return _alleKennisgewings.where((kennisgewing) {
      // Tab filter (alles/ongelees)
      final bool tabMatch =
          _currentTabIndex == 0 ||
          (_currentTabIndex == 1 && !(kennisgewing['kennis_gelees'] ?? false));

      // Tipe filter
      if (_tipeFilter != 'all') {
        final tipeNaam =
            kennisgewing['kennisgewing_tipes']?['kennis_tipe_naam'] ?? 'info';
        if (tipeNaam.toLowerCase() != _tipeFilter.toLowerCase()) {
          return false;
        }
      }

      return tabMatch;
    }).toList();
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy HH:mm').format(date);
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

  void _toonKennisgewingDetail(Map<String, dynamic> kennisgewing) {
    final soort = kennisgewing['_kennisgewing_soort'] ?? 'gebruiker';
    final isGelees = kennisgewing['kennis_gelees'] ?? false;
    final tipe = kennisgewing['kennisgewing_tipes']?['kennis_tipe_naam'] ?? 'info';
    final titel = kennisgewing['kennis_titel'] ?? kennisgewing['glob_kennis_titel'] ?? '';
    final beskrywing = kennisgewing['kennis_beskrywing'] ?? 
        kennisgewing['glob_kennis_beskrywing'] ?? 'Kennisgewing';
    final datum = DateTime.parse(
      kennisgewing['kennis_geskep_datum'] ?? kennisgewing['glob_kennis_geskep_datum']
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
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
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
                                      soort == 'globaal' ? 'GLOBAAL' : 'PERSOONLIK',
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
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.6,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Meta inligting
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 18,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Gestuur op: ${_formatDate(datum)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          if (soort == 'gebruiker') ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  isGelees ? Icons.mark_email_read : Icons.mark_email_unread,
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
      default:
        return Colors.blue;
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
                _tipeFilter = value;
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
                value: 'info',
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Text('Inligting'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'waarskuwing',
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    SizedBox(width: 12),
                    Text('Waarskuwing'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'sukses',
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green),
                    SizedBox(width: 12),
                    Text('Sukses'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'fout',
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red),
                    SizedBox(width: 12),
                    Text('Fout'),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _handleRefresh,
              child: _gefilterdeKennisgewings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _currentTabIndex == 1 
                              ? Icons.mark_email_read 
                              : Icons.notifications_none,
                            size: 80,
                            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _currentTabIndex == 1
                                ? 'Geen ongelees kennisgewings'
                                : 'Geen kennisgewings',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _currentTabIndex == 1
                                ? 'Alle kennisgewings is gelees'
                                : 'Jy sal hier kennisgewings sien',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _gefilterdeKennisgewings.length,
                      itemBuilder: (context, index) {
                        final kennisgewing = _gefilterdeKennisgewings[index];
                        final soort = kennisgewing['_kennisgewing_soort'] ?? 'gebruiker';
                        final tipe = kennisgewing['kennisgewing_tipes']?['kennis_tipe_naam'] ?? 'info';
                        final isGelees = kennisgewing['kennis_gelees'] ?? false;
                        final titel = kennisgewing['kennis_titel'] ?? kennisgewing['glob_kennis_titel'] ?? '';
                        final beskrywing = kennisgewing['kennis_beskrywing'] ?? 
                            kennisgewing['glob_kennis_beskrywing'] ?? 'Kennisgewing';
                        final datum = DateTime.parse(
                          kennisgewing['kennis_geskep_datum'] ?? kennisgewing['glob_kennis_geskep_datum']
                        );

                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 300 + (index * 50)),
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
                          child: Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: isGelees ? 1 : 3,
                            shadowColor: _getTipeKleur(tipe).withOpacity(0.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isGelees
                                    ? Colors.transparent
                                    : _getTipeKleur(tipe).withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _toonKennisgewingDetail(kennisgewing),
                              onLongPress: soort == 'gebruiker' && !isGelees
                                  ? () => _markeerAsGelees(kennisgewing['kennis_id'])
                                  : null,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: isGelees
                                      ? null
                                      : LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            _getTipeKleur(tipe).withOpacity(0.02),
                                            Colors.transparent,
                                          ],
                                        ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Ikoon
                                      Container(
                                        width: 52,
                                        height: 52,
                                        decoration: BoxDecoration(
                                          color: _getTipeKleur(tipe).withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(
                                            color: _getTipeKleur(tipe).withOpacity(0.3),
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          _getTipeIkoon(tipe),
                                          color: _getTipeKleur(tipe),
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      
                                      // Content
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      if (titel.isNotEmpty) ...[
                                                        Text(
                                                          titel,
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 16,
                                                            color: isGelees
                                                                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
                                                                : Theme.of(context).colorScheme.onSurface,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                        ),
                                                        const SizedBox(height: 4),
                                                      ],
                                                      Text(
                                                        beskrywing,
                                                        style: TextStyle(
                                                          fontWeight: titel.isNotEmpty && !isGelees
                                                              ? FontWeight.w500
                                                              : (isGelees ? FontWeight.normal : FontWeight.w600),
                                                          fontSize: titel.isNotEmpty ? 14 : 15,
                                                          color: isGelees
                                                              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                                                              : Theme.of(context).colorScheme.onSurface,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                if (!isGelees && soort == 'gebruiker')
                                                  Container(
                                                    width: 10,
                                                    height: 10,
                                                    margin: const EdgeInsets.only(left: 8),
                                                    decoration: BoxDecoration(
                                                      color: _getTipeKleur(tipe),
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  size: 14,
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  _formatTimeAgo(datum),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: soort == 'globaal'
                                                        ? Colors.green.withOpacity(0.15)
                                                        : _getTipeKleur(tipe).withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    soort == 'globaal' ? 'GLOBAAL' : tipe.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: soort == 'globaal'
                                                          ? Colors.green
                                                          : _getTipeKleur(tipe),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
