import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spys_api_client/spys_api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../locator.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../app/presentation/widgets/app_bottom_nav.dart';
import '../../../../shared/state/cart_badge.dart';
import '../../../../shared/state/order_refresh_notifier.dart';

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
  final days = ['Alle', 'Maandag', 'Dinsdag', 'Woensdag', 'Donderdag', 'Vrydag', 'Saterdag', 'Sondag'];
  List<Map<String, dynamic>> dietTypes = [{'dieet_id': 'alle', 'dieet_naam': 'Alle'}];

  Map<String, dynamic>? spyskaart;
  List<Map<String, dynamic>> allMenuItems =
      []; // each item = wrapper map (merged)
  List<Map<String, dynamic>> filteredMenuItems = [];
  bool isLoading = true;
  String searchQuery = '';
  Map<String, List<String>> itemDietMapping = {}; // kosItemId -> list of dietIds
  
  // Menu date and week transition logic
  DateTime? currentMenuDate;
  bool isNextWeekMenu = false;
  
  // Cache for menu data to prevent repeated API calls
  static Map<String, dynamic>? _cachedSpyskaart;
  static List<Map<String, dynamic>> _cachedMenuItems = [];
  static Map<String, List<String>> _cachedDietMappings = {};
  static DateTime? _cachedMenuDate;
  static bool _cachedIsNextWeekMenu = false;
  static DateTime? _lastCacheTime;
  
  // Timer for periodic cart cleanup
  Timer? _cartCleanupTimer;
  StreamSubscription? _globalRefreshSubscription;
  
  static const Duration _cacheTimeout = Duration(minutes: 5); // Cache for 5 minutes
  
  // Helper methods for date and week logic
  DateTime _getCurrentWeekStart() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final daysToSubtract = weekday - 1; // Monday is 1, so subtract (weekday - 1) days
    return DateTime(now.year, now.month, now.day - daysToSubtract);
  }
  
  DateTime _getNextWeekStart() {
    return _getCurrentWeekStart().add(const Duration(days: 7));
  }
  
  bool _shouldUseNextWeekMenu() {
    final now = DateTime.now();
    final weekday = now.weekday;
    final hour = now.hour;
    
    // Use next week menu if:
    // 1. It's Saturday (6) and after 17:00, OR
    // 2. It's Sunday (7) or later (past the weekend transition)
    final isSaturdayAfter17 = weekday == 6 && hour >= 17;
    final isPastWeekend = weekday == 7; // Sunday
    return isSaturdayAfter17 || isPastWeekend;
  }
  
  bool _isDayPastCutoff(String dayName) {
    final now = DateTime.now();
    
    // Map day names to weekday numbers (Monday = 1, Sunday = 7)
    final dayMap = {
      'maandag': 1, 'dinsdag': 2, 'woensdag': 3, 'donderdag': 4,
      'vrydag': 5, 'saterdag': 6, 'sondag': 7
    };
    
    final dayNumber = dayMap[dayName.toLowerCase()];
    if (dayNumber == null) return false;
    
    // Get the correct week start based on whether we're using next week menu
    final weekStart = _shouldUseNextWeekMenu() ? _getNextWeekStart() : _getCurrentWeekStart();
    
    // Calculate the date for this day in the current week
    final dayDate = weekStart.add(Duration(days: dayNumber - 1));
    
    // For each day, check if it's past 17:00 of the day BEFORE the menu item's day
    final dayBeforeMenuDate = dayDate.subtract(const Duration(days: 1));
    final cutoffDateTime = DateTime(dayBeforeMenuDate.year, dayBeforeMenuDate.month, dayBeforeMenuDate.day, 17, 0);
    
    // Debug logging
    debugPrint('Cutoff check for $dayName:');
    debugPrint('  Current time: $now');
    debugPrint('  Day date: $dayDate');
    debugPrint('  Day before: $dayBeforeMenuDate');
    debugPrint('  Cutoff time: $cutoffDateTime');
    debugPrint('  Is past cutoff: ${now.isAfter(cutoffDateTime)}');
    
    // Check if current time is after cutoff (17:00 SAST the day before the menu item)
    return now.isAfter(cutoffDateTime);
  }
  
  String _formatMenuDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mrt', 'Apr', 'Mei', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Des'
    ];

    // Get the start of the week (Monday)
    final weekStart = date.subtract(Duration(days: date.weekday - 1));
    // Get the end of the week (Sunday)
    final weekEnd = weekStart.add(const Duration(days: 6));

    final startMonth = months[weekStart.month - 1];
    final endMonth = months[weekEnd.month - 1];

    // Format: "6 Okt tot 12 Okt 2024"
    if (weekStart.month == weekEnd.month) {
      return '${weekStart.day} $startMonth tot ${weekEnd.day} $endMonth ${weekStart.year}';
    } else {
      return '${weekStart.day} $startMonth tot ${weekEnd.day} $endMonth ${weekStart.year}';
    }
  }



  @override
void initState() {
  super.initState();
  _loadGebrNaam();
  _loadDietTypes();
  _fetchMenu();
  _startCartCleanupTimer();
  _setupUserDataListener();
  _setupGlobalRefreshListener();
  Supabase.instance.client.auth.onAuthStateChange.listen((_) {
    _loadGebrNaam();
    _loadMandjieCount();
  });
}

@override
void dispose() {
  _cartCleanupTimer?.cancel();
  _globalRefreshSubscription?.cancel();
  super.dispose();
}

void _setupUserDataListener() {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;

  // Listen for changes to user data (like laaste_aktief_datum updates)
  Supabase.instance.client
      .from('gebruikers')
      .stream(primaryKey: ['gebr_id'])
      .eq('gebr_id', user.id)
      .listen((data) {
    // When user data changes, refresh user info
    debugPrint('User data changed, refreshing...');
    _loadGebrNaam();
    _loadMandjieCount();
  });
}

void _setupGlobalRefreshListener() {
  // Listen for global refresh events
  _globalRefreshSubscription = OrderRefreshNotifier().refreshStream.listen((_) {
    debugPrint('Global refresh triggered, updating user data...');
    _loadGebrNaam();
    _loadMandjieCount();
  });
}

void _startCartCleanupTimer() {
  _cartCleanupTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
    _checkAndCleanExpiredCartItems();
  });
}

Future<void> _checkAndCleanExpiredCartItems() async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Get all cart items
    final cartData = await Supabase.instance.client
        .from('mandjie')
        .select('mand_id, week_dag_naam')
        .eq('gebr_id', user.id);

    final List<Map<String, dynamic>> cartItems = List<Map<String, dynamic>>.from(cartData);
    final List<String> expiredDays = [];

    // Check each cart item for cutoff
    for (final cartItem in cartItems) {
      final weekDagNaam = cartItem['week_dag_naam']?.toString();
      if (weekDagNaam != null && _isDayPastCutoff(weekDagNaam)) {
        expiredDays.add(weekDagNaam);
      }
    }

    // Remove expired items only if there are any
    if (expiredDays.isNotEmpty) {
      await Supabase.instance.client
          .from('mandjie')
          .delete()
          .eq('gebr_id', user.id)
          .inFilter('week_dag_naam', expiredDays);

      // Update cart badge
      await _loadMandjieCount();

      // Show notification only if items were actually removed
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Sommige items is nie meer beskikbaar nie en is verwyder uit jou mandjie.'),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    }
  } catch (e) {
    debugPrint('Error checking expired cart items: $e');
  }
}

  Future<void> _loadMandjieCount() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final items = await sl<MandjieRepository>().kryMandjie(user.id);
      if (mounted) {
        setState(() => mandjieCount = items.length);
      }
    } catch (e) {
      debugPrint('Kon nie mandjie count kry nie: $e');
      if (mounted) {
        setState(() => mandjieCount = 0);
      }
    }
  }

  Future<void> _loadGebrNaam() async {
    if (mounted) {
      setState(() => gebrNaamLoading = true);
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          gebrNaam = null;
          gebrNaamLoading = false;
        });
      }
      return;
    }

    try {
      final row = await Supabase.instance.client
          .from('gebruikers')
          .select('gebr_naam')
          .eq('gebr_id', user.id)
          .maybeSingle();

    if (row != null) {
      if (mounted) {
        setState(() => gebrNaam = (row['gebr_naam'] ?? '').toString());
      }
    } else {
      if (mounted) {
        setState(() => gebrNaam = null);
      }
    }
  } catch (e) {
    debugPrint('Kon gebr_naam nie laai nie: $e');
    if (mounted) {
      setState(() => gebrNaam = null);
    }
  } finally {
    if (mounted) {
      setState(() => gebrNaamLoading = false);
    }
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
    
    // Check if we have valid cached data
    final now = DateTime.now();
    if (_cachedSpyskaart != null && 
        _lastCacheTime != null && 
        now.difference(_lastCacheTime!) < _cacheTimeout) {
      setState(() {
        spyskaart = _cachedSpyskaart;
        allMenuItems = _cachedMenuItems;
        itemDietMapping = _cachedDietMappings;
        currentMenuDate = _cachedMenuDate;
        isNextWeekMenu = _cachedIsNextWeekMenu;
        _applyFilters();
        isLoading = false;
      });
      return;
    }
    
    try {
      // Determine which week to fetch based on current time
      final shouldUseNextWeek = _shouldUseNextWeekMenu();
      final targetWeekStart = shouldUseNextWeek ? _getNextWeekStart() : _getCurrentWeekStart();
      
      final spyskaartData = await sl<SpyskaartRepository>()
          .getAktieweSpyskaart(targetWeekStart);
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

        // Set menu date and week info
        final menuDate = DateTime.tryParse(spyskaartData['spyskaart_datum'] ?? '') ?? targetWeekStart;
        debugPrint('Menu date set to: $menuDate (from spyskaart_datum: ${spyskaartData['spyskaart_datum']})');
        
        // Only clear cart if this is an actual week transition (not just a page refresh)
        // We'll check if the user has items from a previous week that are now expired
        await _checkAndCleanExpiredCartItems();
        
        // Cache the data
        _cachedSpyskaart = spyskaartData;
        _cachedMenuItems = mappedItems;
        _cachedDietMappings = itemDietMapping;
        _cachedMenuDate = menuDate;
        _cachedIsNextWeekMenu = shouldUseNextWeek;
        _lastCacheTime = now;

        setState(() {
          spyskaart = spyskaartData;
          allMenuItems = mappedItems;
          currentMenuDate = menuDate;
          isNextWeekMenu = shouldUseNextWeek;
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
      
      // Extract all kos_item_ids
      final kosItemIds = items
          .map((item) => item['kos_item_id']?.toString())
          .where((id) => id != null)
          .toList();
      
      if (kosItemIds.isEmpty) {
        itemDietMapping = mappings;
        return;
      }
      
      // Single query to get all diet mappings at once
      final response = await Supabase.instance.client
          .from('kos_item_dieet_vereistes')
          .select('kos_item_id, dieet_id')
          .inFilter('kos_item_id', kosItemIds);
      
      // Group by kos_item_id
      for (final row in response) {
        final kosItemId = row['kos_item_id']?.toString();
        final dieetId = row['dieet_id']?.toString();
        
        if (kosItemId != null && dieetId != null) {
          mappings[kosItemId] ??= [];
          mappings[kosItemId]!.add(dieetId);
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
      final dayName = (item['week_dag_naam'] ?? '').toString();
      final matchesDay = selectedDay == 'Alle' || dayName == selectedDay;
      
      // Check if this day is past cutoff (grey out and disable ordering)
      final isPastCutoff = _isDayPastCutoff(dayName);
      
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

      // Add cutoff status to item for UI display
      item['is_past_cutoff'] = isPastCutoff;
      
      return matchesDay && matchesDietType && matchesSearch;
    }).toList();
    
    // Sort by day order: Monday (1) to Sunday (7)
    final dayOrder = {
      'maandag': 1, 'dinsdag': 2, 'woensdag': 3, 'donderdag': 4,
      'vrydag': 5, 'saterdag': 6, 'sondag': 7
    };
    
    filteredMenuItems.sort((a, b) {
      final dayA = (a['week_dag_naam'] ?? '').toString().toLowerCase();
      final dayB = (b['week_dag_naam'] ?? '').toString().toLowerCase();
      final orderA = dayOrder[dayA] ?? 999;
      final orderB = dayOrder[dayB] ?? 999;
      return orderA.compareTo(orderB);
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
              color: Theme.of(context).colorScheme.primary,
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
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Wat gaan jy vandag eet?',
                            style: AppTypography.bodySmall.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),
                            ),
                          ),
                          if (currentMenuDate != null) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 16,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Huidige Week: ${_formatMenuDate(currentMenuDate!)}',
                                    style: AppTypography.labelMedium.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.go('/db-test'),
                            icon: Icon(
                              Icons.storage_rounded,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                            tooltip: 'DB Test',
                          ),
                          IconButton(
                            onPressed: () => context.go('/notifications'),
                            icon: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Icon(
                                  Icons.notifications_outlined,
                                  color: Theme.of(context).colorScheme.onPrimary,
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
                                Icon(
                                  Icons.shopping_cart_outlined,
                                  color: Theme.of(context).colorScheme.onPrimary,
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
                      fillColor: Theme.of(context).colorScheme.surface,
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
    thumbVisibility: true,
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
          selectedColor: Theme.of(context).colorScheme.primary,
          labelStyle: TextStyle(
            color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurfaceVariant,
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
    thumbVisibility: true,
    child: ListView.separated(
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
          selectedColor: Theme.of(context).colorScheme.primary,
          labelStyle: TextStyle(
            color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.primary,
          ),
          side: BorderSide(color: Theme.of(context).colorScheme.primary),
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
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.restaurant_menu,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            spyskaart == null 
                                ? 'Geen spyskaart beskikbaar nog nie'
                                : 'Geen items beskikbaar vir hierdie filter',
                            style: AppTypography.bodyLarge.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          if (spyskaart == null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Die admin moet eers \'n spyskaart skep',
                              style: AppTypography.bodySmall.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ],
                      ),
                    )
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
        color: Theme.of(context).colorScheme.error,
        borderRadius: BorderRadius.circular(8),
      ),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      child: Text(
        count,
        style: TextStyle(color: Theme.of(context).colorScheme.onError, fontSize: 10),
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
            color: Theme.of(context).colorScheme.error,
            borderRadius: BorderRadius.circular(8),
          ),
          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
          child: Text(
            '$display',
            style: TextStyle(color: Theme.of(context).colorScheme.onError, fontSize: 10),
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
    // Check if this item is past cutoff
    final isPastCutoff = wrapper['is_past_cutoff'] == true;
    final isDisabled = !available || isPastCutoff;
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
          color: isDisabled 
              ? Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5)
              : null,
          child: Row(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
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
                    ? Icon(
                        Icons.fastfood,
                        size: 40,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      )
                    : null,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name, 
                        style: AppTypography.titleMedium.copyWith(
                          color: isDisabled 
                              ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                              : Theme.of(context).colorScheme.onSurface
                        )
                      ),
                      if (description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall.copyWith(
                              color: isDisabled 
                                  ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)
                                  : Theme.of(context).colorScheme.onSurfaceVariant
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            'R${price.toStringAsFixed(2)}',
                            style: AppTypography.titleMedium.copyWith(
                              color: isDisabled 
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (dayName.isNotEmpty && selectedDay == 'Alle')
                            Text(
                              dayName, 
                              style: AppTypography.labelSmall.copyWith(
                                color: isDisabled 
                                    ? Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5)
                                    : Theme.of(context).colorScheme.onSurfaceVariant
                              )
                            ),
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
                      if (isPastCutoff)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Bestelling gesluit (na 17:00 vorige dag)',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        )
                      else if (!available)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Nie beskikbaar nie',
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
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
