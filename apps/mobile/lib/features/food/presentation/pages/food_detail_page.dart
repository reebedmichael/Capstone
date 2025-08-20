import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/constants/spacing.dart';

class FoodDetailPage extends StatefulWidget {
  const FoodDetailPage({super.key});

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  int quantity = 1;
  bool isFavorite = false;

  void updateQuantity(int newQty) {
    if (newQty >= 1 && newQty <= 10) {
      setState(() => quantity = newQty);
    }
  }

  void handleAddToCart() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bygevoeg: $quantity x Dag se Spesiaal')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: Text(
                    'Dag se Spesiaal',
                    style: AppTypography.titleLarge,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() => isFavorite = !isFavorite),
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.red : null,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Skakel gekopieer na klipbord')),
                    );
                  },
                  icon: const Icon(Icons.share_outlined),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Food Image
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.fastfood, size: 80, color: Colors.black38),
                    ),
                  ),

                  // Content Padding
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and Description
                        Text(
                          'Dag se Spesiaal',
                          style: AppTypography.displayLarge.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Heerlike vars opsies met plaaslike bestanddele.',
                          style: AppTypography.bodyMedium.copyWith(color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 12),

                        // Time and Portion Info
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text('15-20 min', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            const SizedBox(width: 16),
                            Icon(Icons.group_outlined, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 4),
                            Text('1 porsie', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Allergen Warning
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Allergie Waarskuwing: Hierdie item bevat bestanddele wat ooreenstem met jou dieetbeperkings.',
                                  style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Ingredients
                        _buildSectionCard(
                          title: 'Bestanddele',
                          icon: Icons.info_outline,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['Beesvleis', 'Uie', 'Tamatiesous', 'Speserye']
                                .map((ing) => _buildPill(ing))
                                .toList(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Allergens
                        _buildSectionCard(
                          title: 'Allergie Inligting',
                          icon: Icons.warning_rounded,
                          titleColor: Colors.orange.shade600,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['Gluten', 'Lactose']
                                .map((a) => _buildPill('Bevat $a', backgroundColor: const Color(0xFFFFE5E5), textColor: Colors.red.shade700))
                                .toList(),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Nutritional Info
                        _buildSectionCard(
                          title: 'Voeding Inligting (per porsie)',
                          child: Column(
                            children: [
                              _buildNutrientRow('Kalorieë:', '420 kcal'),
                              const SizedBox(height: 8),
                              _buildNutrientRow('Proteïen:', '25g'),
                              const SizedBox(height: 8),
                              _buildNutrientRow('Koolhidrate:', '35g'),
                              const SizedBox(height: 8),
                              _buildNutrientRow('Vet:', '18g'),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Availability
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFFAF1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Beskikbaar',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                  ),
                                  Text(
                                    'Gereed vir bestelling',
                                    style: TextStyle(fontSize: 12, color: Colors.green.shade600),
                                  ),
                                ],
                              ),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 100), // Space for bottom bar
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quantity Row
              Row(
                children: [
                  const Text('Hoeveelheid:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: quantity <= 1 ? null : () => updateQuantity(quantity - 1),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(40, 40),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.remove, size: 18),
                  ),
                  SizedBox(
                    width: 40,
                    child: Center(
                      child: Text(
                        '$quantity',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: quantity >= 10 ? null : () => updateQuantity(quantity + 1),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(40, 40),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.add, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Total and Add to Cart Row
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Totaal:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        'R${(49.99 * quantity).toStringAsFixed(2)}',
                        style: AppTypography.titleLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: handleAddToCart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                      ),
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text('Voeg by Mandjie'),
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

  Widget _buildSectionCard({
    required String title,
    IconData? icon,
    Color? titleColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: titleColor ?? Colors.grey.shade600),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildPill(String text, {Color? backgroundColor, Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(color: textColor),
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(width: 8),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
