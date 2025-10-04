import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/auth_providers.dart';

class WagVirGoedkeuringPage extends ConsumerWidget {
  const WagVirGoedkeuringPage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pending_actions,
                  size: 64,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Wag vir Goedkeuring',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Jou admin-registrasie is suksesvol voltooi, maar wag nog vir goedkeuring deur \'n Primêre Admin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Jy sal toegang tot die admin-paneel kry sodra jou aansoek goedgekeur is.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      onPressed: () async {
                        final authService = ref.read(authServiceProvider);
                        await authService.signOut();
                        if (context.mounted) {
                          context.go('/teken_in');
                        }
                      },
                      child: const Text('Teken uit'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Refresh approval status
                        ref.invalidate(userApprovalProvider);
                      },
                      child: const Text('Herlaai Status'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 