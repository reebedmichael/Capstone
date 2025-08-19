// day_section.dart
import 'package:flutter/material.dart';
import 'models.dart';
import 'item_card.dart';
import 'item_search_overlay.dart';

class DaySection extends StatefulWidget {
  final WeekSpyskaart? spyskaart;
  final String aktieweDag;
  final String aktieweweek;
  final List<Map<String, String>> daeVanWeek;
  final void Function(String) onChangeDag;
  final Kositem? Function(String) kryItem;
  final bool Function(WeekSpyskaart?) kanWysig;
  final void Function(WeekSpyskaart, String, String) voegItem;
  final void Function(WeekSpyskaart, String, String) verwyderItem;
  final void Function(Kositem) openDetail;
  final List<Kositem> searchItems; // items to search from

  const DaySection({
    super.key,
    required this.spyskaart,
    required this.aktieweDag,
    required this.aktieweweek,
    required this.daeVanWeek,
    required this.onChangeDag,
    required this.kryItem,
    required this.kanWysig,
    required this.voegItem,
    required this.verwyderItem,
    required this.openDetail,
    required this.searchItems,
  });

  @override
  State<DaySection> createState() => _DaySectionState();
}

class _DaySectionState extends State<DaySection> {
  Future<void> _openSearchOverlay() async {
    final s = widget.spyskaart;
    if (s == null) return;

    final addedId = await showGeneralDialog<String>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Voeg Item by',
      barrierColor: Colors.black54,
      pageBuilder: (ctx, anim, secAnim) {
        return Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 1100,
                  maxHeight: 700,
                ),
                child: ItemSearchOverlay(
                  items: widget.searchItems,
                  alreadySelectedIds: s.dae[widget.aktieweDag] ?? [],
                  onClose: () => Navigator.of(ctx).pop(),
                  onAdd: (id) => Navigator.of(ctx).pop(id),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (addedId != null) {
      widget.voegItem(s, widget.aktieweDag, addedId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.spyskaart;
    return Column(
      children: [
        // Tabs horizontally
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: widget.daeVanWeek.map((d) {
              final k = d['key']!;
              final label = d['label']!;
              final count = s?.dae[k]?.length ?? 0;
              final active = widget.aktieweDag == k;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ChoiceChip(
                  selected: active,
                  onSelected: (_) => widget.onChangeDag(k),
                  label: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.secondary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('$count'),
                      ),
                    ],
                  ),
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: active
                        ? Theme.of(context).colorScheme.onPrimary
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (ctx) {
            if (s == null) {
              return Column(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 72,
                    color: Theme.of(context).hintColor,
                  ),
                  const SizedBox(height: 8),
                  const Text('Geen Spyskaart'),
                ],
              );
            }

            final items = s.dae[widget.aktieweDag] ?? [];
            final canEdit = widget.kanWysig(s);

            return Column(
              children: [
                // header
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.daeVanWeek.firstWhere(
                                (e) => e['key'] == widget.aktieweDag,
                              )['label']!,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${items.length} items gekies',
                              style: TextStyle(
                                color: Theme.of(context).hintColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (canEdit)
                        FilledButton.icon(
                          onPressed: _openSearchOverlay,
                          icon: const Icon(Icons.add),
                          label: const Text('Voeg Item By'),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Empty state or grid
                if (items.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.calendar_month,
                          size: 56,
                          color: Theme.of(context).hintColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Geen items vir ${widget.daeVanWeek.firstWhere((e) => e['key'] == widget.aktieweDag)['label']} nog nie',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 12),
                        if (canEdit)
                          FilledButton.icon(
                            onPressed: _openSearchOverlay,
                            icon: const Icon(Icons.add),
                            label: const Text('Voeg Eerste Item By'),
                          ),
                      ],
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, c) {
                      int cols = 1;
                      if (c.maxWidth >= 1200)
                        cols = 3;
                      else if (c.maxWidth >= 800)
                        cols = 2;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.05,
                        ),
                        itemCount: items.length,
                        itemBuilder: (ctx, i) {
                          final itemId = items[i];
                          final item = widget.kryItem(itemId);
                          if (item == null) return const SizedBox();
                          return ItemCard(
                            item: item,
                            spyskaart: s,
                            tipeWeek: widget.aktieweweek,
                            dagKey: widget.aktieweDag,
                            canEdit: canEdit,
                            onView: () => widget.openDetail(item),
                            onDelete: () => widget.verwyderItem(
                              s,
                              widget.aktieweDag,
                              item.id,
                            ),
                          );
                        },
                      );
                    },
                  ),
                const SizedBox(height: 12),
              ],
            );
          },
        ),
      ],
    );
  }
}
