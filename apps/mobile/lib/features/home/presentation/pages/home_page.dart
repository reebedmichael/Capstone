import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../app/presentation/widgets/app_bottom_nav.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedDay = 'Maandag';
  String selectedCategory = 'Alle';
  final days = ['Maandag', 'Dinsdag', 'Woensdag', 'Donderdag', 'Vrydag'];
  final categories = [
    'Alle',
    'Hoofkos',
    'Vegetaries',
    'Vegan',
    'Glutenvry',
    'Personeelspesifiek'
  ];

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
                    onSelected: (_) => setState(() => selectedDay = day),
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
                        onSelected: (_) => setState(() => selectedCategory = cat),
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
              child: ListView.builder(
                padding: const EdgeInsets.all(Spacing.screenHPad),
                itemCount: 5, // voorbeeld items
                itemBuilder: (context, index) {
                  return _buildFoodCard(
                    name: 'Dag se spesiaal',
                    description: 'Heerlike vars opsies',
                    price: 49.99,
                    imageUrl: null,
                    available: index % 2 == 0,
                    allergens: ['Gluten', 'Lactose'],
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
    String? imageUrl,
    required bool available,
    required List<String> allergens,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              image: imageUrl != null
                  ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: !available
                ? Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Text('Uitverkoop', style: TextStyle(color: Colors.white)),
                    ),
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
                  const SizedBox(height: 4),
                  Text(description, style: AppTypography.bodySmall, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: allergens
                        .map((a) => Container(
                              margin: const EdgeInsets.only(right: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.primary),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(a, style: const TextStyle(fontSize: 10)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('R${price.toStringAsFixed(2)}', style: AppTypography.titleMedium.copyWith(color: AppColors.primary)),
                      ElevatedButton(
                        onPressed: available ? () => context.go('/food-detail') : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        child: Text(available ? 'Besigtig Detail' : 'Uitverkoop'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
