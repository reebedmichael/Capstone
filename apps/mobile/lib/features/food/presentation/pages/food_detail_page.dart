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
  late Map<String, dynamic> item;
  int quantity = 1;
  bool isFavorite = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = GoRouterState.of(context).extra;
    if (args != null && args is Map<String, dynamic>) {
      item = args;
    } else {
      item = {
        'KOS_ITEM_NAAM': 'Onbekende Item',
        'KOS_ITEM_BESKRYWING': '',
        'KOS_ITEM_KOSTE': 0.0,
        'KOS_ITEM_PRENTJIE': null,
        'IS_AKTIEF': true,
      };
    }
  }

  bool get available => item['IS_AKTIEF'] ?? true;

  void updateQuantity(int newQty) {
    if (newQty >= 1 && newQty <= 10) {
      setState(() => quantity = newQty);
    }
  }

  void handleAddToCart() {
    if (!available) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Bygevoeg: $quantity x ${item['KOS_ITEM_NAAM']}')),
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
            title: Text(item['KOS_ITEM_NAAM'] ?? '', style: AppTypography.titleMedium, overflow: TextOverflow.ellipsis),
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
                    child: item['KOS_ITEM_PRENTJIE'] != null
                        ? Image.network(item['KOS_ITEM_PRENTJIE'], fit: BoxFit.cover)
                        : const Icon(Icons.fastfood, size: 88, color: Colors.black38),
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
                      child: Text('R${(item['KOS_ITEM_KOSTE'] ?? 0).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
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
                  Text(item['KOS_ITEM_NAAM'] ?? '', style: AppTypography.displayLarge.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(item['KOS_ITEM_BESKRYWING'] ?? '', style: AppTypography.bodySmall.copyWith(color: Colors.black54)),
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
                  Text('R${((item['KOS_ITEM_KOSTE'] ?? 0) * quantity).toStringAsFixed(2)}', style: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
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
