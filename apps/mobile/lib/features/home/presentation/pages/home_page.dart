import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../locator.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../app/presentation/widgets/app_bottom_nav.dart';
import 'package:spys_api_client/src/spyskaart_repository.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchMenu();
  }

  Future<void> _fetchMenu() async {
    setState(() => isLoading = true);
    try {
      final spyskaartData = await sl<SpyskaartRepository>().getAktieweSpyskaart();
      if (spyskaartData != null) {
        final List<dynamic> items = spyskaartData['spyskaart_kos_item'] ?? [];
        final mappedItems = items.map((e) {
          final kosItem = Map<String, dynamic>.from(e['kos_item'] ?? {});
          kosItem['week_dag_naam'] = e['week_dag']?['week_dag_naam'] ?? '';
          kosItem['kos_item_kategorie'] = kosItem['kos_item_kategorie'] ?? 'Alle';
          return kosItem;
        }).toList();

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
    } catch (e) {
      print('Error fetching menu: $e');
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
    final query = searchQuery.toLowerCase();
    filteredMenuItems = allMenuItems.where((item) {
      final matchesDay = selectedDay == 'Alle' || item['week_dag_naam'] == selectedDay;
      final matchesCategory =
          selectedCategory == 'Alle' || item['kos_item_kategorie'] == selectedCategory;
      final matchesSearch = query.isEmpty ||
          (item['kos_item_naam']?.toLowerCase().contains(query) ?? false) ||
          (item['kos_item_beskrywing']?.toLowerCase().contains(query) ?? false);
      return matchesDay && matchesCategory && matchesSearch;
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
              padding: const EdgeInsets.fromLTRB(Spacing.screenHPad, 20, Spacing.screenHPad, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welkom, Gebruiker!',
                              style: AppTypography.titleLarge.copyWith(color: Colors.white)),
                          const SizedBox(height: 4),
                          Text('Wat gaan jy vandag eet?',
                              style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                        ],
                      ),
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
                                const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                                Positioned(
                                  right: -2,
                                  top: -2,
                                  child: _buildBadge('2'),
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
                    labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.onSurfaceVariant),
                  );
                },
              ),
            ),

            // Category Filters
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
                        labelStyle: TextStyle(
                            color: isSelected ? Colors.white : AppColors.primary),
                        side: BorderSide(color: AppColors.primary),
                      ),
                    );
                  }).toList(),
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
                            final item = filteredMenuItems[index];
                            final available = item['is_aktief'] ?? true;
                            return _buildFoodCard(
                              name: item['kos_item_naam'] ?? 'Geen Naam',
                              description: item['kos_item_beskrywing'] ?? '',
                              price: item['kos_item_koste']?.toDouble() ?? 0.0,
                              available: available,
                              dayName: item['week_dag_naam'] ?? '',
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
      child: Text(count, style: const TextStyle(color: Colors.white, fontSize: 10)),
    );
  }

  Widget _buildFoodCard({
    required String name,
    required String description,
    required double price,
    required bool available,
    required String dayName,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            color: AppColors.surfaceVariant,
            child: const Icon(Icons.fastfood, size: 40, color: AppColors.onSurfaceVariant),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: AppTypography.titleMedium),
                  if (description.isNotEmpty) Text(description),
                  Text('Prys: R$price'),
                  Text('Dag: $dayName'),
                  if (!available) Text('Nie beskikbaar nie', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
