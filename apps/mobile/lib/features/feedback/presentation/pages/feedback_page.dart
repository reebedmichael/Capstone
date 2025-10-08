import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';

const List<String> FEEDBACK_OPTIONS = [
  'Baie lekker!',
  'Goed',
  'Gemiddeld',
  'Fantasties!',
  'Nie tevrede nie',
  'Kan beter wees',
  'Swak diens',
  'Laat',
];

class FeedbackPage extends StatefulWidget {
  final Map<String, dynamic> order;
  final Function(Map<String, dynamic> updatedOrder) onFeedbackUpdated;

  const FeedbackPage({
    super.key,
    required this.order,
    required this.onFeedbackUpdated,
  });

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  String _selectedFeedback = '';
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    final feedback = widget.order['feedback'];
    if (feedback != null) {
      _liked = feedback['liked'] ?? false;
      _selectedFeedback = feedback['selectedFeedback'] ?? '';
    }
  }

  void _toggleLikeFeedback() {
    setState(() {
      _liked = !_liked;
    });

    // Update only the 'liked' state, not the 'selectedFeedback'.
    widget.order['feedback'] = {
      'liked': _liked,
      'selectedFeedback': _selectedFeedback, // Don't reset feedback
      'date': DateTime.now(),
    };

    widget.onFeedbackUpdated(widget.order);

    Fluttertoast.showToast(
      msg: _liked ? 'Dankie vir jou like!' : 'Like verwyder',
    );
  }

  void _openDetailedFeedback() {
    _selectedFeedback = '';
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kies Gedetailleerde Terugvoer'),
        content: StatefulBuilder(
          builder: (context, setLocalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  hint: Text("Kies een opsie.."),
                  value: _selectedFeedback.isEmpty ? null : _selectedFeedback,
                  items: FEEDBACK_OPTIONS
                      .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                      .toList(),
                  onChanged: (v) =>
                      setLocalState(() => _selectedFeedback = v ?? ''),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Kanselleer'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedFeedback.isEmpty
                            ? null
                            : () {
                                setState(() {
                                  widget.order['feedback'] = {
                                    'liked': _liked,
                                    'selectedFeedback': _selectedFeedback,
                                    'date': DateTime.now(),
                                  };
                                });
                                widget.onFeedbackUpdated(widget.order);
                                Navigator.pop(context);
                                Fluttertoast.showToast(
                                  msg: 'Gedetailleerde terugvoer gestuur!',
                                );
                              },
                        child: const Text('Stuur'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _editFeedback() {
    _openDetailedFeedback(); // Open the feedback dialog for editing
  }

  @override
  Widget build(BuildContext context) {
    final feedback = widget.order['feedback'];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Terugvoer:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _toggleLikeFeedback,
                  icon: Icon(_liked ? Icons.thumb_up : Icons.thumb_up_off_alt),
                ),
                // Only show the "Voeg terugvoer by" button if feedback is not already given
                if (feedback == null || feedback['selectedFeedback'] == null)
                  OutlinedButton.icon(
                    onPressed: _openDetailedFeedback,
                    icon: const Icon(FeatherIcons.plus, size: 16),
                    label: const Text('Voeg terugvoer by'),
                  ),
                // Show the edit button if feedback is already provided
                if (feedback != null && feedback['selectedFeedback'] != null)
                  IconButton(
                    onPressed: _editFeedback,
                    icon: const Icon(FeatherIcons.edit),
                  ),
              ],
            ),
          ],
        ),
        if (feedback != null && feedback['selectedFeedback'] != null) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(FeatherIcons.checkCircle, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(feedback['selectedFeedback'] ?? '')),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
