import 'dart:convert';

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
  bool _initialized = false;

  // Helper: try multiple keys and return first non-null
  dynamic _pick(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      if (map.containsKey(k) && map[k] != null) return map[k];
    }
    return null;
  }

  // Normalized accessors (robust to different key casings / wrappers)
  String get _name =>
      _pick(item, ['kos_item_naam', 'KOS_ITEM_NAAM', 'name'])?.toString() ?? 'Onbekende Item';

  String get _description =>
      _pick(item, ['kos_item_beskrywing', 'KOS_ITEM_BESKRYWING', 'beskrywing', 'description'])?.toString() ?? '';

  double get _price {
    final raw = _pick(item, ['kos_item_koste', 'KOS_ITEM_KOSTE', 'koste', 'price']);
    if (raw == null) return 0.0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0.0;
  }

  String get _imageUrl =>
      _pick(item, ['kos_item_prentjie', 'KOS_ITEM_PRENTJIE', 'prentjie', 'image', 'image_url'])?.toString() ?? '';

  bool get _available {
    final raw = _pick(item, ['is_aktief', 'IS_AKTIEF', 'active', 'isActive']);
    if (raw == null) return true;
    if (raw is bool) return raw;
    final s = raw.toString().toLowerCase();
    return s == 'true' || s == '1';
  }

  String get _day =>
      _pick(item, ['week_dag_naam', 'week_dag', 'dag', 'day'])?.toString() ?? '';

  // Try multiple keys to find allergens
  List<String> get _allergens {
    final raw = _pick(item, ['kos_item_allergene', 'ALLERGENS', 'allergens']);
    if (raw == null) return [];
    if (raw is List) return raw.map((e) => e.toString()).toList();
    return raw.toString().split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  }

  /// Robust ingredient extraction:
  /// - checks various candidate keys,
  /// - accepts List, Map, JSON array string, CSV/semicolon/newline separated strings,
  /// - tries nested 'kos_item' key and description fallback.
  List<String> get _ingredients {
    final candidateKeys = [
      'kos_item_bestandele',
      'KOS_ITEM_BESTANDELE',
      'bestandele',
      'bestanddele',
      'ingredients',
      'ingrediente',
      'bestanddeel'
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
        return desc.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      }
    }

    return [];
  }

  // Parse various raw formats into List<String>
  List<String> _parseIngredientsRaw(dynamic raw) {
    if (raw == null) return [];

    if (raw is List) {
      return raw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
    }

    if (raw is Map) {
      final vals = raw.values.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      if (vals.isNotEmpty) return vals;
    }

    if (raw is String) {
      final s = raw.trim();
      if (s.isEmpty) return [];

      // JSON array like '["a","b"]'
      if (s.startsWith('[') && s.endsWith(']')) {
        try {
          final decoded = jsonDecode(s);
          if (decoded is List) {
            return decoded.map((e) => e.toString().trim()).where((x) => x.isNotEmpty).toList();
          }
        } catch (_) {
          // not JSON -> continue
        }
      }

      // split common separators
      final parts = s.split(RegExp(r',|;|\n|•|\u2022'));
      if (parts.length > 1) {
        return parts.map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      }

      // dash separated fallback
      if (s.contains(' - ')) {
        return s.split(' - ').map((p) => p.trim()).where((p) => p.isNotEmpty).toList();
      }

      // single short string -> treat as single ingredient
      if (s.length <= 80) return [s];
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
      if (args.containsKey('kos_item') && args['kos_item'] is Map<String, dynamic>) {
        // prefer nested kos_item map
        item = Map<String, dynamic>.from(args['kos_item'] as Map);
        // but also copy top-level week_dag_naam if present in wrapper so _day works
        if (args.containsKey('week_dag') && args['week_dag'] is Map && args['week_dag']['week_dag_naam'] != null) {
          item['week_dag_naam'] = args['week_dag']['week_dag_naam'];
        } else if (args.containsKey('week_dag_naam') && args['week_dag_naam'] != null) {
          item['week_dag_naam'] = args['week_dag_naam'];
        }
      } else {
        item = Map<String, dynamic>.from(args);
      }
    } else {
      // fallback data so UI still shows something (keeps layout stable)
      item = <String, dynamic>{
        'kos_item_naam': 'Dag se Spesiaal',
        'kos_item_beskrywing': 'Heerlike vars opsies met plaaslike bestanddele.',
        'kos_item_koste': 49.99,
        'kos_item_prentjie': null,
        'is_aktief': true,
        'kos_item_bestandele': ['Beesvleis', 'Uie', 'Tamatiesous', 'Speserye'],
        'week_dag_naam': 'Maandag',
      };
    }

    debugPrint('FOOD DETAIL RAW ITEM: $item'); // handig vir debugging

    _initialized = true;
  }

  void updateQuantity(int newQty) {
    if (newQty >= 1 && newQty <= 10) setState(() => quantity = newQty);
  }

  void handleAddToCart() {
    if (!_available) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hierdie item is tans nie beskikbaar nie.')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Bygevoeg: $quantity x ${_name}')));
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _imageUrl;
    final available = _available;
    final ingredients = _ingredients;
    final allergens = _allergens;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
            decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
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
                  child: Text(_name, style: AppTypography.titleLarge, textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                ),
                IconButton(onPressed: () => setState(() => isFavorite = !isFavorite), icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.red : null)),
                IconButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Skakel gekopieer na klipbord'))),
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
                  // Photo with price badge
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: Spacing.screenHPad, vertical: 12),
                    child: Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: imageUrl.isNotEmpty
                                ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(color: Colors.grey.shade200, child: const Center(child: CircularProgressIndicator()));
                                    },
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey.shade200,
                                      child: const Center(child: Icon(Icons.broken_image, size: 56, color: Colors.black26)),
                                    ),
                                  )
                                : Container(color: Colors.grey.shade200, child: const Center(child: Icon(Icons.fastfood, size: 56, color: Colors.black38))),
                          ),
                        ),

                        // Price badge bottom-right on image
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(999), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2))]),
                            child: Text('R${_price.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Content area
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Day label (only show if present)
                      if (_day.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(_day, style: AppTypography.labelLarge.copyWith(color: Colors.grey.shade700)),
                        ),

                      // Title & description
                      Text(_name, style: AppTypography.displayLarge.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (_description.isNotEmpty) Text(_description, style: AppTypography.bodyMedium.copyWith(color: Colors.grey.shade600)),
                      const SizedBox(height: 12),

                      // Static time/portion row
                      Row(children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('15-20 min', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        const SizedBox(width: 16),
                        Icon(Icons.group_outlined, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text('1 porsie', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                      ]),
                      const SizedBox(height: 16),

                      // Allergens
                      if (allergens.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                          child: Row(children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600, size: 20),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Allergene: ${allergens.join(', ')}', style: TextStyle(color: Colors.orange.shade800, fontSize: 12))),
                          ]),
                        ),

                      if (allergens.isNotEmpty) const SizedBox(height: 16),

                      // Ingredients
                      if (ingredients.isNotEmpty)
                        _buildSectionCard(
                          title: 'Bestanddele',
                          icon: Icons.restaurant_menu,
                          child: Wrap(spacing: 8, runSpacing: 8, children: ingredients.map((ing) => _buildPill(ing)).toList()),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('Geen bestanddele beskikbaar nie.', style: TextStyle(color: Colors.grey.shade600)),
                        ),

                      const SizedBox(height: 24),

                      // Availability state
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: available ? const Color(0xFFEFFAF1) : const Color(0xFFFEECEC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: available ? Colors.green.shade200 : Colors.red.shade200),
                        ),
                        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(available ? 'Beskikbaar' : 'Uitverkoop', style: TextStyle(fontWeight: FontWeight.bold, color: available ? Colors.green.shade800 : Colors.red.shade800)),
                            const SizedBox(height: 2),
                            Text(available ? 'Gereed vir bestelling' : 'Tans nie beskikbaar nie', style: TextStyle(fontSize: 12, color: available ? Colors.green.shade600 : Colors.red.shade600)),
                          ]),
                          Container(width: 12, height: 12, decoration: BoxDecoration(color: available ? Colors.green : Colors.red, shape: BoxShape.circle)),
                        ]),
                      ),

                      const SizedBox(height: 100), // ruimte vir bottom bar
                    ]),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Quantity row
            Row(children: [
              const Text('Hoeveelheid:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
              const Spacer(),
              OutlinedButton(onPressed: quantity <= 1 ? null : () => updateQuantity(quantity - 1), style: OutlinedButton.styleFrom(minimumSize: const Size(40, 40), padding: EdgeInsets.zero), child: const Icon(Icons.remove, size: 18)),
              SizedBox(width: 40, child: Center(child: Text('$quantity', style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold)))),
              OutlinedButton(onPressed: quantity >= 10 ? null : () => updateQuantity(quantity + 1), style: OutlinedButton.styleFrom(minimumSize: const Size(40, 40), padding: EdgeInsets.zero), child: const Icon(Icons.add, size: 18)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Totaal:', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text('R${(_price * quantity).toStringAsFixed(2)}', style: AppTypography.titleLarge.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
              ]),
              const Spacer(),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: available ? handleAddToCart : null,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, minimumSize: const Size(0, 48)),
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('Voeg by Mandjie'),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required String title, IconData? icon, Color? titleColor, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (icon != null) ...[Icon(icon, size: 16, color: titleColor ?? Colors.grey.shade600), const SizedBox(width: 8)],
          Text(title, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold, color: titleColor)),
        ]),
        const SizedBox(height: 8),
        child,
      ]),
    );
  }

  Widget _buildPill(String text, {Color? backgroundColor, Color? textColor}) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: backgroundColor ?? Colors.grey.shade100, borderRadius: BorderRadius.circular(16)), child: Text(text, style: AppTypography.labelSmall.copyWith(color: textColor)));
  }
}
