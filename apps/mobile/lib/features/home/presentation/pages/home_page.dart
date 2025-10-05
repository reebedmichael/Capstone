import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spys_api_client/spys_api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../locator.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../app/presentation/widgets/app_bottom_nav.dart';
import '../../../../shared/state/cart_badge.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

String? gebrNaam;
bool gebrNaamLoading = false;

int mandjieCount = 0;

class _HomePageState extends State<HomePage> {
  String selectedDay = 'Alle';
  String selectedDietType = 'alle';
  final days = ['Alle', 'Maandag', 'Dinsdag', 'Woensdag', 'Donderdag', 'Vrydag'];
  List<Map<String, dynamic>> dietTypes = [{'dieet_id': 'alle', 'dieet_naam': 'Alle'}];

  Map<String, dynamic>? spyskaart;
  List<Map<String, dynamic>> allMenuItems =
      []; // each item = wrapper map (merged)
  List<Map<String, dynamic>> filteredMenuItems = [];
  bool isLoading = true;
  String searchQuery = '';
  Map<String, List<String>> itemDietMapping = {}; // kosItemId -> list of dietIds
  
  // Scroll controllers for Scrollbars
  final ScrollController _dayScrollController = ScrollController();
  final ScrollController _dietScrollController = ScrollController();

  @override
void initState() {
  super.initState();
  _loadGebrNaam();
  _loadDietTypes();
  _fetchMenu();
  Supabase.instance.client.auth.onAuthStateChange.listen((_) {
    _loadGebrNaam();
    _loadMandjieCount();
  });
}

@override
void dispose() {
  _dayScrollController.dispose();
  _dietScrollController.dispose();
  super.dispose();
}

  Future<void> _loadMandjieCount() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final items = await sl<MandjieRepository>().kryMandjie(user.id);
      setState(() => mandjieCount = items.length);
    } catch (e) {
      debugPrint('Kon nie mandjie count kry nie: $e');
      setState(() => mandjieCount = 0);
    }
  }

  Future<void> _loadGebrNaam() async {
    setState(() => gebrNaamLoading = true);

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        gebrNaam = null;
        gebrNaamLoading = false;
      });
      return;
    }

    try {
      final row = await Supabase.instance.client
          .from('gebruikers')
          .select('gebr_naam')
          .eq('gebr_id', user.id)
          .maybeSingle();

    if (row != null) {
      setState(() => gebrNaam = (row['gebr_naam'] ?? '').toString());
    } else {
      setState(() => gebrNaam = null);
    }
  } catch (e) {
    debugPrint('Kon gebr_naam nie laai nie: $e');
    setState(() => gebrNaam = null);
  } finally {
    setState(() => gebrNaamLoading = false);
  }
}

  Future<void> _loadDietTypes() async {
    try {
      final allDiets = await sl<DieetRepository>().getAllDietTypes();
      setState(() {
        dietTypes = <Map<String, dynamic>>[{'dieet_id': 'alle', 'dieet_naam': 'Alle'}] + allDiets;
      });
    } catch (e) {
      debugPrint('Kon nie dieet tipes laai nie: $e');
      // Keep default 'Alle' option
    }
  }

  Future<void> _fetchMenu() async {
    setState(() => isLoading = true);
    try {
      final spyskaartData = await sl<SpyskaartRepository>()
          .getAktieweSpyskaart();
      if (spyskaartData != null) {
        final List<dynamic> items = spyskaartData['spyskaart_kos_item'] ?? [];

        // Build wrapper objects that contain both wrapper fields and nested kos_item
        final mappedItems = items.map<Map<String, dynamic>>((dynamic e) {
          final wrapper = Map<String, dynamic>.from(e as Map<String, dynamic>);
          final nestedKos = Map<String, dynamic>.from(
            wrapper['kos_item'] ?? <String, dynamic>{},
          );

          // Merge nestedKos into wrapper so we can easily filter/display using
          // keys like 'kos_item_naam' etc — but keep the nested map too.
          wrapper.addAll(nestedKos);
          wrapper['kos_item'] = nestedKos;

          // Ensure a readable category & week label exist
          wrapper['week_dag_naam'] = wrapper['week_dag'] is Map
              ? (wrapper['week_dag']['week_dag_naam'] ??
                    wrapper['week_dag_naam'])
              : (wrapper['week_dag_naam'] ?? '');
          wrapper['kos_item_kategorie'] =
              wrapper['kos_item_kategorie'] ??
              nestedKos['kos_item_kategorie'] ??
              'Alle';

          return wrapper;
        }).toList();

        // Load diet mappings for all items
        await _loadDietMappings(mappedItems);

        setState(() {
          spyskaart = spyskaartData;
          allMenuItems = mappedItems;
          _applyFilters();
        });
      } else {
        setState(() {
          spyskaart = null;
          allMenuItems = [];
          filteredMenuItems = [];
        });
      }
    } catch (e, st) {
      print('Error fetching menu: $e\n$st');
      setState(() {
        spyskaart = null;
        allMenuItems = [];
        filteredMenuItems = [];
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadDietMappings(List<Map<String, dynamic>> items) async {
    try {
      final Map<String, List<String>> mappings = {};
      
      for (final item in items) {
        final kosItemId = item['kos_item_id']?.toString();
        if (kosItemId != null) {
          // Query diet mappings for this item
          final response = await Supabase.instance.client
              .from('kos_item_dieet_vereistes')
              .select('dieet_id')
              .eq('kos_item_id', kosItemId);
          
          mappings[kosItemId] = response
              .map<String>((row) => row['dieet_id'].toString())
              .toList();
        }
      }
      
      itemDietMapping = mappings;
    } catch (e) {
      debugPrint('Kon nie dieet mappings laai nie: $e');
      itemDietMapping = {};
    }
  }

  void _applyFilters() {
    final query = searchQuery.toLowerCase();
    filteredMenuItems = allMenuItems.where((item) {
      // item is the wrapper map containing merged fields
      final matchesDay = selectedDay == 'Alle' || (item['week_dag_naam'] ?? '').toString() == selectedDay;
      
      // Check diet type filter
      bool matchesDietType = selectedDietType == 'alle';
      if (!matchesDietType && selectedDietType != 'alle') {
        final kosItemId = item['kos_item_id']?.toString();
        if (kosItemId != null && itemDietMapping.containsKey(kosItemId)) {
          final itemDiets = itemDietMapping[kosItemId] ?? [];
          matchesDietType = itemDiets.contains(selectedDietType);
        }
      }
      
      final matchesSearch = query.isEmpty ||
          (item['kos_item_naam']?.toString().toLowerCase().contains(query) ?? false) ||
          (item['kos_item_beskrywing']?.toString().toLowerCase().contains(query) ?? false);
      // Also skip non-active kos items
      final isActive =
          (item['is_aktief'] ?? item['kos_item']?['is_aktief'] ?? true);
      if (isActive is bool && isActive == false) return false;

      return matchesDay && matchesDietType && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: AppColors.primary,
              padding: const EdgeInsets.fromLTRB(
                Spacing.screenHPad,
                20,
                Spacing.screenHPad,
                16,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            gebrNaamLoading
                                ? 'Welkom...'
                                : 'Welkom, ${gebrNaam != null && gebrNaam!.isNotEmpty ? gebrNaam : 'Gebruiker'}!',
                            style: AppTypography.titleLarge.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Wat gaan jy vandag eet?',
                            style: AppTypography.bodySmall.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.go('/db-test'),
                            icon: const Icon(
                              Icons.storage_rounded,
                              color: Colors.white,
                            ),
                            tooltip: 'DB Test',
                          ),
                          IconButton(
                            onPressed: () => context.go('/notifications'),
                            icon: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                ),
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: _buildBadge('3'),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => context.go('/cart'),
                            icon: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(
                                  Icons.shopping_cart_outlined,
                                  color: Colors.white,
                                ),
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: _buildBadgeMandjie(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search bar
                  TextField(
                    onChanged: (val) {
                      setState(() {
                        searchQuery = val;
                        _applyFilters();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Soek na kos, bestanddele...',
                      prefixIcon: const Icon(Icons.search),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),

        // Day Tabs
SizedBox(
  height: 48,
  child: Scrollbar(
    controller: _dayScrollController,
    thumbVisibility: true,
    child: ListView.separated(
      controller: _dayScrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.screenHPad),
      itemCount: days.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final day = days[index];
        final isSelected = day == selectedDay;
        return ChoiceChip(
          label: Text(day),
          selected: isSelected,
          onSelected: (_) => setState(() {
            selectedDay = day;
            _applyFilters();
          }),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
          ),
          labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        );
      },
    ),
  ),
),

// Dieet tipe Filters (same style as day tabs)
SizedBox(
  height: 48,
  child: Scrollbar(
    controller: _dietScrollController,
    thumbVisibility: true,
    child: ListView.separated(
      controller: _dietScrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.screenHPad),
      itemCount: dietTypes.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (context, index) {
        final diet = dietTypes[index];
        final dietId = diet['dieet_id']?.toString() ?? '';
        final dietName = diet['dieet_naam']?.toString() ?? '';
        final isSelected = dietId == selectedDietType;
        return ChoiceChip(
          label: Text(dietName),
          selected: isSelected,
          onSelected: (_) => setState(() {
            selectedDietType = dietId;
            _applyFilters();
          }),
          selectedColor: AppColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.primary,
          ),
          side: BorderSide(color: AppColors.primary),
          labelPadding: const EdgeInsets.symmetric(horizontal: 12),
        );
      },
    ),
  ),
),



            // Food Items List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredMenuItems.isEmpty
                  ? const Center(child: Text('Geen items beskikbaar'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(Spacing.screenHPad),
                      itemCount: filteredMenuItems.length,
                      itemBuilder: (context, index) {
                        final wrapper = filteredMenuItems[index];
                        final available =
                            wrapper['is_aktief'] ??
                            wrapper['kos_item']?['is_aktief'] ??
                            true;
                        final name =
                            wrapper['kos_item_naam'] ??
                            wrapper['kos_item']?['kos_item_naam'] ??
                            'Geen Naam';
                        final description =
                            wrapper['kos_item_beskrywing'] ??
                            wrapper['kos_item']?['kos_item_beskrywing'] ??
                            '';
                        final priceRaw =
                            wrapper['kos_item_koste'] ??
                            wrapper['kos_item']?['kos_item_koste'] ??
                            0;
                        final price = (priceRaw is num)
                            ? priceRaw.toDouble()
                            : double.tryParse(priceRaw.toString()) ?? 0.0;
                        final dayName = wrapper['week_dag_naam'] ?? '';
                        final image =
                            wrapper['kos_item_prentjie'] ??
                            wrapper['kos_item']?['kos_item_prentjie'] ??
                            '';

                        return _buildFoodCard(
                          name: name.toString(),
                          description: description.toString(),
                          price: price,
                          available: available == true,
                          dayName: dayName.toString(),
                          wrapper: wrapper,
                          imageUrl: image?.toString() ?? '',
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 0),
    );
  }

  Widget _buildBadge(String count) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(8),
      ),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      child: Text(
        count,
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
    );
  }

  Widget _buildBadgeMandjie() {
    // Subscribe to global cart badge updates for real-time count
    return ValueListenableBuilder<int>(
      valueListenable: CartBadgeState.count,
      builder: (context, value, _) {
        final display = value > 0 ? value : mandjieCount;
        if (display == 0) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(8),
          ),
          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
          child: Text(
            '$display',
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        );
      },
    );
  }

  Widget _buildFoodCard({
    required String name,
    required String description,
    required double price,
    required bool available,
    required String dayName,
    required Map<String, dynamic> wrapper,
    required String imageUrl,
  }) {
    // Tappable card wrapper: entire card opens the food detail view
    return Semantics(
      button: true,
      label: 'Open detail vir $name',
      child: InkWell(
        onTap: () {
          context.push('/food-detail', extra: wrapper);
        },
        borderRadius: BorderRadius.circular(12),
        child: Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  image: imageUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(imageUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: imageUrl.isEmpty
                    ? const Icon(
                        Icons.fastfood,
                        size: 40,
                        color: AppColors.onSurfaceVariant,
                      )
                    : null,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: AppTypography.titleMedium),
                      if (description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'R${price.toStringAsFixed(2)}',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (dayName.isNotEmpty && selectedDay == 'Alle')
                            Text(dayName, style: AppTypography.labelSmall),
                          const Spacer(),
                          // Keep visible action button with exact text "Meer detail"
                          TextButton(
                            onPressed: () {
                              // Pass the wrapper (contains nested kos_item and wrapper-level fields)
                              context.push('/food-detail', extra: wrapper);
                            },
                            child: const Text('Meer detail'),
                          ),
                        ],
                      ),
                      if (!available)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: const Text(
                            'Nie beskikbaar nie',
                            style: TextStyle(color: Colors.red),
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
    );
  }
}
