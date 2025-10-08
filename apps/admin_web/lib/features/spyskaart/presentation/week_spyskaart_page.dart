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
import '../../templates/widgets/kos_item_detail.dart';
import '../widgets/approval_dialog.dart';
import '../widgets/quantity_dialog.dart';
import '../widgets/template_items_dialog.dart';
import '../../templates/widgets/kos_item_templaat.dart';

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
  bool toonQuantityModal = false;
  bool toonTemplateItemsModal = false;
  KositemTemplate? gekieseItem;
  KositemTemplate? itemVirQuantity;
  List<TemplateItem>? templateItemsVirDialog;
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
    final items = rows.map((r) => _mapKosRowToKositemTemplate(r)).toList();
    // for templates table fallback, fetch kos templates if you have a separate column - here we just use kositems
    setState(
      () => appState = appState.copyWith(
        kositems: items,
        kositemTemplates:
            [], // optionally fetch template items if tracked separately
      ),
    );
  }

  KositemTemplate _mapKosRowToKositemTemplate(Map<String, dynamic> r) {
    // Extract dieet categories from kos_item_dieet_vereistes
    final dieetVereistes = List<Map<String, dynamic>>.from(
      r['kos_item_dieet_vereistes'] ?? [],
    );
    final dieetKategorie = dieetVereistes
        .map((d) => d['dieet']?['dieet_naam'] as String?)
        .whereType<String>()
        .toList();

    // Map your DB row fields to KositemTemplate model expected by widgets.
    return KositemTemplate(
      id: r['kos_item_id'].toString(),
      naam: r['kos_item_naam'] ?? '',
      bestanddele: List<String>.from(r['kos_item_bestandele'] ?? []),
      beskrywing: r['kos_item_beskrywing'] ?? '',
      allergene: List<String>.from(r['kos_item_allergene'] ?? []),
      prys: (r['kos_item_koste'] ?? 0).toDouble(),
      dieetKategorie: dieetKategorie,
      prent: r['kos_item_prentjie'] as String?,
    );
  }

  Future<void> _loadSpyskaarte() async {
    final now = DateTime.now();

    // Determine if we should use next week as current week
    // This happens if:
    // 1. It's Saturday 17:00 or later, OR
    // 2. It's Sunday or later (past the weekend transition)
    final isSaturdayAfter17 = now.weekday == 6 && now.hour >= 17;
    final isPastWeekend = now.weekday == 7; // Sunday
    final shouldUseNextWeek = isSaturdayAfter17 || isPastWeekend;

    // Calculate the actual week starts
    final currentWeekStart = _weekStartFor('huidige');
    final nextWeekStart = _weekStartFor('volgende');

    // Determine which week to show as "current" and which as "next"
    final actualCurrentWeekStart = shouldUseNextWeek
        ? nextWeekStart
        : currentWeekStart;
    final actualNextWeekStart = shouldUseNextWeek
        ? nextWeekStart.add(const Duration(days: 7))
        : nextWeekStart;

    // Fetch or create the spyskaart data
    final currentRaw = await weekRepo.getOrCreateSpyskaartForDate(
      actualCurrentWeekStart,
    );
    final nextRaw = await weekRepo.getOrCreateSpyskaartForDate(
      actualNextWeekStart,
    );

    // Map to WeekSpyskaart objects
    final huidige = _mapRawToWeekSpyskaart(
      currentRaw,
      weekStart: actualCurrentWeekStart,
      status: 'aktief',
    );

    final volgende = _mapRawToWeekSpyskaart(
      nextRaw,
      weekStart: actualNextWeekStart,
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

    final itemDetails = <String, Map<String, SpyskaartItem>>{
      'maandag': <String, SpyskaartItem>{},
      'dinsdag': <String, SpyskaartItem>{},
      'woensdag': <String, SpyskaartItem>{},
      'donderdag': <String, SpyskaartItem>{},
      'vrydag': <String, SpyskaartItem>{},
      'saterdag': <String, SpyskaartItem>{},
      'sondag': <String, SpyskaartItem>{},
    };

    for (final child in kinders) {
      final kos = Map<String, dynamic>.from(child['kos_item'] ?? {});
      final dag = Map<String, dynamic>.from(child['week_dag'] ?? {});
      final dagNaam = (dag['week_dag_naam'] ?? '').toString().toLowerCase();
      if (!dae.containsKey(dagNaam)) continue;

      final itemId = kos['kos_item_id'].toString();
      dae[dagNaam]!.add(itemId);

      // Extract quantity and cutoff time
      final quantity = child['kos_item_hoeveelheid'] as int? ?? 1;
      final cutoffTimeStr = child['spyskaart_kos_afsny_datum'] as String?;
      final cutoffTime = cutoffTimeStr != null
          ? DateTime.tryParse(cutoffTimeStr)
          : null;

      itemDetails[dagNaam]![itemId] = SpyskaartItem(
        itemId: itemId,
        quantity: quantity,
        cutoffTime: cutoffTime,
      );
    }

    final weekEnd = weekStart.add(const Duration(days: 6));
    final sperdatum = weekStart.add(
      const Duration(days: -1),
    ); // default sperdatum = weekStart+5 (customize as needed)

    return WeekSpyskaart(
      id: raw['spyskaart_id'].toString(),
      status: status,
      dae: dae,
      itemDetails: itemDetails,
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

  List<KositemTemplate> get alleBeskikbareItems => appState.kositems;

  KositemTemplate? kryItem(String id) {
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

  void toonQuantityDialog(KositemTemplate item) {
    setState(() {
      itemVirQuantity = item;
      toonQuantityModal = true;
    });
  }

  Future<void> voegItemBy(
    WeekSpyskaart sp,
    String dag,
    String itemId, {
    int quantity = 1,
    DateTime? cutoffTime,
  }) async {
    try {
      await weekRepo.addItemToSpyskaart(
        spyskaartId: sp.id,
        dagNaam: dag,
        kosItemId: itemId,
        quantity: quantity,
        cutoffTime: cutoffTime,
      );
      // refresh the spyskaart
      await _loadSpyskaarte();
      setState(() {
        suksesBoodskap = 'Item bygevoeg by ${_label(dag)}';
      });
      Future.delayed(const Duration(seconds: 1), () {
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
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() => suksesBoodskap = '');
      });
    } catch (e) {
      setState(
        () => foutBoodskap = 'Kon nie item verwyder nie: ${e.toString()}',
      );
    }
  }

  Future<void> updateItemQuantity(
    WeekSpyskaart sp,
    String dag,
    String itemId,
    int quantity,
    DateTime cutoffTime,
  ) async {
    try {
      await weekRepo.updateItemQuantity(
        spyskaartId: sp.id,
        dagNaam: dag,
        kosItemId: itemId,
        quantity: quantity,
        cutoffTime: cutoffTime,
      );
      await _loadSpyskaarte();
      setState(
        () => suksesBoodskap = 'Item hoeveelheid opgedateer vir ${_label(dag)}',
      );
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        setState(() => suksesBoodskap = '');
      });
    } catch (e) {
      setState(
        () => foutBoodskap =
            'Kon nie item hoeveelheid opdateer nie: ${e.toString()}',
      );
    }
  }

  void laaiTemplaat(String tplId) async {
    try {
      // Get template raw (contains kos items organized by week_dag)
      final tplRaw = await weekRepo.getTemplateRawById(tplId);
      if (tplRaw == null) return;

      // Build template items list for the dialog
      final kinders = List<Map<String, dynamic>>.from(
        (tplRaw['spyskaart_kos_item'] as List?) ?? [],
      );

      final templateItems = <TemplateItem>[];

      for (final child in kinders) {
        final kos = Map<String, dynamic>.from(child['kos_item'] ?? {});
        final dag = Map<String, dynamic>.from(child['week_dag'] ?? {});
        final dagNaam = (dag['week_dag_naam'] ?? '').toString().toLowerCase();
        final dagLabel = daeVanWeek.firstWhere(
          (d) => d['key'] == dagNaam,
          orElse: () => {'label': dagNaam},
        )['label']!;

        // Find the corresponding KositemTemplate
        final kosItemId = kos['kos_item_id'].toString();
        final kosItem = kryItem(kosItemId);

        if (kosItem != null) {
          templateItems.add(
            TemplateItem(
              itemId: kosItemId,
              dayName: dagNaam,
              dayLabel: dagLabel,
              item: kosItem,
              quantity: 1,
              cutoffTime: DateTime.now().copyWith(hour: 17, minute: 0),
            ),
          );
        }
      }

      setState(() {
        templateItemsVirDialog = templateItems;
        toonTemplateItemsModal = true;
        toonTemplaatModal = false;
      });
    } catch (e) {
      setState(
        () => foutBoodskap = 'Kon nie templaat laai nie: ${e.toString()}',
      );
    }
  }

  Future<void> vervangMenuMetTemplate(List<TemplateItem> templateItems) async {
    try {
      // target = volgende week spyskaart (create if not exists)
      final volStart = _weekStartFor('volgende');
      final volRaw = await weekRepo.getOrCreateSpyskaartForDate(volStart);
      final volId = volRaw['spyskaart_id'] as String;

      // Convert template items to the format expected by replaceItemsInSpyskaart
      final itemsToReplace = templateItems
          .map(
            (templateItem) => {
              'dagNaam': templateItem.dayName,
              'kosItemId': templateItem.itemId,
              'quantity': templateItem.quantity,
              'cutoffTime': templateItem.cutoffTime,
            },
          )
          .toList();

      await weekRepo.replaceItemsInSpyskaart(
        spyskaartId: volId,
        items: itemsToReplace,
      );

      await _loadSpyskaarte();
      setState(() {
        suksesBoodskap = 'Spyskaart suksesvol vervang met templaat';
        templateItemsVirDialog = null;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => suksesBoodskap = '');
      });
    } catch (e) {
      setState(
        () => foutBoodskap = 'Kon nie Spyskaart vervang nie: ${e.toString()}',
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
      Future.delayed(const Duration(seconds: 1), () {
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
    //  Show loader while fetching
    if (isLoading) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    //  Only render UI when data is loaded
    final spyskaart = aktieweWeek == 'huidige' ? huidigeWeek : volgendeWeek;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Styled Header
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width < 600 ? 16 : 24,
                vertical: MediaQuery.of(context).size.width < 600 ? 12 : 16,
              ),
              child: MediaQuery.of(context).size.width < 600
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
                                child: Text(
                                  "📋",
                                  style: TextStyle(fontSize: 18),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Week Spyskaart",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                                  ),
                                  Text(
                                    "Bestuur aktiewe en volgende week se spyskaarte",
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
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(
                                  Icons.menu_book_outlined,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Laai templaat',
                                  style: TextStyle(fontSize: 12),
                                ),
                                onPressed: aktieweWeek == 'volgende'
                                    ? () => setState(
                                        () => toonTemplaatModal = true,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.save, size: 18),
                                label: const Text(
                                  'Stoor as templaat',
                                  style: TextStyle(fontSize: 12),
                                ),
                                onPressed: stoorAsTemplaat,
                              ),
                            ),
                          ],
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left section: logo + title + description
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
                                child: Text(
                                  "📋",
                                  style: TextStyle(fontSize: 20),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Week Spyskaart",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  "Bestuur aktiewe en volgende week se spyskaarte",
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).textTheme.bodySmall?.color,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        // Right section: action buttons
                        Row(
                          children: [
                            OutlinedButton.icon(
                              icon: const Icon(Icons.menu_book_outlined),
                              label: const Text('Laai templaat'),
                              onPressed: aktieweWeek == 'volgende'
                                  ? () =>
                                        setState(() => toonTemplaatModal = true)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.save),
                              label: const Text('Stoor as templaat'),
                              onPressed: stoorAsTemplaat,
                            ),
                          ],
                        ),
                      ],
                    ),
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
                      voegItem: (sp, dag, itemId) =>
                          toonQuantityDialog(kryItem(itemId)!),
                      verwyderItem: verwyderItem,
                      updateItemQuantity: updateItemQuantity,
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
          builder: (_) => KositemDetailDialog(item: gekieseItem!), //
        );
      });
    }
    if (toonQuantityModal && itemVirQuantity != null) {
      toonQuantityModal = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Determine day index (0 = Maandag, 6 = Sondag)
        final dayIndex = daeVanWeek.indexWhere((d) => d['key'] == aktieweDag);

        // Fallback to "today at 17:00" if we can't match day
        DateTime initialCutoff;
        if (dayIndex == -1) {
          initialCutoff = DateTime.now().copyWith(hour: 17, minute: 0);
        } else {
          // Compute the week start for the currently active week (huidige or volgende)
          final weekStart = _weekStartFor(aktieweWeek);
          // Add the day offset and set the time to 17:00
          initialCutoff = weekStart
              .add(Duration(days: dayIndex - 1))
              .copyWith(hour: 17, minute: 0);
        }

        showDialog(
          context: context,
          builder: (_) => QuantityDialog(
            item: itemVirQuantity!,
            open: true,
            initialQuantity: 1,
            initialCutoffTime: initialCutoff,
            onOpenChange:
                (open) {}, // Not used anymore, but kept for compatibility
            onConfirm: (itemId, quantity, cutoffTime) {
              final sp = aktieweWeek == 'huidige' ? huidigeWeek : volgendeWeek;
              if (sp != null) {
                voegItemBy(
                  sp,
                  aktieweDag,
                  itemId,
                  quantity: quantity,
                  cutoffTime: cutoffTime,
                );
              }
              setState(() {
                itemVirQuantity = null;
              });
            },
          ),
        );
      });
    }

    if (toonTemplateItemsModal && templateItemsVirDialog != null) {
      toonTemplateItemsModal = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (_) => TemplateItemsDialog(
            templateItems: templateItemsVirDialog!,
            open: true,
            onOpenChange:
                (open) {}, // Not used anymore, but kept for compatibility
            onConfirm: (templateItems) {
              vervangMenuMetTemplate(templateItems);
              setState(() {
                templateItemsVirDialog = null;
              });
            },
          ),
        );
      });
    }
  }
}
