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
  // Mock food item data (no network images)
  final String name = 'Dag se Spesiaal';
  final String description = 'Heerlike vars opsies met plaaslike bestanddele.';
  final double price = 49.99;
  final bool available = true;
  final List<String> ingredients = <String>['Beesvleis', 'Uie', 'Tamatiesous', 'Speserye'];
  final List<String> allergens = <String>['Gluten', 'Lactose'];
  final List<String> userDietaryRequirements = <String>['Gluten']; // demo to trigger warning

  int quantity = 1;
  bool isFavorite = false;

  bool get hasAllergenWarning {
    if (userDietaryRequirements.isEmpty) return false;
    for (final String allergen in allergens) {
      for (final String req in userDietaryRequirements) {
        if (req.toLowerCase().contains(allergen.toLowerCase())) {
          return true;
        }
      }
    }
    return false;
  }

  void updateQuantity(int newQty) {
    if (newQty >= 1 && newQty <= 10) {
      setState(() => quantity = newQty);
    }
  }

  void handleAddToCart() {
    if (!available) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bygevoeg: $quantity x $name')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            expandedHeight: 260,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (GoRouter.of(context).canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              },
            ),
            title: Text(name, style: AppTypography.titleMedium, overflow: TextOverflow.ellipsis),
            actions: <Widget>[
              IconButton(
                tooltip: 'Gunstelling',
                onPressed: () => setState(() => isFavorite = !isFavorite),
                icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border),
                color: isFavorite ? Colors.red : null,
              ),
              IconButton(
                tooltip: 'Deel',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Skakel gekopieer na klipbord')),
                  );
                },
                icon: const Icon(Icons.share_outlined),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Color(0xFFE0E0E0), Color(0xFFBDBDBD)],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.fastfood, size: 88, color: Colors.black38),
                  ),
                  if (!available)
                    Container(
                      color: Colors.black.withOpacity(0.55),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const <Widget>[
                          Icon(Icons.warning_amber_rounded, color: Colors.white, size: 48),
                          SizedBox(height: 8),
                          Text('Uitverkoop', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: const <BoxShadow>[BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
                      ),
                      child: Text('R${price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.screenHPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(name, style: AppTypography.displayLarge.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(description, style: AppTypography.bodySmall.copyWith(color: Colors.black54)),
                  const SizedBox(height: 10),
                  Row(
                    children: const <Widget>[
                      Icon(Icons.access_time, size: 16),
                      SizedBox(width: 4),
                      Text('15-20 min', style: TextStyle(fontSize: 12)),
                      SizedBox(width: 16),
                      Icon(Icons.group_outlined, size: 16),
                      SizedBox(width: 4),
                      Text('1 porsie', style: TextStyle(fontSize: 12)),
                    ],
                  ),

                  const SizedBox(height: 14),

                  if (hasAllergenWarning)
                    _AlertCard(
                      icon: Icons.warning_amber_rounded,
                      iconColor: Colors.orange,
                      backgroundColor: const Color(0xFFFFF7ED),
                      text: 'Allergie Waarskuwing: Hierdie item bevat bestanddele wat ooreenstem met jou dieetbeperkings.',
                    ),

                  const SizedBox(height: 14),

                  _SectionCard(
                    title: 'Bestanddele',
                    titleIcon: Icons.info_outline,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ingredients
                          .map((String ing) => _Pill(text: ing))
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (allergens.isNotEmpty)
                    _SectionCard(
                      title: 'Allergie Inligting',
                      titleIcon: Icons.warning_rounded,
                      titleColor: Colors.orange,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: allergens
                            .map((String a) => _Pill(text: 'Bevat $a', backgroundColor: const Color(0xFFFFE5E5), textColor: Colors.red.shade700))
                            .toList(),
                      ),
                    ),

                  const SizedBox(height: 14),

                  _SectionCard(
                    title: 'Voeding Inligting (per porsie)',
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 5,
                      children: const <Widget>[
                        _NutrientRow(label: 'Kalorieë:', value: '420 kcal'),
                        _NutrientRow(label: 'Proteïen:', value: '25g'),
                        _NutrientRow(label: 'Koolhidrate:', value: '35g'),
                        _NutrientRow(label: 'Vet:', value: '18g'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  _AvailabilityCard(available: available),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0x1F000000))),
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: Row(
            children: <Widget>[
              const Text('Hoeveelheid:', style: TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: (quantity <= 1 || !available) ? null : () => updateQuantity(quantity - 1),
                style: OutlinedButton.styleFrom(minimumSize: const Size(40, 40), padding: EdgeInsets.zero),
                child: const Icon(Icons.remove, size: 18),
              ),
              SizedBox(
                width: 36,
                child: Center(child: Text('$quantity', style: AppTypography.labelLarge)),
              ),
              OutlinedButton(
                onPressed: (quantity >= 10 || !available) ? null : () => updateQuantity(quantity + 1),
                style: OutlinedButton.styleFrom(minimumSize: const Size(40, 40), padding: EdgeInsets.zero),
                child: const Icon(Icons.add, size: 18),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Totaal:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  Text('R${(price * quantity).toStringAsFixed(2)}', style: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: available ? handleAddToCart : null,
                style: ElevatedButton.styleFrom(minimumSize: const Size(140, 48), backgroundColor: AppColors.primary),
                icon: const Icon(Icons.shopping_cart_outlined),
                label: Text(available ? 'Voeg by Mandjie' : 'Uitverkoop'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutrientRow extends StatelessWidget {
  final String label;
  final String value;
  const _NutrientRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(width: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _AlertCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final String text;
  const _AlertCard({required this.icon, required this.iconColor, required this.backgroundColor, required this.text});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: AppTypography.bodySmall.copyWith(color: Colors.black87))),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData? titleIcon;
  final Color? titleColor;
  final Widget child;
  const _SectionCard({required this.title, this.titleIcon, this.titleColor, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (titleIcon != null) ...<Widget>[
                  Icon(titleIcon, size: 16, color: titleColor),
                  const SizedBox(width: 8),
                ],
                Text(title, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w700, color: titleColor)),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color? backgroundColor;
  final Color? textColor;
  const _Pill({required this.text, this.backgroundColor, this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black12,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: AppTypography.labelSmall.copyWith(color: textColor)),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  final bool available;
  const _AvailabilityCard({required this.available});

  @override
  Widget build(BuildContext context) {
    final Color bg = available ? const Color(0xFFEFFAF1) : const Color(0xFFFEECEC);
    final Color text1 = available ? Colors.green.shade800 : Colors.red.shade800;
    final Color text2 = available ? Colors.green.shade600 : Colors.red.shade600;
    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(available ? 'Beskikbaar' : 'Uitverkoop', style: TextStyle(fontWeight: FontWeight.w700, color: text1)),
                const SizedBox(height: 2),
                Text(available ? 'Gereed vir bestelling' : 'Tans nie beskikbaar nie', style: TextStyle(fontSize: 12, color: text2)),
              ],
            ),
            Container(width: 10, height: 10, decoration: BoxDecoration(color: available ? Colors.green : Colors.red, shape: BoxShape.circle)),
          ],
        ),
      ),
    );
  }
}
