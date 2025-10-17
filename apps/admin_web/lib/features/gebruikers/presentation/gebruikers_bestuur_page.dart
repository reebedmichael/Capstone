import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/providers/auth_providers.dart';
import '../../../shared/utils/admin_permissions.dart';
import '../../../shared/utils/async_utils.dart';
import '../../../locator.dart';
import 'package:spys_api_client/spys_api_client.dart';

class GebruikersBestuurPage extends ConsumerStatefulWidget {
  const GebruikersBestuurPage({super.key});

  @override
  ConsumerState<GebruikersBestuurPage> createState() =>
      _GebruikersBestuurPageState();
}

class _GebruikersBestuurPageState extends ConsumerState<GebruikersBestuurPage> {
  String searchQuery = '';
  String? filterGebrTipeId;
  String? filterAdminTipeId;
  String? filterKampusId;
  bool? filterAktief;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = const [];
  List<Map<String, dynamic>> _gebrTipes = const [];
  List<Map<String, dynamic>> _adminTipes = const [];
  List<Map<String, dynamic>> _kampusse = const [];
  int _usersWithAllowancesCount = 0;

  // Get current user ID for self-modification checks
  String? get currentUserId => Supabase.instance.client.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final sb = Supabase.instance.client;
    try {
      final gebruikers = await sb
          .from('gebruikers')
          .select(
            '*, gebr_tipe:gebr_tipe_id(gebr_tipe_naam, gebr_toelaag), admin_tipe:admin_tipe_id(admin_tipe_naam), kampus:kampus_id(kampus_naam)',
          )
          .limit(200);
      final gt = await sb
          .from('gebruiker_tipes')
          .select('gebr_tipe_id, gebr_tipe_naam, gebr_toelaag');
      final at = await sb
          .from('admin_tipes')
          .select('admin_tipe_id, admin_tipe_naam');
      final ks = await sb.from('kampus').select('kampus_id, kampus_naam');

      // Load allowances count
      int allowancesCount = 0;
      try {
        allowancesCount = await sl<AllowanceRepository>()
            .getUsersWithAllowancesCount();
      } catch (e) {
        debugPrint('Could not load allowances count: $e');
      }

      setState(() {
        _rows = List<Map<String, dynamic>>.from(gebruikers);
        _gebrTipes = List<Map<String, dynamic>>.from(gt);
        _adminTipes = List<Map<String, dynamic>>.from(at);
        _kampusse = List<Map<String, dynamic>>.from(ks);
        _usersWithAllowancesCount = allowancesCount;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool _hasActiveFilters() {
    return searchQuery.isNotEmpty ||
        filterGebrTipeId != null ||
        filterAdminTipeId != null ||
        filterKampusId != null ||
        filterAktief != null;
  }

  String _getGebrTipeName(String id) {
    final type = _gebrTipes.firstWhere(
      (t) => t['gebr_tipe_id'] == id,
      orElse: () => {'gebr_tipe_naam': 'Onbekend'},
    );
    return type['gebr_tipe_naam'] ?? 'Onbekend';
  }

  String _getAdminTipeName(String id) {
    final type = _adminTipes.firstWhere(
      (t) => t['admin_tipe_id'] == id,
      orElse: () => {'admin_tipe_naam': 'Onbekend'},
    );
    return type['admin_tipe_naam'] ?? 'Onbekend';
  }

  String _getKampusName(String id) {
    final kampus = _kampusse.firstWhere(
      (k) => k['kampus_id'] == id,
      orElse: () => {'kampus_naam': 'Onbekend'},
    );
    return kampus['kampus_naam'] ?? 'Onbekend';
  }

  String _getAdminTypeName(String id) {
    final adminType = _adminTipes.firstWhere(
      (at) => at['admin_tipe_id'] == id,
      orElse: () => <String, dynamic>{},
    );
    return adminType['admin_tipe_naam'] ?? 'Onbekend';
  }

  Map<String, bool> _getPermissionsForAdminType(String adminTypeId) {
    final adminTypeName = _getAdminTypeName(adminTypeId);
    return {
      'Kan gebruikers goedkeur': AdminPermissions.canAcceptUsers(adminTypeName),
      'Kan tipes skep': AdminPermissions.canCreateTypes(adminTypeName),
      'Kan toelae wysig': AdminPermissions.canEditAllowances(adminTypeName),
      'Kan gebruiker tipes wysig': AdminPermissions.canModifyUserTypes(
        adminTypeName,
      ),
      'Kan admin tipes wysig': AdminPermissions.canChangeAdminTypes(
        adminTypeName,
      ),
      'Kan bestellings bestuur': AdminPermissions.canManageOrders(
        adminTypeName,
      ),
      'Kan verslae sien': AdminPermissions.canViewReports(adminTypeName),
    };
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _rows.where((u) {
      final name = ((u['gebr_naam'] ?? '') + ' ' + (u['gebr_van'] ?? ''))
          .toString()
          .toLowerCase();
      final email = (u['gebr_epos'] ?? '').toString().toLowerCase();
      final matchesSearch =
          searchQuery.isEmpty ||
          name.contains(searchQuery.toLowerCase()) ||
          email.contains(searchQuery.toLowerCase());
      final matchesGebrTipe =
          filterGebrTipeId == null || u['gebr_tipe_id'] == filterGebrTipeId;
      final matchesAdminTipe =
          filterAdminTipeId == null || u['admin_tipe_id'] == filterAdminTipeId;
      final matchesKampus =
          filterKampusId == null || u['kampus_id'] == filterKampusId;
      final matchesAktief =
          filterAktief == null || (u['is_aktief'] == filterAktief);
      return matchesSearch &&
          matchesGebrTipe &&
          matchesAdminTipe &&
          matchesKampus &&
          matchesAktief;
    }).toList();

    // Sort users by gebr_naam (first name)
    filteredUsers.sort((a, b) {
      final nameA = (a['gebr_naam'] ?? '').toString().toLowerCase();
      final nameB = (b['gebr_naam'] ?? '').toString().toLowerCase();
      return nameA.compareTo(nameB);
    });

    return Scaffold(
      body: Column(
        children: [
          // Custom header matching dashboard_header.dart style
          _buildCustomHeader(),
          // Main content
          Expanded(child: _buildUsersTab(filteredUsers)),
        ],
      ),
    );
  }

  Widget _buildCustomHeader() {
    final mediaWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = mediaWidth < 600;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: isSmallScreen ? 12 : 16,
      ),
      child: isSmallScreen
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo and title section
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text("👥", style: TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Gebruikers Bestuur",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text(
                            "Bestuur gebruikers en regte",
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(
                                context,
                              ).textTheme.bodySmall?.color,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Action buttons section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Three-dot menu for Primary admins only
                    Consumer(
                      builder: (context, ref, child) {
                        final isPrimaryAsync = ref.watch(
                          isPrimaryAdminProvider,
                        );
                        return isPrimaryAsync.when(
                          data: (isPrimary) {
                            if (!isPrimary) return const SizedBox.shrink();

                            return PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              tooltip: 'Bestuur Tipes',
                              onSelected: (value) {
                                switch (value) {
                                  case 'add_gebr_tipe':
                                    _showAddTypeDialog(context, isAdmin: false);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem<String>(
                                  value: 'add_gebr_tipe',
                                  child: ListTile(
                                    leading: Icon(Icons.group_add),
                                    title: Text('Voeg Gebruiker Tipe'),
                                    dense: true,
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                    ),
                    OutlinedButton(
                      onPressed: _loadData,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        "Herlaai",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// Left section: logo + title + description
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text("👥", style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Gebruikers Bestuur",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          "Bestuur gebruikers en regte",
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                /// Right section: three-dot menu + refresh button
                Row(
                  children: [
                    // Three-dot menu for Primary admins only
                    Consumer(
                      builder: (context, ref, child) {
                        final isPrimaryAsync = ref.watch(
                          isPrimaryAdminProvider,
                        );
                        return isPrimaryAsync.when(
                          data: (isPrimary) {
                            if (!isPrimary) return const SizedBox.shrink();

                            return PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              tooltip: 'Bestuur Tipes',
                              onSelected: (value) {
                                switch (value) {
                                  case 'add_gebr_tipe':
                                    _showAddTypeDialog(context, isAdmin: false);
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem<String>(
                                  value: 'add_gebr_tipe',
                                  child: ListTile(
                                    leading: Icon(Icons.group_add),
                                    title: Text('Voeg Gebruiker Tipe'),
                                    dense: true,
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _loadData,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text("Herlaai"),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildUsersTab(List<Map<String, dynamic>> filteredUsers) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Loading and error states with improved styling
          if (_loading)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              child: LinearProgressIndicator(
                backgroundColor: Theme.of(context).colorScheme.surface,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          if (_error != null)
            Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.error),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // 🔹 Rol-oorsig blok (counts based on filtered live data) - improved UI
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 16),
                  child: Text(
                    'Rol Oorsig',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final isWide = screenWidth >= 1200;
                    final isMedium = screenWidth >= 800;
                    final isSmall = screenWidth >= 600;

                    // More responsive grid calculations
                    int crossAxisCount;
                    double childAspectRatio;
                    double spacing;

                    if (isWide) {
                      crossAxisCount = 4;
                      childAspectRatio = 1.9;
                      spacing = 16;
                    } else if (isMedium) {
                      crossAxisCount = 3;
                      childAspectRatio = 1.7;
                      spacing = 12;
                    } else if (isSmall) {
                      crossAxisCount = 2;
                      childAspectRatio = 1.5;
                      spacing = 10;
                    } else {
                      crossAxisCount = 1;
                      childAspectRatio = 1.3;
                      spacing = 8;
                    }

                    final roleStats = [
                      {
                        'title': 'Primêre Admins',
                        'value': filteredUsers
                            .where(
                              (u) =>
                                  (u['admin_tipe']?['admin_tipe_naam'] ?? '') ==
                                  'Primary',
                            )
                            .length
                            .toString(),
                        'icon': Icons.admin_panel_settings,
                        'color': Theme.of(context).colorScheme.primary,
                      },
                      {
                        'title': 'Admins',
                        'value': filteredUsers
                            .where(
                              (u) =>
                                  (u['admin_tipe']?['admin_tipe_naam'] ?? '') !=
                                  '',
                            )
                            .length
                            .toString(),
                        'icon': Icons.security,
                        'color': Theme.of(context).colorScheme.secondary,
                      },
                      {
                        'title': 'Studente',
                        'value': filteredUsers
                            .where(
                              (u) =>
                                  (u['gebr_tipe']?['gebr_tipe_naam'] ?? '') ==
                                  'Student',
                            )
                            .length
                            .toString(),
                        'icon': Icons.school,
                        'color': Theme.of(context).colorScheme.tertiary,
                      },
                      {
                        'title': 'Personeel',
                        'value': filteredUsers
                            .where(
                              (u) =>
                                  (u['gebr_tipe']?['gebr_tipe_naam'] ?? '') ==
                                  'Personeel',
                            )
                            .length
                            .toString(),
                        'icon': Icons.work,
                        'color': Theme.of(context).colorScheme.outline,
                      },
                    ];

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemCount: roleStats.length,
                      itemBuilder: (context, index) {
                        final stat = roleStats[index];
                        return _buildEnhancedStatCard(
                          stat['title'] as String,
                          stat['value'] as String,
                          stat['icon'] as IconData,
                          stat['color'] as Color,
                          small: 'Gebruiker tipe',
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // 🔹 Statistiek blok (live counts) - improved UI
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 16),
                  child: Text(
                    'Gebruiker Statistieke',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final isWide = screenWidth >= 1200;
                    final isMedium = screenWidth >= 800;
                    final isSmall = screenWidth >= 600;

                    // More responsive grid calculations
                    int crossAxisCount;
                    double childAspectRatio;
                    double spacing;

                    if (isWide) {
                      crossAxisCount = 4;
                      childAspectRatio = 1.9;
                      spacing = 16;
                    } else if (isMedium) {
                      crossAxisCount = 3;
                      childAspectRatio = 1.7;
                      spacing = 12;
                    } else if (isSmall) {
                      crossAxisCount = 2;
                      childAspectRatio = 1.5;
                      spacing = 10;
                    } else {
                      crossAxisCount = 1;
                      childAspectRatio = 1.3;
                      spacing = 8;
                    }

                    final stats = [
                      {
                        'title': 'Totaal Gebruikers',
                        'value': _rows.length.toString(),
                        'label': 'Algeheel',
                        'icon': Icons.people,
                        'color': Theme.of(context).colorScheme.primary,
                      },
                      {
                        'title': 'Wag Goedkeuring',
                        'value': _rows
                            .where(
                              (u) =>
                                  u['is_aktief'] == false &&
                                  (u['admin_tipe_id'] != null ||
                                      (u['gebr_tipe']?['gebr_tipe_naam'] ??
                                              '') ==
                                          'Ekstern'),
                            )
                            .length
                            .toString(),
                        'label': 'Nie aktief',
                        'icon': Icons.pending_actions,
                        'color': Theme.of(context).colorScheme.secondary,
                      },
                      {
                        'title': 'Studente met Toelae',
                        'value': _usersWithAllowancesCount.toString(),
                        'label': 'Toelae per tipe',
                        'icon': Icons.account_balance_wallet,
                        'color': Theme.of(context).colorScheme.tertiary,
                      },
                      {
                        'title': 'Aktiewe Gebruikers',
                        'value': _rows
                            .where((u) => u['is_aktief'] == true)
                            .length
                            .toString(),
                        'label': 'Huidig aktief',
                        'icon': Icons.check_circle,
                        'color': Theme.of(context).colorScheme.outline,
                      },
                    ];

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: spacing,
                        mainAxisSpacing: spacing,
                        childAspectRatio: childAspectRatio,
                      ),
                      itemCount: stats.length,
                      itemBuilder: (context, index) {
                        final s = stats[index];
                        return _buildEnhancedStatCard(
                          s['title'] as String,
                          s['value'] as String,
                          s['icon'] as IconData,
                          s['color'] as Color,
                          small: s['label'] as String,
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // 🔹 Search en filter (enhanced UI)
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 16),
                  child: Text(
                    'Soek en Filter',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 700;
                    final filterControls = Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Enhanced search bar
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Theme.of(context).colorScheme.surface,
                              ),
                              child: TextField(
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    Icons.search,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  hintText: 'Soek naam of e-pos',
                                  hintStyle: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                onChanged: (value) =>
                                    setState(() => searchQuery = value),
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Enhanced filter row
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.center,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _buildFilterDropdown(
                                  'Gebruiker Tipe',
                                  filterGebrTipeId,
                                  _gebrTipes
                                      .map(
                                        (t) => MapEntry(
                                          t['gebr_tipe_id'] as String,
                                          t['gebr_tipe_naam'] as String,
                                        ),
                                      )
                                      .toList(),
                                  (v) => setState(() => filterGebrTipeId = v),
                                ),
                                _buildFilterDropdown(
                                  'Admin Tipe',
                                  filterAdminTipeId,
                                  _adminTipes
                                      .map(
                                        (t) => MapEntry(
                                          t['admin_tipe_id'] as String,
                                          t['admin_tipe_naam'] as String,
                                        ),
                                      )
                                      .toList(),
                                  (v) => setState(() => filterAdminTipeId = v),
                                ),
                                _buildFilterDropdown(
                                  'Kampus',
                                  filterKampusId,
                                  _kampusse
                                      .map(
                                        (t) => MapEntry(
                                          t['kampus_id'] as String,
                                          t['kampus_naam'] as String,
                                        ),
                                      )
                                      .toList(),
                                  (v) => setState(() => filterKampusId = v),
                                ),
                                _buildStatusDropdown(),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                  ),
                                  child: TextButton.icon(
                                    onPressed: () => setState(() {
                                      searchQuery = '';
                                      filterGebrTipeId = null;
                                      filterAdminTipeId = null;
                                      filterKampusId = null;
                                      filterAktief = null;
                                    }),
                                    icon: Icon(
                                      Icons.restart_alt,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                                    label: Text(
                                      'Herstel',
                                      style: TextStyle(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                    if (narrow) {
                      return ExpansionTile(
                        title: const Text('Filters'),
                        children: [filterControls],
                      );
                    }
                    return filterControls;
                  },
                ),
              ],
            ),
          ),

          // Active filter chips with specific values
          if (_hasActiveFilters())
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  if (searchQuery.isNotEmpty)
                    InputChip(
                      label: Text('Soek: "$searchQuery"'),
                      onDeleted: () => setState(() => searchQuery = ''),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primaryContainer,
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  if (filterGebrTipeId != null)
                    InputChip(
                      label: Text(
                        'Gebruiker: ${_getGebrTipeName(filterGebrTipeId!)}',
                      ),
                      onDeleted: () => setState(() => filterGebrTipeId = null),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer,
                      labelStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  if (filterAdminTipeId != null)
                    InputChip(
                      label: Text(
                        'Admin: ${_getAdminTipeName(filterAdminTipeId!)}',
                      ),
                      onDeleted: () => setState(() => filterAdminTipeId = null),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.tertiaryContainer,
                      labelStyle: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onTertiaryContainer,
                      ),
                    ),
                  if (filterKampusId != null)
                    InputChip(
                      label: Text('Kampus: ${_getKampusName(filterKampusId!)}'),
                      onDeleted: () => setState(() => filterKampusId = null),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceVariant,
                      labelStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  if (filterAktief != null)
                    InputChip(
                      label: Text(
                        'Status: ${filterAktief == true ? 'Aktief' : 'Nie aktief'}',
                      ),
                      onDeleted: () => setState(() => filterAktief = null),
                      backgroundColor: filterAktief == true
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.errorContainer,
                      labelStyle: TextStyle(
                        color: filterAktief == true
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                ],
              ),
            ),

          // 🔹 Gebruiker lys as cards - enhanced UI
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 16),
                  child: Row(
                    children: [
                      Text(
                        'Gebruikers Lys',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${filteredUsers.length} gebruikers',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (filteredUsers.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.5),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Geen gebruikers gevind',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Probeer jou soekterme of filters te verander',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                              ),
                        ),
                      ],
                    ),
                  )
                else
                  ...filteredUsers.map((user) => _buildEnhancedUserCard(user)),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // NOTE: Moved "Add Type" buttons to three-dot menu at top-right
          // This provides better UX and clearer distinction between adding types vs users
          const SizedBox(height: 16),

          // NOTE: Removed "Add Student" and "Add Admin" buttons per new workflow.
          // New users now register via mobile app and appear as pending Ekstern users.
          // Primary admins can Accept/Decline them from the pending users list.
          // To add new user types (not users), use the three-dot menu at top-right.
          const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String? value,
    List<MapEntry<String, String>> items,
    Function(String?) onChanged,
  ) {
    return Container(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 250),
      child: DropdownButtonFormField<String?>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        items: [
          DropdownMenuItem<String?>(
            value: null,
            child: Text(
              'Alle',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          ...items.map(
            (item) => DropdownMenuItem<String>(
              value: item.key,
              child: Text(item.value),
            ),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      constraints: const BoxConstraints(minWidth: 200, maxWidth: 250),
      child: DropdownButtonFormField<bool?>(
        value: filterAktief,
        decoration: InputDecoration(
          labelText: 'Status',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        items: [
          DropdownMenuItem<bool?>(
            value: null,
            child: Text(
              'Alle',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          DropdownMenuItem<bool?>(
            value: true,
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text('Aktief'),
              ],
            ),
          ),
          DropdownMenuItem<bool?>(
            value: false,
            child: Row(
              children: [
                Icon(
                  Icons.cancel,
                  color: Theme.of(context).colorScheme.error,
                  size: 16,
                ),
                const SizedBox(width: 8),
                const Text('Nie aktief'),
              ],
            ),
          ),
        ],
        onChanged: (v) => setState(() => filterAktief = v),
      ),
    );
  }

  Widget _buildEnhancedStatCard(
    String title,
    String count,
    IconData icon,
    Color color, {
    String? small,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 350;
    final isSmall = screenWidth < 500;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.all(isVerySmall ? 12 : (isSmall ? 16 : 20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and title row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: isVerySmall ? 16 : (isSmall ? 18 : 20),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: isVerySmall ? 11 : (isSmall ? 12 : 13),
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            SizedBox(height: isVerySmall ? 8 : (isSmall ? 12 : 16)),

            // Count
            Text(
              count,
              style: TextStyle(
                fontSize: isVerySmall ? 24 : (isSmall ? 28 : 32),
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
                height: 1.1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Small text (if provided)
            if (small != null) ...[
              SizedBox(height: isVerySmall ? 4 : 6),
              Text(
                small,
                style: TextStyle(
                  fontSize: isVerySmall ? 10 : (isSmall ? 11 : 12),
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedUserCard(Map<String, dynamic> u) {
    final name = ((u['gebr_naam'] ?? '') + ' ' + (u['gebr_van'] ?? '')).trim();
    final email = (u['gebr_epos'] ?? '').toString();
    final phone = (u['gebr_selfoon'] ?? '').toString();
    final role = (u['gebr_tipe']?['gebr_tipe_naam'] ?? '').toString();
    final admin = (u['admin_tipe']?['admin_tipe_naam'] ?? '').toString();
    final requestedAdmin = (u['requested_admin_tipe']?['admin_tipe_naam'] ?? '')
        .toString();
    final kampus = (u['kampus']?['kampus_naam'] ?? '').toString();
    final aktief = (u['is_aktief'] == true);
    final isPending = AdminPermissions.isPendingApproval(u);

    // Determine status color using theme colors
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isPending) {
      statusColor = Theme.of(context).colorScheme.secondary;
      statusIcon = Icons.pending;
      statusText = 'Wag';
    } else if (aktief) {
      statusColor = Theme.of(context).colorScheme.primary;
      statusIcon = Icons.check_circle;
      statusText = 'Aktief';
    } else {
      statusColor = Theme.of(context).colorScheme.error;
      statusIcon = Icons.cancel;
      statusText = 'Nie aktief';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with avatar and basic info
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Center(
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? '(Geen naam)' : name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (role.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            role,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Status indicator
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Details layout - responsive row/column
            LayoutBuilder(
              builder: (context, constraints) {
                final isLargeScreen = constraints.maxWidth > 600;

                if (isLargeScreen) {
                  // Large screens: horizontal layout
                  return Row(
                    children: [
                      if (email.isNotEmpty) ...[
                        _buildSimpleInfo("E-pos", email, Icons.email),
                        const SizedBox(width: 16),
                      ],
                      if (phone.isNotEmpty) ...[
                        _buildSimpleInfo("Selfoon", phone, Icons.phone),
                        const SizedBox(width: 16),
                      ],
                      if (admin.isNotEmpty) ...[
                        _buildSimpleInfo(
                          "Admin",
                          admin,
                          Icons.admin_panel_settings,
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (requestedAdmin.isNotEmpty && isPending) ...[
                        _buildSimpleInfo(
                          "Versoek",
                          requestedAdmin,
                          Icons.pending_actions,
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (kampus.isNotEmpty) ...[
                        _buildSimpleInfo("Kampus", kampus, Icons.location_on),
                      ],
                    ],
                  );
                } else {
                  // Small screens: vertical layout
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (email.isNotEmpty) ...[
                        _buildSimpleInfo("E-pos", email, Icons.email),
                        const SizedBox(height: 8),
                      ],
                      if (phone.isNotEmpty) ...[
                        _buildSimpleInfo("Selfoon", phone, Icons.phone),
                        const SizedBox(height: 8),
                      ],
                      if (admin.isNotEmpty) ...[
                        _buildSimpleInfo(
                          "Admin",
                          admin,
                          Icons.admin_panel_settings,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (requestedAdmin.isNotEmpty && isPending) ...[
                        _buildSimpleInfo(
                          "Versoek",
                          requestedAdmin,
                          Icons.pending_actions,
                        ),
                        const SizedBox(height: 8),
                      ],
                      if (kampus.isNotEmpty) ...[
                        _buildSimpleInfo("Kampus", kampus, Icons.location_on),
                      ],
                    ],
                  );
                }
              },
            ),

            const SizedBox(height: 16),

            // Action buttons
            Consumer(
              builder: (context, ref, child) {
                final isPrimaryAsync = ref.watch(isPrimaryAdminProvider);
                final adminTypeAsync = ref.watch(currentAdminTypeProvider);

                return isPrimaryAsync.when(
                  data: (isPrimary) {
                    return adminTypeAsync.when(
                      data: (adminTypeName) {
                        final userId = u['gebr_id'].toString();
                        final isSelf = userId == currentUserId;

                        // Disable actions for self-modification
                        if (isSelf) {
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.lock,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Jy kan nie jou eie status verander nie',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        // Primary admins have full access to everything
                        if (isPrimary) {
                          if (isPending) {
                            return _buildActionButtons([
                              _buildActionButton(
                                'Keur Goed',
                                Icons.check_circle,
                                Colors.green,
                                () => _showAcceptUserDialog(u),
                              ),
                              _buildActionButton(
                                'Verwerp',
                                Icons.cancel,
                                Colors.red,
                                () => _showDeclineUserDialog(u),
                              ),
                            ]);
                          } else {
                            // Check if user is active to show appropriate button
                            if (aktief) {
                              return _buildActionButtons([
                                _buildActionButton(
                                  'Deaktiveer',
                                  Icons.person_off,
                                  Colors.orange,
                                  () => _setUserActive(userId, false),
                                ),
                                _buildActionButton(
                                  'Admin Tipe',
                                  Icons.admin_panel_settings,
                                  Colors.blue,
                                  () => _showChangeAdminTypeDialog(u),
                                ),
                                _buildActionButton(
                                  'Gebruiker Tipe',
                                  Icons.person,
                                  Colors.purple,
                                  () => _showChangeUserTypeDialog(u),
                                ),
                              ]);
                            } else {
                              // User is inactive - show activate button
                              return _buildActionButtons([
                                _buildActionButton(
                                  'Aktiveer',
                                  Icons.person_add,
                                  Colors.green,
                                  () => _setUserActive(userId, true),
                                ),
                                _buildActionButton(
                                  'Admin Tipe',
                                  Icons.admin_panel_settings,
                                  Colors.blue,
                                  () => _showChangeAdminTypeDialog(u),
                                ),
                                _buildActionButton(
                                  'Gebruiker Tipe',
                                  Icons.person,
                                  Colors.purple,
                                  () => _showChangeUserTypeDialog(u),
                                ),
                              ]);
                            }
                          }
                        } else {
                          // Non-primary admins - show limited buttons based on role
                          final canManageUsers =
                              AdminPermissions.canAcceptUsers(adminTypeName);
                          final canChangeAdminTypes =
                              AdminPermissions.canChangeAdminTypes(
                                adminTypeName,
                              );
                          final canModifyUserTypes =
                              AdminPermissions.canModifyUserTypes(
                                adminTypeName,
                              );

                          if (!canManageUsers &&
                              !canChangeAdminTypes &&
                              !canModifyUserTypes) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lock,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Jy het nie die regte om gebruikers te bestuur nie',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final buttons = <Widget>[];
                          if (isPending && canManageUsers) {
                            buttons.addAll([
                              _buildActionButton(
                                'Keur Goed',
                                Icons.check_circle,
                                Colors.green,
                                () => _showAcceptUserDialog(u),
                              ),
                              _buildActionButton(
                                'Verwerp',
                                Icons.cancel,
                                Colors.red,
                                () => _showDeclineUserDialog(u),
                              ),
                            ]);
                          } else if (!isPending) {
                            if (canManageUsers) {
                              if (aktief) {
                                // User is active - show deactivate button
                                buttons.add(
                                  _buildActionButton(
                                    'Deaktiveer',
                                    Icons.person_off,
                                    Colors.orange,
                                    () => _setUserActive(userId, false),
                                  ),
                                );
                              } else {
                                // User is inactive - show activate button
                                buttons.add(
                                  _buildActionButton(
                                    'Aktiveer',
                                    Icons.person_add,
                                    Colors.green,
                                    () => _setUserActive(userId, true),
                                  ),
                                );
                              }
                            }
                            if (canChangeAdminTypes) {
                              buttons.add(
                                _buildActionButton(
                                  'Admin Tipe',
                                  Icons.admin_panel_settings,
                                  Colors.blue,
                                  () => _showChangeAdminTypeDialog(u),
                                ),
                              );
                            }
                            if (canModifyUserTypes) {
                              buttons.add(
                                _buildActionButton(
                                  'Gebruiker Tipe',
                                  Icons.person,
                                  Colors.purple,
                                  () => _showChangeUserTypeDialog(u),
                                ),
                              );
                            }
                          }

                          if (buttons.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lock,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Jy het nie die regte om hierdie gebruiker te bestuur nie',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return _buildActionButtons(buttons);
                        }
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                  loading: () => const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  error: (_, __) => const Icon(Icons.error, color: Colors.grey),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleInfo(String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: color),
        label: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildActionButtons(List<Widget> buttons) {
    return Row(
      children: buttons
          .expand(
            (button) => [
              button,
              if (button != buttons.last) const SizedBox(width: 8),
            ],
          )
          .toList(),
    );
  }

  // Removed old _buildUserCard method - replaced with _buildEnhancedUserCard

  // Removed _infoColumn method - replaced with _buildInfoChip in enhanced user cards

  Future<void> _setUserActive(String gebrId, bool active) async {
    // TODO: SERVER-SIDE ENFORCEMENT REQUIRED
    // Server must validate that the calling user is a Primary admin before allowing
    // user activation/deactivation. Add RLS policy or API endpoint validation.

    // fixed: async + watchdog + refresh
    AsyncUtils.executeWithWatchdog(
      operation: () async {
        final sb = Supabase.instance.client;
        return await sb
            .from('gebruikers')
            .update({'is_aktief': active})
            .eq('gebr_id', gebrId);
      },
      onSuccess: (result) async {
        // Data will be refreshed manually via refresh button
      },
      onError: (error) {
        // Error handling is done by AsyncUtils
      },
      context: context,
      successMessage: active
          ? 'Gebruiker geaktiveer'
          : 'Gebruiker gedeaktiveer',
      errorMessage: 'Kon nie gebruiker status opdateer nie',
    );
  }

  // Old simple _showAddTypeDialog method removed - using comprehensive version below

  // Removed _showAllowanceDialog method - allowance management moved to separate page

  // NOTE: Removed _showAddUserDialog method - users now register via mobile app
  // and appear as pending Ekstern users for Primary admin approval.

  Future<void> _showAcceptUserDialog(Map<String, dynamic> user) async {
    final userId = user['gebr_id'].toString();
    final userName = '${user['gebr_naam'] ?? ''} ${user['gebr_van'] ?? ''}'
        .trim();
    // Removed: requested_admin_tipe - column doesn't exist in client schema
    final requestedAdminType = '';
    final currentUserType = user['gebr_tipe']?['gebr_tipe_naam'] ?? 'Ekstern';

    // Default selections - ensure user gets a valid gebr_tipe_id
    String? selectedGebrTipeId =
        user['gebr_tipe_id'] ??
        AdminPermissions.eksternTypeId; // Default to Ekstern if null
    // Default to Tierseriy - requested_admin_tipe_id column doesn't exist in client schema
    String? selectedAdminTipeId = AdminPermissions.tierseriyAdminId;

    bool isLoading = false; // Add loading state

    await showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissing during loading
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Keur Gebruiker Goed: $userName'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // User Info Card
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gebruiker Inligting:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('Naam: $userName'),
                            Text('E-pos: ${user['gebr_epos'] ?? ''}'),
                            Text('Selfoon: ${user['gebr_selfoon'] ?? ''}'),
                            Text('Huidige Tipe: $currentUserType'),
                            if (requestedAdminType.isNotEmpty)
                              Text(
                                'Versoekte Admin Tipe: $requestedAdminType',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // User Type Selection
                      DropdownButtonFormField<String?>(
                        value: selectedGebrTipeId,
                        decoration: const InputDecoration(
                          labelText: 'Gebruiker Tipe *',
                          border: OutlineInputBorder(),
                          helperText: 'Kies die finale gebruiker tipe',
                        ),
                        items: _gebrTipes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type['gebr_tipe_id'],
                            child: Text(type['gebr_tipe_naam']),
                          );
                        }).toList(),
                        onChanged: isLoading
                            ? null
                            : (value) {
                                setDialogState(() {
                                  selectedGebrTipeId = value;
                                });
                              },
                      ),
                      const SizedBox(height: 12),

                      // Admin Type Selection
                      DropdownButtonFormField<String?>(
                        value: selectedAdminTipeId,
                        decoration: const InputDecoration(
                          labelText: 'Admin Tipe',
                          border: OutlineInputBorder(),
                          helperText:
                              'Standaard: Tierseriy (kan verander word later)',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Geen admin regte'),
                          ),
                          ..._adminTipes
                              .where(
                                (type) => type['admin_tipe_naam'] != 'Pending',
                              )
                              .map((type) {
                                return DropdownMenuItem<String>(
                                  value: type['admin_tipe_id'],
                                  child: Text(type['admin_tipe_naam']),
                                );
                              }),
                        ],
                        onChanged: isLoading
                            ? null
                            : (value) {
                                setDialogState(() {
                                  selectedAdminTipeId = value;
                                });
                              },
                      ),
                      const SizedBox(height: 16),

                      // Permissions Preview
                      if (selectedAdminTipeId != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Regte vir ${_getAdminTypeName(selectedAdminTipeId!)}:',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ..._getPermissionsForAdminType(
                                selectedAdminTipeId!,
                              ).entries.map((entry) {
                                return Row(
                                  children: [
                                    Icon(
                                      entry.value ? Icons.check : Icons.close,
                                      color: entry.value
                                          ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                          : Theme.of(context).colorScheme.error,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      entry.key,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Kanselleer'),
                ),
                ElevatedButton(
                  onPressed: (selectedGebrTipeId == null || isLoading)
                      ? null
                      : () {
                          final adminId = currentUserId;
                          if (adminId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Not authenticated'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          // fixed: async + watchdog + refresh
                          AsyncUtils.executeWithWatchdog(
                            operation: () async {
                              return await sl<GebruikersRepository>().approveUser(
                                userId: userId,
                                currentAdminId: adminId,
                                gebrTipeId: selectedGebrTipeId,
                                adminTipeId:
                                    selectedAdminTipeId, // Will default to Tierseriy if null
                              );
                            },
                            onSuccess: (result) async {
                              setDialogState(() {
                                isLoading = false;
                              });
                              Navigator.pop(context);
                              // Data will be refreshed manually via refresh button // Refresh the users list
                            },
                            onError: (error) {
                              setDialogState(() {
                                isLoading = false;
                              });
                            },
                            context: context,
                            successMessage: selectedAdminTipeId != null
                                ? '$userName is goedgekeur as ${_getAdminTypeName(selectedAdminTipeId!)}'
                                : '$userName is goedgekeur',
                            errorMessage:
                                'Kon nie gebruiker goedkeur nie — probeer asseblief weer',
                          );
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Keur Goed'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showDeclineUserDialog(Map<String, dynamic> user) async {
    final userId = user['gebr_id'].toString();
    final userName = '${user['gebr_naam'] ?? ''} ${user['gebr_van'] ?? ''}'
        .trim();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Verwerp Gebruiker: $userName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Is jy seker jy wil hierdie gebruiker se registrasie verwerp?',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Gebruiker Inligting:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Naam: $userName'),
                    Text('E-pos: ${user['gebr_epos'] ?? ''}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Hierdie aksie sal die gebruiker se rekening verwyder. Hulle sal weer moet registreer.',
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kanselleer'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final sb = Supabase.instance.client;

                  // Delete the user record (this will also delete auth user due to RLS)
                  await sb.from('gebruikers').delete().eq('gebr_id', userId);

                  Navigator.pop(context);
                  await _loadData();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '$userName se registrasie is verwerp en verwyder',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Kon nie gebruiker verwerp nie: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                'Verwerp en Verwyder',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddTypeDialog(
    BuildContext context, {
    required bool isAdmin,
  }) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final allowanceController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isAdmin ? 'Voeg Admin Tipe by' : 'Voeg Gebruiker Tipe by',
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tipe Naam *',
                    border: OutlineInputBorder(),
                    helperText: 'Bv. "Student", "Personeel", "Manager"',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Beskrywing',
                    border: OutlineInputBorder(),
                    helperText: 'Opsionele beskrywing van hierdie tipe',
                  ),
                  maxLines: 2,
                ),
                if (!isAdmin) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: allowanceController,
                    decoration: const InputDecoration(
                      labelText: 'Maandelikse Toelae (R)',
                      border: OutlineInputBorder(),
                      helperText: 'Standaard toelae vir hierdie gebruiker tipe',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
                if (isAdmin) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Regte:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '• Kan gebruikers bestuur',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '• Kan spyskaarte bestuur',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '• Kan verslae sien',
                          style: TextStyle(fontSize: 12),
                        ),
                        Text(
                          '• Primary admins kan ander admins bestuur',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kanselleer'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tipe naam is vereist')),
                  );
                  return;
                }

                try {
                  final sb = Supabase.instance.client;

                  // TODO: SERVER-SIDE ENFORCEMENT REQUIRED
                  // Server must validate Primary admin status before allowing type creation.
                  // Add RLS policies or API endpoints with proper authorization checks.

                  if (isAdmin) {
                    // Create admin type
                    await sb.from('admin_tipes').insert({
                      'admin_tipe_naam': nameController.text.trim(),
                      'admin_tipe_beskrywing':
                          descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      'permissions':
                          '{"canManageUsers": true, "canManageMenus": true, "canViewReports": true}',
                    });
                  } else {
                    // Create user type
                    final allowance = allowanceController.text.trim().isEmpty
                        ? null
                        : double.tryParse(allowanceController.text.trim());

                    await sb.from('gebruiker_tipes').insert({
                      'gebr_tipe_naam': nameController.text.trim(),
                      'gebr_tipe_beskrywing':
                          descriptionController.text.trim().isEmpty
                          ? null
                          : descriptionController.text.trim(),
                      'gebr_toelaag': allowance,
                    });
                  }

                  Navigator.pop(context);
                  await _loadData();

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${isAdmin ? 'Admin' : 'Gebruiker'} tipe suksesvol bygevoeg',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Kon nie tipe byvoeg nie: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: Text(isAdmin ? 'Skep Admin Tipe' : 'Skep Gebruiker Tipe'),
            ),
          ],
        );
      },
    );
  }

  // removed: _buildToelaeTab (Toelae side panel) per requirements

  // removed: _buildToelaeCard (Toelae side panel) per requirements

  // removed: _showEditToelaeDialog (Toelae side panel) per requirements

  // removed: _calculateTotalMonthlyPayout (Toelae side panel) per requirements
  // removed: _calculateTotalMonthlyPayout (Toelae side panel) per requirements

  Future<void> _showChangeAdminTypeDialog(Map<String, dynamic> user) async {
    final userId = user['gebr_id'].toString();
    final userName = '${user['gebr_naam'] ?? ''} ${user['gebr_van'] ?? ''}'
        .trim();
    final currentAdminType = user['admin_tipe']?['admin_tipe_naam'] ?? '';
    final currentAdminTypeId = user['admin_tipe_id'];

    String? selectedAdminTipeId = currentAdminTypeId;
    bool isLoading = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissing during loading
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Verander Admin Tipe: $userName'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Huidige Inligting:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Naam: $userName'),
                          Text('Huidige Admin Tipe: $currentAdminType'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      value: selectedAdminTipeId,
                      decoration: const InputDecoration(
                        labelText: 'Nuwe Admin Tipe *',
                        border: OutlineInputBorder(),
                        helperText:
                            'Kies die nuwe admin tipe vir hierdie gebruiker',
                      ),
                      items: _adminTipes
                          .where((type) => type['admin_tipe_naam'] != 'Pending')
                          .map((type) {
                            return DropdownMenuItem<String>(
                              value: type['admin_tipe_id'],
                              child: Text(type['admin_tipe_naam']),
                            );
                          })
                          .toList(),
                      onChanged: isLoading
                          ? null
                          : (value) {
                              setDialogState(() {
                                selectedAdminTipeId = value;
                              });
                            },
                    ),
                    const SizedBox(height: 16),
                    if (selectedAdminTipeId != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Regte vir ${_getAdminTypeName(selectedAdminTipeId!)}:',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ..._getPermissionsForAdminType(
                              selectedAdminTipeId!,
                            ).entries.map((entry) {
                              return Row(
                                children: [
                                  Icon(
                                    entry.value ? Icons.check : Icons.close,
                                    color: entry.value
                                        ? Colors.green
                                        : Colors.red,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    entry.key,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Kanselleer'),
                ),
                ElevatedButton(
                  onPressed: (selectedAdminTipeId == null || isLoading)
                      ? null
                      : () {
                          setDialogState(() {
                            isLoading = true;
                          });

                          // fixed: async + watchdog + refresh
                          AsyncUtils.executeWithWatchdog(
                            operation: () async {
                              final sb = Supabase.instance.client;

                              // TODO: SERVER-SIDE ENFORCEMENT REQUIRED
                              // Server must validate Primary admin status before allowing admin type changes

                              return await sb
                                  .from('gebruikers')
                                  .update({
                                    'admin_tipe_id': selectedAdminTipeId,
                                  })
                                  .eq('gebr_id', userId);
                            },
                            onSuccess: (result) async {
                              setDialogState(() {
                                isLoading = false;
                              });
                              Navigator.pop(context);
                              await _loadData();
                            },
                            onError: (error) {
                              setDialogState(() {
                                isLoading = false;
                              });
                            },
                            context: context,
                            successMessage:
                                '$userName se admin tipe verander na ${_getAdminTypeName(selectedAdminTipeId!)}',
                            errorMessage: 'Kon nie admin tipe verander nie',
                          );
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Verander'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showChangeUserTypeDialog(Map<String, dynamic> user) async {
    final userId = user['gebr_id'].toString();
    final userName = '${user['gebr_naam'] ?? ''} ${user['gebr_van'] ?? ''}'
        .trim();
    final currentUserType = user['gebr_tipe']?['gebr_tipe_naam'] ?? '';
    final currentUserTypeId = user['gebr_tipe_id'];
    // Removed: currentOverride - toelaag_override column doesn't exist in client schema

    String? selectedGebrTipeId = currentUserTypeId;
    bool isLoading = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissing during loading
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Get effective allowance for selected type
            final selectedType = _gebrTipes.firstWhere(
              (t) => t['gebr_tipe_id'] == selectedGebrTipeId,
              orElse: () => <String, dynamic>{},
            );
            final typeAllowance =
                selectedType['gebr_toelaag']?.toDouble() ?? 0.0;

            return AlertDialog(
              title: Text('Verander Gebruiker Tipe: $userName'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Huidige Inligting:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Naam: $userName'),
                          Text('Huidige Tipe: $currentUserType'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String?>(
                      value: selectedGebrTipeId,
                      decoration: const InputDecoration(
                        labelText: 'Nuwe Gebruiker Tipe *',
                        border: OutlineInputBorder(),
                        helperText: 'Kies die nuwe gebruiker tipe',
                      ),
                      items: _gebrTipes.map((type) {
                        return DropdownMenuItem<String>(
                          value: type['gebr_tipe_id'],
                          child: Text(type['gebr_tipe_naam']),
                        );
                      }).toList(),
                      onChanged: isLoading
                          ? null
                          : (value) {
                              setDialogState(() {
                                selectedGebrTipeId = value;
                              });
                            },
                    ),
                    const SizedBox(height: 12),
                    // Removed: override input field - toelaag_override column doesn't exist in client schema
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.orange.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Toelae Inligting',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tipe standaard toelae: R${typeAllowance.toStringAsFixed(2)}',
                          ),
                          const Text(
                            'Individuele toelae oorskryf is nie beskikbaar nie.',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Kanselleer'),
                ),
                ElevatedButton(
                  onPressed: (selectedGebrTipeId == null || isLoading)
                      ? null
                      : () {
                          setDialogState(() {
                            isLoading = true;
                          });

                          // fixed: async + watchdog + refresh
                          AsyncUtils.executeWithWatchdog(
                            operation: () async {
                              final sb = Supabase.instance.client;

                              // Removed: override validation - toelaag_override column doesn't exist in client schema

                              // TODO: SERVER-SIDE ENFORCEMENT REQUIRED
                              // Server must validate Primary admin status before allowing user type changes

                              // Only update user type - toelaag_override column doesn't exist in client schema
                              return await sb
                                  .from('gebruikers')
                                  .update({'gebr_tipe_id': selectedGebrTipeId})
                                  .eq('gebr_id', userId);
                            },
                            onSuccess: (result) async {
                              setDialogState(() {
                                isLoading = false;
                              });
                              Navigator.pop(context);
                              await _loadData();
                            },
                            onError: (error) {
                              setDialogState(() {
                                isLoading = false;
                              });
                            },
                            context: context,
                            successMessage:
                                '$userName se gebruiker tipe verander na ${selectedType['gebr_tipe_naam']}',
                            errorMessage: 'Kon nie gebruiker tipe verander nie',
                          );
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Verander'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // NOTE: All old user creation methods removed per new workflow.
  // Users now register via mobile app and appear as pending Ekstern users.
}
