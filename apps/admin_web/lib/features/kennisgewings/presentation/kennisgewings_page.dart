import 'package:flutter/material.dart';

class KennisgewingsPage extends StatefulWidget {
  const KennisgewingsPage({super.key});
  @override
  State<KennisgewingsPage> createState() => _KennisgewingsPageState();
}

class _KennisgewingsPageState extends State<KennisgewingsPage> {
  final List<_Kennisgewing> _all = <_Kennisgewing>[
    _Kennisgewing(
      id: '1',
      titel: 'Nuwe bestelling wag vir afhaal',
      beskrywing: 'Bestelling #12345 is gereed vir afhaal by Spys Kiosk.',
      inhoud: 'Toon jou QR kode by die kiosk om te versamel.',
      tipe: 'info',
      prioriteit: 'medium',
      geleeS: false,
      datum: DateTime.now().subtract(const Duration(minutes: 30)),
      doelgroep: const <String>['alle'],
    ),
    _Kennisgewing(
      id: '2',
      titel: 'Lae voorraad: Hoenderburgers',
      beskrywing: 'Slegs 8 oor – oorweeg aanvulling.',
      inhoud: 'Outomatiese waarskuwing uit voorraadbestuur.',
      tipe: 'waarskuwing',
      prioriteit: 'hoog',
      geleeS: true,
      datum: DateTime.now().subtract(const Duration(hours: 2)),
      doelgroep: const <String>['primere_admin', 'sekondere_admin'],
    ),
    _Kennisgewing(
      id: '3',
      titel: 'Betaalpoort fout herstel',
      beskrywing: 'Kort onderbreking van 09:10–09:20 is opgelos.',
      inhoud: 'Geen aksie benodig nie. Moniteer vir verdere insidente.',
      tipe: 'sukses',
      prioriteit: 'laag',
      geleeS: true,
      datum: DateTime.now().subtract(const Duration(days: 1)),
      doelgroep: const <String>['alle'],
    ),
  ];

  String _geleesFilter = 'alles'; // alles | ongelees | gelees
  String _tipeFilter =
      'alle_tipes'; // alle_tipes | info | waarskuwing | fout | sukses

  // Skep modal state
  final TextEditingController _titelCtrl = TextEditingController();
  final TextEditingController _kortCtrl = TextEditingController();
  final TextEditingController _inhoudCtrl = TextEditingController();
  String _nuweTipe = 'info';
  String _nuwePrioriteit = 'medium';
  String _nuweDoelgroep = 'alle';

  @override
  void dispose() {
    _titelCtrl.dispose();
    _kortCtrl.dispose();
    _inhoudCtrl.dispose();
    super.dispose();
  }

  List<_Kennisgewing> get _gefilterde => _all.where((final _Kennisgewing k) {
    final bool matchLees =
        _geleesFilter == 'alles' ||
        (_geleesFilter == 'gelees' && k.geleeS) ||
        (_geleesFilter == 'ongelees' && !k.geleeS);
    final bool matchTipe = _tipeFilter == 'alle_tipes' || k.tipe == _tipeFilter;
    return matchLees && matchTipe;
  }).toList();

  int get _ongelees => _all.where((k) => !k.geleeS).length;
  int get _waarskuwings => _all.where((k) => k.tipe == 'waarskuwing').length;
  int get _kritiek => _all.where((k) => k.prioriteit == 'kritiek').length;

  void _markeerAsGelees(String id, bool gelees) {
    setState(() {
      final int i = _all.indexWhere((k) => k.id == id);
      if (i != -1) _all[i] = _all[i].copyWith(geleeS: gelees);
    });
  }

  void _verwyder(String id) =>
      setState(() => _all.removeWhere((k) => k.id == id));
  void _markeerAllesAsGelees() =>
      setState(() => _all.setAll(0, _all.map((k) => k.copyWith(geleeS: true))));
  void _verwyderAlleGelees() =>
      setState(() => _all.removeWhere((k) => k.geleeS));

  void _openSkepDialog() {
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
                Row(
                  children: <Widget>[
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _nuweTipe,
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _nuwePrioriteit,
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _nuweDoelgroep,
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
            onPressed: () {
              if (_titelCtrl.text.trim().isEmpty ||
                  _kortCtrl.text.trim().isEmpty)
                return;
              setState(() {
                _all.add(
                  _Kennisgewing(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    titel: _titelCtrl.text.trim(),
                    beskrywing: _kortCtrl.text.trim(),
                    inhoud: _inhoudCtrl.text.trim().isEmpty
                        ? null
                        : _inhoudCtrl.text.trim(),
                    tipe: _nuweTipe,
                    prioriteit: _nuwePrioriteit,
                    geleeS: false,
                    datum: DateTime.now(),
                    doelgroep: <String>[_nuweDoelgroep],
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Stuur Kennisgewing'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                        onPressed: _all.any((k) => k.geleeS)
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
                      children: _gefilterde.map((final _Kennisgewing k) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: k.geleeS
                                ? Theme.of(context).colorScheme.surface
                                : Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.05),
                            border: Border.all(
                              color: k.geleeS
                                  ? Theme.of(context).dividerColor
                                  : Theme.of(context).colorScheme.primary
                                        .withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Icon(
                                    _typeIcon(k.tipe),
                                    color: _typeColor(k.tipe),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Text(
                                              k.titel,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.copyWith(
                                                    fontWeight: k.geleeS
                                                        ? FontWeight.w500
                                                        : FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.black26,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                k.prioriteit,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.labelSmall,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          k.beskrywing,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: <Widget>[
                                            const Icon(
                                              Icons.access_time,
                                              size: 14,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _formatDate(k.datum),
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                            const SizedBox(width: 10),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: Colors.black26,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                _doelgroeplabel(k.doelgroep),
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.labelSmall,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: <Widget>[
                                  IconButton(
                                    onPressed: () => _showDetail(k),
                                    icon: const Icon(Icons.visibility_outlined),
                                  ),
                                  if (!k.geleeS)
                                    IconButton(
                                      onPressed: () =>
                                          _markeerAsGelees(k.id, true),
                                      icon: const Icon(
                                        Icons.mark_email_read_outlined,
                                        color: Colors.green,
                                      ),
                                    ),
                                  if (k.geleeS)
                                    IconButton(
                                      onPressed: () =>
                                          _markeerAsGelees(k.id, false),
                                      icon: const Icon(
                                        Icons.mark_email_unread_outlined,
                                      ),
                                    ),
                                  IconButton(
                                    onPressed: () => _verwyder(k.id),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

  void _showDetail(_Kennisgewing k) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kennisgewing Besonderhede'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(k.titel, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 6),
                Text(k.beskrywing),
                if (k.inhoud != null && k.inhoud!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    'Volledige Inhoud:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(k.inhoud!),
                ],
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(child: _kv('Gestuur op', _formatDate(k.datum))),
                    Expanded(child: _kv('Aan', _doelgroeplabel(k.doelgroep))),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maak toe'),
          ),
        ],
      ),
    );
  }

  Widget _kv(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(label, style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 4),
      Text(value, style: Theme.of(context).textTheme.bodyMedium),
    ],
  );

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
                color: color.withValues(alpha: 0.1),
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
                    style: Theme.of(
                      context,
                    ).textTheme.headlineSmall?.copyWith(color: color),
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
    return '${d.day.toString().padLeft(2, '0')} ${s[d.month - 1]} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _doelgroeplabel(List<String> d) {
    if (d.contains('alle')) return 'Almal';
    if (d.contains('primere_admin') || d.contains('sekondere_admin'))
      return 'Admins';
    if (d.contains('student')) return 'Studente';
    if (d.contains('personeel')) return 'Personeel';
    if (d.length == 1) return 'Spesifiek';
    return '${d.length} doelgroepe';
  }
}

class _Kennisgewing {
  final String id;
  final String titel;
  final String beskrywing;
  final String? inhoud;
  final String tipe; // info | waarskuwing | fout | sukses
  final String prioriteit; // laag | medium | hoog | kritiek
  final bool geleeS;
  final DateTime datum;
  final List<String> doelgroep;

  const _Kennisgewing({
    required this.id,
    required this.titel,
    required this.beskrywing,
    required this.inhoud,
    required this.tipe,
    required this.prioriteit,
    required this.geleeS,
    required this.datum,
    required this.doelgroep,
  });

  _Kennisgewing copyWith({
    String? id,
    String? titel,
    String? beskrywing,
    String? inhoud,
    String? tipe,
    String? prioriteit,
    bool? geleeS,
    DateTime? datum,
    List<String>? doelgroep,
  }) {
    return _Kennisgewing(
      id: id ?? this.id,
      titel: titel ?? this.titel,
      beskrywing: beskrywing ?? this.beskrywing,
      inhoud: inhoud ?? this.inhoud,
      tipe: tipe ?? this.tipe,
      prioriteit: prioriteit ?? this.prioriteit,
      geleeS: geleeS ?? this.geleeS,
      datum: datum ?? this.datum,
      doelgroep: doelgroep ?? this.doelgroep,
    );
  }
}
