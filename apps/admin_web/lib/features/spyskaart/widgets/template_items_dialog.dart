import 'package:flutter/material.dart';
import '../../templates/widgets/kos_item_templaat.dart';

class TemplateItem {
  final String itemId;
  final String dayName; // expected in lower-case ('maandag', 'dinsdag', ...)
  final String dayLabel;
  final KositemTemplate item;
  int quantity;
  DateTime cutoffTime;

  TemplateItem({
    required this.itemId,
    required this.dayName,
    required this.dayLabel,
    required this.item,
    this.quantity = 1,
    DateTime? cutoffTime,
  }) : cutoffTime = cutoffTime ?? DateTime.now().copyWith(hour: 17, minute: 0);
}

class TemplateItemsDialog extends StatefulWidget {
  final List<TemplateItem> templateItems;
  final bool open;
  final void Function(bool open) onOpenChange;
  final void Function(List<TemplateItem> itemsWithSettings) onConfirm;

  const TemplateItemsDialog({
    super.key,
    required this.templateItems,
    required this.open,
    required this.onOpenChange,
    required this.onConfirm,
  });

  @override
  State<TemplateItemsDialog> createState() => _TemplateItemsDialogState();
}

class _TemplateItemsDialogState extends State<TemplateItemsDialog> {
  late List<TemplateItem> _items;
  final Map<String, TextEditingController> _quantityControllers = {};

  // NOTE: keys are lower-case to match dayName values used elsewhere in your app
  final Map<String, int> _dayNameToWeekday = {
    "maandag": DateTime.monday,
    "dinsdag": DateTime.tuesday,
    "woensdag": DateTime.wednesday,
    "donderdag": DateTime.thursday,
    "vrydag": DateTime.friday,
    "saterdag": DateTime.saturday,
    "sondag": DateTime.sunday,
  };

  @override
  void initState() {
    super.initState();
    _items = widget.templateItems
        .map(
          (item) => TemplateItem(
            itemId: item.itemId,
            dayName: item.dayName,
            dayLabel: item.dayLabel,
            item: item.item,
            quantity: item.quantity,
            // default cutoff: one day before the corresponding weekday in NEXT week at 17:00
            cutoffTime: _getNextWeekCutoff(item.dayName),
          ),
        )
        .toList();

    // Initialize controllers for each item
    for (var item in _items) {
      _quantityControllers[item.itemId] = TextEditingController(
        text: item.quantity.toString(),
      );
    }
  }

  DateTime _getNextWeekCutoff(String dayName) {
    final now = DateTime.now();
    final weekday = _dayNameToWeekday[dayName.toLowerCase()] ?? DateTime.monday;

    // Compute the Monday of the current week
    final thisMonday = now.subtract(Duration(days: now.weekday - 1));

    // Start of next week = thisMonday + 7 days
    final nextWeekStart = thisMonday.add(const Duration(days: 7));

    // Target date in next week for the requested weekday
    final targetDate = nextWeekStart.add(
      Duration(days: weekday - DateTime.monday),
    );

    // Cutoff day = one day before target date
    final cutoffDay = targetDate.subtract(const Duration(days: 1));

    // Return cutoff at 17:00 local time
    return DateTime(cutoffDay.year, cutoffDay.month, cutoffDay.day, 17, 0);
  }

  @override
  void dispose() {
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickCutoffDateTime(TemplateItem templateItem) async {
    // Step 1: Pick a date (seeded with current cutoff)
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: templateItem.cutoffTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      // Step 2: Pick a time
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(templateItem.cutoffTime),
      );

      if (pickedTime != null) {
        setState(() {
          templateItem.cutoffTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  void _handleConfirm() {
    widget.onConfirm(_items);
    Navigator.of(context).pop();
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  void _setQuantityForAll(int quantity) {
    setState(() {
      for (var item in _items) {
        item.quantity = quantity;
        _quantityControllers[item.itemId]?.text = quantity.toString();
      }
    });
  }

  void _updateQuantityForAll(int quantity) {
    setState(() {
      for (var item in _items) {
        item.quantity = item.quantity + quantity;
        _quantityControllers[item.itemId]?.text = item.quantity.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.open) return const SizedBox.shrink();

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 700),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              const Text(
                "Vervang spyskaart met Templaat",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Hierdie templaat sal die huidige spyskaart vervang. Spesifiseer hoeveelheid en afsny tyd vir elke item.",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.orange.shade700,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Let op: Dit sal alle bestaande items in die huidige week vervang.",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Bulk actions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.settings, color: Colors.blue),
                    const SizedBox(width: 8),
                    const Text(
                      "Bulk instellings:",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => _setQuantityForAll(0),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text("Hoeveelheid = 0"),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => _updateQuantityForAll(5),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      child: const Text("Hoeveelheid +5"),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Items list
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: _items.map((templateItem) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Day indicator
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                templateItem.dayLabel,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Item info
                            Row(
                              children: [
                                // Image placeholder or actual image
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: templateItem.item.prent != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          child: Image.network(
                                            templateItem.item.prent!,
                                            width: 48,
                                            height: 48,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.restaurant,
                                                    color: Colors.grey,
                                                  );
                                                },
                                          ),
                                        )
                                      : const Icon(
                                          Icons.restaurant,
                                          color: Colors.grey,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        templateItem.item.naam,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                      Text(
                                        "R${templateItem.item.prys.toStringAsFixed(2)}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Quantity + Cut-off
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Text(
                                            "Hoeveelheid items beskikbaar",
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Tooltip(
                                            message:
                                                "Die aantal items wat beskikbaar is vir bestelling",
                                            child: Icon(
                                              Icons.info_outline,
                                              size: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller:
                                            _quantityControllers[templateItem
                                                .itemId],
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          hintText: "1",
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                        ),
                                        onChanged: (value) {
                                          templateItem.quantity =
                                              int.tryParse(value) ?? 1;
                                        },
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ],
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
                                          const Icon(Icons.event, size: 14),
                                          const SizedBox(width: 4),
                                          const Text(
                                            "Afsny datum & tyd",
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Tooltip(
                                            message:
                                                "Die tyd wanneer bestellings vir hierdie item afgesny word",
                                            child: Icon(
                                              Icons.info_outline,
                                              size: 14,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      InkWell(
                                        onTap: () =>
                                            _pickCutoffDateTime(templateItem),
                                        child: InputDecorator(
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 8,
                                                ),
                                          ),
                                          child: Text(
                                            "${templateItem.cutoffTime.year}-${templateItem.cutoffTime.month.toString().padLeft(2, '0')}-${templateItem.cutoffTime.day.toString().padLeft(2, '0')} "
                                            "${templateItem.cutoffTime.hour.toString().padLeft(2, '0')}:${templateItem.cutoffTime.minute.toString().padLeft(2, '0')}",
                                            style: const TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _handleCancel,
                    child: const Text("Kanselleer"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _handleConfirm,
                    child: const Text("Vervang menu"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
