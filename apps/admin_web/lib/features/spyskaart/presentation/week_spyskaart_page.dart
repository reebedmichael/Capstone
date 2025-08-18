// week_spyskaart_page.dart
// Full feature parity with the provided React screen (UI + front-end logic only)
// No backend calls. Purely local state and mock data. Overflow-safe.

import 'dart:typed_data';
import 'package:flutter/material.dart';

/// ---------- Models (mirror React types) ----------

class AppUser {
  final String id;
  final String naam;
  AppUser({required this.id, required this.naam});
}

class Kositem {
  final String id;
  final String naam;
  final List<String> bestanddele;
  final List<String> allergene;
  final double prys;
  final String kategorie;
  final Uint8List? prent; // If you have bytes
  // final String? prentUrl; // Or a URL
  final bool beskikbaar;
  final DateTime geskep;

  Kositem({
    required this.id,
    required this.naam,
    required this.bestanddele,
    required this.allergene,
    required this.prys,
    required this.kategorie,
    this.prent,
    // this.prentUrl,
    this.beskikbaar = true,
    DateTime? geskep,
  }) : geskep = geskep ?? DateTime.now();
}

class WeekTemplate {
  final String id;
  final String naam;
  final String? beskrywing;
  final Map<String, List<String>> dae;
  final DateTime geskep;

  WeekTemplate({
    required this.id,
    required this.naam,
    required this.dae,
    this.beskrywing,
    DateTime? geskep,
  }) : geskep = geskep ?? DateTime.now();
}

class WeekSpyskaart {
  final String id;
  final String status; // 'aktief' | 'konsep' | 'goedgekeur'
  final Map<String, List<String>> dae;
  final DateTime weekBegin;
  final DateTime weekEinde;
  final DateTime sperdatum;
  final String? goedgekeurDeur;
  final DateTime? goedgekeurDatum;

  WeekSpyskaart({
    required this.id,
    required this.status,
    required this.dae,
    required this.weekBegin,
    required this.weekEinde,
    required this.sperdatum,
    this.goedgekeurDeur,
    this.goedgekeurDatum,
  });

  WeekSpyskaart copyWith({
    String? status,
    Map<String, List<String>>? dae,
    String? goedgekeurDeur,
    DateTime? goedgekeurDatum,
  }) {
    return WeekSpyskaart(
      id: id,
      status: status ?? this.status,
      dae: dae ?? this.dae,
      weekBegin: weekBegin,
      weekEinde: weekEinde,
      sperdatum: sperdatum,
      goedgekeurDeur: goedgekeurDeur ?? this.goedgekeurDeur,
      goedgekeurDatum: goedgekeurDatum ?? this.goedgekeurDatum,
    );
  }
}

class AppState {
  final List<WeekSpyskaart> weekSpyskaarte;
  final List<Kositem> kositems;
  final List<Kositem> kositemTemplates;
  final List<WeekTemplate> weekTemplates;
  final AppUser? ingetekenGebruiker;

  AppState({
    required this.weekSpyskaarte,
    required this.kositems,
    required this.kositemTemplates,
    required this.weekTemplates,
    required this.ingetekenGebruiker,
  });

  AppState copyWith({
    List<WeekSpyskaart>? weekSpyskaarte,
    List<Kositem>? kositems,
    List<Kositem>? kositemTemplates,
    List<WeekTemplate>? weekTemplates,
    AppUser? ingetekenGebruiker,
  }) {
    return AppState(
      weekSpyskaarte: weekSpyskaarte ?? this.weekSpyskaarte,
      kositems: kositems ?? this.kositems,
      kositemTemplates: kositemTemplates ?? this.kositemTemplates,
      weekTemplates: weekTemplates ?? this.weekTemplates,
      ingetekenGebruiker: ingetekenGebruiker ?? this.ingetekenGebruiker,
    );
  }
}

/// ---------- Screen ----------

class WeekSpyskaartPage extends StatefulWidget {
  final bool isDisabled;
  final void Function()? onBack; // optional navigation callback

  const WeekSpyskaartPage({super.key, this.isDisabled = false, this.onBack});

  @override
  State<WeekSpyskaartPage> createState() => _WeekSpyskaartPageState();
}

class _WeekSpyskaartPageState extends State<WeekSpyskaartPage> {
  // UI State
  bool toonTemplaatModal = false;
  bool toonStuurModal = false;
  bool toonDetailModal = false;
  Kositem? gekieseItem;
  String suksesBoodskap = '';
  String foutBoodskap = '';
  bool isLoading = false;

  String aktieweWeek = 'huidige'; // 'huidige' | 'volgende'
  String aktieweDag = 'maandag';
  String soekTerm = '';
  bool toonSoeker = false;

  // Data state (mocked / local)
  late AppState appState;

  static const List<Map<String, String>> daeVanWeek = [
    {'key': 'maandag', 'label': 'Maandag'},
    {'key': 'dinsdag', 'label': 'Dinsdag'},
    {'key': 'woensdag', 'label': 'Woensdag'},
    {'key': 'donderdag', 'label': 'Donderdag'},
    {'key': 'vrydag', 'label': 'Vrydag'},
    {'key': 'saterdag', 'label': 'Saterdag'},
    {'key': 'sondag', 'label': 'Sondag'},
  ];

  @override
  void initState() {
    super.initState();

    // Mock items
    final items = <Kositem>[
      Kositem(
        id: "1",
        naam: "Beesburger",
        bestanddele: ["Beesvleis", "Broodjie", "Kaas", "Tamatie", "Slaai"],
        allergene: ["Gluten", "Melk"],
        prys: 85.00,
        kategorie: "Hoofgereg",
      ),
      Kositem(
        id: "2",
        naam: "Ontbyt Omelet",
        bestanddele: ["Eiers", "Kaas", "Uie", "Spinasie"],
        allergene: ["Eiers", "Melk"],
        prys: 55.00,
        kategorie: "Ontbyt",
      ),
      Kositem(
        id: "3",
        naam: "Vrugteslaai",
        bestanddele: ["Appel", "Bessie", "Druiwe", "Piesang"],
        allergene: [],
        prys: 45.00,
        kategorie: "Ligte ete",
        beskikbaar: true,
      ),
      Kositem(
        id: "4",
        naam: "Koffie Latte",
        bestanddele: ["Koffie", "Melk", "Suiker"],
        allergene: ["Melk"],
        prys: 30.00,
        kategorie: "Drankie",
      ),
    ];

    final now = DateTime.now();
    final beginHuidig = _mondayOfWeek(now);
    final eindeHuidig = beginHuidig.add(const Duration(days: 6));
    final beginVolgende = beginHuidig.add(const Duration(days: 7));
    final eindeVolgende = beginVolgende.add(const Duration(days: 6));

    final huidige = WeekSpyskaart(
      id: 'ws1',
      status: 'aktief',
      dae: {
        'maandag': ['1', '2'],
        'dinsdag': ['3'],
        'woensdag': [],
        'donderdag': ['4'],
        'vrydag': ['3'],
        'saterdag': [],
        'sondag': [],
      },
      weekBegin: beginHuidig,
      weekEinde: eindeHuidig,
      sperdatum: beginVolgende.subtract(const Duration(days: 2)),
    );

    final volgende = WeekSpyskaart(
      id: 'ws2',
      status: 'konsep',
      dae: {
        'maandag': [],
        'dinsdag': [],
        'woensdag': [],
        'donderdag': [],
        'vrydag': [],
        'saterdag': [],
        'sondag': [],
      },
      weekBegin: beginVolgende,
      weekEinde: eindeVolgende,
      sperdatum: beginVolgende.add(const Duration(days: 2)),
    );

    final templates = <WeekTemplate>[
      WeekTemplate(
        id: 't1',
        naam: 'Week Spyskaart',
        beskrywing: 'Voorbeeld week spyskaart met geregte',
        dae: {
          'maandag': ['1'],
          'dinsdag': ['2'],
          'woensdag': ['3'],
          'donderdag': ['4'],
          'vrydag': [],
          'saterdag': [],
          'sondag': [],
        },
      ),
    ];

    appState = AppState(
      weekSpyskaarte: [huidige, volgende],
      kositems: items,
      kositemTemplates: [
        // treat as extra selectable items as per React combining arrays
      ],
      weekTemplates: templates,
      ingetekenGebruiker: AppUser(id: 'user_1', naam: 'Admin'),
    );
  }

  // ---------- Helpers ----------
  DateTime _mondayOfWeek(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final weekday = d.weekday; // 1=Mon ... 7=Sun
    return d.subtract(Duration(days: weekday - 1));
  }

  String _formateerDatum(DateTime d) {
    const dae = [
      'Maandag',
      'Dinsdag',
      'Woensdag',
      'Donderdag',
      'Vrydag',
      'Saterdag',
      'Sondag',
    ];
    const maande = [
      'Januarie',
      'Februarie',
      'Maart',
      'April',
      'Mei',
      'Junie',
      'Julie',
      'Augustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    final dagNaam = dae[d.weekday - 1];
    final maandNaam = maande[d.month - 1];
    return '$dagNaam, ${d.day} $maandNaam ${d.year}';
    // Mirrors af-ZA long style without adding intl dependency.
  }

  bool _isNaSperdatum(WeekSpyskaart spyskaart) =>
      DateTime.now().isAfter(spyskaart.sperdatum);

  bool _kanWysig(WeekSpyskaart? spyskaart) {
    if (spyskaart == null) return false;
    if (aktieweWeek == 'huidige') return true; // add allowed, remove not
    return spyskaart.status == 'konsep' && !_isNaSperdatum(spyskaart);
  }

  WeekSpyskaart? get _huidigeWeekSpyskaart =>
      appState.weekSpyskaarte.firstWhere(
        (ws) => ws.status == 'aktief',
        orElse: () => appState.weekSpyskaarte.first,
      );

  WeekSpyskaart? get _volgendeWeekSpyskaart =>
      appState.weekSpyskaarte.firstWhere(
        (ws) => ws.status == 'konsep' || ws.status == 'goedgekeur',
        orElse: () => appState.weekSpyskaarte.last,
      );

  List<Kositem> get _alleBeskikbareItems => [
    ...appState.kositems,
    ...appState.kositemTemplates,
  ];

  Kositem? _kryItemDetails(String itemId) {
    try {
      return _alleBeskikbareItems.firstWhere((i) => i.id == itemId);
    } catch (_) {
      return null;
    }
  }

  // ---------- State updaters (mirror React logic) ----------
  void _updateAppState(AppState newState) =>
      setState(() => appState = newState);

  void _voegItemByVirDag(WeekSpyskaart spyskaart, String dag, String itemId) {
    final opgedaterdeDae = Map<String, List<String>>.from(spyskaart.dae);
    opgedaterdeDae[dag] = [...(opgedaterdeDae[dag] ?? []), itemId];

    final opgedaterdeSpyskaarte = appState.weekSpyskaarte
        .map(
          (ws) => ws.id == spyskaart.id ? ws.copyWith(dae: opgedaterdeDae) : ws,
        )
        .toList();

    _updateAppState(appState.copyWith(weekSpyskaarte: opgedaterdeSpyskaarte));
    setState(() {
      soekTerm = '';
      toonSoeker = false;
      suksesBoodskap = 'Item bygevoeg by ${_dagLabel(dag)}';
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => suksesBoodskap = '');
    });
  }

  void _verwyderItemVanDag(WeekSpyskaart spyskaart, String dag, String itemId) {
    final opgedaterdeDae = Map<String, List<String>>.from(spyskaart.dae);
    opgedaterdeDae[dag] = (opgedaterdeDae[dag] ?? [])
        .where((id) => id != itemId)
        .toList();

    final opgedaterdeSpyskaarte = appState.weekSpyskaarte
        .map(
          (ws) => ws.id == spyskaart.id ? ws.copyWith(dae: opgedaterdeDae) : ws,
        )
        .toList();

    _updateAppState(appState.copyWith(weekSpyskaarte: opgedaterdeSpyskaarte));
    setState(() => suksesBoodskap = 'Item verwyder van ${_dagLabel(dag)}');
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => suksesBoodskap = '');
    });
  }

  void _laaiTemplaat(String templateId) {
    final volgende = _volgendeWeekSpyskaart;
    if (volgende == null) return;

    final template = appState.weekTemplates.firstWhere(
      (t) => t.id == templateId,
      orElse: () => appState.weekTemplates.first,
    );
    final opgedaterde = appState.weekSpyskaarte.map((ws) {
      if (ws.id == volgende.id) {
        return ws.copyWith(
          dae: {
            for (final e in template.dae.entries)
              e.key: List<String>.from(e.value),
          },
        );
      }
      return ws;
    }).toList();

    _updateAppState(appState.copyWith(weekSpyskaarte: opgedaterde));
    setState(() => toonTemplaatModal = false);
    setState(
      () => suksesBoodskap = 'Templaat "${template.naam}" suksesvol gelaai',
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => suksesBoodskap = '');
    });
  }

  void _stoorAsTemplaat() {
    final spyskaart = aktieweWeek == 'huidige'
        ? _huidigeWeekSpyskaart
        : _volgendeWeekSpyskaart;
    if (spyskaart == null) return;

    final nuweTemplaat = WeekTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      naam:
          'Week Templaat ${DateTime.now().toLocal().toString().split(" ").first}',
      beskrywing: 'Outomaties geskep van $aktieweWeek week spyskaart',
      dae: {
        for (final e in spyskaart.dae.entries)
          e.key: List<String>.from(e.value),
      },
    );

    _updateAppState(
      appState.copyWith(
        weekTemplates: [...appState.weekTemplates, nuweTemplaat],
      ),
    );
    setState(() => suksesBoodskap = 'Week spyskaart gestoor as templaat');
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => suksesBoodskap = '');
    });
  }

  void _stuurVirGoedkeuring() async {
    final volgende = _volgendeWeekSpyskaart;
    if (volgende == null) return;

    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    final opgedaterde = appState.weekSpyskaarte.map((ws) {
      if (ws.id == volgende.id) {
        return ws.copyWith(
          status: 'goedgekeur',
          goedgekeurDeur: appState.ingetekenGebruiker?.id,
          goedgekeurDatum: DateTime.now(),
        );
      }
      return ws;
    }).toList();

    _updateAppState(appState.copyWith(weekSpyskaarte: opgedaterde));
    setState(() {
      toonStuurModal = false;
      suksesBoodskap = 'Volgende week se spyskaart suksesvol goedgekeur';
      isLoading = false;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => suksesBoodskap = '');
    });
  }

  // ---------- UI bits ----------

  String _dagLabel(String key) =>
      daeVanWeek.firstWhere((d) => d['key'] == key)['label']!;

  Widget _badge(
    String text, {
    Color? bg,
    Color? fg,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    BorderSide? border,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg ?? Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(100),
        border: border != null ? Border.fromBorderSide(border) : null,
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: fg ?? Colors.black87),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final volgende = _volgendeWeekSpyskaart;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Week Spyskaart Bestuur',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bestuur huidige en volgende week se spyskaarte',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed:
                    (aktieweWeek == 'huidige' ||
                        volgende == null ||
                        _isNaSperdatum(volgende))
                    ? null
                    : () => setState(() => toonTemplaatModal = true),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Laai Templaat'),
              ),
              OutlinedButton.icon(
                onPressed: _stoorAsTemplaat,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Stoor as Templaat'),
              ),
              if (aktieweWeek == 'volgende' &&
                  volgende != null &&
                  volgende.status == 'konsep')
                FilledButton.icon(
                  onPressed: _isNaSperdatum(volgende)
                      ? null
                      : () => setState(() => toonStuurModal = true),
                  icon: const Icon(Icons.send),
                  label: const Text('Goedkeuring'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBanners() {
    return Column(
      children: [
        if (suksesBoodskap.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC8E6C9)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    suksesBoodskap,
                    style: const TextStyle(color: Colors.green, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        if (foutBoodskap.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFCDD2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    foutBoodskap,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _weekSwitcher() {
    final huidige = _huidigeWeekSpyskaart;
    final volgende = _volgendeWeekSpyskaart;

    Widget _weekBtn({
      required String keyVal,
      required String label,
      String? chip,
      bool active = false,
      VoidCallback? onTap,
    }) {
      final activeStyle = FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
      final outlineStyle = OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );

      final btnChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          if (chip != null) const SizedBox(width: 8),
          if (chip != null)
            _badge(chip, bg: Theme.of(context).colorScheme.secondaryContainer),
        ],
      );

      return active
          ? FilledButton(onPressed: onTap, style: activeStyle, child: btnChild)
          : OutlinedButton(
              onPressed: onTap,
              style: outlineStyle,
              child: btnChild,
            );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _weekBtn(
          keyVal: 'huidige',
          label: 'Huidige Week',
          chip: huidige != null ? 'Aktief' : null,
          active: aktieweWeek == 'huidige',
          onTap: () => setState(() {
            aktieweWeek = 'huidige';
            aktieweDag = 'maandag';
          }),
        ),
        _weekBtn(
          keyVal: 'volgende',
          label: 'Volgende Week',
          chip: (volgende != null)
              ? (volgende.status == 'konsep' ? 'Konsep' : 'Goedgekeur')
              : null,
          active: aktieweWeek == 'volgende',
          onTap: () => setState(() {
            aktieweWeek = 'volgende';
            aktieweDag = 'maandag';
          }),
        ),
      ],
    );
  }

  Widget _weekInfoCard() {
    final spyskaart = aktieweWeek == 'huidige'
        ? _huidigeWeekSpyskaart
        : _volgendeWeekSpyskaart;
    if (spyskaart == null) return const SizedBox();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, c) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DefaultTextStyle(
                  style: Theme.of(context).textTheme.bodyLarge!,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            aktieweWeek == 'huidige'
                                ? Icons.check_circle
                                : Icons.edit,
                            color: aktieweWeek == 'huidige'
                                ? Colors.green
                                : Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            aktieweWeek == 'huidige'
                                ? 'Huidige Week Spyskaart'
                                : 'Volgende Week Spyskaart',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Text(
                            '${_formateerDatum(spyskaart.weekBegin)} tot ${_formateerDatum(spyskaart.weekEinde)}',
                          ),
                          if (aktieweWeek == 'huidige')
                            Text(
                              '• Jy kan items byvoeg, maar nie verwyder nie',
                              style: const TextStyle(color: Colors.green),
                            ),
                          if (aktieweWeek == 'volgende')
                            Text(
                              _isNaSperdatum(spyskaart)
                                  ? '• Sperdatum verby - geen wysigings toegelaat'
                                  : '• Volledige bestuur toegelaat tot sperdatum',
                              style: TextStyle(
                                color: _isNaSperdatum(spyskaart)
                                    ? Colors.red
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (aktieweWeek == 'volgende')
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _badge(
                      spyskaart.status == 'konsep' ? 'Konsep' : 'Goedgekeur',
                      bg: spyskaart.status == 'konsep'
                          ? Theme.of(context).colorScheme.secondaryContainer
                          : Theme.of(context).colorScheme.primaryContainer,
                    ),
                    _badge(
                      'Sperdatum: ${_formateerDatum(spyskaart.sperdatum)}',
                      border: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sperdatumWarning() {
    final volgende = _volgendeWeekSpyskaart;
    if (aktieweWeek == 'volgende' &&
        volgende != null &&
        _isNaSperdatum(volgende)) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEBEE),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFCDD2)),
        ),
        child: Row(
          children: const [
            Icon(Icons.lock_outline, color: Colors.red),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Die sperdatum vir hierdie week se spyskaart het verby gegaan. Geen wysigings kan meer gemaak word nie.',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox();
  }

  Widget _dagTabs() {
    final spyskaart = aktieweWeek == 'huidige'
        ? _huidigeWeekSpyskaart
        : _volgendeWeekSpyskaart;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Dag Bestuur",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Kies 'n dag om items te bestuur",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            // Tabs list (overflow-safe)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: daeVanWeek.map((dag) {
                  final key = dag['key']!;
                  final label = dag['label']!;
                  final count = spyskaart?.dae[key]?.length ?? 0;
                  final active = aktieweDag == key;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      selected: active,
                      onSelected: (_) => setState(() => aktieweDag = key),
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              label,
                              overflow: TextOverflow.visible,
                              softWrap: false,
                            ),
                          ),

                          const SizedBox(height: 4),
                          _badge(
                            '$count',
                            bg: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                          ),
                        ],
                      ),
                      selectedColor: Theme.of(context).colorScheme.primary,
                      labelStyle: TextStyle(
                        color: active
                            ? Theme.of(context).colorScheme.onPrimary
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            _renderDagInhoud(spyskaart, aktieweDag),
          ],
        ),
      ),
    );
  }

  Widget _renderDagInhoud(WeekSpyskaart? spyskaart, String dagKey) {
    if (spyskaart == null) {
      return _leegSpyskaart();
    }

    final items = spyskaart.dae[dagKey] ?? [];
    final isReadOnly = aktieweWeek == 'huidige' ? false : !_kanWysig(spyskaart);
    final kanByvoeg = _kanWysig(spyskaart) || aktieweWeek == 'huidige';

    // Header
    final header = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _dagLabel(dagKey),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${items.length} items gekies',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
          if (kanByvoeg)
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  toonSoeker = true;
                  soekTerm = '';
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Voeg Item By'),
            ),
        ],
      ),
    );

    // Content
    Widget content;
    if (items.isNotEmpty) {
      content = LayoutBuilder(
        builder: (context, constraints) {
          // Responsive columns to avoid overflow
          int columns = 1;
          if (constraints.maxWidth >= 1200) {
            columns = 3;
          } else if (constraints.maxWidth >= 800) {
            columns = 2;
          }

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.05,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = _kryItemDetails(items[index]);
              if (item == null) return const SizedBox();
              return _itemCard(spyskaart, dagKey, item, isReadOnly);
            },
          );
        },
      );
    } else {
      content = Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            style: BorderStyle.solid,
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.calendar_today,
              size: 56,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Geen items vir ${_dagLabel(dagKey)} nog nie',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 14),
            if (kanByvoeg)
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    toonSoeker = true;
                    soekTerm = '';
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('Voeg Eerste Item By'),
              ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            header,
            const SizedBox(height: 16),
            content,
            const SizedBox(height: 8),
          ],
        ),
        if (toonSoeker && kanByvoeg) _itemSoekerOverlay(spyskaart, dagKey),
      ],
    );
  }

  Widget _leegSpyskaart() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.calendar_month,
            size: 80,
            color: Theme.of(context).hintColor,
          ),
          const SizedBox(height: 8),
          const Text('Geen Spyskaart'),
          const SizedBox(height: 4),
          Text(
            'Daar is geen spyskaart vir hierdie week nie.',
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(
    WeekSpyskaart spyskaart,
    String dagKey,
    Kositem item,
    bool isReadOnly,
  ) {
    return Card(
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.prent != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: item.prent != null
                      ? Image.memory(item.prent!, fit: BoxFit.cover)
                      : Image.network(
                          "https://www.svgrepo.com/show/508699/landscape-placeholder.svg",
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.naam,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'R${item.prys.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _badge(
                  item.kategorie,
                  border: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                const SizedBox(width: 8),
                if (!item.beskikbaar)
                  _badge('Nie Beskikbaar', bg: Colors.red, fg: Colors.white),
              ],
            ),
            if (item.allergene.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: item.allergene
                    .map(
                      (a) => _badge(
                        a,
                        bg: const Color(0xFFFFCDD2),
                        fg: Colors.red,
                      ),
                    )
                    .toList(),
              ),
            ],
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        gekieseItem = item;
                        toonDetailModal = true;
                      });
                      // _openItemDetailDialog();
                    },
                    icon: const Icon(Icons.remove_red_eye_outlined),
                    label: const Text('Beskou'),
                  ),
                ),
                const SizedBox(width: 8),
                if (aktieweWeek == 'volgende' && _kanWysig(spyskaart))
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.withOpacity(0.3)),
                    ),
                    onPressed: () =>
                        _verwyderItemVanDag(spyskaart, dagKey, item.id),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemSoekerOverlay(WeekSpyskaart spyskaart, String dagKey) {
    final gefilterdeItems = _alleBeskikbareItems.where((item) {
      final q = soekTerm.toLowerCase();
      return item.naam.toLowerCase().contains(q) ||
          item.kategorie.toLowerCase().contains(q) ||
          item.bestanddele.any((b) => b.toLowerCase().contains(q));
    }).toList();

    final already = spyskaart.dae[dagKey] ?? [];

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.5),
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 700),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.05),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.15),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Voeg Item by ${_dagLabel(dagKey)}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Soek en kies uit beskikbare kositems',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () {
                          setState(() {
                            toonSoeker = false;
                            soekTerm = '';
                          });
                        },
                        child: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                // Body
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(left: 14),
                              child: Icon(Icons.search),
                            ),
                            TextField(
                              autofocus: true,
                              onChanged: (v) => setState(() => soekTerm = v),
                              decoration: InputDecoration(
                                hintText:
                                    'Soek volgens naam, kategorie of bestanddele...',
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                  horizontal: 44,
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.2),
                                    width: 2,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              if (soekTerm.isEmpty) {
                                return _emptySearchHint();
                              }
                              if (gefilterdeItems.isEmpty) {
                                return _noSearchResults();
                              }
                              return LayoutBuilder(
                                builder: (context, c) {
                                  int cols = 1;
                                  if (c.maxWidth >= 1000) {
                                    cols = 2;
                                  }
                                  return GridView.builder(
                                    itemCount: gefilterdeItems.length,
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: cols,
                                          childAspectRatio: 3.4,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                        ),
                                    itemBuilder: (context, i) {
                                      final item = gefilterdeItems[i];
                                      final isAlreeds = already.contains(
                                        item.id,
                                      );

                                      return InkWell(
                                        onTap: () {
                                          if (!isAlreeds) {
                                            _voegItemByVirDag(
                                              spyskaart,
                                              dagKey,
                                              item.id,
                                            );
                                          }
                                        },
                                        child: Card(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            side: BorderSide(
                                              color: isAlreeds
                                                  ? Colors.green.shade300
                                                  : Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withOpacity(0.2),
                                              width: 2,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (item.prent != null)
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          10,
                                                        ),
                                                    child: SizedBox(
                                                      width: 72,
                                                      height: 72,
                                                      child: item.prent != null
                                                          ? Image.memory(
                                                              item.prent!,
                                                              fit: BoxFit.cover,
                                                            )
                                                          : Image.network(
                                                              "https://www.svgrepo.com/show/508699/landscape-placeholder.svg",
                                                              fit: BoxFit.cover,
                                                            ),
                                                    ),
                                                  ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child: Text(
                                                              item.naam,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: Theme.of(context)
                                                                  .textTheme
                                                                  .titleMedium
                                                                  ?.copyWith(
                                                                    color: Theme.of(
                                                                      context,
                                                                    ).colorScheme.primary,
                                                                  ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Text(
                                                            'R${item.prys.toStringAsFixed(2)}',
                                                            style: Theme.of(context)
                                                                .textTheme
                                                                .titleMedium
                                                                ?.copyWith(
                                                                  color: Theme.of(
                                                                    context,
                                                                  ).colorScheme.primary,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Wrap(
                                                        spacing: 6,
                                                        crossAxisAlignment:
                                                            WrapCrossAlignment
                                                                .center,
                                                        children: [
                                                          _badge(
                                                            item.kategorie,
                                                            border: BorderSide(
                                                              color:
                                                                  Theme.of(
                                                                        context,
                                                                      )
                                                                      .colorScheme
                                                                      .primary
                                                                      .withOpacity(
                                                                        0.3,
                                                                      ),
                                                            ),
                                                          ),
                                                          if (isAlreeds)
                                                            _badge(
                                                              'Bygevoeg',
                                                              bg: Colors.green,
                                                              fg: Colors.white,
                                                            ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 6),
                                                      Text(
                                                        item.bestanddele.join(
                                                          ', ',
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          color: Theme.of(
                                                            context,
                                                          ).hintColor,
                                                        ),
                                                      ),
                                                      if (item
                                                          .allergene
                                                          .isNotEmpty)
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets.only(
                                                                top: 6,
                                                              ),
                                                          child: Wrap(
                                                            spacing: 4,
                                                            runSpacing: 4,
                                                            children: item
                                                                .allergene
                                                                .map(
                                                                  (a) => _badge(
                                                                    a,
                                                                    bg: const Color(
                                                                      0xFFFFCDD2,
                                                                    ),
                                                                    fg: Colors
                                                                        .red,
                                                                    padding: const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          6,
                                                                      vertical:
                                                                          2,
                                                                    ),
                                                                  ),
                                                                )
                                                                .toList(),
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptySearchHint() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 56, color: Theme.of(context).hintColor),
          const SizedBox(height: 8),
          Text(
            'Begin tik om items te soek',
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }

  Widget _noSearchResults() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 56, color: Theme.of(context).hintColor),
          const SizedBox(height: 8),
          Text(
            'Geen items gevind nie',
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
          const SizedBox(height: 4),
          Text(
            "Probeer 'n ander soekterm",
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }

  Future<void> _openItemDetailDialog() async {
    if (gekieseItem == null) return;
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Item Besonderhede',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Volledige inligting oor die gekiese kositem',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  if (gekieseItem!.prent != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: gekieseItem!.prent != null
                            ? Image.memory(
                                gekieseItem!.prent!,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                "https://www.svgrepo.com/show/508699/landscape-placeholder.svg",
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          gekieseItem!.naam,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                      ),
                      Text(
                        'R${gekieseItem!.prys.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _badge(
                        gekieseItem!.kategorie,
                        border: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      _badge(
                        gekieseItem!.beskikbaar
                            ? 'Beskikbaar'
                            : 'Nie Beskikbaar',
                        bg: gekieseItem!.beskikbaar ? Colors.green : Colors.red,
                        fg: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bestanddele:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    gekieseItem!.bestanddele.join(', '),
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 16,
                    ),
                  ),
                  if (gekieseItem!.allergene.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Allergene:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: gekieseItem!.allergene
                          .map(
                            (a) => _badge(
                              a,
                              bg: const Color(0xFFFFCDD2),
                              fg: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Geskep op: ${_formateerDatum(gekieseItem!.geskep)}',
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Maak toe'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openTemplaatDialog() async {
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Laai Week Templaat',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Kies 'n bestaande templaat om in die volgende week se spyskaart te laai",
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                if (appState.weekTemplates.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          size: 64,
                          color: Theme.of(context).hintColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Geen templates beskikbaar nie',
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: appState.weekTemplates.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final t = appState.weekTemplates[i];
                        return InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            _laaiTemplaat(t.id);
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          t.naam,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                              ),
                                        ),
                                        if (t.beskrywing != null) ...[
                                          const SizedBox(height: 4),
                                          Text(
                                            t.beskrywing!,
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).hintColor,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        _badge(
                                          _formateerDatum(t.geskep),
                                          bg: Theme.of(
                                            context,
                                          ).colorScheme.secondaryContainer,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.description_outlined),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Kanselleer'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openStuurDialog() async {
    await showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Bevestig Goedkeuring',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Is jy seker jy wil hierdie spyskaart finaliseer en goedkeur?',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFC8E6C9)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Nadat die spyskaart goedgekeur is, kan dit nie meer gewysig word nie. Maak seker dat alle items korrek is voordat jy voortgaan.',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Kanselleer'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                Navigator.of(context).pop();
                                _stuurVirGoedkeuring();
                              },
                        child: Text(isLoading ? 'Stuur...' : 'Ja, Keur Goed'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    if (widget.isDisabled) {
      return _disabledView();
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _header(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _statusBanners(),
                        _weekSwitcher(),
                        const SizedBox(height: 16),
                        _weekInfoCard(),
                        const SizedBox(height: 16),
                        _sperdatumWarning(),
                        const SizedBox(height: 16),
                        _dagTabs(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Dialog triggers to mirror React toggles
            if (toonDetailModal)
              const SizedBox(), // placeholder (real dialog opens via showDialog)
            if (toonTemplaatModal) const SizedBox(),
            if (toonStuurModal) const SizedBox(),
          ],
        ),
      ),
      // Floating dialog openers that mirror React button effects
      // (We call showDialog() to avoid overflow)
      // These setters keep parity with the React 'open' booleans.
      // Note: The actual UI buttons live in header and elsewhere.
    );
  }

  // Intercept state booleans to open material dialogs (keeps parity with React's open flags)
  @override
  void didUpdateWidget(covariant WeekSpyskaartPage oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void setState(VoidCallback fn) {
    // call super then handle dialog openings after state change
    super.setState(fn);
    // Synchronize "open" booleans with real dialogs:
    if (toonDetailModal) {
      toonDetailModal = false;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openItemDetailDialog(),
      );
    }
    if (toonTemplaatModal) {
      toonTemplaatModal = false;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _openTemplaatDialog(),
      );
    }
    if (toonStuurModal) {
      toonStuurModal = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _openStuurDialog());
    }
  }

  Widget _disabledView() {
    return Scaffold(
      body: SafeArea(
        child: Opacity(
          opacity: 0.5,
          child: IgnorePointer(
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Week Spyskaart Bestuur',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Funksie nie beskikbaar - wag vir goedkeuring',
                            style: TextStyle(
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFCDD2)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.error_outline, color: Colors.red),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Week spyskaart bestuur sal beskikbaar wees nadat jou admin rekening goedgekeur is.',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
