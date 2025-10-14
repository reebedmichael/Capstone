import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:spys_api_client/spys_api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/state/order_refresh_notifier.dart';

class FoodDetailPage extends StatefulWidget {
  const FoodDetailPage({super.key});

  @override
  State<FoodDetailPage> createState() => _FoodDetailPageState();
}

class _FoodDetailPageState extends State<FoodDetailPage> {
  late Map<String, dynamic> item;
  int quantity = 1;
  bool isFavorite = false;
  bool _initialized = false;
  int _currentImage = 0; // carousel index

  // Helper: try multiple keys and return first non-null
  dynamic _pick(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      if (map.containsKey(k) && map[k] != null) return map[k];
    }
    return null;
  }

  // Normalized accessors (robust to different key casings / wrappers)
  String get _name =>
      _pick(item, ['kos_item_naam', 'KOS_ITEM_NAAM', 'name'])?.toString() ??
      'Onbekende Item';

  String get _description =>
      _pick(item, [
        'kos_item_beskrywing',
        'KOS_ITEM_BESKRYWING',
        'beskrywing',
        'description',
      ])?.toString() ??
      '';

  double get _price {
    final raw = _pick(item, [
      'kos_item_koste',
      'KOS_ITEM_KOSTE',
      'koste',
      'price',
    ]);
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0.0;
  }

  String get _imageUrl =>
      _pick(item, [
        'kos_item_prentjie',
        'KOS_ITEM_PRENTJIE',
        'prentjie',
        'image',
        'image_url',
      ])?.toString() ??
      '';

  bool get _available {
    final raw = _pick(item, ['is_aktief', 'IS_AKTIEF', 'active', 'isActive']);
    if (raw == null) return true;
    if (raw is bool) return raw;
    final s = raw.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  String get _day =>
      _pick(item, ['week_dag_naam', 'week_dag', 'dag', 'day'])?.toString() ??
      '';

  // Try multiple keys to find allergens
  List<String> get _allergens {
    final raw = _pick(item, ['kos_item_allergene', 'ALLERGENS', 'allergens']);
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return raw
        .toString()
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// Robust ingredient extraction:
  /// - checks various candidate keys,
  /// - accepts List, Map, JSON array string, CSV/semicolon/newline separated strings,
  /// - supports Postgres array string format `{a,b}`,
  /// - tries nested 'kos_item' key and description fallback.
  List<String> get _ingredients {
    final candidateKeys = [
      'kos_item_bestandele',
      'KOS_ITEM_BESTANDELE',
      'bestandele',
      'bestanddele',
      'ingredients',
      'ingrediente',
      'bestanddeel',
    ];

    // direct keys on item
    for (final k in candidateKeys) {
      if (item.containsKey(k) && item[k] != null) {
        final parsed = _parseIngredientsRaw(item[k]);
        if (parsed.isNotEmpty) return parsed;
      }
    }

    // nested kos_item wrapper (sometimes Home passed spyskaart_kos_item)
    if (item.containsKey('kos_item') && item['kos_item'] is Map) {
      final nested = Map<String, dynamic>.from(item['kos_item'] as Map);
      for (final k in candidateKeys) {
        if (nested.containsKey(k) && nested[k] != null) {
          final parsed = _parseIngredientsRaw(nested[k]);
          if (parsed.isNotEmpty) return parsed;
        }
      }
    }

    // Try to extract "Bestanddele: ..." from description using safe regexp
    final desc = _description;
    if (desc.isNotEmpty) {
      final regex = RegExp(
        r'(?:(?:bestanddel(?:e|es)?)|(?:bestanddele)|(?:ingredients?))\s*[:\-]\s*(.+)',
        caseSensitive: false,
        dotAll: true,
      );
      final match = regex.firstMatch(desc);
      if (match != null) {
        final group = match.group(1) ?? '';
        final parsed = _parseIngredientsRaw(group);
        if (parsed.isNotEmpty) return parsed;
      }

      // fallback: if description is short CSV-like, parse it
      if (desc.contains(',') && desc.split(',').length <= 8) {
        return desc
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
    }

    return [];
  }

  // Parse various raw formats into List<String>
  List<String> _parseIngredientsRaw(dynamic raw) {
    if (raw == null) return [];

    // If Supabase already gave a List
    if (raw is List) {
      return raw
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    // Map -> take values
    if (raw is Map) {
      final vals = raw.values
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
      if (vals.isNotEmpty) return vals;
    }

    // Strings: handle many possible formats
    if (raw is String) {
      final s = raw.trim();
      if (s.isEmpty) return [];

      // JSON array like '["a","b"]'
      if (s.startsWith('[') && s.endsWith(']')) {
        try {
          final decoded = jsonDecode(s);
          if (decoded is List) {
            return decoded
                .map((e) => e.toString().trim())
                .where((x) => x.isNotEmpty)
                .toList();
          }
        } catch (_) {
          // not JSON -> continue
        }
      }

      // Postgres array string like '{Beesvleis,Uie}' or '{"Beesvleis","Uie"}'
      if (s.startsWith('{') && s.endsWith('}')) {
        final inner = s.substring(1, s.length - 1);
        // split on commas that are not inside quotes - simple approach:
        // if values are quoted, remove surrounding quotes later.
        final parts = inner.split(',');
        final cleaned = parts
            .map((p) {
              var part = p.trim();
              if ((part.startsWith('"') && part.endsWith('"')) ||
                  (part.startsWith("'") && part.endsWith("'"))) {
                part = part.substring(1, part.length - 1);
              }
              return part;
            })
            .where((p) => p.isNotEmpty)
            .toList();
        if (cleaned.isNotEmpty) return cleaned;
      }

      // split common separators (comma, semicolon, newline, bullet)
      final parts = s.split(RegExp(r',|;|\n|•|\u2022'));
      if (parts.length > 1) {
        return parts
            .map((p) {
              var v = p.trim();
              // remove surrounding quotes if present
              if ((v.startsWith('"') && v.endsWith('"')) ||
                  (v.startsWith("'") && v.endsWith("'"))) {
                v = v.substring(1, v.length - 1);
              }
              return v;
            })
            .where((p) => p.isNotEmpty)
            .toList();
      }

      // dash separated fallback
      if (s.contains(' - ')) {
        return s
            .split(' - ')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();
      }

      // single short string -> treat as single ingredient
      if (s.length <= 200) return [s];
    }

    return [];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    final args = GoRouterState.of(context).extra;
    if (args != null && args is Map<String, dynamic>) {
      // Accept both wrapper (spyskaart_kos_item) or direct kos_item map
      if (args.containsKey('kos_item') &&
          args['kos_item'] is Map<String, dynamic>) {
        // prefer nested kos_item map
        item = Map<String, dynamic>.from(args['kos_item'] as Map);
        // copy top-level week_dag_naam if present
        if (args.containsKey('week_dag') &&
            args['week_dag'] is Map &&
            args['week_dag']['week_dag_naam'] != null) {
          item['week_dag_naam'] = args['week_dag']['week_dag_naam'];
        } else if (args.containsKey('week_dag_naam') &&
            args['week_dag_naam'] != null) {
          item['week_dag_naam'] = args['week_dag_naam'];
        }
      } else {
        item = Map<String, dynamic>.from(args);
      }
    } else {
      // fallback data so UI still shows something (keeps layout stable)
      item = <String, dynamic>{
        'kos_item_naam': 'Dag se Spesiaal',
        'kos_item_beskrywing':
            'Heerlike vars opsies met plaaslike bestanddele.',
        'kos_item_koste': 49.99,
        'kos_item_prentjie': null,
        'is_aktief': true,
        'kos_item_bestandele': ['Beesvleis', 'Uie', 'Tamatiesous', 'Speserye'],
        'week_dag_naam': 'Maandag',
      };
    }

    debugPrint('FOOD DETAIL RAW ITEM: $item'); // handig vir debugging

    // Check if this item is past cutoff and set the field
    final weekDagNaam = item['week_dag_naam']?.toString() ?? '';
    final isPastCutoff = _checkIfDayPastCutoff(weekDagNaam);
    item['is_past_cutoff'] = isPastCutoff;
    debugPrint('FOOD DETAIL: Item $weekDagNaam is past cutoff: $isPastCutoff');

    _initialized = true;
  }

  void updateQuantity(int newQty) {
    if (newQty >= 1 && newQty <= 10) setState(() => quantity = newQty);
  }

  // Helper methods for week logic (same as home page)
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

  bool _checkIfDayPastCutoff(String dayName) {
    if (dayName.isEmpty) return false;
    
    final now = DateTime.now();
    
    // Map day names to weekday numbers (Monday = 1, Sunday = 7)
    final dayMap = {
      'maandag': 1, 'dinsdag': 2, 'woensdag': 3, 'donderdag': 4,
      'vrydag': 5, 'saterdag': 6, 'sondag': 7
    };
    
    final dayNumber = dayMap[dayName.toLowerCase()];
    if (dayNumber == null) return false;
    
    // Use the same week logic as home page
    final shouldUseNextWeek = _shouldUseNextWeekMenu();
    final weekStart = shouldUseNextWeek ? _getNextWeekStart() : _getCurrentWeekStart();
    
    // Calculate the date for this day in the current week
    final dayDate = weekStart.add(Duration(days: dayNumber - 1));
    
    // For each day, check if it's past 17:00 of the day BEFORE the menu item's day
    final dayBeforeMenuDate = dayDate.subtract(const Duration(days: 1));
    final cutoffDateTime = DateTime(dayBeforeMenuDate.year, dayBeforeMenuDate.month, dayBeforeMenuDate.day, 17, 0);
    
    // Debug logging
    debugPrint('Food Detail Cutoff check for $dayName:');
    debugPrint('  Current time: $now');
    debugPrint('  Should use next week: $shouldUseNextWeek');
    debugPrint('  Week start: $weekStart');
    debugPrint('  Day date: $dayDate');
    debugPrint('  Day before: $dayBeforeMenuDate');
    debugPrint('  Cutoff time: $cutoffDateTime');
    debugPrint('  Is past cutoff: ${now.isAfter(cutoffDateTime)}');
    
    return now.isAfter(cutoffDateTime);
  }

  // ---------- DATABASE-READY: add to mandjie ----------
  void handleAddToCart() async {
    if (!_available) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hierdie item is tans nie beskikbaar nie.'),
        ),
      );
      return;
    }

    // Check if this item is past cutoff (real-time check)
    final weekDagNaam = item['week_dag_naam']?.toString() ?? '';
    debugPrint('Food Detail: Checking cutoff for $weekDagNaam');
    final isPastCutoff = _checkIfDayPastCutoff(weekDagNaam);
    debugPrint('Food Detail: Is past cutoff: $isPastCutoff');
    if (isPastCutoff) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bestelling vir hierdie dag is gesluit (na 17:00 vorige dag).'),
        ),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jy moet eers inteken om \'n mandjie te gebruik.'),
        ),
      );
      return;
    }

    try {
      // Let op: construct SupabaseDb with the real client
      final mandjieRepo = MandjieRepository(
        SupabaseDb(Supabase.instance.client),
      );

      // Voeg item by mandjie en skryf ook die week dag naam (indien beskikbaar)
      await mandjieRepo.voegByMandjie(
        gebrId: user.id,
        kosItemId: item['kos_item_id'].toString(),
        aantal: quantity,
        weekDagNaam: _day.isNotEmpty ? _day : null,
      );

      // Trigger global refresh to update cart badge and notifications
      OrderRefreshNotifier().triggerRefresh();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Bygevoeg: $quantity x $_name')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kon nie by mandjie voeg nie: $e')),
        );
      }
    }
  }

  // ----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl;
    final available = _available;
    final ingredients = _ingredients;
    final allergens = _allergens;
    final List<String> gallery = (() {
      final multi = item['images'] ?? item['gallery'] ?? item['prentjies'];
      if (multi is List) {
        return multi
            .map((e) => e?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return imageUrl.isNotEmpty ? [imageUrl] : <String>[];
    })();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(bottom: BorderSide(color: Theme.of(context).colorScheme.outline)),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    if (GoRouter.of(context).canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
                Expanded(
                  child: Text(
                    _name,
                    style: AppTypography.titleLarge.copyWith(color: Theme.of(context).colorScheme.onSurface),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // removed like/share controls per requirements
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Photo with price badge (carousel + thumbnails)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.screenHPad,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Stack(
                          children: [
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: PageView.builder(
                                  onPageChanged: (i) =>
                                      setState(() => _currentImage = i),
                                  itemCount: gallery.isNotEmpty
                                      ? gallery.length
                                      : 1,
                                  itemBuilder: (context, index) {
                                    final url = gallery.isNotEmpty
                                        ? gallery[index]
                                        : '';
                                    if (url.isEmpty) {
                                      return Container(
                                        color: Theme.of(context).colorScheme.surfaceVariant,
                                        child: Center(
                                          child: Icon(
                                            Icons.fastfood,
                                            size: 56,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.38),
                                          ),
                                        ),
                                      );
                                    }
                                    return Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                      loadingBuilder:
                                          (context, child, loadingProgress) {
                                            if (loadingProgress == null) {
                                              return child;
                                            }
                                            return Container(
                                              color: Theme.of(context).colorScheme.surfaceVariant,
                                              child: const Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              ),
                                            );
                                          },
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Container(
                                                color: Theme.of(context).colorScheme.surfaceVariant,
                                                child: Center(
                                                  child: Icon(
                                                    Icons.broken_image,
                                                    size: 56,
                                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.26),
                                                  ),
                                                ),
                                              ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            // Price badge bottom-right on image
                            Positioned(
                              right: 12,
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.shadow.withOpacity(0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'R${_price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (gallery.length > 1)
                          SizedBox(
                            height: 72,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount: gallery.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final url = gallery[index];
                                final isActive = index == _currentImage;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _currentImage = index),
                                  child: Container(
                                    width: 88,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: isActive
                                            ? Theme.of(context).colorScheme.primary
                                            : Theme.of(context).colorScheme.outline,
                                        width: isActive ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      color: Theme.of(context).colorScheme.surfaceVariant,
                                      image: url.isNotEmpty
                                          ? DecorationImage(
                                              image: NetworkImage(url),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: url.isEmpty
                                        ? Icon(
                                            Icons.image,
                                            size: 24,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.26),
                                          )
                                        : null,
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Content area
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Day label (only show if present)
                        if (_day.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              _day,
                              style: AppTypography.labelLarge.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),

                        // Title & description
                        Text(
                          _name,
                          style: AppTypography.displayLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_description.isNotEmpty)
                          Text(
                            _description,
                            style: AppTypography.bodyMedium.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        const SizedBox(height: 12),

                        // Day availability
                        if (_day.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Beskikbaar op $_day',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 16),

                        // Allergens
                        if (allergens.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Theme.of(context).colorScheme.error,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Allergene: ${allergens.join(', ')}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.error,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (allergens.isNotEmpty) const SizedBox(height: 16),

                        // Ingredients
                        if (ingredients.isNotEmpty)
                          _buildSectionCard(
                            title: 'Bestanddele',
                            icon: Icons.restaurant_menu,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: ingredients
                                  .map((ing) => _buildPill(ing))
                                  .toList(),
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Availability state
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (available && item['is_past_cutoff'] != true) 
                                        ? 'Beskikbaar' 
                                        : (item['is_past_cutoff'] == true ? 'Nie meer beskikbaar' : 'Uitverkoop'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: (available && item['is_past_cutoff'] != true)
                                          ? Theme.of(context).colorScheme.primary
                                          : Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    (available && item['is_past_cutoff'] != true)
                                        ? 'Gereed vir bestelling'
                                        : (item['is_past_cutoff'] == true 
                                            ? 'Bestelling gesluit na 17:00 vorige dag'
                                            : 'Tans nie beskikbaar nie'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: (available && item['is_past_cutoff'] != true)
                                          ? Theme.of(context).colorScheme.onSurfaceVariant
                                          : Theme.of(context).colorScheme.error,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: (available && item['is_past_cutoff'] != true) 
                                      ? Theme.of(context).colorScheme.primary 
                                      : Theme.of(context).colorScheme.error,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 100), // ruimte vir bottom bar
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
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.12))),
        ),
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quantity row
              Row(
                children: [
                  Text(
                    'Hoeveelheid:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: quantity <= 1
                        ? null
                        : () => updateQuantity(quantity - 1),
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
                        style: AppTypography.titleMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: quantity >= 10
                        ? null
                        : () => updateQuantity(quantity + 1),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(40, 40),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Icon(Icons.add, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Totaal:',
                        style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      Text(
                        'R${(_price * quantity).toStringAsFixed(2)}',
                        style: AppTypography.titleLarge.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: (available && item['is_past_cutoff'] != true) ? handleAddToCart : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: titleColor ?? Theme.of(context).colorScheme.onSurfaceVariant),
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
        color: backgroundColor ?? Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(color: textColor),
      ),
    );
  }
}
