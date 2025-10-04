import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../locator.dart';
import 'package:spys_api_client/spys_api_client.dart';
import '../../../../shared/state/cart_badge.dart';
// removed embedded widget; pickup UI now inline above

// Cart item food model (includes ingredients/allergens for diet checks and detail page)
class FoodItemModel {
  final String id;
  final String name;
  final String? imageUrl; // Network images disabled for offline/dev environments
  final double price;
  final bool available;
  final List<String> ingredients;
  final List<String> allergens;

  const FoodItemModel({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.price,
    required this.available,
    this.ingredients = const <String>[],
    this.allergens = const <String>[],
  });
}

// In-cart item (one line in the mandjie)
class CartItemModel {
  final String id; // mand_id from mandjie table
  final FoodItemModel foodItem;
  int quantity;
  final String? weekDag;

  CartItemModel({
    required this.id,
    required this.foodItem,
    this.quantity = 1,
    this.weekDag,
  });
}

// Diet conflict representation for modal warnings
class _DietConflict {
  final String itemName;
  final String reason;
  const _DietConflict({required this.itemName, required this.reason});
}

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // Wallet balance (includes allowance - same field)
  double walletBalance = 0.0;

  // Cart loaded from DB
  final List<CartItemModel> cart = <CartItemModel>[];

  String? pickupLocation;
  final List<String> pickupLocations = <String>[]; // dynamic from DB
  bool pickupLoading = false;
  String? pickupError;

  bool loading = true;

  // expose setter for pickup from child
  void _setPickup(String? v) => setState(() => pickupLocation = v);

  bool get cartIsEmpty => cart.isEmpty;
  List<CartItemModel> get unavailableItems => cart.where((c) => !c.foodItem.available).toList();
  double get subtotal => cart.fold(0.0, (double sum, CartItemModel c) => sum + (c.foodItem.price * c.quantity));
  double get deliveryFee => 0.0; // pickup is free
  double get total => subtotal + deliveryFee;
  bool get hasSufficientFunds => walletBalance >= total;
  List<String> userDietPrefs = const <String>[];

  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  Future<void> _loadEverything() async {
    setState(() => loading = true);
    await _loadWalletBalance();
    await _loadCart();
    await _loadPickupLocations();
    await _loadUserDietPrefs();
    setState(() => loading = false);
  }

  Future<void> _loadUserDietPrefs() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      userDietPrefs = const <String>[];
      return;
    }
    try {
      // Try join to DIEET_VEREISTE names if available; else empty
      final rows = await Supabase.instance.client
          .from('gebruiker_dieet_vereistes')
          .select('dieet:dieet_id(dieet_naam)')
          .eq('gebr_id', user.id);
      final List prefs = (rows is List) ? rows : const [];
      userDietPrefs = prefs
          .map((e) => (e['dieet']?['dieet_naam'] ?? '').toString().trim().toLowerCase())
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (_) {
      userDietPrefs = const <String>[];
    }
  }

  List<_DietConflict> _validateDietConflicts() {
    final List<_DietConflict> conflicts = <_DietConflict>[];
    if (userDietPrefs.isEmpty) return conflicts;

    bool requiresVegan = userDietPrefs.contains('vegan');
    bool requiresVegetarian = userDietPrefs.contains('vegetarian') || userDietPrefs.contains('vegetaries');
    final Set<String> allergenPrefs = userDietPrefs
        .where((p) => p != 'vegan' && p != 'vegetarian' && p != 'vegetaries')
        .toSet();

    for (final CartItemModel c in cart) {
      final name = c.foodItem.name;
      final List<String> ingredients = c.foodItem.ingredients.map((e) => e.toLowerCase()).toList();
      final List<String> allergens = c.foodItem.allergens.map((e) => e.toLowerCase()).toList();

      // Allergen conflicts
      for (final a in allergenPrefs) {
        if (allergens.contains(a) || ingredients.any((ing) => ing.contains(a))) {
          conflicts.add(_DietConflict(itemName: name, reason: 'Allergeen: $a'));
        }
      }

      // Simple vegan/vegetarian inference
      if (requiresVegan || requiresVegetarian) {
        final hasMeat = ingredients.any((ing) =>
            ing.contains('vleis') || ing.contains('beef') || ing.contains('chicken') || ing.contains('hoender') || ing.contains('pork') || ing.contains('spekvleis') || ing.contains('ham'));
        final hasDairyOrEgg = ingredients.any((ing) => ing.contains('milk') || ing.contains('melk') || ing.contains('kaas') || ing.contains('cheese') || ing.contains('egg') || ing.contains('eier'));
        if (requiresVegan && (hasMeat || hasDairyOrEgg)) {
          conflicts.add(_DietConflict(itemName: name, reason: 'Konflik met vegan'));
        } else if (requiresVegetarian && hasMeat) {
          conflicts.add(_DietConflict(itemName: name, reason: 'Konflik met vegetaries'));
        }
      }
    }
    return conflicts;
  }

  Future<bool> _confirmDietConflicts(List<_DietConflict> conflicts) async {
    if (conflicts.isEmpty) return true;
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text('Dieet/Allergeen waarskuwings'),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ons het moontlike konflikte gevind:'),
                    const SizedBox(height: 8),
                    ...conflicts.map((c) => Text('• ${c.itemName}: ${c.reason}')),
                    const SizedBox(height: 12),
                    const Text('Wil jy voortgaan met die bestelling?'),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Kanselleer'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Gaan voort'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> _confirmOrderSummary(List<_DietConflict> conflicts) async {
    // Final confirmation modal listing items, pickup and any warnings
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text('Bevestig Bestelling'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Items:'),
                    const SizedBox(height: 6),
                    ...cart.map((c) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text('${c.foodItem.name} × ${c.quantity}')),
                            Text('R${(c.foodItem.price * c.quantity).toStringAsFixed(2)}'),
                          ],
                        )),
                    const Divider(height: 16),
                    Text('Afhaallokasie: ${pickupLocation ?? '-'}'),
                    const SizedBox(height: 8),
                    if (conflicts.isNotEmpty) ...[
                      const Text('Waarskuwings:', style: TextStyle(color: Colors.orange)),
                      const SizedBox(height: 4),
                      ...conflicts.map((c) => Text('• ${c.itemName}: ${c.reason}', style: const TextStyle(fontSize: 12))),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Totaal:'),
                        Text('R${total.toStringAsFixed(2)}', style: AppTypography.titleSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Wysig Mandjie')),
                ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Bevestig')),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _loadPickupLocations() async {
    setState(() {
      pickupLoading = true;
      pickupError = null;
    });
    try {
      final data = await sl<KampusRepository>().kryKampusse();
      final names = (data)
          .where((m) => m != null && m!['kampus_naam'] != null)
          .map((m) => m!['kampus_naam'].toString().trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      setState(() {
        pickupLocations
          ..clear()
          ..addAll(names);
        pickupLocation = pickupLocations.isNotEmpty ? pickupLocations.first : null;
        pickupLoading = false;
      });
    } catch (e) {
      setState(() {
        pickupError = e.toString();
        pickupLocations.clear();
        pickupLocation = null;
        pickupLoading = false;
      });
    }
  }

  Future<void> _loadWalletBalance() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      walletBalance = 0.0;
      return;
    }
    try {
      final row = await Supabase.instance.client
          .from('gebruikers')
          .select('beursie_balans')
          .eq('gebr_id', user.id)
          .maybeSingle();
      if (row != null && row is Map<String, dynamic>) {
        final raw = row['beursie_balans'];
        if (raw is num) {
          walletBalance = raw.toDouble();
        } else {
          walletBalance = double.tryParse('$raw') ?? 0.0;
        }
      } else {
        walletBalance = 0.0;
      }
    } catch (_) {
      walletBalance = 0.0;
    }
  }

  Future<void> _loadCart() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() {
        cart.clear();
      });
      return;
    }

    try {
      // select mandjie rows for the user and join kos_item fields
      final data = await Supabase.instance.client.from('mandjie').select(r'''
        mand_id,
        qty,
        week_dag_naam,
        kos_item: kos_item_id (
          kos_item_id,
          kos_item_naam,
          kos_item_koste,
          kos_item_prentjie,
          is_aktief,
          kos_item_bestandele,
          kos_item_allergene
        )
      ''').eq('gebr_id', user.id);


      final List<Map<String, dynamic>> rows = List<Map<String, dynamic>>.from(data as List);

      final List<CartItemModel> loaded = rows.map((r) {
        final kos = r['kos_item'] as Map<String, dynamic>? ?? <String, dynamic>{};
        final List<String> parsedIngredients = _parseIngredients(kos['kos_item_bestandele']);
        final List<String> parsedAllergens = _parseList(kos['kos_item_allergene']);

        final food = FoodItemModel(
          id: (kos['kos_item_id'] ?? '').toString(),
          name: (kos['kos_item_naam'] ?? 'Onbekende Item').toString(),
          imageUrl: kos['kos_item_prentjie']?.toString(),
          price: (kos['kos_item_koste'] is num) ? (kos['kos_item_koste'] as num).toDouble() : double.tryParse('${kos['kos_item_koste']}') ?? 0.0,
          available: kos.containsKey('is_aktief') ? (kos['is_aktief'] == true || kos['is_aktief'].toString().toLowerCase() == 'true') : true,
          ingredients: parsedIngredients,
          allergens: parsedAllergens,
        );

        return CartItemModel(
          id: r['mand_id'].toString(),
          foodItem: food,
          quantity: (r['qty'] is int) ? r['qty'] as int : int.tryParse('${r['qty']}') ?? 1,
          weekDag: r['week_dag_naam']?.toString(),
        );
      }).toList();

      setState(() {
        cart
          ..clear()
          ..addAll(loaded);
      });
      // Update global badge count (sum of quantities)
      final totalCount = cart.fold<int>(0, (s, c) => s + c.quantity);
      CartBadgeState.count.value = totalCount;
    } catch (e) {
      // if error, keep existing cart or clear - show snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kon nie mandjie laai nie: $e')));
      }
    }
  }

  List<String> _parseList(dynamic raw) {
    if (raw == null) return const <String>[];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    final s = raw.toString().trim();
    if (s.startsWith('{') && s.endsWith('}')) {
      return s.substring(1, s.length - 1).split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }
    return s.split(RegExp(r'[;,\n]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  List<String> _parseIngredients(dynamic raw) {
    return _parseList(raw);
  }

  void updateCartQuantity(String itemId, int newQuantity) async {
    // keep UI responsive
    setState(() {
      final CartItemModel item = cart.firstWhere((c) => c.id == itemId);
      if (newQuantity <= 0) {
        // remove locally (DB delete will follow)
        cart.removeWhere((c) => c.id == itemId);
      } else {
        item.quantity = newQuantity.clamp(0, 10);
      }
    });

    try {
      if (newQuantity <= 0) {
        await Supabase.instance.client.from('mandjie').delete().eq('mand_id', itemId);
      } else {
        await Supabase.instance.client.from('mandjie').update({'qty': newQuantity}).eq('mand_id', itemId);
      }
    } catch (e) {
      // Rollback UI change by reloading cart
      await _loadCart();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kon nie hoeveelheid opdateer nie: $e')));
    }

    // refresh wallet just in case
    await _loadWalletBalance();
    // update global badge after change
    CartBadgeState.count.value = cart.fold<int>(0, (s, c) => s + c.quantity);
    if (mounted) setState(() {});
  }

  void removeFromCart(String itemId) async {
    setState(() => cart.removeWhere((c) => c.id == itemId));
    try {
      await Supabase.instance.client.from('mandjie').delete().eq('mand_id', itemId);
    } catch (e) {
      await _loadCart();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Kon nie item verwyder nie: $e')));
    }
    await _loadWalletBalance();
    CartBadgeState.count.value = cart.fold<int>(0, (s, c) => s + c.quantity);
  }

  Future<String> _ensureTransTypeId(String name) async {
    final sb = Supabase.instance.client;
    // Try to find the transaksie tipe by name
    final row = await sb.from('transaksie_tipe').select('trans_tipe_id').eq('trans_tipe_naam', name).maybeSingle();
    if (row != null && row is Map<String, dynamic> && row['trans_tipe_id'] != null) {
      return row['trans_tipe_id'].toString();
    }
    // If not found, insert it (so we always have the uuid)
    final inserted = await sb.from('transaksie_tipe').insert({'trans_tipe_naam': name}).select().maybeSingle();
    if (inserted != null && inserted['trans_tipe_id'] != null) {
      return inserted['trans_tipe_id'].toString();
    }
    throw Exception('Kon transaksie tipe nie kry of skep nie ($name).');
  }

Future<bool> placeOrder(String pickup) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return false;

  if (cart.isEmpty) return false;

  final sb = Supabase.instance.client;
  final double orderTotal = subtotal;

  // Load latest balance
  await _loadWalletBalance();
  if (walletBalance < orderTotal) return false;

  try {
    // 1️⃣ Ensure transaksie_tipe 'uitbetaling'
    final transTypeId = await _ensureTransTypeId('uitbetaling');

    // 2️⃣ Create bestelling
    final bestellingInsert = await sb.from('bestelling').insert({
      'gebr_id': user.id,
      'best_volledige_prys': orderTotal,
    }).select().maybeSingle();

    if (bestellingInsert == null || bestellingInsert['best_id'] == null) {
      throw Exception('Kon nie bestelling skep nie.');
    }
    final String bestId = bestellingInsert['best_id'].toString();

    // 3️⃣ Insert bestelling_kos_item rows
    final List<Map<String, dynamic>> bkItems = cart.map((c) {
      return {
        'best_id': bestId,
        'kos_item_id': c.foodItem.id,
        'item_hoev': c.quantity,
      };
    }).toList();

    final insertedItems = await sb.from('bestelling_kos_item').insert(bkItems).select();
    if (insertedItems == null) throw Exception('Kon items nie insit nie.');

    // 4️⃣ Insert status for each item ('Bestelling Ontvang')
    const String initialStatusId = 'aef58a24-1a1d-4940-8855-df4c35ae5d5e';
    final List<Map<String, dynamic>> statusInserts = List.generate(insertedItems.length, (i) {
      final bestKosId = insertedItems[i]['best_kos_id'];
      return {
        'best_kos_id': bestKosId,
        'kos_stat_id': initialStatusId,
      };
    });

    await sb.from('best_kos_item_statusse').insert(statusInserts);

    // 5️⃣ Record beursie_transaksie
    await sb.from('beursie_transaksie').insert({
      'gebr_id': user.id,
      'trans_bedrag': orderTotal,
      'trans_tipe_id': transTypeId,
      'trans_beskrywing': 'Bestelling $bestId - afhaallokasie: $pickup',
    });

    // 6️⃣ Update wallet
    final double newBal = walletBalance - orderTotal;
    await sb.from('gebruikers').update({'beursie_balans': newBal}).eq('gebr_id', user.id);

    // 7️⃣ Clear mandjie
    await sb.from('mandjie').delete().eq('gebr_id', user.id);

    // 8️⃣ Update local state
    setState(() {
      walletBalance = newBal;
      cart.clear();
    });

    return true;
  } catch (e) {
    debugPrint('Fout tydens plaasBestelling: $e');
    await _loadEverything(); // reload to reflect DB state
    return false;
  }
}

// (pickup helper widget removed; using inline UI)



  @override
  Widget build(BuildContext context) {
    // If loading, show same UI but with progress
    if (loading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                    return Semantics(
                      button: true,
                      label: 'Open detail vir ${item.foodItem.name}',
                      child: InkWell(
                        onTap: () {
                          final wrapper = {
                            'kos_item': {
                              'kos_item_id': item.foodItem.id,
                              'kos_item_naam': item.foodItem.name,
                              'kos_item_koste': item.foodItem.price,
                              'kos_item_prentjie': item.foodItem.imageUrl,
                              'is_aktief': item.foodItem.available,
                              'kos_item_bestandele': item.foodItem.ingredients,
                              'kos_item_allergene': item.foodItem.allergens,
                            },
                            'week_dag_naam': item.weekDag,
                          };
                          context.push('/food-detail', extra: wrapper);
                        },
                        child: Card(
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
                            if (item.weekDag != null && item.weekDag!.isNotEmpty)
                              Text(
                                'Vir: ${item.weekDag}',
                                style: AppTypography.bodySmall.copyWith(color: Colors.black54),
                              ),
                          ],
                        ),
                          ),
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

                // Pickup Location (dynamic from DB)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: const <Widget>[
                            Icon(Icons.location_on_outlined, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text('Afhaallokasie', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (pickupLoading) const LinearProgressIndicator(),
                        if (!pickupLoading && pickupLocations.isEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Geen afhaal plekke beskikbaar', style: TextStyle(color: Colors.black54)),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _loadPickupLocations,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Probeer weer'),
                              ),
                            ],
                          )
                        else if (!pickupLoading)
                          DropdownButtonFormField<String>(
                            value: pickupLocation,
                            items: pickupLocations
                                .map((l) => DropdownMenuItem<String>(value: l, child: Text(l)))
                                .toList(),
                            onChanged: (v) => setState(() => pickupLocation = v),
                            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Kies afhaallokasie'),
                          ),
                        if (pickupError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(pickupError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
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
                    : () async {
                        final conflicts = _validateDietConflicts();
                        final proceed = await _confirmDietConflicts(conflicts);
                        if (!proceed) return;
                        if (conflicts.isNotEmpty) {
                          // Log warning locally
                          debugPrint('Diet conflicts acknowledged: ${conflicts.map((c) => '${c.itemName}:${c.reason}').join('; ')}');
                        }
                        final confirm = await _confirmOrderSummary(conflicts);
                        if (!confirm) return;
                        final bool success = await placeOrder(pickupLocation!);
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
