import 'package:flutter/material.dart';
import 'kos_item_templaat.dart';

class WeekTemplateCard extends StatefulWidget {
  final Map<String, dynamic> templaat;
  final List<Map<String, String>> daeVanWeek;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const WeekTemplateCard({
    super.key,
    required this.templaat,
    required this.daeVanWeek,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<WeekTemplateCard> createState() => _WeekTemplateCardState();
}

class _WeekTemplateCardState extends State<WeekTemplateCard> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final beskrywing = (widget.templaat['beskrywing'] as String?) ?? '';
    final daeMap = Map<String, dynamic>.from(
      widget.templaat['dae'] as Map<dynamic, dynamic>,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titel + beskrywing
            Text(
              widget.templaat['naam'] as String,
              style: Theme.of(context).textTheme.titleLarge,
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
            const SizedBox(height: 8),

            // --- TABLE (per dag) ---
            Expanded(
              child: Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    defaultVerticalAlignment: TableCellVerticalAlignment.top,
                    columnWidths: const {
                      0: IntrinsicColumnWidth(), // day label
                      1: FlexColumnWidth(), // items
                    },
                    children: widget.daeVanWeek.map((dag) {
                      final dagKey = dag['key'] as String;
                      final dagLabel = dag['label'] as String;

                      final List<Map<String, dynamic>> kosMaps =
                          ((daeMap[dagKey] as List?) ?? const [])
                              .map<Map<String, dynamic>>(
                                (e) => Map<String, dynamic>.from(e as Map),
                              )
                              .toList();

                      return TableRow(
                        children: [
                          // Dag kolom
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: Text(
                              dagLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Items kolom
                          Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: kosMaps.isEmpty
                                ? const Text('-')
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: kosMaps.map((map) {
                                      final item = KositemTemplate.fromMap(map);
                                      return Card(
                                        margin: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        child: ListTile(
                                          dense: true,
                                          title: Text(item.naam),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Beskrywing: ${item.beskrywing}",
                                              ),
                                              Text(
                                                "Kategorie: ${item.kategorie}",
                                              ),
                                              Text(
                                                "Prys: R${item.prys.toStringAsFixed(2)}",
                                              ),
                                              if (item.bestanddele.isNotEmpty)
                                                Text(
                                                  "Bestanddele: ${item.bestanddele.join(', ')}",
                                                ),
                                              if (item.allergene.isNotEmpty)
                                                Text(
                                                  "Allergene: ${item.allergene.join(', ')}",
                                                  style: const TextStyle(
                                                    color: Colors.red,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Aksie knoppies
            Row(
              children: [
                Expanded(
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
      ),
    );
  }
}
