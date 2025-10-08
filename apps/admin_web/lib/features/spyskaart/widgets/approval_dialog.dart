// approval_dialog.dart
import 'package:flutter/material.dart';

class ApprovalDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final bool isLoading;
  const ApprovalDialog({
    super.key,
    required this.onConfirm,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Bevestig Goedkeuring',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Is jy seker jy wil hierdie spyskaart finaliseer en goedkeur?',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Nadat die spyskaart goedgekeur is, kan dit nie meer gewysig word nie.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Kanselleer'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              onConfirm();
                              Navigator.of(context).pop();
                            },
                      child: Text(isLoading ? 'Stuur...' : 'Ja, Keur Goed'),
                    ),
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
