import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SearchBarWidget extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChange;
  final String placeholder;

  const SearchBarWidget({
    super.key,
    required this.value,
    required this.onChange,
    this.placeholder = "Soek bestellings...",
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length), // keep cursor at end
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          TextField(
            controller: _controller,
            onChanged: widget.onChange,
            decoration: InputDecoration(
              hintText: widget.placeholder,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 12,
              ).copyWith(left: 40),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
            ),
          ),
          Positioned(
            left: 12,
            child: Icon(
              LucideIcons.search,
              size: 18,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }
}
