import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/constants/spacing.dart';

class FoodItemModel {
  final String id;
  final String name;
  final String? imageUrl; // Network images disabled for offline/dev environments
  final double price;
  final bool available;

  const FoodItemModel({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.price,
    required this.available,
  });
}

class CartItemModel {
  final String id;
  final FoodItemModel foodItem;
  int quantity;

  CartItemModel({
    required this.id,
    required this.foodItem,
    this.quantity = 1,
  });
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // Mock user wallet
  double walletBalance = 250.00;

  // Mock cart
  final List<CartItemModel> cart = <CartItemModel>[
    CartItemModel(
      id: 'ci-1',
      foodItem: const FoodItemModel(
        id: 'f-1',
        name: 'Boerewors en Pap',
        price: 45.00,
        available: true,
      ),
      quantity: 1,
    ),
    CartItemModel(
      id: 'ci-2',
      foodItem: const FoodItemModel(
        id: 'f-2',
        name: 'Vegetariese Pasta',
        price: 38.00,
        available: true,
      ),
      quantity: 2,
    ),
    CartItemModel(
      id: 'ci-3',
      foodItem: const FoodItemModel(
        id: 'f-3',
        name: 'Dag Spesiaal',
        price: 55.00,
        available: false,
      ),
      quantity: 1,
    ),
  ];

  String? pickupLocation;
  final List<String> pickupLocations = <String>[
    'Hoofkampus Kafeteria',
    'Ingenieurskampus Kafeteria',
    'Mediese Skool Kafeteria',
    'Residensie Eetsal - Nerina',
    'Residensie Eetsal - Helshoogte',
    'Sport Kafeteria',
  ];

  bool get cartIsEmpty => cart.isEmpty;
  List<CartItemModel> get unavailableItems => cart.where((c) => !c.foodItem.available).toList();
  double get subtotal => cart.fold(0.0, (double sum, CartItemModel c) => sum + (c.foodItem.price * c.quantity));
  double get deliveryFee => 0.0; // pickup is free
  double get total => subtotal + deliveryFee;
  bool get hasSufficientFunds => walletBalance >= total;

  void updateCartQuantity(String itemId, int newQuantity) {
    setState(() {
      final CartItemModel item = cart.firstWhere((c) => c.id == itemId);
      if (newQuantity <= 0) {
        cart.removeWhere((c) => c.id == itemId);
      } else {
        item.quantity = newQuantity.clamp(0, 10);
      }
    });
  }

  void removeFromCart(String itemId) {
    setState(() {
      cart.removeWhere((c) => c.id == itemId);
    });
  }

  bool placeOrder(String pickup) {
    // Simulate success and deduct balance
    if (!hasSufficientFunds) return false;
    setState(() {
      walletBalance -= total;
      cart.clear();
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // Empty State
    if (cartIsEmpty) {
      return Scaffold(
        body: Column(
          children: <Widget>[
            Container(
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0x1F000000))),
                color: Colors.white,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/home'),
                    ),
                    Text('Mandjie', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.black38),
                      const SizedBox(height: 12),
                      Text('Jou mandjie is leeg', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text('Voeg items by jou mandjie om te begin bestel', style: AppTypography.bodyMedium.copyWith(color: Colors.black54)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.go('/home'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                        child: const Text('Begin Inkopies'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              AppColors.primary.withValues(alpha: 0.05),
              AppColors.secondary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: Spacing.screenHPad, right: Spacing.screenHPad, bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.go('/home'),
                    ),
                    Text('Mandjie (${cart.length})', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 40),
                  ],
                ),

                const SizedBox(height: 12),

                // Unavailable Items Alert
                if (unavailableItems.isNotEmpty)
                  Card(
                    color: const Color(0xFFFFF7ED),
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Colors.orange.shade500),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Let wel: ${unavailableItems.length} item(s) in jou mandjie is nie meer beskikbaar nie en sal verwyder word.',
                              style: AppTypography.bodySmall.copyWith(color: Colors.orange.shade800),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Cart Items
                Column(
                  children: cart.map((CartItemModel item) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: <Widget>[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                // Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: <Widget>[
                                      if (item.foodItem.imageUrl != null)
                                        Image.network(
                                          item.foodItem.imageUrl!,
                                          width: 64,
                                          height: 64,
                                          fit: BoxFit.cover,
                                        )
                                      else
                                        Container(
                                          width: 64,
                                          height: 64,
                                          color: Colors.grey.shade300,
                                          alignment: Alignment.center,
                                          child: const Icon(Icons.fastfood, color: Colors.white70),
                                        ),
                                      if (!item.foodItem.available)
                                        Container(
                                          width: 64,
                                          height: 64,
                                          color: Colors.black.withOpacity(0.5),
                                          alignment: Alignment.center,
                                          child: const Text('Uit', style: TextStyle(color: Colors.white, fontSize: 12)),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(item.foodItem.name, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 4),
                                      Text('R${item.foodItem.price.toStringAsFixed(2)} elk', style: AppTypography.bodySmall.copyWith(color: Colors.black54)),
                                      if (!item.foodItem.available)
                                        const Text('Nie meer beskikbaar nie', style: TextStyle(fontSize: 12, color: Colors.red)),
                                    ],
                                  ),
                                ),

                                // Quantity controls
                                Row(
                                  children: <Widget>[
                                    OutlinedButton(
                                      onPressed: () => updateCartQuantity(item.id, item.quantity - 1),
                                      style: OutlinedButton.styleFrom(minimumSize: const Size(32, 32), padding: EdgeInsets.zero),
                                      child: const Icon(Icons.remove, size: 16),
                                    ),
                                    SizedBox(
                                      width: 32,
                                      child: Center(
                                        child: Text('${item.quantity}', style: AppTypography.labelLarge),
                                      ),
                                    ),
                                    OutlinedButton(
                                      onPressed: item.foodItem.available && item.quantity < 10
                                          ? () => updateCartQuantity(item.id, item.quantity + 1)
                                          : null,
                                      style: OutlinedButton.styleFrom(minimumSize: const Size(32, 32), padding: EdgeInsets.zero),
                                      child: const Icon(Icons.add, size: 16),
                                    ),
                                    IconButton(
                                      onPressed: () => removeFromCart(item.id),
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            // Item total
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: <Widget>[
                                Text('R${(item.foodItem.price * item.quantity).toStringAsFixed(2)}', style: AppTypography.labelLarge),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),

                // Add more items button
                OutlinedButton.icon(
                  onPressed: () => context.go('/home'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary),
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(44),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Voeg meer items by'),
                ),

                const SizedBox(height: 12),

                // Pickup Location
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            const Icon(Icons.location_on_outlined, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text('Afhaallokasie', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: pickupLocation,
                          items: pickupLocations
                              .map((String l) => DropdownMenuItem<String>(value: l, child: Text(l)))
                              .toList(),
                          onChanged: (String? v) => setState(() => pickupLocation = v),
                          decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Kies afhaallokasie'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Order Summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('Bestelling Opsomming', style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Text('Subtotaal:'),
                            Text('R${subtotal.toStringAsFixed(2)}'),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const <Widget>[
                            Text('Afhaalkoste:'),
                            Text('Gratis', style: TextStyle(color: Colors.green)),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            const Text('Totaal:', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text('R${total.toStringAsFixed(2)}', style: AppTypography.titleSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Wallet Balance info
                Card(
                  color: hasSufficientFunds ? const Color(0xFFEFFAF1) : const Color(0xFFFEECEC),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text('Beursie Balans', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('R${walletBalance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            if (!hasSufficientFunds)
                              Text('Kort: R${(total - walletBalance).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.red)),
                          ],
                        ),
                        if (!hasSufficientFunds)
                          OutlinedButton(
                            onPressed: () => context.go('/wallet'),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              foregroundColor: AppColors.primary,
                            ),
                            child: const Text('Laai Beursie'),
                          )
                        else
                          const Text('Voldoende fondse', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text('Totaal te betaal:', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  Text('R${total.toStringAsFixed(2)}', style: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
              ElevatedButton(
                onPressed: (!hasSufficientFunds || pickupLocation == null || unavailableItems.isNotEmpty)
                    ? null
                    : () {
                        final bool success = placeOrder(pickupLocation!);
                        if (success) context.go('/orders');
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(140, 48),
                ),
                child: const Text('Plaas Bestelling'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
