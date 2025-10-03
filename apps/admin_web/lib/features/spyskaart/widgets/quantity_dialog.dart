import 'package:flutter/material.dart';

class FoodItem {
  final String id;
  final String name;
  final double price;
  final String image;

  FoodItem({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
  });
}

class QuantityDialog extends StatefulWidget {
  final List<FoodItem> items;
  final bool open;
  final void Function(bool open) onOpenChange;
  final void Function(List<Map<String, dynamic>> itemsWithQuantity) onConfirm;

  const QuantityDialog({
    super.key,
    required this.items,
    required this.open,
    required this.onOpenChange,
    required this.onConfirm,
  });

  @override
  State<QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<QuantityDialog> {
  final Map<String, TextEditingController> _quantityControllers = {};
  final Map<String, TextEditingController> _timeControllers = {};

  @override
  void initState() {
    super.initState();
    for (var item in widget.items) {
      _quantityControllers[item.id] = TextEditingController();
      _timeControllers[item.id] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (var c in _quantityControllers.values) {
      c.dispose();
    }
    for (var c in _timeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _handleConfirm() {
    final itemsWithQuantity = widget.items.map((item) {
      final qty = int.tryParse(_quantityControllers[item.id]?.text ?? '') ?? 1;
      final cutoff = _timeControllers[item.id]?.text.isNotEmpty == true
          ? _timeControllers[item.id]!.text
          : '23:59';

      return {
        'id': item.id,
        'name': item.name,
        'price': item.price,
        'image': item.image,
        'quantity': qty,
        'cutOffTime': cutoff,
      };
    }).toList();

    widget.onConfirm(itemsWithQuantity);
    _resetFields();
    widget.onOpenChange(false);
  }

  void _handleCancel() {
    _resetFields();
    widget.onOpenChange(false);
  }

  void _resetFields() {
    for (var c in _quantityControllers.values) {
      c.clear();
    }
    for (var c in _timeControllers.values) {
      c.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.open) return const SizedBox.shrink();

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              const Text(
                "Set Quantities & Cut-off Times",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Specify the quantity and cut-off time for each selected food item to add to the menu.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // Items list
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: widget.items.map((item) {
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
                            // Image + Info
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    item.image,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        "\$${item.price.toStringAsFixed(2)}",
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
                                      const Text(
                                        "Quantity",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller:
                                            _quantityControllers[item.id],
                                        keyboardType: TextInputType.number,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          hintText: "1",
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                        ),
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
                                        children: const [
                                          Icon(Icons.access_time, size: 14),
                                          SizedBox(width: 4),
                                          Text(
                                            "Cut-off Time",
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      TextField(
                                        controller: _timeControllers[item.id],
                                        keyboardType: TextInputType.datetime,
                                        decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          hintText: "23:59",
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 8,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Available until this time",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
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

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _handleCancel,
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _handleConfirm,
                    child: const Text("Add Items"),
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
