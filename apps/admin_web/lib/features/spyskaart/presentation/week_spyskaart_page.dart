// week_spyskaart_page.dart
import 'package:flutter/material.dart';
import '../widgets/models.dart';
import '../widgets/header.dart';
import '../widgets/status_banners.dart';
import '../widgets/week_switcher.dart';
import '../widgets/week_info_card.dart';
import '../widgets/day_section.dart';
import '../widgets/template_dialog.dart';
import '../widgets/item_detail_dialog.dart';
import '../widgets/approval_dialog.dart';

const daeVanWeek = [
  {'key': 'maandag', 'label': 'Maandag'},
  {'key': 'dinsdag', 'label': 'Dinsdag'},
  {'key': 'woensdag', 'label': 'Woensdag'},
  {'key': 'donderdag', 'label': 'Donderdag'},
  {'key': 'vrydag', 'label': 'Vrydag'},
  {'key': 'saterdag', 'label': 'Saterdag'},
  {'key': 'sondag', 'label': 'Sondag'},
];

class WeekSpyskaartPage extends StatefulWidget {
  final bool isDisabled;
  final VoidCallback? onBack;
  const WeekSpyskaartPage({super.key, this.isDisabled = false, this.onBack});

  @override
  State<WeekSpyskaartPage> createState() => _WeekSpyskaartPageState();
}

class _WeekSpyskaartPageState extends State<WeekSpyskaartPage> {
  // UI flags
  bool toonTemplaatModal = false;
  bool toonStuurModal = false;
  bool toonDetailModal = false;
  Kositem? gekieseItem;
  String suksesBoodskap = '';
  String foutBoodskap = '';
  bool isLoading = false;

  String aktieweWeek = 'huidige';
  String aktieweDag = 'maandag';
  String soekTerm = '';
  bool toonSoeker = false;

  late AppState appState;

  @override
  void initState() {
    super.initState();
    _seedMock();
  }

  void _seedMock() {
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
    DateTime monday(DateTime d) => d.subtract(Duration(days: d.weekday - 1));
    final beginHuidig = monday(now);
    final beginVolgende = beginHuidig.add(const Duration(days: 7));

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
      weekEinde: beginHuidig.add(const Duration(days: 6)),
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
      weekEinde: beginVolgende.add(const Duration(days: 6)),
      sperdatum: beginVolgende.add(const Duration(days: 2)),
    );

    final templates = [
      WeekTemplate(
        id: 'tpl1',
        naam: 'Basiese Week Templaat',
        beskrywing: 'Hoofgereg Ma–Vr, nagereg Vrydag',
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
      kositemTemplates: [],
      weekTemplates: templates,
      ingetekenGebruiker: AppUser(id: 'user_1', naam: 'Admin'),
    );
  }

  // helpers to find things
  WeekSpyskaart? get huidigeWeek => appState.weekSpyskaarte.firstWhere(
    (w) => w.status == 'aktief',
    orElse: () => appState.weekSpyskaarte.first,
  );
  WeekSpyskaart? get volgendeWeek => appState.weekSpyskaarte.firstWhere(
    (w) => w.status == 'konsep' || w.status == 'goedgekeur',
    orElse: () => appState.weekSpyskaarte.last,
  );

  List<Kositem> get alleBeskikbareItems => [
    ...appState.kositems,
    ...appState.kositemTemplates,
  ];

  Kositem? kryItem(String id) {
    try {
      return alleBeskikbareItems.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  bool isNaSperdatum(WeekSpyskaart s) => DateTime.now().isAfter(s.sperdatum);

  bool kanWysig(WeekSpyskaart? s) {
    if (s == null) return false;
    if (aktieweWeek == 'huidige') return true;
    return s.status == 'konsep' && !isNaSperdatum(s);
  }

  void updateState(AppState s) => setState(() => appState = s);

  void voegItemBy(WeekSpyskaart sp, String dag, String itemId) {
    final newDae = Map<String, List<String>>.from(sp.dae);
    newDae[dag] = [...(newDae[dag] ?? []), itemId];
    final updated = appState.weekSpyskaarte
        .map((w) => w.id == sp.id ? w.copyWith(dae: newDae) : w)
        .toList();
    updateState(appState.copyWith(weekSpyskaarte: updated));
    setState(() {
      soekTerm = '';
      toonSoeker = false;
      suksesBoodskap = 'Item bygevoeg by ${_label(dag)}';
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => suksesBoodskap = '');
    });
  }

  void verwyderItem(WeekSpyskaart sp, String dag, String itemId) {
    final newDae = Map<String, List<String>>.from(sp.dae);
    newDae[dag] = (newDae[dag] ?? []).where((id) => id != itemId).toList();
    final updated = appState.weekSpyskaarte
        .map((w) => w.id == sp.id ? w.copyWith(dae: newDae) : w)
        .toList();
    updateState(appState.copyWith(weekSpyskaarte: updated));
    setState(() => suksesBoodskap = 'Item verwyder van ${_label(dag)}');
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => suksesBoodskap = '');
    });
  }

  void laaiTemplaat(String tplId) {
    final tpl = appState.weekTemplates.firstWhere(
      (t) => t.id == tplId,
      orElse: () => appState.weekTemplates.first,
    );
    final vol = volgendeWeek;
    if (vol == null) return;
    final updated = appState.weekSpyskaarte.map((w) {
      if (w.id == vol.id) {
        return w.copyWith(
          dae: {
            for (final e in tpl.dae.entries) e.key: List<String>.from(e.value),
          },
        );
      }
      return w;
    }).toList();

    updateState(appState.copyWith(weekSpyskaarte: updated));
    setState(() {
      suksesBoodskap = 'Templaat "${tpl.naam}" suksesvol gelaai';
      toonTemplaatModal = false;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => suksesBoodskap = '');
    });
  }

  void stoorAsTemplaat() {
    final sp = aktieweWeek == 'huidige' ? huidigeWeek : volgendeWeek;
    if (sp == null) return;
    final tpl = WeekTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      naam:
          'Week Templaat ${DateTime.now().toLocal().toString().split(' ').first}',
      beskrywing: 'Outomaties geskep van $aktieweWeek week spyskaart',
      dae: {for (final e in sp.dae.entries) e.key: List<String>.from(e.value)},
    );
    updateState(
      appState.copyWith(weekTemplates: [...appState.weekTemplates, tpl]),
    );
    setState(() => suksesBoodskap = 'Week spyskaart gestoor as templaat');
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => suksesBoodskap = '');
    });
  }

  Future<void> stuurVirGoedkeuring() async {
    final vol = volgendeWeek;
    if (vol == null) return;
    setState(() => isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    final updated = appState.weekSpyskaarte.map((w) {
      if (w.id == vol.id) {
        return w.copyWith(
          status: 'goedgekeur',
          goedgekeurDeur: appState.ingetekenGebruiker?.id,
          goedgekeurDatum: DateTime.now(),
        );
      }
      return w;
    }).toList();
    updateState(appState.copyWith(weekSpyskaarte: updated));
    setState(() {
      isLoading = false;
      suksesBoodskap = 'Volgende week se spyskaart suksesvol goedgekeur';
      toonStuurModal = false;
    });
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => suksesBoodskap = '');
    });
  }

  String _label(String key) =>
      daeVanWeek.firstWhere((d) => d['key'] == key)['label']!;

  @override
  Widget build(BuildContext context) {
    if (widget.isDisabled) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Text(
              'Funksie nie beskikbaar - wag vir goedkeuring',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
      );
    }

    final spyskaart = aktieweWeek == 'huidige' ? huidigeWeek : volgendeWeek;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            HeaderWidget(
              aktieweWeek: aktieweWeek,
              volgendeWeek: volgendeWeek,
              onOpenTemplate: () => setState(() => toonTemplaatModal = true),
              onSaveTemplate: stoorAsTemplaat,
              onOpenSend: () => setState(() => toonStuurModal = true),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusBanners(sukses: suksesBoodskap, fout: foutBoodskap),
                    const SizedBox(height: 12),
                    WeekSwitcher(
                      huidigeWeek: huidigeWeek,
                      volgendeWeek: volgendeWeek,
                      aktieweWeek: aktieweWeek,
                      onChange: (w) => setState(() {
                        aktieweWeek = w;
                        aktieweDag = 'maandag';
                      }),
                    ),
                    const SizedBox(height: 12),
                    WeekInfoCard(
                      aktieweWeek: aktieweWeek,
                      huidige: huidigeWeek,
                      volgende: volgendeWeek,
                    ),
                    const SizedBox(height: 12),
                    if (aktieweWeek == 'volgende' &&
                        volgendeWeek != null &&
                        isNaSperdatum(volgendeWeek!))
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.lock),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Sperdatum verby - geen wysigings toegelaat',
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    DaySection(
                      spyskaart: spyskaart,
                      aktieweDag: aktieweDag,
                      aktieweweek: aktieweWeek,
                      onChangeDag: (d) => setState(() => aktieweDag = d),
                      daeVanWeek: daeVanWeek,
                      kryItem: kryItem,
                      kanWysig: (s) => kanWysig(s),
                      voegItem: voegItemBy,
                      verwyderItem: verwyderItem,
                      openDetail: (i) => setState(() {
                        gekieseItem = i;
                        toonDetailModal = true;
                      }),
                      searchItems: appState.kositems,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    // open dialogs after setState so we avoid build-time dialog calls
    if (toonTemplaatModal) {
      toonTemplaatModal = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => TemplateDialog(
            templates: appState.weekTemplates,
            onSelect: (id) => laaiTemplaat(id),
          ),
        );
      });
    }
    if (toonStuurModal) {
      toonStuurModal = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => ApprovalDialog(
            onConfirm: () => stuurVirGoedkeuring(),
            isLoading: isLoading,
          ),
        );
      });
    }
    if (toonDetailModal && gekieseItem != null) {
      toonDetailModal = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => ItemDetailDialog(item: gekieseItem!),
        );
      });
    }
  }
}
