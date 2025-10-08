import 'package:flutter/material.dart';
import '../../templates/widgets/kos_item_templaat.dart';

class QuantityDialog extends StatefulWidget {
  final KositemTemplate item;
  final bool open;
  final void Function(bool open) onOpenChange;
  final void Function(String itemId, int quantity, DateTime cutoffTime)
  onConfirm;
  final int? initialQuantity;
  final DateTime? initialCutoffTime;

  const QuantityDialog({
    super.key,
    required this.item,
    required this.open,
    required this.onOpenChange,
    required this.onConfirm,
    this.initialQuantity,
    this.initialCutoffTime,
  });

  @override
  State<QuantityDialog> createState() => _QuantityDialogState();
}

class _QuantityDialogState extends State<QuantityDialog> {
  late final TextEditingController _quantityController;
  late DateTime _cutoffDateTime;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(
      text: (widget.initialQuantity ?? 1).toString(),
    );
    _cutoffDateTime =
        widget.initialCutoffTime ??
        DateTime.now().copyWith(hour: 17, minute: 00);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickCutoffDateTime() async {
    // Step 1: Pick a date
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _cutoffDateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      // Step 2: Pick a time
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_cutoffDateTime),
      );

      if (pickedTime != null) {
        setState(() {
          _cutoffDateTime = DateTime(
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
    final quantity = int.tryParse(_quantityController.text) ?? 1;
    widget.onConfirm(widget.item.id, quantity, _cutoffDateTime);
    _resetFields();
    Navigator.of(context).pop();
  }

  void _handleCancel() {
    _resetFields();
    Navigator.of(context).pop();
  }

  void _resetFields() {
    _quantityController.text = (widget.initialQuantity ?? 1).toString();
    _cutoffDateTime =
        widget.initialCutoffTime ??
        DateTime.now().copyWith(hour: 17, minute: 00);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.open) return const SizedBox.shrink();

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 500),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              const Text(
                "Stel item hoeveelheid & Bestelling afsny tyd",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Spesifiseer die hoeveelheid items beskikbaar en  bestelling afsny datum & tyd vir ${widget.item.naam}.",
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Item info
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    // Image placeholder or actual image
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: widget.item.prent != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                widget.item.prent!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.restaurant,
                                    color: Colors.grey,
                                  );
                                },
                              ),
                            )
                          : const Icon(Icons.restaurant, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.item.naam,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            "R${widget.item.prys.toStringAsFixed(2)}",
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
              ),

              // Quantity + Cut-off
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Hoeveelheid items beskikbaar",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextField(
                          controller: _quantityController,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.event, size: 14),
                            SizedBox(width: 4),
                            Text(
                              "Afsny datum & tyd",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: _pickCutoffDateTime,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                            child: Text(
                              "${_cutoffDateTime.year}-${_cutoffDateTime.month.toString().padLeft(2, '0')}-${_cutoffDateTime.day.toString().padLeft(2, '0')} "
                              "${_cutoffDateTime.hour.toString().padLeft(2, '0')}:${_cutoffDateTime.minute.toString().padLeft(2, '0')}",
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                    child: const Text("Voeg item by"),
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
