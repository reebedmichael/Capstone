import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../locator.dart';
import 'package:spys_api_client/spys_api_client.dart';
import '../../../../shared/state/cart_badge.dart';
import '../../../../shared/state/order_refresh_notifier.dart';
// removed embedded widget; pickup UI now inline above

// Cart item food model (includes ingredients/allergens for diet checks and detail page)
class FoodItemModel {
  final String id;
  final String name;
  final String?
  imageUrl; // Network images disabled for offline/dev environments
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
  bool isPlacingOrder = false; // Prevent multiple order submissions

  // expose setter for pickup from child (unused but kept for potential future use)
  // void _setPickup(String? v) => setState(() => pickupLocation = v);

  bool get cartIsEmpty => cart.isEmpty;
  List<CartItemModel> get unavailableItems =>
      cart.where((c) => !c.foodItem.available).toList();
  double get subtotal => cart.fold(
    0.0,
    (double sum, CartItemModel c) => sum + (c.foodItem.price * c.quantity),
  );
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
      // Load user's diet preferences using proper join
      final rows = await Supabase.instance.client
          .from('gebruiker_dieet_vereistes')
          .select('''
            dieet_vereiste:dieet_id(
              dieet_id,
              dieet_naam
            )
          ''')
          .eq('gebr_id', user.id);
      
      final List prefs = rows;
      userDietPrefs = prefs
          .map((e) => (e['dieet_vereiste']?['dieet_id'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('Kon nie gebruiker dieet voorkeure laai nie: $e');
      userDietPrefs = const <String>[];
    }
  }

  Future<List<_DietConflict>> _validateDietConflicts() async {
    final List<_DietConflict> conflicts = <_DietConflict>[];
    if (userDietPrefs.isEmpty) return conflicts;

    // Get unique food items to avoid duplicate validation
    final Set<String> processedItems = <String>{};
    
    // For each cart item, check if it conflicts with user's diet preferences
    for (final CartItemModel c in cart) {
      final name = c.foodItem.name;
      final kosItemId = c.foodItem.id;
      
      // Only validate each unique food item once
      if (!processedItems.contains(kosItemId)) {
        processedItems.add(kosItemId);
        // Check if this item has diet restrictions that conflict with user preferences
        await _checkItemDietConflicts(kosItemId, name, conflicts);
      }
    }
    return conflicts;
  }

  Future<void> _checkItemDietConflicts(String kosItemId, String itemName, List<_DietConflict> conflicts) async {
    try {
      // Get diet types for this food item
      final itemDiets = await Supabase.instance.client
          .from('kos_item_dieet_vereistes')
          .select('dieet_id')
          .eq('kos_item_id', kosItemId);
      
      final itemDietIds = itemDiets
          .map<String>((row) => row['dieet_id'].toString())
          .toList();
      
      // Collect all missing diet requirements for this item
      final List<String> missingDiets = [];
      
      // Check if user has diet preferences that are NOT satisfied by this item
      for (final userDietId in userDietPrefs) {
        if (!itemDietIds.contains(userDietId)) {
          // Get diet name for better error message
          final dietInfo = await Supabase.instance.client
              .from('dieet_vereiste')
              .select('dieet_naam')
              .eq('dieet_id', userDietId)
              .maybeSingle();
          
          final dietName = dietInfo?['dieet_naam'] ?? 'Onbekende dieet';
          missingDiets.add(dietName);
        }
      }
      
      // Only add one conflict per item, combining all missing diet requirements
      if (missingDiets.isNotEmpty) {
        final reason = missingDiets.length == 1 
            ? 'Nie geskik vir ${missingDiets.first} nie'
            : 'Nie geskik vir ${missingDiets.join(', ')} nie';
        
        conflicts.add(_DietConflict(
          itemName: itemName, 
          reason: reason
        ));
      }
    } catch (e) {
      debugPrint('Kon nie dieet konflik nagaan vir $itemName nie: $e');
      // Fallback to ingredient-based validation for backward compatibility
      _fallbackIngredientValidation(itemName, conflicts);
    }
  }

  void _fallbackIngredientValidation(String itemName, List<_DietConflict> conflicts) {
    // Keep the original ingredient-based validation as fallback
    // This is a simplified version for when DB queries fail
    conflicts.add(_DietConflict(
      itemName: itemName, 
      reason: 'Kon nie dieet inligting verifieer nie - gaan voort met versigtigheid'
    ));
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
                    ...conflicts.map(
                      (c) => Text('• ${c.itemName}: ${c.reason}'),
                    ),
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
                    ...cart.map(
                      (c) => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text('${c.foodItem.name} × ${c.quantity}'),
                          ),
                          Text(
                            'R${(c.foodItem.price * c.quantity).toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 16),
                    Text('Afhaallokasie: ${pickupLocation ?? '-'}'),
                    const SizedBox(height: 8),
                    if (conflicts.isNotEmpty) ...[
                      Text(
                        'Waarskuwings:',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dieet/Allergeen konflikte is reeds bevestig',
                        style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Totaal:'),
                        Text(
                          'R${total.toStringAsFixed(2)}',
                          style: AppTypography.titleSmall.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Wysig Mandjie'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Bevestig'),
                ),
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
          .where((m) => m != null && m['kampus_naam'] != null)
          .map((m) => m!['kampus_naam'].toString().trim())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      setState(() {
        pickupLocations
          ..clear()
          ..addAll(names);
        pickupLocation = pickupLocations.isNotEmpty
            ? pickupLocations.first
            : null;
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
      if (row != null) {
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
      final data = await Supabase.instance.client
          .from('mandjie')
          .select(r'''
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
      ''')
          .eq('gebr_id', user.id);

      final List<Map<String, dynamic>> rows = List<Map<String, dynamic>>.from(
        data as List,
      );

      final List<CartItemModel> loaded = rows.map((r) {
        final kos =
            r['kos_item'] as Map<String, dynamic>? ?? <String, dynamic>{};
        final List<String> parsedIngredients = _parseIngredients(
          kos['kos_item_bestandele'],
        );
        final List<String> parsedAllergens = _parseList(
          kos['kos_item_allergene'],
        );

        final food = FoodItemModel(
          id: (kos['kos_item_id'] ?? '').toString(),
          name: (kos['kos_item_naam'] ?? 'Onbekende Item').toString(),
          imageUrl: kos['kos_item_prentjie']?.toString(),
          price: (kos['kos_item_koste'] is num)
              ? (kos['kos_item_koste'] as num).toDouble()
              : double.tryParse('${kos['kos_item_koste']}') ?? 0.0,
          available: kos.containsKey('is_aktief')
              ? (kos['is_aktief'] == true ||
                    kos['is_aktief'].toString().toLowerCase() == 'true')
              : true,
          ingredients: parsedIngredients,
          allergens: parsedAllergens,
        );

        return CartItemModel(
          id: r['mand_id'].toString(),
          foodItem: food,
          quantity: (r['qty'] is int)
              ? r['qty'] as int
              : int.tryParse('${r['qty']}') ?? 1,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Kon nie mandjie laai nie: $e')));
      }
    }
  }

  List<String> _parseList(dynamic raw) {
    if (raw == null) return const <String>[];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    final s = raw.toString().trim();
    if (s.startsWith('{') && s.endsWith('}')) {
      return s
          .substring(1, s.length - 1)
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return s
        .split(RegExp(r'[;,\n]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
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
        await Supabase.instance.client
            .from('mandjie')
            .delete()
            .eq('mand_id', itemId);
      } else {
        await Supabase.instance.client
            .from('mandjie')
            .update({'qty': newQuantity})
            .eq('mand_id', itemId);
      }
      
      // Trigger global refresh to update cart badge and notifications
      OrderRefreshNotifier().triggerRefresh();
    } catch (e) {
      // Rollback UI change by reloading cart
      await _loadCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kon nie hoeveelheid opdateer nie: $e')),
        );
      }
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
      await Supabase.instance.client
          .from('mandjie')
          .delete()
          .eq('mand_id', itemId);
      
      // Trigger global refresh to update cart badge and notifications
      OrderRefreshNotifier().triggerRefresh();
    } catch (e) {
      await _loadCart();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kon nie item verwyder nie: $e')),
        );
      }
    }
    await _loadWalletBalance();
    CartBadgeState.count.value = cart.fold<int>(0, (s, c) => s + c.quantity);
  }

  Future<String> _ensureTransTypeId(String name) async {
    final sb = Supabase.instance.client;
    // Try to find the transaksie tipe by name
    final row = await sb.from('transaksie_tipe').select('trans_tipe_id').eq('trans_tipe_naam', name).maybeSingle();
    if (row != null && row['trans_tipe_id'] != null) {
      return row['trans_tipe_id'].toString();
    }
    // If not found, insert it (so we always have the uuid)
    final inserted = await sb
        .from('transaksie_tipe')
        .insert({'trans_tipe_naam': name})
        .select()
        .maybeSingle();
    if (inserted != null && inserted['trans_tipe_id'] != null) {
      return inserted['trans_tipe_id'].toString();
    }
    throw Exception('Kon transaksie tipe nie kry of skep nie ($name).');
  }


  /// Calculate the correct date for a food item based on its week_dag_naam
  /// This uses the same logic as the home page to determine the current menu week
  DateTime _calculateItemDate(String? weekDagNaam) {
    if (weekDagNaam == null || weekDagNaam.isEmpty) {
      // If no day specified, use current date
      return DateTime.now();
    }

    // Get the current menu week start (Monday)
    final now = DateTime.now();
    final weekday = now.weekday;
    final daysToSubtract = weekday - 1; // Monday is 1, so subtract (weekday - 1) days
    final currentWeekStart = DateTime(now.year, now.month, now.day - daysToSubtract);
    
    // Check if we should use next week's menu (same logic as home page)
    final hour = now.hour;
    final isSaturdayAfter17 = weekday == 6 && hour >= 17;
    final isPastWeekend = weekday == 7; // Sunday
    final shouldUseNextWeek = isSaturdayAfter17 || isPastWeekend;
    
    // Use next week if needed
    final weekStart = shouldUseNextWeek 
        ? currentWeekStart.add(const Duration(days: 7))
        : currentWeekStart;
    
    // Map day names to weekday numbers (Monday = 1, Sunday = 7)
    final dayMap = {
      'maandag': 1, 'dinsdag': 2, 'woensdag': 3, 'donderdag': 4,
      'vrydag': 5, 'saterdag': 6, 'sondag': 7
    };
    
    final dayNumber = dayMap[weekDagNaam.toLowerCase()];
    if (dayNumber == null) {
      // If day name not recognized, use current date
      return DateTime.now();
    }
    
    // Calculate the date for this day in the current menu week
    return weekStart.add(Duration(days: dayNumber - 1));
  }

  Future<bool> placeOrder(String pickup) async {
    debugPrint('Starting order placement for pickup: $pickup');

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => isPlacingOrder = false);
      return false;
    }

    if (cart.isEmpty) {
      setState(() => isPlacingOrder = false);
      return false;
    }

    final double orderTotal = subtotal;

    // Load latest balance
    await _loadWalletBalance();
    if (walletBalance < orderTotal) {
      setState(() => isPlacingOrder = false);
      return false;
    }

    try {
      debugPrint('Starting order placement...');
      
      // Add timeout to prevent hanging
      await Future.any([
        _performOrderPlacement(pickup, orderTotal, user.id),
        Future.delayed(const Duration(seconds: 30), () => throw TimeoutException('Order placement timed out after 30 seconds')),
      ]);
      
      debugPrint('Order placement completed successfully');
      return true;
    } catch (e) {
      debugPrint('Fout tydens plaasBestelling: $e');
      setState(() => isPlacingOrder = false); // Reset loading state on error
      await _loadEverything(); // reload to reflect DB state
      return false;
    } finally {
      // Ensure loading state is always reset
      debugPrint('Resetting isPlacingOrder flag');
      if (mounted) {
        setState(() {
          isPlacingOrder = false;
        });
      }
    }
  }

  Future<void> _performOrderPlacement(String pickup, double orderTotal, String userId) async {
    try {
      // 1️⃣ Ensure transaksie_tipe 'uitbetaling'
      debugPrint('Getting transaction type ID...');
      final transTypeId = await _ensureTransTypeId('uitbetaling').timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Transaction type lookup timed out'),
      );
      debugPrint('Transaction type ID: $transTypeId');

      // 2️⃣ Get kampus_id from pickup location name
      String? kampusId;
      try {
        kampusId = await sl<KampusRepository>().kryKampusID(pickup);
        debugPrint('Kampus ID for "$pickup": $kampusId');
      } catch (e) {
        debugPrint('Warning: Could not get kampus ID for "$pickup": $e');
        // Continue without kampus_id - order will still be created
      }

      // 3️⃣ Create bestelling with kampus_id
      final bestellingData = {
        'gebr_id': userId, 
        'best_volledige_prys': orderTotal,
        if (kampusId != null) 'kampus_id': kampusId,
      };
      
      final sb = Supabase.instance.client;
      debugPrint('Creating bestelling...');
      final bestellingInsert = await sb
          .from('bestelling')
          .insert(bestellingData)
          .select()
          .maybeSingle()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Bestelling creation timed out'),
          );

      if (bestellingInsert == null || bestellingInsert['best_id'] == null) {
        throw Exception('Kon nie bestelling skep nie.');
      }
      final String bestId = bestellingInsert['best_id'].toString();

      // 4️⃣ Insert bestelling_kos_item rows with correct dates and daily order numbers
      debugPrint('Creating bestelling_kos_item rows...');
      final List<Map<String, dynamic>> bkItems = [];
      
      for (final c in cart) {
        // Calculate the correct date for this food item based on its week_dag_naam
        debugPrint('Calculating date for item: ${c.foodItem.name}, weekDag: ${c.weekDag}');
        final correctDate = _calculateItemDate(c.weekDag);
        debugPrint('Calculated date: $correctDate');
        
        // Generate daily order number for this food item
        final dailyOrderNumber = await _generateDailyOrderNumber(c.foodItem.id, c.weekDag);
        debugPrint('Generated daily order number: $dailyOrderNumber');
        
        bkItems.add({
          'best_id': bestId,
          'kos_item_id': c.foodItem.id,
          'item_hoev': c.quantity,
          'best_datum': correctDate.toIso8601String(), // Set the actual date the item is for
          'best_kos_is_liked': false, // Default to not liked
          'best_nommer': dailyOrderNumber, // Add daily order number
        });
      }

      debugPrint('Inserting bestelling_kos_item rows...');
      final insertedItems = await sb.from('bestelling_kos_item').insert(bkItems).select().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('Bestelling_kos_item insertion timed out'),
      );
      debugPrint('Inserted ${insertedItems.length} items');
      if (insertedItems.isEmpty) throw Exception('Kon items nie insit nie.');

      // 5️⃣ Insert status for each item ('Bestelling Ontvang')
      const String initialStatusId = 'aef58a24-1a1d-4940-8855-df4c35ae5d5e';
      final List<Map<String, dynamic>> statusInserts = List.generate(
        insertedItems.length,
        (i) {
          final bestKosId = insertedItems[i]['best_kos_id'];
          return {'best_kos_id': bestKosId, 'kos_stat_id': initialStatusId};
        },
      );

      await sb.from('best_kos_item_statusse').insert(statusInserts);

      // 6️⃣ Record beursie_transaksie (negative amount for uitbetaling)
      await sb.from('beursie_transaksie').insert({
        'gebr_id': userId,
        'trans_bedrag': -orderTotal, // Negative amount for uitbetaling (money going out)
        'trans_tipe_id': transTypeId,
        'trans_beskrywing': 'Bestelling $bestId - afhaallokasie: $pickup',
        'trans_geskep_datum': DateTime.now().toIso8601String(), // Explicitly set transaction date
      });

      // 7️⃣ Update wallet
      final double newBal = walletBalance - orderTotal;
      await sb
          .from('gebruikers')
          .update({'beursie_balans': newBal})
          .eq('gebr_id', userId);

      // 8️⃣ Clear mandjie
      await sb.from('mandjie').delete().eq('gebr_id', userId);

      // Trigger global refresh to update cart badge and notifications
      OrderRefreshNotifier().triggerRefresh();

      // 9️⃣ Update local state
      debugPrint('Order placement successful! Updating UI...');
      setState(() {
        walletBalance = newBal;
        cart.clear();
      });

      debugPrint('Order placement completed successfully');
    } catch (e) {
      debugPrint('Fout in _performOrderPlacement: $e');
      await _loadEverything(); // reload to reflect DB state
      rethrow; // Re-throw to be caught by the timeout wrapper
    }
  }

  // (pickup helper widget removed; using inline UI)

  @override
  Widget build(BuildContext context) {
    // If loading, show same UI but with progress
    if (loading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Empty State
    if (cartIsEmpty) {
      return Scaffold(
        body: Column(
          children: <Widget>[
            Container(
              color: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onPrimary),
                      onPressed: () => context.go('/home'),
                    ),
                    Text(
                      'Mandjie',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
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
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Jou mandjie is leeg',
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Voeg items by jou mandjie om te begin bestel',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.go('/home'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                        ),
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
              Theme.of(context).colorScheme.primary.withOpacity(0.05),
              Theme.of(context).colorScheme.secondary.withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: Spacing.screenPadding(context).copyWith(
              bottom: ResponsiveUtils.getResponsiveSpacing(context, 
                mobile: ResponsiveUtils.isSmallScreen(context) ? 120 : 140, 
                tablet: 160, 
                desktop: 180
              ),
            ),
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
                    Text(
                      'Mandjie (${cart.length})',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: ResponsiveUtils.getResponsiveFontSize(context, mobile: 18, tablet: 20, desktop: 22),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),

                const SizedBox(height: 12),

                // Unavailable Items Alert
                if (unavailableItems.isNotEmpty)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: Theme.of(context).colorScheme.error),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Let wel: ${unavailableItems.length} item(s) in jou mandjie is nie meer beskikbaar nie en sal verwyder word.',
                              style: AppTypography.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
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
                            padding: EdgeInsets.all(ResponsiveUtils.isSmallScreen(context) ? 8 : 12),
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
                                              width: ResponsiveUtils.isSmallScreen(context) ? 56 : 64,
                                              height: ResponsiveUtils.isSmallScreen(context) ? 56 : 64,
                                              fit: BoxFit.cover,
                                            )
                                          else
                                            Container(
                                              width: ResponsiveUtils.isSmallScreen(context) ? 56 : 64,
                                              height: ResponsiveUtils.isSmallScreen(context) ? 56 : 64,
                                              color: Theme.of(context).colorScheme.surfaceVariant,
                                              alignment: Alignment.center,
                                              child: Icon(
                                                Icons.fastfood,
                                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          if (!item.foodItem.available)
                                            Container(
                                              width: ResponsiveUtils.isSmallScreen(context) ? 56 : 64,
                                              height: ResponsiveUtils.isSmallScreen(context) ? 56 : 64,
                                              color: Theme.of(context).colorScheme.onSurface.withOpacity(
                                                0.5,
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                'Uit',
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            item.foodItem.name,
                                            style: AppTypography.labelLarge
                                                .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: Theme.of(context).colorScheme.onSurface,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'R${item.foodItem.price.toStringAsFixed(2)} elk',
                                            style: AppTypography.bodySmall
                                                .copyWith(
                                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54),
                                                ),
                                          ),
                                          if (!item.foodItem.available)
                                            Text(
                                              'Nie meer beskikbaar nie',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Theme.of(context).colorScheme.error,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    // Quantity controls
                                    Row(
                                      children: <Widget>[
                                        OutlinedButton(
                                          onPressed: item.quantity > 1 
                                            ? () => updateCartQuantity(
                                                item.id,
                                                item.quantity - 1,
                                              )
                                            : null,
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: ResponsiveUtils.isSmallScreen(context) 
                                              ? const Size(28, 28) 
                                              : const Size(32, 32),
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: Icon(
                                            Icons.remove,
                                            size: 16,
                                            color: item.quantity > 1 
                                              ? null 
                                              : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                          ),
                                        ),
                                        SizedBox(
                                          width: ResponsiveUtils.isSmallScreen(context) ? 28 : 32,
                                          child: Center(
                                            child: Text(
                                              '${item.quantity}',
                                              style: AppTypography.labelLarge.copyWith(color: Theme.of(context).colorScheme.onSurface),
                                            ),
                                          ),
                                        ),
                                        OutlinedButton(
                                          onPressed:
                                              item.foodItem.available &&
                                                  item.quantity < 10
                                              ? () => updateCartQuantity(
                                                  item.id,
                                                  item.quantity + 1,
                                                )
                                              : null,
                                          style: OutlinedButton.styleFrom(
                                            minimumSize: ResponsiveUtils.isSmallScreen(context) 
                                              ? const Size(28, 28) 
                                              : const Size(32, 32),
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            size: 16,
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              removeFromCart(item.id),
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: Theme.of(context).colorScheme.error,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                // Item total
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    Text(
                                      'R${(item.foodItem.price * item.quantity).toStringAsFixed(2)}',
                                      style: AppTypography.labelLarge.copyWith(color: Theme.of(context).colorScheme.onSurface),
                                    ),
                                  ],
                                ),
                                if (item.weekDag != null &&
                                    item.weekDag!.isNotEmpty)
                                  Text(
                                    'Vir: ${item.weekDag}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54),
                                    ),
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
                    side: BorderSide(color: Theme.of(context).colorScheme.primary),
                    foregroundColor: Theme.of(context).colorScheme.primary,
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
                          children: <Widget>[
                            Icon(
                              Icons.location_on_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Afhaallokasie',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (pickupLoading) const LinearProgressIndicator(),
                        if (!pickupLoading && pickupLocations.isEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Geen afhaal plekke beskikbaar',
                                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                              ),
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
                                .map(
                                  (l) => DropdownMenuItem<String>(
                                    value: l,
                                    child: Text(l),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => pickupLocation = v),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Kies afhaallokasie',
                            ),
                          ),
                        if (pickupError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              pickupError!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                            ),
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
                        Text(
                          'Bestelling Opsomming',
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('Subtotaal:', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                            Text('R${subtotal.toStringAsFixed(2)}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('Afhaalkoste:', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                            Text(
                              'Gratis',
                              style: TextStyle(color: Theme.of(context).colorScheme.primary),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Totaal:',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                            ),
                            Text(
                              'R${total.toStringAsFixed(2)}',
                              style: AppTypography.titleSmall.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Wallet Balance info
                Card(
                  color: hasSufficientFunds
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Beursie Balans',
                              style: TextStyle(
                                fontWeight: FontWeight.w600, 
                                color: hasSufficientFunds 
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).colorScheme.onError
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'R${walletBalance.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: hasSufficientFunds 
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Theme.of(context).colorScheme.onError
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (!hasSufficientFunds)
                              Text(
                                'Kort: R${(total - walletBalance).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              )
                            else if (cart.isNotEmpty)
                              Text(
                                'Na betaling: R${(walletBalance - total).toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                          ],
                        ),
                        if (!hasSufficientFunds)
                          OutlinedButton(
                            onPressed: () => context.go('/wallet'),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.white),
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.white.withOpacity(0.1),
                            ),
                            child: const Text(
                              'Laai Beursie',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          Text(
                            'Voldoende fondse',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
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
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.12))),
          color: Theme.of(context).colorScheme.surface,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.isSmallScreen(context) ? 12 : 16,
          vertical: ResponsiveUtils.isSmallScreen(context) ? 12 : 16,
        ),
        child: SafeArea(
          top: false,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Totaal te betaal:',
                    style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                  ),
                  Text(
                    'R${total.toStringAsFixed(2)}',
                    style: AppTypography.titleMedium.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed:
                    (isPlacingOrder || // Disable when placing order
                        !hasSufficientFunds ||
                        pickupLocation == null ||
                        unavailableItems.isNotEmpty)
                    ? null
                    : () async {
                        // Prevent multiple rapid button presses
                        if (isPlacingOrder) {
                          debugPrint('Order already being processed, ignoring duplicate request');
                          return;
                        }
                        
                        // Set flag immediately to prevent multiple clicks
                        setState(() {
                          isPlacingOrder = true;
                        });
                        
                        try {
                          final conflicts = await _validateDietConflicts();
                          final proceed = await _confirmDietConflicts(conflicts);
                          if (!proceed) {
                            setState(() => isPlacingOrder = false);
                            return;
                          }
                          if (conflicts.isNotEmpty) {
                            // Log warning locally
                            debugPrint(
                              'Diet conflicts acknowledged: ${conflicts.map((c) => '${c.itemName}:${c.reason}').join('; ')}',
                            );
                          }
                          final confirm = await _confirmOrderSummary(conflicts);
                          if (!confirm) {
                            setState(() => isPlacingOrder = false);
                            return;
                          }
                          final bool success = await placeOrder(pickupLocation!);
                          if (success) {
                            // Order completed successfully, navigate to orders page
                            context.go('/orders');
                          } else {
                            // Order failed, reset the flag
                            setState(() => isPlacingOrder = false);
                          }
                        } catch (e) {
                          setState(() => isPlacingOrder = false);
                          debugPrint('Error in order process: $e');
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  minimumSize: ResponsiveUtils.isSmallScreen(context) 
                    ? const Size(120, 44) 
                    : const Size(140, 48),
                ),
                child: isPlacingOrder 
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Plaas Bestelling...'),
                        ],
                      )
                    : const Text('Plaas Bestelling'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Generates a daily order number for a specific food item and day
  /// Format: YYYY-MM-DD-number (e.g., 2025-10-15-1)
  /// Each day starts at 1 and increments for that specific food item
  /// Uses the best_datum (when the order is for) not the current date
  Future<String> _generateDailyOrderNumber(String kosItemId, String? weekDagNaam) async {
    // Calculate the correct date for this food item based on its week_dag_naam
    final correctDate = _calculateItemDate(weekDagNaam);
    final dateString = '${correctDate.year}-${correctDate.month.toString().padLeft(2, '0')}-${correctDate.day.toString().padLeft(2, '0')}';
    
    final sb = Supabase.instance.client;
    
    // Find the highest order number for this food item for the specific order date
    final existingOrders = await sb
        .from('bestelling_kos_item')
        .select('best_nommer')
        .eq('kos_item_id', kosItemId)
        .eq('best_datum', correctDate.toIso8601String()) // Use the specific order date
        .not('best_nommer', 'is', null);
    
    int nextNumber = 1;
    if (existingOrders.isNotEmpty) {
      // Extract numbers from existing order numbers and find the highest
      final numbers = existingOrders
          .map((order) {
            final nommer = order['best_nommer']?.toString() ?? '';
            // Extract number from format like "2025-10-15-3"
            final parts = nommer.split('-');
            if (parts.length >= 4) {
              return int.tryParse(parts.last) ?? 0;
            }
            return 0;
          })
          .where((num) => num > 0)
          .toList();
      
      if (numbers.isNotEmpty) {
        nextNumber = numbers.reduce((a, b) => a > b ? a : b) + 1;
      }
    }
    
    return '$dateString-$nextNumber';
  }
}
