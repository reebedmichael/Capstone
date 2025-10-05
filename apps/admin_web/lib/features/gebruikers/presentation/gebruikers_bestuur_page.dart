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
  ConsumerState<GebruikersBestuurPage> createState() => _GebruikersBestuurPageState();
}

class _GebruikersBestuurPageState extends ConsumerState<GebruikersBestuurPage> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
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
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    final sb = Supabase.instance.client;
    try {
      final gebruikers = await sb
          .from('gebruikers')
          .select('*, gebr_tipe:gebr_tipe_id(gebr_tipe_naam, gebr_toelaag), admin_tipe:admin_tipe_id(admin_tipe_naam), kampus:kampus_id(kampus_naam)')
          .limit(200);
      final gt = await sb.from('gebruiker_tipes').select('gebr_tipe_id, gebr_tipe_naam, gebr_toelaag');
      final at = await sb.from('admin_tipes').select('admin_tipe_id, admin_tipe_naam');
      final ks = await sb.from('kampus').select('kampus_id, kampus_naam');
      
      // Load allowances count
      int allowancesCount = 0;
      try {
        allowancesCount = await sl<AllowanceRepository>().getUsersWithAllowancesCount();
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
      setState(() { _error = e.toString(); _loading = false; });
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
      'Kan gebruiker tipes wysig': AdminPermissions.canModifyUserTypes(adminTypeName),
      'Kan admin tipes wysig': AdminPermissions.canChangeAdminTypes(adminTypeName),
      'Kan bestellings bestuur': AdminPermissions.canManageOrders(adminTypeName),
      'Kan verslae sien': AdminPermissions.canViewReports(adminTypeName),
    };
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _rows.where((u) {
      final name = ((u['gebr_naam'] ?? '') + ' ' + (u['gebr_van'] ?? '')).toString().toLowerCase();
      final email = (u['gebr_epos'] ?? '').toString().toLowerCase();
      final matchesSearch = searchQuery.isEmpty || name.contains(searchQuery.toLowerCase()) || email.contains(searchQuery.toLowerCase());
      final matchesGebrTipe = filterGebrTipeId == null || u['gebr_tipe_id'] == filterGebrTipeId;
      final matchesAdminTipe = filterAdminTipeId == null || u['admin_tipe_id'] == filterAdminTipeId;
      final matchesKampus = filterKampusId == null || u['kampus_id'] == filterKampusId;
      final matchesAktief = filterAktief == null || (u['is_aktief'] == filterAktief);
      return matchesSearch && matchesGebrTipe && matchesAdminTipe && matchesKampus && matchesAktief;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gebruikers Bestuur'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Herlaai data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Gebruikers', icon: Icon(Icons.people)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Users Tab only (toelae panel removed)
          _buildUsersTab(filteredUsers),
        ],
      ),
    );
  }
  
  Widget _buildUsersTab(List<Map<String, dynamic>> filteredUsers) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🔹 Titel met kebab menu
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Center(
                  child: Text("Gebruikers Bestuur",
              style: Theme.of(context).textTheme.headlineSmall),
                ),
              ),
              // Three-dot menu for Primary admins only
              Consumer(
                builder: (context, ref, child) {
                  final isPrimaryAsync = ref.watch(isPrimaryAdminProvider);
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
                            case 'add_admin_tipe':
                              _showAddTypeDialog(context, isAdmin: true);
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
                          const PopupMenuItem<String>(
                            value: 'add_admin_tipe',
                            child: ListTile(
                              leading: Icon(Icons.admin_panel_settings),
                              title: Text('Voeg Admin Tipe'),
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
            ],
          ),
          const SizedBox(height: 20),

          if (_loading) const LinearProgressIndicator(),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),

          // 🔹 Rol-oorsig blok (counts based on filtered live data) - improved UI
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1100;
              final isMedium = constraints.maxWidth >= 700;
              final crossAxisCount = isWide ? 4 : (isMedium ? 2 : 1);
              final roleStats = [
                {
                  'title': 'Primêre Admins',
                  'value': filteredUsers.where((u) => (u['admin_tipe']?['admin_tipe_naam'] ?? '') == 'Primary').length.toString(),
                  'icon': Icons.admin_panel_settings,
                  'color': Colors.blue,
                },
                {
                  'title': 'Admins',
                  'value': filteredUsers.where((u) => (u['admin_tipe']?['admin_tipe_naam'] ?? '') != '').length.toString(),
                  'icon': Icons.security,
                  'color': Colors.purple,
                },
                {
                  'title': 'Studente',
                  'value': filteredUsers.where((u) => (u['gebr_tipe']?['gebr_tipe_naam'] ?? '') == 'Student').length.toString(),
                  'icon': Icons.school,
                  'color': Colors.green,
                },
                {
                  'title': 'Personeel',
                  'value': filteredUsers.where((u) => (u['gebr_tipe']?['gebr_tipe_naam'] ?? '') == 'Personeel').length.toString(),
                  'icon': Icons.work,
                  'color': Colors.orange,
                },
              ];
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 3.8 : (isMedium ? 3.2 : 3.0),
                ),
                itemCount: roleStats.length,
                itemBuilder: (context, index) {
                  final stat = roleStats[index];
                  return _buildBigStat(
                    stat['title'] as String,
                    stat['value'] as String,
                    small: 'Gebruiker tipe',
                  );
                },
              );
            },
          ),

          const SizedBox(height: 30),

          // 🔹 Statistiek blok (live counts)
          // improved stats card layout
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1100;
              final isMedium = constraints.maxWidth >= 700;
              final crossAxisCount = isWide ? 4 : (isMedium ? 2 : 1);
              final stats = [
                {
                  'title': 'Totaal Gebruikers',
                  'value': _rows.length.toString(),
                  'label': 'Algeheel'
                },
                {
                  'title': 'Wag Goedkeuring',
                  'value': _rows.where((u) => u['is_aktief'] == false && (
                    u['admin_tipe_id'] != null || (u['gebr_tipe']?['gebr_tipe_naam'] ?? '') == 'Ekstern'
                  )).length.toString(),
                  'label': 'Nie aktief'
                },
                {
                  'title': 'Studente met Toelae',
                  'value': _usersWithAllowancesCount.toString(),
                  'label': 'Toelae per tipe'
                },
                {
                  'title': 'Aktiewe Gebruikers',
                  'value': _rows.where((u) => u['is_aktief'] == true).length.toString(),
                  'label': 'Huidig aktief'
                },
              ];
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: isWide ? 3.8 : (isMedium ? 3.2 : 3.0),
                ),
                itemCount: stats.length,
                itemBuilder: (context, index) {
                  final s = stats[index];
                  return _buildBigStat(s['title'] as String, s['value'] as String, small: s['label'] as String);
                },
              );
            },
          ),

          const SizedBox(height: 30),

          // 🔹 Quick filter buttons for common views
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => setState(() {
                  // Show only pending users (Pending admin type or inactive Ekstern)
                  filterAdminTipeId = AdminPermissions.pendingAdminId;
                  filterAktief = false;
                }),
                icon: const Icon(Icons.pending_actions, size: 16),
                label: const Text('Wag Goedkeuring'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade100,
                  foregroundColor: Colors.orange.shade800,
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => setState(() {
                  // Clear all filters
                  searchQuery = '';
                  filterGebrTipeId = null;
                  filterAdminTipeId = null;
                  filterKampusId = null;
                  filterAktief = null;
                }),
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Alle Gebruikers'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade100,
                  foregroundColor: Colors.blue.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 🔹 Search en filter (refined layout inside a card for better visual grouping)
          LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 700;
              final filterControls = Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Centered search bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: TextField(
                              decoration: InputDecoration(
                                prefixIcon: const Icon(Icons.search),
                                hintText: 'Soek naam of e-pos',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              ),
                              onChanged: (value) => setState(() => searchQuery = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Filter row
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          SizedBox(
                            width: 220,
                            child: DropdownButtonFormField<String?>(
                              value: filterGebrTipeId,
                              decoration: const InputDecoration(labelText: 'Gebruiker tipe', border: OutlineInputBorder()),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Alle')),
                                ..._gebrTipes.map((t) => DropdownMenuItem(value: t['gebr_tipe_id'] as String, child: Text(t['gebr_tipe_naam']))),
                              ],
                              onChanged: (v) => setState(() => filterGebrTipeId = v),
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: DropdownButtonFormField<String?>(
                              value: filterAdminTipeId,
                              decoration: const InputDecoration(labelText: 'Admin tipe', border: OutlineInputBorder()),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Alle')),
                                ..._adminTipes.map((t) => DropdownMenuItem(value: t['admin_tipe_id'] as String, child: Text(t['admin_tipe_naam']))),
                              ],
                              onChanged: (v) => setState(() => filterAdminTipeId = v),
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: DropdownButtonFormField<String?>(
                              value: filterKampusId,
                              decoration: const InputDecoration(labelText: 'Kampus', border: OutlineInputBorder()),
                              items: [
                                const DropdownMenuItem(value: null, child: Text('Alle')),
                                ..._kampusse.map((t) => DropdownMenuItem(value: t['kampus_id'] as String, child: Text(t['kampus_naam']))),
                              ],
                              onChanged: (v) => setState(() => filterKampusId = v),
                            ),
                          ),
                          SizedBox(
                            width: 220,
                            child: DropdownButtonFormField<bool?>(
                              value: filterAktief,
                              decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                              items: const [
                                DropdownMenuItem<bool?>(value: null, child: Text('Alle')),
                                DropdownMenuItem<bool?>(value: true, child: Text('Aktief')),
                                DropdownMenuItem<bool?>(value: false, child: Text('Nie aktief')),
                              ],
                              onChanged: (v) => setState(() => filterAktief = v),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () => setState(() {
                              searchQuery = '';
                              filterGebrTipeId = null;
                              filterAdminTipeId = null;
                              filterKampusId = null;
                              filterAktief = null;
                            }),
                            icon: const Icon(Icons.restart_alt),
                            label: const Text('Herstel filters'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
              if (narrow) {
                return ExpansionTile(title: const Text('Filters'), children: [filterControls]);
              }
              return Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: filterControls);
            },
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
                      backgroundColor: Colors.blue.shade50,
                    ),
              if (filterGebrTipeId != null)
                    InputChip(
                      label: Text('Gebruiker: ${_getGebrTipeName(filterGebrTipeId!)}'),
                      onDeleted: () => setState(() => filterGebrTipeId = null),
                      backgroundColor: Colors.green.shade50,
                    ),
              if (filterAdminTipeId != null)
                    InputChip(
                      label: Text('Admin: ${_getAdminTipeName(filterAdminTipeId!)}'),
                      onDeleted: () => setState(() => filterAdminTipeId = null),
                      backgroundColor: Colors.orange.shade50,
                    ),
              if (filterKampusId != null)
                    InputChip(
                      label: Text('Kampus: ${_getKampusName(filterKampusId!)}'),
                      onDeleted: () => setState(() => filterKampusId = null),
                      backgroundColor: Colors.purple.shade50,
                    ),
              if (filterAktief != null)
                    InputChip(
                      label: Text('Status: ${filterAktief == true ? 'Aktief' : 'Nie aktief'}'),
                      onDeleted: () => setState(() => filterAktief = null),
                      backgroundColor: filterAktief == true ? Colors.green.shade50 : Colors.red.shade50,
                    ),
                ],
              ),
          ),

          const SizedBox(height: 20),

          // 🔹 Gebruiker lys as cards
          Column(
            children: filteredUsers.map((user) => _buildUserCard(user)).toList(),
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



Widget _buildBigStat(String title, String count, {String? small}) {
  return Card(
    elevation: 1,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title, 
            style: TextStyle(
              fontSize: 12, 
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)
            )
          ),
          const SizedBox(height: 8),
          Text(
            count, 
            style: TextStyle(
              fontSize: 26, 
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            )
          ),
          if (small != null) ...[
          const SizedBox(height: 4),
            Text(
              small, 
              style: TextStyle(
                fontSize: 11, 
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)
              )
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> u) {
    final name = ((u['gebr_naam'] ?? '') + ' ' + (u['gebr_van'] ?? '')).trim();
    final email = (u['gebr_epos'] ?? '').toString();
    final phone = (u['gebr_selfoon'] ?? '').toString();
    final role = (u['gebr_tipe']?['gebr_tipe_naam'] ?? '').toString();
    final admin = (u['admin_tipe']?['admin_tipe_naam'] ?? '').toString();
    final requestedAdmin = (u['requested_admin_tipe']?['admin_tipe_naam'] ?? '').toString();
    final kampus = (u['kampus']?['kampus_naam'] ?? '').toString();
    final aktief = (u['is_aktief'] == true);
    final isPending = AdminPermissions.isPendingApproval(u);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Naam en rol bo
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.person)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.isEmpty ? '(Geen naam)' : name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      if (role.isNotEmpty)
                        Text(role,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Ander info
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (email.isNotEmpty) _infoColumn("E-pos", email),
                  if (phone.isNotEmpty) _infoColumn("Selfoon", phone),
                  if (admin.isNotEmpty) _infoColumn("Admin", admin),
                  if (requestedAdmin.isNotEmpty && isPending) 
                    _infoColumn("Versoek", requestedAdmin, color: Colors.blue),
                  if (kampus.isNotEmpty) _infoColumn("Kampus", kampus),
                  _infoColumn("Status", aktief ? 'Aktief' : 'Nie aktief',
                      color: aktief ? Colors.green : Colors.orange),
                  // User action buttons with role restrictions
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
                            return const Tooltip(
                              message: 'Jy kan nie jou eie status verander nie',
                              child: Icon(Icons.lock, color: Colors.grey),
                            );
                          }
                          
                              // Primary admins have full access to everything
                              if (isPrimary) {
                                // Primary admin - show all buttons
                                if (isPending) {
                                  // This is a pending user - show approve/decline buttons
                                  return Row(
                                    children: [
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.check_circle, size: 16),
                                        label: const Text('Keur Goed'),
                                        onPressed: () {
                                          // Use async pattern with watchdog
                                          AsyncUtils.executeWithWatchdog(
                                            operation: () async => _showAcceptUserDialog(u),
                                            onSuccess: (result) {},
                                            onError: (error) {},
                                            context: context,
                                            successMessage: 'Goedkeur dialoog oopgemaak',
                                            errorMessage: 'Kon nie goedkeur dialoog oopmaak nie',
                                          );
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.cancel, size: 16),
                                        label: const Text('Verwerp'),
                                        onPressed: () => _showDeclineUserDialog(u),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  // This is an active user - show all management buttons
                                  return Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.person_off, color: Colors.orange),
                                        onPressed: () {
                                          // Use async pattern with watchdog
                                          AsyncUtils.executeWithWatchdog(
                                            operation: () async => _setUserActive(userId, false),
                                            onSuccess: (result) async {
                                              // Data will be refreshed manually via refresh button
                                            },
                                            onError: (error) {},
                                            context: context,
                                            successMessage: 'Gebruiker status opgedateer',
                                            errorMessage: 'Kon nie gebruiker status opdateer nie',
                                          );
                                        },
                                        tooltip: 'Deaktiveer gebruiker',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.admin_panel_settings, color: Colors.blue),
                                        onPressed: () {
                                          // Use async pattern with watchdog
                                          AsyncUtils.executeWithWatchdog(
                                            operation: () async => _showChangeAdminTypeDialog(u),
                                            onSuccess: (result) {},
                                            onError: (error) {},
                                            context: context,
                                            successMessage: 'Admin tipe dialoog oopgemaak',
                                            errorMessage: 'Kon nie admin tipe dialoog oopmaak nie',
                                          );
                                        },
                                        tooltip: 'Verander Admin Tipe',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.person, color: Colors.purple),
                                        onPressed: () {
                                          // fixed: enforce Secondary cannot edit admin targets
                                          final adminTipeId = (u['admin_tipe_id'] ?? '').toString();
                                          final isAdminTarget = adminTipeId.isNotEmpty && adminTipeId != '902397b6-c835-44c2-80cb-d6ad93407048';
                                          if (!isPrimary && isAdminTarget) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Sekondêr kan nie admin gebruikers wysig nie')),
                                            );
                                            return;
                                          }
                                          // Use async pattern with watchdog
                                          AsyncUtils.executeWithWatchdog(
                                            operation: () async => _showChangeUserTypeDialog(u),
                                            onSuccess: (result) {},
                                            onError: (error) {},
                                            context: context,
                                            successMessage: 'Gebruiker tipe dialoog oopgemaak',
                                            errorMessage: 'Kon nie gebruiker tipe dialoog oopmaak nie',
                                          );
                                        },
                                        tooltip: 'Verander Gebruiker Tipe',
                                      ),
                                    ],
                                  );
                                }
                              } else {
                                // Non-primary admins - show limited buttons based on role
                                final canManageUsers = AdminPermissions.canAcceptUsers(adminTypeName);
                                final canChangeAdminTypes = AdminPermissions.canChangeAdminTypes(adminTypeName);
                                final canModifyUserTypes = AdminPermissions.canModifyUserTypes(adminTypeName);
                                
                                if (!canManageUsers && !canChangeAdminTypes && !canModifyUserTypes) {
                            return const Tooltip(
                                    message: 'Jy het nie die regte om gebruikers te bestuur nie',
                              child: Icon(Icons.lock, color: Colors.grey),
                            );
                          }
                          
                          if (isPending) {
                                  // This is a pending user - show approve/decline buttons (if allowed)
                                  if (canManageUsers) {
                              return Row(
                                children: [
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.check_circle, size: 16),
                                    label: const Text('Keur Goed'),
                                          onPressed: () {
                                          // Use async pattern with watchdog
                                          AsyncUtils.executeWithWatchdog(
                                            operation: () async => _showAcceptUserDialog(u),
                                            onSuccess: (result) {},
                                            onError: (error) {},
                                            context: context,
                                            successMessage: 'Goedkeur dialoog oopgemaak',
                                            errorMessage: 'Kon nie goedkeur dialoog oopmaak nie',
                                          );
                                        },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    icon: const Icon(Icons.cancel, size: 16),
                                    label: const Text('Verwerp'),
                                    onPressed: () => _showDeclineUserDialog(u),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                  ),
                                ],
                              );
                            } else {
                                    return const Tooltip(
                                      message: 'Slegs Primêre Admins kan gebruikers goedkeur',
                                      child: Icon(Icons.lock, color: Colors.grey),
                                    );
                                  }
                                } else {
                                  // This is an active user - show management buttons based on role
                                  final buttons = <Widget>[];
                                  
                                  if (canManageUsers) {
                                    buttons.add(
                        IconButton(
                                        icon: const Icon(Icons.person_off, color: Colors.orange),
                                        onPressed: () {
                                          // Use async pattern with watchdog
                                          AsyncUtils.executeWithWatchdog(
                                            operation: () async => _setUserActive(userId, false),
                                            onSuccess: (result) async {
                                              // Data will be refreshed manually via refresh button
                                            },
                                            onError: (error) {},
                                            context: context,
                                            successMessage: 'Gebruiker status opgedateer',
                                            errorMessage: 'Kon nie gebruiker status opdateer nie',
                                          );
                                        },
                                        tooltip: 'Deaktiveer gebruiker',
                                      ),
                                    );
                                  }
                                  
                                  if (canChangeAdminTypes) {
                                    buttons.add(
                        IconButton(
                                        icon: const Icon(Icons.admin_panel_settings, color: Colors.blue),
                                        onPressed: () {
                                          // Use async pattern with watchdog
                                          AsyncUtils.executeWithWatchdog(
                                            operation: () async => _showChangeAdminTypeDialog(u),
                                            onSuccess: (result) {},
                                            onError: (error) {},
                                            context: context,
                                            successMessage: 'Admin tipe dialoog oopgemaak',
                                            errorMessage: 'Kon nie admin tipe dialoog oopmaak nie',
                                          );
                                        },
                                        tooltip: 'Verander Admin Tipe',
                                      ),
                                    );
                                  }
                                  
                                  if (canModifyUserTypes) {
                                    buttons.add(
                                      IconButton(
                                        icon: const Icon(Icons.person, color: Colors.purple),
                                        onPressed: () => _showChangeUserTypeDialog(u),
                                        tooltip: 'Verander Gebruiker Tipe',
                                      ),
                                    );
                                  }
                                  
                                  if (buttons.isEmpty) {
                                    return const Tooltip(
                                      message: 'Jy het nie die regte om hierdie gebruiker te bestuur nie',
                                      child: Icon(Icons.lock, color: Colors.grey),
                                    );
                                  }
                                  
                                  return Row(children: buttons);
                                }
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
                  // Allowance management button (Primary admin only, for students)
                  Consumer(
                    builder: (context, ref, child) {
                      final isPrimaryAsync = ref.watch(isPrimaryAdminProvider);
                      return isPrimaryAsync.when(
                        data: (isPrimary) {
                          if (!isPrimary) return const SizedBox.shrink();
                          
                          // Show allowance management for all user types (not just students)
                          final userType = (u['gebr_tipe']?['gebr_tipe_naam'] ?? '');
                          if (userType.isEmpty || userType == 'Ekstern') return const SizedBox.shrink();
                          
                          return IconButton(
                            icon: const Icon(Icons.account_balance_wallet, color: Colors.blue),
                            onPressed: () => _showAllowanceDialog(u),
                            tooltip: 'Bestuur Toelae',
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                  ),
                  // User type change button (Primary admin only)
                  Consumer(
                    builder: (context, ref, child) {
                      final isPrimaryAsync = ref.watch(isPrimaryAdminProvider);
                      return isPrimaryAsync.when(
                        data: (isPrimary) {
                          if (!isPrimary) return const SizedBox.shrink();
                          
                          final userId = u['gebr_id'].toString();
                          final isSelf = userId == currentUserId;
                          
                          // Don't show for self
                          if (isSelf) return const SizedBox.shrink();
                          
                          // Removed duplicate "Verander Gebruiker Tipe" button
                          // This functionality is already available in the main action buttons
                          return const SizedBox.shrink();
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoColumn(String title, String value, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(fontSize: 14, color: color ?? Colors.black)),
        ],
      ),
    );
  }

  Future<void> _setUserActive(String gebrId, bool active) async {
    // TODO: SERVER-SIDE ENFORCEMENT REQUIRED
    // Server must validate that the calling user is a Primary admin before allowing
    // user activation/deactivation. Add RLS policy or API endpoint validation.
    
    // fixed: async + watchdog + refresh
    AsyncUtils.executeWithWatchdog(
      operation: () async {
    final sb = Supabase.instance.client;
        return await sb.from('gebruikers').update({'is_aktief': active}).eq('gebr_id', gebrId);
      },
      onSuccess: (result) async {
        // Data will be refreshed manually via refresh button
      },
      onError: (error) {
        // Error handling is done by AsyncUtils
      },
      context: context,
      successMessage: active ? 'Gebruiker geaktiveer' : 'Gebruiker gedeaktiveer',
      errorMessage: 'Kon nie gebruiker status opdateer nie',
    );
  }

  // Old simple _showAddTypeDialog method removed - using comprehensive version below

  Future<void> _showAllowanceDialog(Map<String, dynamic> user) async {
    final userName = '${user['gebr_naam'] ?? ''} ${user['gebr_van'] ?? ''}'.trim();
    final userTypeName = user['gebr_tipe']?['gebr_tipe_naam'] ?? 'Unknown';
    final typeAllowance = user['gebr_tipe']?['gebr_toelaag']?.toDouble() ?? 0.0;
    
    await showDialog<void>(
      context: context,
      builder: (context) {
            return AlertDialog(
          title: Text('Toelae vir: $userName'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Current allowance info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Toelae vir $userName ($userTypeName):', 
                               style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                      Text('Maandelikse toelae: R${typeAllowance.toStringAsFixed(2)}'),
                      Text('Bron: Van gebruiker tipe', 
                               style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                // Info message
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
                          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          const Text('Toelae Bestuur', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Individuele toelae oorskryf is nie beskikbaar nie. '
                                 'Om toelae te verander, gaan na die "Toelae" tab om die '
                                 'standaard bedrag vir hierdie gebruiker tipe te wysig.'),
                    ],
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
              child: const Text('Sluit'),
            ),
          ],
        );
      },
    );
  }

  // NOTE: Removed _showAddUserDialog method - users now register via mobile app
  // and appear as pending Ekstern users for Primary admin approval.
  
  Future<void> _showAcceptUserDialog(Map<String, dynamic> user) async {
    final userId = user['gebr_id'].toString();
    final userName = '${user['gebr_naam'] ?? ''} ${user['gebr_van'] ?? ''}'.trim();
    // Removed: requested_admin_tipe - column doesn't exist in client schema
    final requestedAdminType = '';
    final currentUserType = user['gebr_tipe']?['gebr_tipe_naam'] ?? 'Ekstern';
    
    // Default selections - ensure user gets a valid gebr_tipe_id
    String? selectedGebrTipeId = user['gebr_tipe_id'] ?? AdminPermissions.eksternTypeId; // Default to Ekstern if null
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
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Gebruiker Inligting:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('Naam: $userName'),
                            Text('E-pos: ${user['gebr_epos'] ?? ''}'),
                            Text('Selfoon: ${user['gebr_selfoon'] ?? ''}'),
                            Text('Huidige Tipe: $currentUserType'),
                            if (requestedAdminType.isNotEmpty)
                              Text('Versoekte Admin Tipe: $requestedAdminType', 
                                   style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600)),
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
                        onChanged: isLoading ? null : (value) {
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
                          helperText: 'Standaard: Tierseriy (kan verander word later)',
                        ),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('Geen admin regte')),
                          ..._adminTipes.where((type) => type['admin_tipe_naam'] != 'Pending').map((type) {
                            return DropdownMenuItem<String>(
                              value: type['admin_tipe_id'],
                              child: Text(type['admin_tipe_naam']),
                            );
                          }),
                        ],
                        onChanged: isLoading ? null : (value) {
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
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Regte vir ${_getAdminTypeName(selectedAdminTipeId!)}:', 
                                   style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              ..._getPermissionsForAdminType(selectedAdminTipeId!).entries.map((entry) {
                                return Row(
                                  children: [
                                    Icon(entry.value ? Icons.check : Icons.close, 
                                         color: entry.value ? Colors.green : Colors.red, size: 16),
                                    const SizedBox(width: 4),
                                    Text(entry.key, style: const TextStyle(fontSize: 12)),
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
                  onPressed: (selectedGebrTipeId == null || isLoading) ? null : () {
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
                          adminTipeId: selectedAdminTipeId, // Will default to Tierseriy if null
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
                      errorMessage: 'Kon nie gebruiker goedkeur nie — probeer asseblief weer',
                    );
                  },
                  child: isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
    final userName = '${user['gebr_naam'] ?? ''} ${user['gebr_van'] ?? ''}'.trim();
    
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Verwerp Gebruiker: $userName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Is jy seker jy wil hierdie gebruiker se registrasie verwerp?'),
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
                    const Text('Gebruiker Inligting:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        content: Text('$userName se registrasie is verwerp en verwyder'),
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
              child: const Text('Verwerp en Verwyder', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _showAddTypeDialog(BuildContext context, {required bool isAdmin}) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final allowanceController = TextEditingController();
    
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isAdmin ? 'Voeg Admin Tipe by' : 'Voeg Gebruiker Tipe by'),
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
                        Text('Admin Regte:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('• Kan gebruikers bestuur', style: TextStyle(fontSize: 12)),
                        Text('• Kan spyskaarte bestuur', style: TextStyle(fontSize: 12)),
                        Text('• Kan verslae sien', style: TextStyle(fontSize: 12)),
                        Text('• Primary admins kan ander admins bestuur', style: TextStyle(fontSize: 12)),
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
                      'admin_tipe_beskrywing': descriptionController.text.trim().isEmpty 
                          ? null : descriptionController.text.trim(),
                      'permissions': '{"canManageUsers": true, "canManageMenus": true, "canViewReports": true}',
                    });
                  } else {
                    // Create user type
                    final allowance = allowanceController.text.trim().isEmpty 
                        ? null 
                        : double.tryParse(allowanceController.text.trim());
                    
                    await sb.from('gebruiker_tipes').insert({
                      'gebr_tipe_naam': nameController.text.trim(),
                      'gebr_tipe_beskrywing': descriptionController.text.trim().isEmpty 
                          ? null : descriptionController.text.trim(),
                      'gebr_toelaag': allowance,
                    });
                  }
                  
                  Navigator.pop(context);
                  await _loadData();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${isAdmin ? 'Admin' : 'Gebruiker'} tipe suksesvol bygevoeg'),
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
    final userName = '${user['gebr_naam'] ?? ''} ${user['gebr_van'] ?? ''}'.trim();
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
                          const Text('Huidige Inligting:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                        helperText: 'Kies die nuwe admin tipe vir hierdie gebruiker',
                      ),
                      items: _adminTipes.where((type) => type['admin_tipe_naam'] != 'Pending').map((type) {
                        return DropdownMenuItem<String>(
                          value: type['admin_tipe_id'],
                          child: Text(type['admin_tipe_naam']),
                        );
                      }).toList(),
                        onChanged: isLoading ? null : (value) {
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
                            Text('Regte vir ${_getAdminTypeName(selectedAdminTipeId!)}:', 
                                 style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ..._getPermissionsForAdminType(selectedAdminTipeId!).entries.map((entry) {
                              return Row(
                                children: [
                                  Icon(entry.value ? Icons.check : Icons.close, 
                                       color: entry.value ? Colors.green : Colors.red, size: 16),
                                  const SizedBox(width: 4),
                                  Text(entry.key, style: const TextStyle(fontSize: 12)),
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
                  onPressed: (selectedAdminTipeId == null || isLoading) ? null : () {
                    setDialogState(() {
                      isLoading = true;
                    });
                    
                    // fixed: async + watchdog + refresh
                    AsyncUtils.executeWithWatchdog(
                      operation: () async {
                      final sb = Supabase.instance.client;
                      
                      // TODO: SERVER-SIDE ENFORCEMENT REQUIRED
                      // Server must validate Primary admin status before allowing admin type changes
                      
                        return await sb.from('gebruikers').update({
                        'admin_tipe_id': selectedAdminTipeId,
                      }).eq('gebr_id', userId);
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
                      successMessage: '$userName se admin tipe verander na ${_getAdminTypeName(selectedAdminTipeId!)}',
                      errorMessage: 'Kon nie admin tipe verander nie',
                    );
                  },
                  child: isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
    final userName = '${user['gebr_naam'] ?? ''} ${user['gebr_van'] ?? ''}'.trim();
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
            final typeAllowance = selectedType['gebr_toelaag']?.toDouble() ?? 0.0;
            
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
                          const Text('Huidige Inligting:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      onChanged: isLoading ? null : (value) {
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
                              Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                              const SizedBox(width: 8),
                              const Text('Toelae Inligting', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Tipe standaard toelae: R${typeAllowance.toStringAsFixed(2)}'),
                          const Text('Individuele toelae oorskryf is nie beskikbaar nie.'),
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
                  onPressed: (selectedGebrTipeId == null || isLoading) ? null : () {
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
                        return await sb.from('gebruikers').update({
                        'gebr_tipe_id': selectedGebrTipeId,
                      }).eq('gebr_id', userId);
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
                      successMessage: '$userName se gebruiker tipe verander na ${selectedType['gebr_tipe_naam']}',
                      errorMessage: 'Kon nie gebruiker tipe verander nie',
                    );
                  },
                  child: isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

  // Add missing _showDeactivateUserDialog method
  Future<void> _showDeactivateUserDialog(Map<String, dynamic> user) async {
    final userName = '${user['gebr_naam'] ?? ''} ${user['gebr_van'] ?? ''}'.trim();
    
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Deaktiveer Gebruiker - $userName'),
        content: const Text('Is jy seker jy wil hierdie gebruiker deaktiveer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kanselleer'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Add deactivation logic here if needed
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$userName is gedeaktiveer')),
              );
            },
            child: const Text('Deaktiveer'),
          ),
        ],
      ),
    );
  }
  
  // NOTE: All old user creation methods removed per new workflow.
  // Users now register via mobile app and appear as pending Ekstern users.
}
