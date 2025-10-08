import 'package:flutter/material.dart';
import 'kos_item_templaat.dart';
import 'kos_templaat_card.dart';

class WeekTemplateCard extends StatefulWidget {
  final Map<String, dynamic> templaat;
  final List<Map<String, String>> daeVanWeek;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Function(KositemTemplate)? onViewItem;

  const WeekTemplateCard({
    super.key,
    required this.templaat,
    required this.daeVanWeek,
    required this.onEdit,
    required this.onDelete,
    this.onViewItem,
  });

  @override
  State<WeekTemplateCard> createState() => _WeekTemplateCardState();
}

class _WeekTemplateCardState extends State<WeekTemplateCard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, bool> _expandedDays = {};
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    for (final day in widget.daeVanWeek) {
      final key = day['key'] ?? '';
      _expandedDays[key] = false;
    }

    _tabController = TabController(
      // length: widget.daeVanWeek.length + 1,
      length: widget.daeVanWeek.length,
      vsync: this,
    );
    _tabController.addListener(() {
      // rebuild when tab changes so AnimatedSize can animate to new child size
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildKosItems(List<Map<String, dynamic>> kosMaps) {
    // Wrap in LayoutBuilder so cards size to available width
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableWidth = constraints.maxWidth;
          final cardWidth = (availableWidth / 2).clamp(180.0, 220.0);
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kosMaps.map((map) {
              final item = KositemTemplate.fromMap(map);
              return SizedBox(
                width: cardWidth,
                child: KositemTemplateCard(
                  template: item,
                  onView: () {
                    if (widget.onViewItem != null) widget.onViewItem!(item);
                  },
                  onEdit: () {},
                  onDelete: () {},
                  showEditDeleteButtons: false,
                  showEditButton: false,
                  showDeleteButton: false,
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildDayTabContent(String dagKey, Map<String, dynamic> daeMap) {
    final List<Map<String, dynamic>> kosMaps =
        (((daeMap[dagKey] as List?) ?? const []))
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (kosMaps.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Geen items vir hierdie dag',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          )
        else
          _buildKosItems(kosMaps),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final beskrywing = (widget.templaat['beskrywing'] as String?) ?? '';
    final daeMap = Map<String, dynamic>.from(
      (widget.templaat['dae'] as Map<dynamic, dynamic>?) ?? {},
    );

    // limit the maximum height so very large content still scrolls instead of overflowing the screen
    final maxAllowedHeight = MediaQuery.of(context).size.height * 0.8;

    return Card(
      shadowColor: Colors.grey[300],
      surfaceTintColor: Theme.of(context).colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // This part remains the same
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.templaat['naam'] as String? ?? '',
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 150,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Wysig'),
                        onPressed: widget.onEdit,
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: widget.onDelete,
                    ),
                  ],
                ),
              ],
            ),

            if (beskrywing.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  beskrywing,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // ======== NEW: TOGGLE BUTTON ========
            // An InkWell makes the Row tappable to toggle the state.
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(child: SizedBox()),
                    Text(
                      _isExpanded ? 'Wys minder' : 'Wys meer besonderhede',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),

            // ======== NEW: COLLAPSIBLE SECTION ========
            // Use AnimatedCrossFade to smoothly show/hide its child.
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 8),

                  // This is your original content that will now be collapsible
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: Theme.of(context).colorScheme.primary,
                    tabs: [
                      ...widget.daeVanWeek.map((d) => Tab(text: d['label'])),
                    ],
                  ),
                  const SizedBox(height: 12),

                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: maxAllowedHeight),
                    child: SingleChildScrollView(
                      child: AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        child: Builder(
                          builder: (context) {
                            final activeIndex = _tabController.index;
                            final int dayIdx = activeIndex;
                            final dagKey =
                                widget.daeVanWeek[dayIdx]['key'] ?? '';
                            return _buildDayTabContent(dagKey, daeMap);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
          ],
        ),
      ),
    );
  }
}
