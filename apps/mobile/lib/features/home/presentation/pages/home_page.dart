import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spys_api_client/spys_api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../locator.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../app/presentation/widgets/app_bottom_nav.dart';
import 'package:spys_api_client/src/spyskaart_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedDay = 'Alle';
  String selectedCategory = 'Alle';
  final days = ['Alle', 'Maandag', 'Dinsdag', 'Woensdag', 'Donderdag', 'Vrydag'];
  final categories = [
    'Alle',
    'Hoofkos',
    'Vegetaries',
    'Vegan',
    'Glutenvry',
    'Personeelspesifiek'
  ];

  Map<String, dynamic>? spyskaart;
  List<Map<String, dynamic>> allMenuItems = [];
  List<Map<String, dynamic>> filteredMenuItems = [];
  bool isLoading = true;
  String searchQuery = '';

  String userName = 'Gebruiker';
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    currentUserId = user?.id ?? '';
    _fetchUserName();
    _fetchMenu();
  }

  Future<void> _fetchUserName() async {
    if (currentUserId.isEmpty) return;
    try {
      final user = await sl<GebruikersRepository>().kryGebruiker(currentUserId);
      if (user != null && user['gebr_naam'] != null) {
        setState(() {
          userName = user['gebr_naam'];
        });
      }
    } catch (e) {
      // alleen log
      debugPrint('Error fetching user name: $e');
    }
  }

  Future<void> _fetchMenu() async {
    setState(() => isLoading = true);
    try {
      final spyskaartData = await sl<SpyskaartRepository>().getAktieweSpyskaart();
      if (spyskaartData != null) {
        final List<dynamic> items = spyskaartData['spyskaart_kos_item'] ?? [];

        // Map elke spyskaart_kos_item in 'n selfstandige kaart item, gebruik kos_item velde (foto, aktief, ens.)
        final mappedItems = <Map<String, dynamic>>[];
        for (final e in items) {
          final kos = Map<String, dynamic>.from(e['kos_item'] ?? {});
          // haal unieke id van die spyskaart_kos entry as beskikbaar
          final spyskaartKosId = e['spyskaart_kos_id'] ?? e['spyskaart_kos_id'];
          final weekDagNaam = e['week_dag']?['week_dag_naam'] ?? (e['week_dag_naam'] ?? '');

          final mapped = <String, dynamic>{
            'spyskaart_kos_id': spyskaartKosId,
            'kos_item_id': kos['kos_item_id'] ?? kos['id'] ?? kos['id'],
            'kos_item_naam': kos['kos_item_naam'] ?? kos['naam'] ?? '',
            'kos_item_beskrywing': kos['kos_item_beskrywing'] ?? kos['beskrywing'] ?? '',
            // prys in DB is 'kos_item_koste' (kyk na jou teruggawe); parse as double
            'kos_item_koste': (kos['kos_item_koste'] is num) ? (kos['kos_item_koste'] as num).toDouble() : (kos['kos_item_koste'] != null ? double.tryParse(kos['kos_item_koste'].toString()) ?? 0.0 : 0.0),
            'kos_item_prentjie': kos['kos_item_prentjie'] ?? kos['kos_item_prentjie'] ?? '',
            'kos_item_kategorie': kos['kos_item_kategorie'] ?? 'Alle',
            'is_aktief': kos['is_aktief'] ?? true,
            'week_dag_naam': weekDagNaam,
            'week_dag_id': e['week_dag_id'] ?? e['week_dag']?['week_dag_id'],
          };

          // filter: slegs indien die KOS ITEM self aktief is
          if (mapped['is_aktief'] == true) {
            mappedItems.add(mapped);
          }
        }

        // Voorkom onnodige identiese duplikate (gebruik spyskaart_kos_id indien beskikbaar)
        final unique = <String, Map<String, dynamic>>{};
        for (var m in mappedItems) {
          final key = m['spyskaart_kos_id']?.toString().isNotEmpty == true
              ? m['spyskaart_kos_id'].toString()
              : '${m['kos_item_id']}_${m['week_dag_naam']}';
          // as dieselfde key tweemaal voorkom, die laaste een oorskryf — wat goed is as dit presies dieselfde inskrywing is
          unique[key] = m;
        }

        setState(() {
          spyskaart = spyskaartData;
          allMenuItems = unique.values.toList();
        });

        // Pas filters toe
        _applyFilters();
      } else {
        setState(() {
          spyskaart = null;
          allMenuItems = [];
          filteredMenuItems = [];
        });
      }
    } catch (e, st) {
      debugPrint('Error fetching menu: $e\n$st');
      setState(() {
        spyskaart = null;
        allMenuItems = [];
        filteredMenuItems = [];
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _applyFilters() {
    final query = searchQuery.trim().toLowerCase();
    final results = allMenuItems.where((item) {
      final matchesDay = selectedDay == 'Alle' || (item['week_dag_naam'] ?? '') == selectedDay;
      final matchesCategory = selectedCategory == 'Alle' || (item['kos_item_kategorie'] ?? 'Alle') == selectedCategory;
      final matchesSearch = query.isEmpty ||
          (item['kos_item_naam']?.toString().toLowerCase().contains(query) ?? false) ||
          (item['kos_item_beskrywing']?.toString().toLowerCase().contains(query) ?? false);
      return matchesDay && matchesCategory && matchesSearch;
    }).toList();

    setState(() {
      filteredMenuItems = results;
    });
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
              padding: const EdgeInsets.fromLTRB(Spacing.screenHPad, 20, Spacing.screenHPad, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Welkom + naam
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welkom, $userName!',
                              style: AppTypography.titleLarge.copyWith(color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('Wat gaan jy vandag eet?',
                              style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                        ],
                      ),

                      // Icons
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.go('/db-test'),
                            icon: const Icon(Icons.storage_rounded, color: Colors.white),
                            tooltip: 'DB Test',
                          ),
                          IconButton(
                            onPressed: () => context.go('/notifications'),
                            icon: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(Icons.notifications_outlined, color: Colors.white),
                                Positioned(right: -2, top: -2, child: _buildBadge('3')),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => context.go('/cart'),
                            icon: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                                Positioned(right: -2, top: -2, child: _buildBadge('2')),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Search
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
            Container(
              color: AppColors.surfaceVariant,
              height: 48,
              child: ListView.separated(
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
                    labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.onSurfaceVariant),
                  );
                },
              ),
            ),

            // Category Chips
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: Spacing.screenHPad),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = cat == selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (_) => setState(() {
                          selectedCategory = cat;
                          _applyFilters();
                        }),
                        selectedColor: AppColors.primary,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.primary),
                        side: BorderSide(color: AppColors.primary),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Items
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredMenuItems.isEmpty
                      ? const Center(child: Text('Geen items beskikbaar'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(Spacing.screenHPad),
                          itemCount: filteredMenuItems.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = filteredMenuItems[index];
                            final imageUrl = (item['kos_item_prentjie'] ?? '').toString();
                            final price = (item['kos_item_koste'] is num) ? (item['kos_item_koste'] as num).toDouble() : double.tryParse('${item['kos_item_koste']}') ?? 0.0;
                            final dayNameToShow = (selectedDay == 'Alle') ? (item['week_dag_naam'] ?? '') : '';
                            return _buildFoodCard(
                              name: item['kos_item_naam'] ?? 'Geen Naam',
                              description: item['kos_item_beskrywing'] ?? '',
                              price: price,
                              imageUrl: imageUrl,
                              dayName: dayNameToShow,
                              item: item,
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
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      child: Text(count, style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }

  Widget _buildFoodCard({
    required String name,
    required String description,
    required double price,
    required String imageUrl,
    required String dayName,
    required Map<String, dynamic> item,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.push('/food-detail', extra: item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // Image column (optional)
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppColors.surfaceVariant,
                  image: imageUrl.isNotEmpty
                      ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                      : null,
                ),
                child: imageUrl.isEmpty
                    ? Center(child: Icon(Icons.fastfood, size: 36, color: AppColors.onSurfaceVariant))
                    : null,
              ),

              const SizedBox(width: 12),

              // Text column
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppTypography.titleMedium),
                    const SizedBox(height: 6),
                    if (description.isNotEmpty)
                      Text(description, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppTypography.bodySmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('R${price.toStringAsFixed(2)}', style: AppTypography.titleMedium.copyWith(color: AppColors.primary)),
                        const Spacer(),
                        if (dayName.isNotEmpty) Text(dayName, style: AppTypography.labelSmall),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => context.push('/food-detail', extra: item),
                          child: const Text('Meer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
