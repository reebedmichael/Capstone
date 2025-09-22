import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart';

class KennisgewingsPage extends StatefulWidget {
  const KennisgewingsPage({super.key});
  @override
  State<KennisgewingsPage> createState() => _KennisgewingsPageState();
}

class _KennisgewingsPageState extends State<KennisgewingsPage> {
  List<Map<String, dynamic>> _all = [];
  bool _isLoading = true;
  Map<String, int> _statistieke = {'totaal': 0, 'ongelees': 0, 'gelees': 0};

  String _geleesFilter = 'alles'; // alles | ongelees | gelees
  String _tipeFilter = 'alle_tipes'; // alle_tipes | info | waarskuwing | fout | sukses

  // Skep modal state
  final TextEditingController _titelCtrl = TextEditingController();
  final TextEditingController _kortCtrl = TextEditingController();
  final TextEditingController _inhoudCtrl = TextEditingController();
  String _nuweTipe = 'info';
  String _nuwePrioriteit = 'medium';
  String _nuweDoelgroep = 'alle';

  @override
  void initState() {
    super.initState();
    _laaiKennisgewings();
  }

  @override
  void dispose() {
    _titelCtrl.dispose();
    _kortCtrl.dispose();
    _inhoudCtrl.dispose();
    super.dispose();
  }

  Future<void> _laaiKennisgewings() async {
    try {
      final kennisgewingRepo = KennisgewingRepository(SupabaseDb(Supabase.instance.client));
      
      // Laai globale kennisgewings
      final kennisgewings = await kennisgewingRepo.kryGlobaleKennisgewings();
      
      setState(() {
        _all = kennisgewings;
        _isLoading = false;
      });
    } catch (e) {
      print('Fout met laai kennisgewings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _gefilterde => _all.where((final Map<String, dynamic> k) {
    final bool matchLees =
        _geleesFilter == 'alles' ||
        (_geleesFilter == 'gelees' && (k['kennis_gelees'] ?? false)) ||
        (_geleesFilter == 'ongelees' && !(k['kennis_gelees'] ?? false));
    final bool matchTipe = _tipeFilter == 'alle_tipes' || 
        (k['kennisgewing_tipes']?['kennis_tipe_naam'] ?? 'info') == _tipeFilter;
    return matchLees && matchTipe;
  }).toList();

  int get _ongelees => _all.where((k) => !(k['kennis_gelees'] ?? false)).length;
  int get _waarskuwings => _all.where((k) => (k['kennisgewing_tipes']?['kennis_tipe_naam'] ?? 'info') == 'waarskuwing').length;
  int get _kritiek => _all.where((k) => (k['kennisgewing_tipes']?['kennis_tipe_naam'] ?? 'info') == 'kritiek').length;

  Future<void> _markeerAsGelees(String id, bool gelees) async {
    try {
      final kennisgewingRepo = KennisgewingRepository(SupabaseDb(Supabase.instance.client));
      await kennisgewingRepo.markeerAsGelees(id);
      await _laaiKennisgewings();
    } catch (e) {
      print('Fout met markeer as gelees: $e');
    }
  }

  Future<void> _verwyder(String id) async {
    try {
      final kennisgewingRepo = KennisgewingRepository(SupabaseDb(Supabase.instance.client));
      await kennisgewingRepo.verwyderKennisgewing(id);
      await _laaiKennisgewings();
    } catch (e) {
      print('Fout met verwyder: $e');
    }
  }

  Future<void> _markeerAllesAsGelees() async {
    // Implementeer as nodig
  }

  Future<void> _verwyderAlleGelees() async {
    // Implementeer as nodig
  }

  Future<void> _openSkepDialog() async {
    _titelCtrl.clear();
    _kortCtrl.clear();
    _inhoudCtrl.clear();
    _nuweTipe = 'info';
    _nuwePrioriteit = 'medium';
    _nuweDoelgroep = 'alle';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Skep Nuwe Kennisgewing'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: _titelCtrl,
                  decoration: const InputDecoration(labelText: 'Titel *'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _kortCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Kort Boodskap *',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _inhoudCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Volledige Inhoud (opsioneel)',
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 8),
                Column(
                  children: <Widget>[
                    DropdownButtonFormField<String>(
                      value: _nuweTipe,
                      isExpanded: true,
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem(
                          value: 'info',
                          child: Text('Inligting'),
                        ),
                        DropdownMenuItem(
                          value: 'waarskuwing',
                          child: Text('Waarskuwing'),
                        ),
                        DropdownMenuItem(
                          value: 'sukses',
                          child: Text('Sukses'),
                        ),
                        DropdownMenuItem(value: 'fout', child: Text('Fout')),
                      ],
                      onChanged: (v) =>
                          setState(() => _nuweTipe = v ?? 'info'),
                      decoration: const InputDecoration(labelText: 'Tipe'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _nuwePrioriteit,
                      isExpanded: true,
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem(value: 'laag', child: Text('Laag')),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem(value: 'hoog', child: Text('Hoog')),
                        DropdownMenuItem(
                          value: 'kritiek',
                          child: Text('Kritiek'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _nuwePrioriteit = v ?? 'medium'),
                      decoration: const InputDecoration(
                        labelText: 'Prioriteit',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _nuweDoelgroep,
                      isExpanded: true,
                      items: const <DropdownMenuItem<String>>[
                        DropdownMenuItem(value: 'alle', child: Text('Almal')),
                        DropdownMenuItem(
                          value: 'admins',
                          child: Text('Admins'),
                        ),
                        DropdownMenuItem(
                          value: 'studente',
                          child: Text('Studente'),
                        ),
                        DropdownMenuItem(
                          value: 'personeel',
                          child: Text('Personeel'),
                        ),
                        DropdownMenuItem(
                          value: 'spesifiek',
                          child: Text('Spesifieke Gebruiker'),
                        ),
                      ],
                      onChanged: (v) =>
                          setState(() => _nuweDoelgroep = v ?? 'alle'),
                      decoration: const InputDecoration(
                        labelText: 'Stuur Aan *',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kanselleer'),
          ),
          FilledButton(
            onPressed: () async {
              if (_titelCtrl.text.trim().isEmpty ||
                  _kortCtrl.text.trim().isEmpty) {
                return;
              }

              try {
                final kennisgewingRepo = KennisgewingRepository(SupabaseDb(Supabase.instance.client));
                
                bool sukses = false;
                
                switch (_nuweDoelgroep) {
                  case 'alle':
                    sukses = await kennisgewingRepo.stuurAanAlleGebruikers(
                    beskrywing: _kortCtrl.text.trim(),
                      tipeNaam: _nuweTipe,
                    );
                    break;
                  case 'admins':
                    // Kry admin gebruikers
                    final admins = await Supabase.instance.client
                        .from('gebruikers')
                        .select('gebr_id')
                        .not('admin_tipe_id', 'is', null);
                    final adminIds = admins.map((a) => a['gebr_id'].toString()).toList();
                    
                    sukses = await kennisgewingRepo.stuurAanSpesifiekeGebruikers(
                      gebrIds: adminIds,
                      beskrywing: _kortCtrl.text.trim(),
                      tipeNaam: _nuweTipe,
                    );
                    break;
                  case 'studente':
                    // Kry student gebruikers
                    final studente = await Supabase.instance.client
                        .from('gebruikers')
                        .select('gebr_id')
                        .eq('gebr_tipe_id', 'student'); // Aanpas na jou tipe ID
                    final studentIds = studente.map((s) => s['gebr_id'].toString()).toList();
                    
                    sukses = await kennisgewingRepo.stuurAanSpesifiekeGebruikers(
                      gebrIds: studentIds,
                      beskrywing: _kortCtrl.text.trim(),
                      tipeNaam: _nuweTipe,
                    );
                    break;
                  case 'personeel':
                    // Kry personeel gebruikers
                    final personeel = await Supabase.instance.client
                        .from('gebruikers')
                        .select('gebr_id')
                        .eq('gebr_tipe_id', 'personeel'); // Aanpas na jou tipe ID
                    final personeelIds = personeel.map((p) => p['gebr_id'].toString()).toList();
                    
                    sukses = await kennisgewingRepo.stuurAanSpesifiekeGebruikers(
                      gebrIds: personeelIds,
                      beskrywing: _kortCtrl.text.trim(),
                      tipeNaam: _nuweTipe,
                    );
                    break;
                  default:
                    // Stuur as globale kennisgewing
                    sukses = await kennisgewingRepo.skepGlobaleKennisgewing(
                      beskrywing: _kortCtrl.text.trim(),
                      tipeNaam: _nuweTipe,
                    );
                }

                if (sukses) {
              Navigator.pop(context);
                  await _laaiKennisgewings();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kennisgewing suksesvol gestuur!')),
                    );
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fout met stuur kennisgewing!')),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fout: $e')),
                  );
                }
              }
            },
            child: const Text('Stuur Kennisgewing'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Statistieke
          LayoutBuilder(
            builder: (context, constraints) {
              final int cols = constraints.maxWidth > 1100
                  ? 4
                  : constraints.maxWidth > 800
                  ? 2
                  : 1;
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: cols,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 3.6,
                children: <Widget>[
                  _stat(
                    'Totaal',
                    '${_all.length}',
                    Icons.notifications_none,
                    Theme.of(context).colorScheme.primary,
                  ),
                  _stat(
                    'Ongelees',
                    '$_ongelees',
                    Icons.notifications_off_outlined,
                    Colors.orange,
                  ),
                  _stat(
                    'Waarskuwings',
                    '$_waarskuwings',
                    Icons.warning_amber_rounded,
                    Colors.orangeAccent,
                  ),
                  _stat(
                    'Kritiek',
                    '$_kritiek',
                    Icons.error_outline,
                    Colors.red,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // Filters en Aksies
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.filter_list,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Filters en Aksies',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      DropdownButton<String>(
                        value: _geleesFilter,
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem(
                            value: 'alles',
                            child: Text('Alle Kennisgewings'),
                          ),
                          DropdownMenuItem(
                            value: 'ongelees',
                            child: Text('Slegs Ongelees'),
                          ),
                          DropdownMenuItem(
                            value: 'gelees',
                            child: Text('Slegs Gelees'),
                          ),
                        ],
                        onChanged: (String? v) =>
                            setState(() => _geleesFilter = v ?? 'alles'),
                      ),
                      DropdownButton<String>(
                        value: _tipeFilter,
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem(
                            value: 'alle_tipes',
                            child: Text('Alle tipes'),
                          ),
                          DropdownMenuItem(
                            value: 'info',
                            child: Text('Inligting'),
                          ),
                          DropdownMenuItem(
                            value: 'waarskuwing',
                            child: Text('Waarskuwing'),
                          ),
                          DropdownMenuItem(value: 'fout', child: Text('Fout')),
                          DropdownMenuItem(
                            value: 'sukses',
                            child: Text('Sukses'),
                          ),
                        ],
                        onChanged: (String? v) =>
                            setState(() => _tipeFilter = v ?? 'alle_tipes'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _ongelees == 0
                            ? null
                            : _markeerAllesAsGelees,
                        icon: const Icon(Icons.done_all),
                        label: const Text('Markeer Alles As Gelees'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _all.any((k) => k['kennis_gelees'] ?? false)
                            ? _verwyderAlleGelees
                            : null,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Verwyder Alle Gelees'),
                      ),
                      FilledButton.icon(
                        onPressed: _openSkepDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Skep Kennisgewing'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Lys
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Kennisgewings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_gefilterde.length} van ${_all.length} kennisgewings',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  if (_gefilterde.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: <Widget>[
                            Icon(
                              Icons.notifications_none,
                              size: 56,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text('Geen Kennisgewings'),
                          ],
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _gefilterde.map((final Map<String, dynamic> k) {
                        final isGelees = k['kennis_gelees'] ?? false;
                        final tipe = k['kennisgewing_tipes']?['kennis_tipe_naam'] ?? 'info';
                        final datum = DateTime.parse(k['kennis_geskep_datum']);
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: isGelees
                                ? Colors.grey[50]
                                : _typeColor(tipe).withOpacity(0.05),
                            border: Border.all(
                              color: isGelees
                                  ? Colors.grey[300]!
                                  : _typeColor(tipe).withOpacity(0.3),
                              width: isGelees ? 1 : 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: isGelees 
                                  ? Colors.grey.withOpacity(0.1)
                                  : _typeColor(tipe).withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _toonKennisgewingDetail(k),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                          child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                      Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: _typeColor(tipe).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(25),
                                          border: Border.all(
                                            color: _typeColor(tipe).withOpacity(0.3),
                                            width: 2,
                                          ),
                                        ),
                                        child: Icon(
                                          _typeIcon(tipe),
                                          color: _typeColor(tipe),
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                                Expanded(
                                                  child: Text(
                                                    k['kennis_beskrywing'] ?? 'Kennisgewing',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: isGelees
                                                        ? FontWeight.w500
                                                          : FontWeight.bold,
                                                      color: isGelees 
                                                        ? Colors.grey[700] 
                                                        : Colors.black87,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (!isGelees)
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                              decoration: BoxDecoration(
                                                      color: _typeColor(tipe),
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
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                    color: _typeColor(tipe).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                border: Border.all(
                                                      color: _typeColor(tipe).withOpacity(0.3),
                                                ),
                                              ),
                                              child: Text(
                                                    tipe.toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: _typeColor(tipe),
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
                                  const SizedBox(height: 16),
                              Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                children: <Widget>[
                                      if (!isGelees)
                                        OutlinedButton.icon(
                                          onPressed: () => _markeerAsGelees(k['kennis_id'], true),
                                          icon: const Icon(Icons.mark_email_read, size: 16),
                                          label: const Text('Markeer as Gelees'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.green,
                                            side: const BorderSide(color: Colors.green),
                                          ),
                                        ),
                                      if (isGelees)
                                        OutlinedButton.icon(
                                          onPressed: () => _markeerAsGelees(k['kennis_id'], false),
                                          icon: const Icon(Icons.mark_email_unread, size: 16),
                                          label: const Text('Markeer as Ongelees'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.orange,
                                            side: const BorderSide(color: Colors.orange),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: () => _verwyder(k['kennis_id']),
                                        icon: const Icon(Icons.delete_outline, size: 16),
                                        label: const Text('Verwyder'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: const BorderSide(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
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
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _typeIcon(String tipe) {
    switch (tipe) {
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

  Color _typeColor(String tipe) {
    switch (tipe) {
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

  String _formatDate(DateTime d) {
    const List<String> s = <String>[
      'Jan', 'Feb', 'Mrt', 'Apr', 'Mei', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    return '${d.day.toString().padLeft(2, '0')} ${s[d.month - 1]} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  void _toonKennisgewingDetail(Map<String, dynamic> k) {
    final isGelees = k['kennis_gelees'] ?? false;
    final tipe = k['kennisgewing_tipes']?['kennis_tipe_naam'] ?? 'info';
    final datum = DateTime.parse(k['kennis_geskep_datum']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _typeColor(tipe).withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: _typeColor(tipe).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                _typeIcon(tipe),
                color: _typeColor(tipe),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Kennisgewing Besonderhede',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  Text(
                    _formatDate(datum),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
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
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _typeColor(tipe).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _typeColor(tipe).withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _typeIcon(tipe),
                          color: _typeColor(tipe),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          tipe.toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: _typeColor(tipe),
                          ),
                        ),
                        const Spacer(),
                        if (!isGelees)
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _typeColor(tipe),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      k['kennis_beskrywing'] ?? 'Kennisgewing',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Gestuur op: ${_formatDate(datum)}',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    isGelees ? Icons.mark_email_read : Icons.mark_email_unread,
                    size: 20,
                    color: isGelees ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isGelees ? 'Gelees' : 'Ongelees',
                    style: TextStyle(
                      fontSize: 16,
                      color: isGelees ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          if (!isGelees)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _markeerAsGelees(k['kennis_id'], true);
              },
              icon: const Icon(Icons.mark_email_read),
              label: const Text('Markeer as Gelees'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
              ),
            ),
          if (isGelees)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _markeerAsGelees(k['kennis_id'], false);
              },
              icon: const Icon(Icons.mark_email_unread),
              label: const Text('Markeer as Ongelees'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange,
                side: const BorderSide(color: Colors.orange),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _verwyder(k['kennis_id']);
            },
            icon: const Icon(Icons.delete_outline),
            label: const Text('Verwyder'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maak Toe'),
          ),
        ],
      ),
    );
  }
}