import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../templates/widgets/kos_item_templaat.dart';

class ItemSearchOverlay extends StatefulWidget {
  final List<KositemTemplate> items;
  final List<String> alreadySelectedIds;
  final VoidCallback onClose;
  final void Function(String) onAdd;

  const ItemSearchOverlay({
    super.key,
    required this.items,
    required this.alreadySelectedIds,
    required this.onClose,
    required this.onAdd,
  });

  @override
  State<ItemSearchOverlay> createState() => _ItemSearchOverlayState();
}

class _ItemSearchOverlayState extends State<ItemSearchOverlay> {
  String q = '';

  List<KositemTemplate> get filtered {
    final term = q.trim().toLowerCase();
    if (term.isEmpty) return [];
    return widget.items.where((item) {
      final inName = item.naam.toLowerCase().contains(term);
      final inCat = item.dieetKategorie.any(
        (cat) => cat.toLowerCase().contains(term),
      );
      final inDesc = item.beskrywing.toLowerCase().contains(term);
      final inIng = item.bestanddele.any((b) => b.toLowerCase().contains(term));
      final inAlg = item.allergene.any((a) => a.toLowerCase().contains(term));
      return inName || inCat || inDesc || inIng || inAlg;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          // header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Voeg Item by',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Soek en kies uit beskikbare kositems',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // search field
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Soek volgens naam of dieet vereiste...',
              ),
              onChanged: (v) => setState(() => q = v),
            ),
          ),

          // results
          Expanded(
            child: Builder(
              builder: (ctx) {
                final results = q.isEmpty ? widget.items : filtered;

                if (results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 56,
                          color: Theme.of(context).hintColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Geen items gevind nie',
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Probeer \'n ander soekterm',
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, c) {
                    // final cols = c.maxWidth >= 1000 ? 3 : 1;
                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 400,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 2.1,
                      ),
                      itemCount: results.length,
                      itemBuilder: (context, i) {
                        final item = results[i];
                        final isAlreeds = widget.alreadySelectedIds.contains(
                          item.id,
                        );
                        // final beskrywing = item.beskrywing.trim();

                        return InkWell(
                          onTap: () {
                            if (!isAlreeds) widget.onAdd(item.id);
                          },
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isAlreeds
                                    ? Colors.green.shade300
                                    : Theme.of(context).dividerColor,
                                width: 2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  if (item.prent != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 120,
                                        height: 120,
                                        child: Image.network(
                                          item.prent!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.naam,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.titleMedium,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'R${item.prys.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        if (item.dieetKategorie.isNotEmpty) ...[
                                          Text(
                                            'Dieet vereiste:',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.dieetKategorie.join(', '),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(
                                                context,
                                              ).textTheme.bodySmall?.color,
                                            ),
                                          ),
                                        ],
                                        if (isAlreeds) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(
                                                  Icons.check,
                                                  size: 12,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(width: 6),
                                                Text(
                                                  'Bygevoeg',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        // if (beskrywing.isNotEmpty) ...[
                                        //   const SizedBox(height: 6),
                                        //   Text(
                                        //     beskrywing,
                                        //     // maxLines: 2,
                                        //     overflow: TextOverflow.ellipsis,
                                        //     style: TextStyle(
                                        //       color: Theme.of(
                                        //         context,
                                        //       ).hintColor,
                                        //     ),
                                        //   ),
                                        // ],
                                        // if (item.bestanddele.isNotEmpty) ...[
                                        //   const SizedBox(height: 6),
                                        //   Text(
                                        //     item.bestanddele.join(', '),
                                        //     maxLines: 2,
                                        //     overflow: TextOverflow.ellipsis,
                                        //     style: TextStyle(
                                        //       color: Theme.of(
                                        //         context,
                                        //       ).hintColor,
                                        //     ),
                                        //   ),
                                        // ],
                                        // if (item.allergene.isNotEmpty)
                                        //   Padding(
                                        //     padding: const EdgeInsets.only(
                                        //       top: 6,
                                        //     ),
                                        //     child: Wrap(
                                        //       spacing: 6,
                                        //       runSpacing: 6,
                                        //       children: item.allergene
                                        //           .map(
                                        //             (a) => Chip(
                                        //               backgroundColor:
                                        //                   Colors.red.shade50,
                                        //               label: Text(a),
                                        //             ),
                                        //           )
                                        //           .toList(),
                                        //     ),
                                        //   ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Create new item button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  // Close the overlay first
                  widget.onClose();
                  // Navigate to kositem template page
                  context.go('/templates/kositem');
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text(
                  'Nie gevind wat jy soek? Skep \'n nuwe kositem',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
