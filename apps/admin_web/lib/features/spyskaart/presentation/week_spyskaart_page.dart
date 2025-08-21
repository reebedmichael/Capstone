// lib/pages/week_spyskaart_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart'; // exports db + repos

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

  late final AdminSpyskaartRepository weekRepo;
  late final KosTemplaatRepository kosRepo;
  late final SupabaseDb db;

  AppState appState = AppState(
    weekSpyskaarte: [],
    kositems: [],
    kositemTemplates: [],
    weekTemplates: [],
    ingetekenGebruiker: AppUser(id: 'user_1', naam: 'Admin'),
  );

  @override
  void initState() {
    super.initState();
    final client = Supabase.instance.client;
    db = SupabaseDb(client);
    weekRepo = AdminSpyskaartRepository(db);
    kosRepo = KosTemplaatRepository(db);

    _loadAll();
  }

  // ---------- helpers to compute week-start (Monday) ----------
  DateTime mondayOf(DateTime d) => d.subtract(Duration(days: d.weekday - 1));
  DateTime _weekStartFor(String which) {
    final now = DateTime.now();
    final thisMonday = mondayOf(now);
    if (which == 'huidige') return thisMonday;
    return thisMonday.add(const Duration(days: 7)); // volgende
  }

  // ---------- Load data ----------
  Future<void> _loadAll() async {
    setState(() => isLoading = true);
    try {
      await Future.wait([_loadKosItems(), _loadSpyskaarte(), _loadTemplates()]);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadKosItems() async {
    final rows = await kosRepo.getKosItems();
    final items = rows.map((r) => _mapKosRowToKositem(r)).toList();
    // for templates table fallback, fetch kos templates if you have a separate column - here we just use kositems
    setState(
      () => appState = appState.copyWith(
        kositems: items,
        kositemTemplates:
            [], // optionally fetch template items if tracked separately
      ),
    );
  }

  Kositem _mapKosRowToKositem(Map<String, dynamic> r) {
    // Map your DB row fields to Kositem model expected by widgets.
    return Kositem(
      id: r['kos_item_id'].toString(),
      naam: r['kos_item_naam'] ?? '',
      bestanddele: List<String>.from(r['kos_item_bestandele'] ?? []),
      beskrywing: r['kos_item_beskrywing'] ?? '',
      allergene: List<String>.from(r['kos_item_allergene'] ?? []),
      prys: (r['kos_item_koste'] ?? 0).toDouble(),
      kategorie: r['kategorie'] ?? '',
      beskikbaar: (r['is_aktief'] ?? true) as bool,
      prentUrl: r['kos_item_prentjie'] as String?,
      prentBytes: null,
      geskep: r['kos_item_geskep_datum'] != null
          ? DateTime.parse(r['kos_item_geskep_datum'])
          : DateTime.now(),
    );
  }

  Future<void> _loadSpyskaarte() async {
    // fetch or create the current and next spyskaart rows based on week start dates
    final huidigStart = _weekStartFor('huidige');
    final volgendeStart = _weekStartFor('volgende');

    final huidigRaw = await weekRepo.getOrCreateSpyskaartForDate(huidigStart);
    final volgendeRaw = await weekRepo.getOrCreateSpyskaartForDate(
      volgendeStart,
    );

    // map raw -> WeekSpyskaart used by your UI
    final huidige = _mapRawToWeekSpyskaart(
      huidigRaw,
      weekStart: huidigStart,
      status: 'aktief',
    );
    final volgende = _mapRawToWeekSpyskaart(
      volgendeRaw,
      weekStart: volgendeStart,
      status: 'konsep',
    );

    setState(() {
      // keep existing templates & users in appState
      appState = appState.copyWith(weekSpyskaarte: [huidige, volgende]);
    });
  }

  Future<void> _loadTemplates() async {
    final rawTemplates = await weekRepo.listWeekTemplatesRaw();
    final shaped = rawTemplates.map((row) {
      final kinders = List<Map<String, dynamic>>.from(
        (row['spyskaart_kos_item'] as List?) ?? [],
      );
      final dae = {
        'maandag': <String>[],
        'dinsdag': <String>[],
        'woensdag': <String>[],
        'donderdag': <String>[],
        'vrydag': <String>[],
        'saterdag': <String>[],
        'sondag': <String>[],
      };
      for (final child in kinders) {
        final kos = Map<String, dynamic>.from(child['kos_item'] ?? {});
        final dag = Map<String, dynamic>.from(child['week_dag'] ?? {});
        final dagNaam = (dag['week_dag_naam'] ?? '').toString().toLowerCase();
        if (!dae.containsKey(dagNaam)) continue;
        dae[dagNaam]!.add(kos['kos_item_id'].toString());
      }

      return WeekTemplate(
        id: row['spyskaart_id'].toString(),
        naam: row['spyskaart_naam'] ?? '',
        beskrywing: row['spyskaart_beskrywing'] ?? '',
        dae: dae,
      );
    }).toList();

    setState(() => appState = appState.copyWith(weekTemplates: shaped));
  }

  WeekSpyskaart _mapRawToWeekSpyskaart(
    Map<String, dynamic> raw, {
    required DateTime weekStart,
    required String status,
  }) {
    final kinders = List<Map<String, dynamic>>.from(
      (raw['spyskaart_kos_item'] as List?) ?? [],
    );
    final dae = {
      'maandag': <String>[],
      'dinsdag': <String>[],
      'woensdag': <String>[],
      'donderdag': <String>[],
      'vrydag': <String>[],
      'saterdag': <String>[],
      'sondag': <String>[],
    };

    for (final child in kinders) {
      final kos = Map<String, dynamic>.from(child['kos_item'] ?? {});
      final dag = Map<String, dynamic>.from(child['week_dag'] ?? {});
      final dagNaam = (dag['week_dag_naam'] ?? '').toString().toLowerCase();
      if (!dae.containsKey(dagNaam)) continue;
      dae[dagNaam]!.add(kos['kos_item_id'].toString());
    }

    final weekEnd = weekStart.add(const Duration(days: 6));
    final sperdatum = weekStart.add(
      const Duration(days: 5),
    ); // default sperdatum = weekStart+5 (customize as needed)

    return WeekSpyskaart(
      id: raw['spyskaart_id'].toString(),
      status: status,
      dae: dae,
      weekBegin: weekStart,
      weekEinde: weekEnd,
      sperdatum: sperdatum,
      goedgekeurDatum: raw['goedgekeur_datum'] != null
          ? DateTime.tryParse(raw['goedgekeur_datum'])
          : null,
      goedgekeurDeur: raw['goedgekeur_deur'] as String?,
    );
  }

  // ---------- helpers used by UI ----------
  WeekSpyskaart? get huidigeWeek =>
      appState.weekSpyskaarte.isNotEmpty ? appState.weekSpyskaarte.first : null;
  WeekSpyskaart? get volgendeWeek =>
      appState.weekSpyskaarte.length > 1 ? appState.weekSpyskaarte[1] : null;

  List<Kositem> get alleBeskikbareItems => appState.kositems;

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
    // volgende can be edited if not past sperdatum and status is 'konsep'
    return s.status == 'konsep' && !isNaSperdatum(s);
  }

  void updateState(AppState s) => setState(() => appState = s);

  // ---------- actions ----------

  Future<void> voegItemBy(WeekSpyskaart sp, String dag, String itemId) async {
    try {
      await weekRepo.addItemToSpyskaart(
        spyskaartId: sp.id,
        dagNaam: dag,
        kosItemId: itemId,
      );
      // refresh the spyskaart
      await _loadSpyskaarte();
      setState(() {
        suksesBoodskap = 'Item bygevoeg by ${_label(dag)}';
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => suksesBoodskap = '');
      });
    } catch (e) {
      setState(() => foutBoodskap = 'Kon nie item byvoeg nie: ${e.toString()}');
    }
  }

  Future<void> verwyderItem(WeekSpyskaart sp, String dag, String itemId) async {
    try {
      await weekRepo.removeItemFromSpyskaart(
        spyskaartId: sp.id,
        dagNaam: dag,
        kosItemId: itemId,
      );
      await _loadSpyskaarte();
      setState(() => suksesBoodskap = 'Item verwyder van ${_label(dag)}');
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => suksesBoodskap = '');
      });
    } catch (e) {
      setState(
        () => foutBoodskap = 'Kon nie item verwyder nie: ${e.toString()}',
      );
    }
  }

  void laaiTemplaat(String tplId) async {
    try {
      // Get template raw (contains kos items organized by week_dag)
      final tplRaw = await weekRepo.getTemplateRawById(tplId);
      if (tplRaw == null) return;
      // target = volgende week spyskaart (create if not exists)
      final volStart = _weekStartFor('volgende');
      final volRaw = await weekRepo.getOrCreateSpyskaartForDate(volStart);
      final volId = volRaw['spyskaart_id'] as String;

      // build dae mapping for update
      final kinders = List<Map<String, dynamic>>.from(
        (tplRaw['spyskaart_kos_item'] as List?) ?? [],
      );
      final daeMap = <String, List<Map<String, dynamic>>>{};
      for (final d in daeVanWeek) daeMap[d['key']!] = [];

      for (final child in kinders) {
        final kos = Map<String, dynamic>.from(child['kos_item'] ?? {});
        final dag = Map<String, dynamic>.from(child['week_dag'] ?? {});
        final dagNaam = (dag['week_dag_naam'] ?? '').toString().toLowerCase();
        if (!daeMap.containsKey(dagNaam)) continue;
        daeMap[dagNaam]!.add({'id': kos['kos_item_id']});
      }

      // Use updateWeekTemplate to replace children for the spyskaart (works for template and non-template rows)
      await weekRepo.updateWeekTemplate(
        spyskaartId: volId,
        naam: volRaw['spyskaart_naam'] ?? 'Volgende Week',
        beskrywing: null,
        dae: daeMap,
      );

      await _loadSpyskaarte();
      setState(() {
        suksesBoodskap = 'Templaat suksesvol gelaai';
        toonTemplaatModal = false;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() => suksesBoodskap = '');
      });
    } catch (e) {
      setState(
        () => foutBoodskap = 'Kon nie templaat laai nie: ${e.toString()}',
      );
    }
  }

  Future<void> stoorAsTemplaat() async {
    // store the active week (huidige/volgende) as a template
    final sp = aktieweWeek == 'huidige' ? huidigeWeek : volgendeWeek;
    if (sp == null) return;

    final daePayload = sp.dae.map(
      (k, v) => MapEntry(k, v.map((id) => {'id': id}).toList()),
    );

    try {
      await weekRepo.createWeekTemplate(
        naam:
            'Week Templaat ${DateTime.now().toLocal().toString().split(' ').first}',
        beskrywing: 'Gestoor vanaf UI',
        dae: daePayload,
      );
      await _loadTemplates();
      setState(() => suksesBoodskap = 'Week spyskaart gestoor as templaat');
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() => suksesBoodskap = '');
      });
    } catch (e) {
      setState(
        () => foutBoodskap = 'Kon nie stoor as templaat nie: ${e.toString()}',
      );
    }
  }

  Future<void> stuurVirGoedkeuring() async {
    final vol = volgendeWeek;
    if (vol == null) return;

    setState(() => isLoading = true);
    try {
      await weekRepo.approveSpyskaart(vol.id);
      // refresh
      await _loadSpyskaarte();
      setState(() {
        isLoading = false;
        suksesBoodskap = 'Volgende week se spyskaart suksesvol goedgekeur';
        toonStuurModal = false;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() => suksesBoodskap = '');
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        foutBoodskap = 'Kon nie goedkeur nie: ${e.toString()}';
      });
    }
  }

  String _label(String key) =>
      daeVanWeek.firstWhere((d) => d['key'] == key)['label']!;

  // ---------- UI ----------

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
          builder: (_) => ItemDetailDialog(item: gekieseItem!), //
        );
      });
    }
  }
}
