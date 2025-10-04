import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:spys_api_client/spys_api_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../locator.dart';

class ItemFeedbackWidget extends StatefulWidget {
  final Map<String, dynamic> bestellingKosItem;
  final Function(Map<String, dynamic> updatedItem) onFeedbackUpdated;

  const ItemFeedbackWidget({
    super.key,
    required this.bestellingKosItem,
    required this.onFeedbackUpdated,
  });

  @override
  State<ItemFeedbackWidget> createState() => _ItemFeedbackWidgetState();
}

class _ItemFeedbackWidgetState extends State<ItemFeedbackWidget> {
  final TerugvoerRepository _terugvoerRepository = sl<TerugvoerRepository>();
  
  List<Map<String, dynamic>> _availableFeedbackOptions = [];
  List<Map<String, dynamic>> _selectedFeedback = [];
  bool _isLoading = false;
  bool _isLiked = false;

  @override
  void initState() {
    super.initState();
    _loadFeedbackData();
  }

  Future<void> _loadFeedbackData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      // Load available feedback options
      final options = await _terugvoerRepository.getTerugvoerOptions();
      
      // Load existing feedback for this item
      final bestKosId = widget.bestellingKosItem['best_kos_id'] as String?;
      List<Map<String, dynamic>> existingFeedback = [];
      
      if (bestKosId != null) {
        existingFeedback = await _terugvoerRepository.getFeedbackForItem(bestKosId);
      }

      // Load like status for the bestelling_kos_item
      final currentUser = Supabase.instance.client.auth.currentUser;
      
      bool isLiked = false;
      
      if (currentUser != null && bestKosId != null) {
        try {
          isLiked = await _terugvoerRepository.hasUserLikedBestellingKosItem(bestKosId);
        } catch (e) {
          print('Error checking like status: $e');
          // If table doesn't exist yet, just continue without like functionality
          isLiked = false;
        }
      }
      
      if (mounted) {
        setState(() {
          _availableFeedbackOptions = options;
          _selectedFeedback = existingFeedback;
          _isLiked = isLiked;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading feedback data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        Fluttertoast.showToast(msg: 'Fout met laai van terugvoer opsies');
      }
    }
  }

  void _openFeedbackDialog() {
    // Create a local copy of selected feedback IDs for the dialog
    final selectedIds = _selectedFeedback
        .map((f) => (f['terugvoer'] as Map<String, dynamic>?)?['terug_id'] as String?)
        .where((id) => id != null)
        .cast<String>()
        .toSet();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kies Terugvoer'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Kies een of meer terugvoer opsies:',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        children: _availableFeedbackOptions.map((option) {
                          final optionId = option['terug_id'] as String;
                          final isSelected = selectedIds.contains(optionId);
                          
                          return CheckboxListTile(
                            title: Text(option['terug_naam'] ?? ''),
                            subtitle: option['terug_beskrywing'] != null && 
                                     (option['terug_beskrywing'] as String).isNotEmpty
                                ? Text(
                                    option['terug_beskrywing'],
                                    style: const TextStyle(fontSize: 12),
                                  )
                                : null,
                            value: isSelected,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  selectedIds.add(optionId);
                                } else {
                                  selectedIds.remove(optionId);
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            dense: true,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kanselleer'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _saveFeedback(selectedIds.toList());
              Navigator.pop(context);
            },
            child: const Text('Stoor'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveFeedback(List<String> selectedIds) async {
    if (!mounted) return;
    
    final bestKosId = widget.bestellingKosItem['best_kos_id'] as String?;
    if (bestKosId == null) {
      Fluttertoast.showToast(msg: 'Fout: Geen item ID gevind nie');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await _terugvoerRepository.saveFeedbackForItem(bestKosId, selectedIds);
      
      if (success) {
        // Reload feedback data to get the updated state
        await _loadFeedbackData();
        
        // Notify parent widget of the update
        widget.onFeedbackUpdated(widget.bestellingKosItem);
        
        Fluttertoast.showToast(msg: 'Terugvoer gestoor!');
      } else {
        Fluttertoast.showToast(msg: 'Fout met stoor van terugvoer');
      }
    } catch (e) {
      print('Error saving feedback: $e');
      Fluttertoast.showToast(msg: 'Fout met stoor van terugvoer');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleLike() async {
    if (!mounted) return;
    
    final bestKosId = widget.bestellingKosItem['best_kos_id'] as String?;
    final currentUser = Supabase.instance.client.auth.currentUser;

    if (bestKosId == null || currentUser == null) {
      Fluttertoast.showToast(msg: 'Fout: Kan nie like status verander nie');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Per requirements: pressing like should increment kos_item.kos_item_likes
      // linked via bestelling_kos_item.kos_item_id. No feedback records.
      final success = await _terugvoerRepository
          .incrementKosItemLikesForBestelling(bestKosId);
      if (success && mounted) {
        setState(() {
          _isLiked = true;
        });
        Fluttertoast.showToast(msg: 'Item gelike!');
      }

      if (!success) {
        Fluttertoast.showToast(msg: 'Fout met verander van like status');
      }
    } catch (e) {
      print('Error toggling like: $e');
      Fluttertoast.showToast(msg: 'Fout met verander van like status');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final hasExistingFeedback = _selectedFeedback.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Like section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _isLoading ? null : _toggleLike,
              icon: Icon(
                _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                size: 18,
                color: _isLiked ? Theme.of(context).colorScheme.primary : null,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const Text(
              'Terugvoer:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                if (!hasExistingFeedback)
                  OutlinedButton.icon(
                    onPressed: _openFeedbackDialog,
                    icon: const Icon(FeatherIcons.plus, size: 14),
                    label: const Text('Voeg by', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      minimumSize: Size.zero,
                    ),
                  ),
                if (hasExistingFeedback)
                  IconButton(
                    onPressed: _openFeedbackDialog,
                    icon: const Icon(FeatherIcons.edit, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
          ],
        ),
        if (hasExistingFeedback) ...[
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: _selectedFeedback.map((feedback) {
              final terugvoerData = feedback['terugvoer'] as Map<String, dynamic>?;
              final feedbackName = terugvoerData?['terug_naam'] as String? ?? 'Onbekend';
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(FeatherIcons.checkCircle, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      feedbackName,
                      style: const TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
