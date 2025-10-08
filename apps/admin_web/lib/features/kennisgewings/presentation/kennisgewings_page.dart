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

  String _soortFilter = 'alles'; // alles | gebruiker | globaal
  String _tipeFilter = 'alle_tipes'; // alle_tipes | info | waarskuwing | fout | sukses

  @override
  void initState() {
    super.initState();
    _laaiKennisgewings();
  }

  Future<void> _laaiKennisgewings() async {
    setState(() => _isLoading = true);
    try {
      final kennisgewingRepo = KennisgewingRepository(SupabaseDb(Supabase.instance.client));
      
      // Laai ALLE kennisgewings (gebruiker + globaal)
      final kennisgewings = await kennisgewingRepo.kryAlleKennisgewingsVirAdmin();
      
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
    final soort = k['_kennisgewing_soort'] ?? 'globaal';
    final bool matchSoort = _soortFilter == 'alles' || soort == _soortFilter;
    
    final bool matchTipe = _tipeFilter == 'alle_tipes' || 
        (k['kennisgewing_tipes']?['kennis_tipe_naam'] ?? 'info') == _tipeFilter;
    
    return matchSoort && matchTipe;
  }).toList();

  int get _gebruikerKennisgewings => _all.where((k) => k['_kennisgewing_soort'] == 'gebruiker').length;
  int get _globaleKennisgewings => _all.where((k) => k['_kennisgewing_soort'] == 'globaal').length;
  int get _waarskuwings => _all.where((k) => (k['kennisgewing_tipes']?['kennis_tipe_naam'] ?? 'info') == 'waarskuwing').length;
  int get _kritiek => _all.where((k) => (k['kennisgewing_tipes']?['kennis_tipe_naam'] ?? 'info') == 'kritiek').length;

  Future<void> _verwyder(Map<String, dynamic> k) async {
    final bevestig = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bevestig Verwydering'),
        content: const Text('Is jy seker jy wil hierdie kennisgewing verwyder?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Kanselleer'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Verwyder'),
          ),
        ],
      ),
    );
    
    if (bevestig != true) return;

              try {
                final kennisgewingRepo = KennisgewingRepository(SupabaseDb(Supabase.instance.client));
      final soort = k['_kennisgewing_soort'];
                
                bool sukses = false;
      if (soort == 'globaal') {
        sukses = await kennisgewingRepo.verwyderGlobaleKennisgewing(k['glob_kennis_id']);
      } else {
        sukses = await kennisgewingRepo.verwyderKennisgewing(k['kennis_id']);
                }

                if (sukses) {
                  await _laaiKennisgewings();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kennisgewing suksesvol verwyder!')),
                    );
                  }
                }
              } catch (e) {
      print('Fout met verwyder: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fout: $e')),
                  );
                }
              }
  }

  Future<void> _openSkepDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _SkepRedigeerDialog(),
    );
    
    if (result == true) {
      await _laaiKennisgewings();
    }
  }

  Future<void> _openRedigeerDialog(Map<String, dynamic> k) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _SkepRedigeerDialog(kennisgewing: k),
    );
    
    if (result == true) {
      await _laaiKennisgewings();
    }
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
                    'Gebruiker',
                    '$_gebruikerKennisgewings',
                    Icons.person_outline,
                    Colors.blue,
                  ),
                  _stat(
                    'Globaal',
                    '$_globaleKennisgewings',
                    Icons.public,
                    Colors.green,
                  ),
                  _stat(
                    'Waarskuwings',
                    '$_waarskuwings',
                    Icons.warning_amber_rounded,
                    Colors.orange,
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
                        value: _soortFilter,
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem(
                            value: 'alles',
                            child: Text('Alle Kennisgewings'),
                          ),
                          DropdownMenuItem(
                            value: 'gebruiker',
                            child: Text('Slegs Gebruiker'),
                          ),
                          DropdownMenuItem(
                            value: 'globaal',
                            child: Text('Slegs Globaal'),
                          ),
                        ],
                        onChanged: (String? v) =>
                            setState(() => _soortFilter = v ?? 'alles'),
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
                        final soort = k['_kennisgewing_soort'] ?? 'globaal';
                        final tipe = k['kennisgewing_tipes']?['kennis_tipe_naam'] ?? 'info';
                        final datum = DateTime.parse(
                          k['kennis_geskep_datum'] ?? k['glob_kennis_geskep_datum']
                        );
                        final beskrywing = k['kennis_beskrywing'] ?? k['glob_kennis_beskrywing'] ?? 'Kennisgewing';
                        
                        // Kry ontvanger inligting
                        String ontvanger = 'Alle gebruikers';
                        if (soort == 'gebruiker') {
                          final gebruiker = k['gebruikers'];
                          if (gebruiker != null) {
                            ontvanger = '${gebruiker['gebr_naam']} ${gebruiker['gebr_van']} (${gebruiker['gebr_epos']})';
                          }
                        }
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: _typeColor(tipe).withOpacity(0.05),
                            border: Border.all(
                              color: _typeColor(tipe).withOpacity(0.3),
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: _typeColor(tipe).withOpacity(0.1),
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
                                                    beskrywing,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                  Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                    color: soort == 'globaal' 
                                                      ? Colors.green.withOpacity(0.1)
                                                      : Colors.blue.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(12),
                                                    border: Border.all(
                                                      color: soort == 'globaal'
                                                        ? Colors.green
                                                        : Colors.blue,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    soort == 'globaal' ? 'GLOBAAL' : 'GEBRUIKER',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: soort == 'globaal'
                                                        ? Colors.green
                                                        : Colors.blue,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.person_outline,
                                                  size: 14,
                                                  color: Colors.grey[600],
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    ontvanger,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.grey[600],
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
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
                                                const SizedBox(width: 12),
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
                                        OutlinedButton.icon(
                                        onPressed: () => _openRedigeerDialog(k),
                                        icon: const Icon(Icons.edit_outlined, size: 16),
                                        label: const Text('Redigeer'),
                                          style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.blue,
                                          side: const BorderSide(color: Colors.blue),
                                          ),
                                        ),
                                      const SizedBox(width: 8),
                                      OutlinedButton.icon(
                                        onPressed: () => _verwyder(k),
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
    final soort = k['_kennisgewing_soort'] ?? 'globaal';
    final tipe = k['kennisgewing_tipes']?['kennis_tipe_naam'] ?? 'info';
    final datum = DateTime.parse(
      k['kennis_geskep_datum'] ?? k['glob_kennis_geskep_datum']
    );
    final beskrywing = k['kennis_beskrywing'] ?? k['glob_kennis_beskrywing'] ?? 'Kennisgewing';
    
    String ontvanger = 'Alle gebruikers';
    if (soort == 'gebruiker') {
      final gebruiker = k['gebruikers'];
      if (gebruiker != null) {
        ontvanger = '${gebruiker['gebr_naam']} ${gebruiker['gebr_van']} (${gebruiker['gebr_epos']})';
      }
    }
    
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
                          Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                            decoration: BoxDecoration(
                            color: soort == 'globaal' 
                              ? Colors.green.withOpacity(0.1)
                              : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: soort == 'globaal'
                                ? Colors.green
                                : Colors.blue,
                            ),
                          ),
                          child: Text(
                            soort == 'globaal' ? 'GLOBAAL' : 'GEBRUIKER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: soort == 'globaal'
                                ? Colors.green
                                : Colors.blue,
                            ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      beskrywing,
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
                    Icons.person_outline,
                    size: 20,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Ontvanger: $ontvanger',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
            ],
          ),
        ),
        actions: [
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              _openRedigeerDialog(k);
              },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Redigeer'),
              style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue,
              side: const BorderSide(color: Colors.blue),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              _verwyder(k);
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

class _SkepRedigeerDialog extends StatefulWidget {
  final Map<String, dynamic>? kennisgewing;
  
  const _SkepRedigeerDialog({this.kennisgewing});

  @override
  State<_SkepRedigeerDialog> createState() => _SkepRedigeerDialogState();
}

class _SkepRedigeerDialogState extends State<_SkepRedigeerDialog> {
  final TextEditingController _titelCtrl = TextEditingController();
  final TextEditingController _kortCtrl = TextEditingController();
  String _nuweTipe = 'info';
  String _nuweDoelgroep = 'alle';
  bool _isRedigeer = false;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.kennisgewing != null) {
      _isRedigeer = true;
      final k = widget.kennisgewing!;
      _kortCtrl.text = k['kennis_beskrywing'] ?? k['glob_kennis_beskrywing'] ?? '';
      _nuweTipe = k['kennisgewing_tipes']?['kennis_tipe_naam'] ?? 'info';
      _nuweDoelgroep = k['_kennisgewing_soort'] == 'globaal' ? 'alle' : 'spesifiek';
    }
  }
  
  @override
  void dispose() {
    _titelCtrl.dispose();
    _kortCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isRedigeer ? 'Redigeer Kennisgewing' : 'Skep Nuwe Kennisgewing'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: _kortCtrl,
                decoration: const InputDecoration(
                  labelText: 'Boodskap *',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _nuweTipe,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tipe',
                  border: OutlineInputBorder(),
                ),
                items: const <DropdownMenuItem<String>>[
                  DropdownMenuItem(value: 'info', child: Text('Inligting')),
                  DropdownMenuItem(value: 'waarskuwing', child: Text('Waarskuwing')),
                  DropdownMenuItem(value: 'sukses', child: Text('Sukses')),
                  DropdownMenuItem(value: 'fout', child: Text('Fout')),
                ],
                onChanged: (v) => setState(() => _nuweTipe = v ?? 'info'),
              ),
              if (!_isRedigeer) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _nuweDoelgroep,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Stuur Aan *',
                    border: OutlineInputBorder(),
                  ),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem(value: 'alle', child: Text('Alle Gebruikers')),
                    DropdownMenuItem(value: 'admins', child: Text('Slegs Admins')),
                    DropdownMenuItem(value: 'studente', child: Text('Slegs Studente')),
                    DropdownMenuItem(value: 'personeel', child: Text('Slegs Personeel')),
                  ],
                  onChanged: (v) => setState(() => _nuweDoelgroep = v ?? 'alle'),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Kanselleer'),
        ),
        FilledButton(
          onPressed: () async {
            if (_kortCtrl.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vul asseblief die boodskap in')),
              );
              return;
            }

            try {
              final kennisgewingRepo = KennisgewingRepository(
                SupabaseDb(Supabase.instance.client)
              );
              
              bool sukses = false;
              
              if (_isRedigeer) {
                // Redigeer bestaande kennisgewing
                final k = widget.kennisgewing!;
                final soort = k['_kennisgewing_soort'];
                
                if (soort == 'globaal') {
                  sukses = await kennisgewingRepo.opdateerGlobaleKennisgewing(
                    globKennisId: k['glob_kennis_id'],
                    beskrywing: _kortCtrl.text.trim(),
                    tipeNaam: _nuweTipe,
                  );
                } else {
                  sukses = await kennisgewingRepo.opdateerKennisgewing(
                    kennisId: k['kennis_id'],
                    beskrywing: _kortCtrl.text.trim(),
                    tipeNaam: _nuweTipe,
                  );
                }
              } else {
                // Skep nuwe kennisgewing
                switch (_nuweDoelgroep) {
                  case 'alle':
                    sukses = await kennisgewingRepo.stuurAanAlleGebruikers(
                      beskrywing: _kortCtrl.text.trim(),
                      tipeNaam: _nuweTipe,
                    );
                    break;
                  case 'admins':
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
                    final studente = await Supabase.instance.client
                        .from('gebruikers')
                        .select('gebr_id')
                        .eq('gebr_tipe_id', 'student');
                    final studentIds = studente.map((s) => s['gebr_id'].toString()).toList();
                    
                    sukses = await kennisgewingRepo.stuurAanSpesifiekeGebruikers(
                      gebrIds: studentIds,
                      beskrywing: _kortCtrl.text.trim(),
                      tipeNaam: _nuweTipe,
                    );
                    break;
                  case 'personeel':
                    final personeel = await Supabase.instance.client
                        .from('gebruikers')
                        .select('gebr_id')
                        .eq('gebr_tipe_id', 'personeel');
                    final personeelIds = personeel.map((p) => p['gebr_id'].toString()).toList();
                    
                    sukses = await kennisgewingRepo.stuurAanSpesifiekeGebruikers(
                      gebrIds: personeelIds,
                      beskrywing: _kortCtrl.text.trim(),
                      tipeNaam: _nuweTipe,
                    );
                    break;
                }
              }

              if (sukses && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isRedigeer 
                      ? 'Kennisgewing suksesvol opgedateer!' 
                      : 'Kennisgewing suksesvol gestuur!'
                    )
                  ),
                );
                Navigator.pop(context, true);
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_isRedigeer 
                      ? 'Fout met opdateer kennisgewing!' 
                      : 'Fout met stuur kennisgewing!'
                    )
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Fout: $e')),
                );
              }
            }
          },
          child: Text(_isRedigeer ? 'Opdateer' : 'Stuur Kennisgewing'),
        ),
      ],
    );
  }
}
