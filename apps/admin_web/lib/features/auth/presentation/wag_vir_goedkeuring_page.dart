import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../shared/providers/auth_providers.dart';

class WagVirGoedkeuringPage extends ConsumerWidget {
	const WagVirGoedkeuringPage({super.key});
	
	@override
	Widget build(BuildContext context, WidgetRef ref) {
		return Scaffold(
			body: Center(
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						const Icon(Icons.hourglass_empty, size: 64),
						const SizedBox(height: 12),
						const Text('Jou admin-aansoek wag vir goedkeuring.'),
						const SizedBox(height: 8),
						const Text('A primary admin should update your rights to access more features.'),
						const SizedBox(height: 16),
						ElevatedButton(
							onPressed: () async {
								final authService = ref.read(authServiceProvider);
								await authService.signOut();
								if (context.mounted) {
									context.go('/teken_in');
								}
							},
							child: const Text('Teken uit'),
						),
					],
				),
			),
		);
	}
} 