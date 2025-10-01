import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GebruikersBestuurPage extends StatefulWidget {
  const GebruikersBestuurPage({super.key});

  @override
  State<GebruikersBestuurPage> createState() => _GebruikersBestuurPageState();
}

class _GebruikersBestuurPageState extends State<GebruikersBestuurPage> {
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

  // Treat current demo login user as Primary admin (can add types)
  bool get isPrimaryAdmin => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() { _loading = true; _error = null; });
    final sb = Supabase.instance.client;
    try {
      final gebruikers = await sb
          .from('gebruikers')
          .select('*, gebr_tipe:gebr_tipe_id(gebr_tipe_naam), admin_tipe:admin_tipe_id(admin_tipe_naam), kampus:kampus_id(kampus_naam)')
          .limit(200);
      final gt = await sb.from('gebruiker_tipes').select('gebr_tipe_id, gebr_tipe_naam');
      final at = await sb.from('admin_tipes').select('admin_tipe_id, admin_tipe_naam');
      final ks = await sb.from('kampus').select('kampus_id, kampus_naam');
      setState(() {
        _rows = List<Map<String, dynamic>>.from(gebruikers ?? const []);
        _gebrTipes = List<Map<String, dynamic>>.from(gt ?? const []);
        _adminTipes = List<Map<String, dynamic>>.from(at ?? const []);
        _kampusse = List<Map<String, dynamic>>.from(ks ?? const []);
        _loading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🔹 Titel
          Text("Gebruikers Bestuur",
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 20),

          if (_loading) const LinearProgressIndicator(),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),

          // 🔹 Rol-oorsig blok (counts based on filtered live data)
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _buildStatCard("Primêre Admins", filteredUsers.where((u) => (u['admin_tipe']?['admin_tipe_naam'] ?? '') == 'Primary').length.toString()),
              _buildStatCard("Admins", filteredUsers.where((u) => (u['admin_tipe']?['admin_tipe_naam'] ?? '') != '' ).length.toString()),
              _buildStatCard("Studente", filteredUsers.where((u) => (u['gebr_tipe']?['gebr_tipe_naam'] ?? '') == 'Student').length.toString()),
              _buildStatCard("Personeel", filteredUsers.where((u) => (u['gebr_tipe']?['gebr_tipe_naam'] ?? '') == 'Personeel').length.toString()),
            ],
          ),

          const SizedBox(height: 30),

          // 🔹 Statistiek blok (live counts)
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              _buildBigStat("Totaal Gebruikers", filteredUsers.length.toString()),
              _buildBigStat("Aktiewe Gebruikers", filteredUsers.where((u) => u['is_aktief'] == true).length.toString()),
              _buildBigStat("Wag Goedkeuring", filteredUsers.where((u) => (u['is_aktief'] != true)).length.toString()),
              _buildBigStat("Gedeaktiveer", filteredUsers.where((u) => u['is_aktief'] == false).length.toString()),
            ],
          ),

          const SizedBox(height: 30),

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

          // Active filter chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              if (searchQuery.isNotEmpty)
                InputChip(label: Text('Soek: $searchQuery'), onDeleted: () => setState(() => searchQuery = '')),
              if (filterGebrTipeId != null)
                InputChip(label: Text('Gebruiker tipe'), onDeleted: () => setState(() => filterGebrTipeId = null)),
              if (filterAdminTipeId != null)
                InputChip(label: Text('Admin tipe'), onDeleted: () => setState(() => filterAdminTipeId = null)),
              if (filterKampusId != null)
                InputChip(label: const Text('Kampus'), onDeleted: () => setState(() => filterKampusId = null)),
              if (filterAktief != null)
                InputChip(label: Text(filterAktief == true ? 'Aktief' : 'Nie aktief'), onDeleted: () => setState(() => filterAktief = null)),
            ],
          ),

          const SizedBox(height: 20),

          // 🔹 Gebruiker lys as cards
          Column(
            children: filteredUsers.map((user) => _buildUserCard(user)).toList(),
          ),
          const SizedBox(height: 24),
          if (isPrimaryAdmin)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showAddTypeDialog(context, isAdmin: true),
                  icon: const Icon(Icons.add),
                  label: const Text('Voeg Admin Tipe by'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showAddTypeDialog(context, isAdmin: false),
                  icon: const Icon(Icons.add),
                  label: const Text('Voeg Gebruiker Tipe by'),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count) {
    return Container(
      width: 140,
      height: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(count,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBigStat(String title, String count) {
    return Container(
      width: 150,
      height: 110,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(count,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> u) {
    final name = ((u['gebr_naam'] ?? '') + ' ' + (u['gebr_van'] ?? '')).trim();
    final email = (u['gebr_epos'] ?? '').toString();
    final phone = (u['gebr_selfoon'] ?? '').toString();
    final role = (u['gebr_tipe']?['gebr_tipe_naam'] ?? '').toString();
    final admin = (u['admin_tipe']?['admin_tipe_naam'] ?? '').toString();
    final kampus = (u['kampus']?['kampus_naam'] ?? '').toString();
    final aktief = (u['is_aktief'] == true);

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
                  if (kampus.isNotEmpty) _infoColumn("Kampus", kampus),
                  _infoColumn("Status", aktief ? 'Aktief' : 'Nie aktief',
                      color: aktief ? Colors.green : Colors.orange),
                  if (!aktief)
                    Row(
                      children: [
                        IconButton(
                            icon: const Icon(Icons.check_circle, color: Colors.green),
                            onPressed: () => _setUserActive(u['gebr_id'].toString(), true)),
                        IconButton(
                            icon: const Icon(Icons.cancel, color: Colors.red),
                            onPressed: () => _setUserActive(u['gebr_id'].toString(), false)),
                      ],
                    )
                  else
                    IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _setUserActive(u['gebr_id'].toString(), false)),
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
    final sb = Supabase.instance.client;
    try {
      await sb.from('gebruikers').update({'is_aktief': active}).eq('gebr_id', gebrId);
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kon nie gebruiker opdateer nie: $e')));
    }
  }

  Future<void> _showAddTypeDialog(BuildContext context, {required bool isAdmin}) async {
    final controller = TextEditingController();
    final title = isAdmin ? 'Nuwe Admin Tipe' : 'Nuwe Gebruiker Tipe';
    final hint = isAdmin ? 'bv. Primary' : 'bv. Student';
    final sb = Supabase.instance.client;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(controller: controller, decoration: InputDecoration(hintText: hint)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselleer')),
            ElevatedButton(
              onPressed: () async {
                try {
                  if (isAdmin) {
                    await sb.from('admin_tipes').insert({'admin_tipe_naam': controller.text.trim()});
                  } else {
                    await sb.from('gebruiker_tipes').insert({'gebr_tipe_naam': controller.text.trim()});
                  }
                  Navigator.pop(context);
                  await _loadData();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kon nie skep nie: $e')));
                }
              },
              child: const Text('Skep'),
            ),
          ],
        );
      },
    );
  }
}
