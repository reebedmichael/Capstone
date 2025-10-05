import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/providers/auth_providers.dart';

class WagVirGoedkeuringPage extends ConsumerWidget {
  const WagVirGoedkeuringPage({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.read(authServiceProvider);
    return FutureBuilder<Map<String, dynamic>?>(
      future: authService.getUserProfile(),
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final profile = snapshot.data;
        final admin = (profile != null) ? profile['admin_tipes'] as Map<String, dynamic>? : null;
        final adminTypeName = (admin?['admin_tipe_naam'] as String?)?.trim() ?? '';

        String title = 'Toegang Beperk';
        String primary = '';
        String secondary = '';
        IconData icon = Icons.info_outline;
        Color color = Colors.orange;

        switch (adminTypeName) {
          case 'Pending':
            title = 'Wag vir Goedkeuring';
            primary = 'Jou admin-profiel wag op goedkeuring deur\n\'n Primêre Admin.';
            secondary = 'Jy sal toegang kry sodra jou aansoek goedgekeur is.';
            icon = Icons.pending_actions;
            color = Colors.orange;
            break;
          case 'Tertiary':
            title = 'Beperkte Toegang (Tersiêr)';
            primary = 'Jy is gemerk as \'Tersiêre Admin\'. Jy het nie toegang\n'
                'tot die webwerf se admin-kenmerke nie,';
            secondary = 'maar jy kan nog steeds bestellings goedkeur en voltooi.';
            icon = Icons.admin_panel_settings_outlined;
            color = Colors.blueGrey;
            break;
          case 'None':
            title = 'Geen Admin Toegang';
            primary = 'Die admin-webwerf en sy kenmerke is nie vir jou beskikbaar nie.';
            secondary = 'Kontak asseblief \'n admin om jou regte op te dateer vir toegang.';
            icon = Icons.block;
            color = Colors.redAccent;
            break;
          default:
            title = 'Toegang Beperk';
            primary = 'Jou profiel het tans nie toegang tot hierdie webwerf nie.';
            secondary = 'Kontak asseblief \'n admin vir meer inligting.';
            icon = Icons.info_outline;
            color = Colors.orange;
        }

        return Scaffold(
          body: Center(
            child: Card(
              margin: const EdgeInsets.all(32),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 64,
                      color: color,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (loading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: CircularProgressIndicator(),
                      )
                    else ...[
                      Text(
                        primary,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        secondary,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () async {
                            final svc = ref.read(authServiceProvider);
                            await svc.signOut();
                            if (context.mounted) {
                              context.go('/teken_in');
                            }
                          },
                          child: const Text('Teken uit'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () async {
                            // Re-fetch profile and redirect if access is now allowed
                            final svc = ref.read(authServiceProvider);
                            try {
                              final prof = await svc.getUserProfile();
                              final admin = prof?['admin_tipes'] as Map<String, dynamic>?;
                              final tipe = (admin?['admin_tipe_naam'] as String?)?.trim() ?? '';
                              final restricted = {'Pending', 'Tertiary', 'None'};
                              if (!restricted.contains(tipe)) {
                                if (context.mounted) {
                                  context.go('/dashboard');
                                }
                                return;
                              }
                              // Still restricted: trigger any listeners and notify user
                              ref.invalidate(userApprovalProvider);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Status herlaai. Wag nog vir toegang.')),
                                );
                              }
                            } catch (_) {
                              // On error, just refresh provider as before
                              ref.invalidate(userApprovalProvider);
                            }
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
      },
    );
  }
} 