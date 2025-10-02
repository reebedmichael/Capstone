import 'package:flutter/material.dart';
import 'models.dart';

class ItemSearchOverlay extends StatefulWidget {
  final List<Kositem> items;
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

  List<Kositem> get filtered {
    final term = q.trim().toLowerCase();
    if (term.isEmpty) return [];
    return widget.items.where((item) {
      final inName = item.naam.toLowerCase().contains(term);
      final inCat = item.kategorie.toLowerCase().contains(term);
      final inDesc = (item.beskrywing ?? '').toLowerCase().contains(term);
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
                hintText:
                    'Soek volgens naam, kategorie, beskrywing of bestanddele...',
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
                    final cols = c.maxWidth >= 1000 ? 3 : 1;
                    return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.9,
                      ),
                      itemCount: results.length,
                      itemBuilder: (context, i) {
                        final item = results[i];
                        final isAlreeds = widget.alreadySelectedIds.contains(
                          item.id,
                        );
                        final beskrywing = (item.beskrywing ?? '').trim();

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
                                  if (item.prentBytes != null ||
                                      item.prentUrl != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 120,
                                        height: 120,
                                        child: item.prentBytes != null
                                            ? Image.memory(
                                                item.prentBytes!,
                                                fit: BoxFit.cover,
                                              )
                                            : Image.network(
                                                item.prentUrl!,
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
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            if (item.kategorie.isNotEmpty)
                                              Chip(label: Text(item.kategorie)),
                                            if (isAlreeds)
                                              Chip(
                                                backgroundColor: Colors.green,
                                                label: Row(
                                                  children: const [
                                                    Icon(Icons.check, size: 12),
                                                    SizedBox(width: 6),
                                                    Text('Bygevoeg'),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        if (beskrywing.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            beskrywing,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).hintColor,
                                            ),
                                          ),
                                        ],
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
        ],
      ),
    );
  }
}
