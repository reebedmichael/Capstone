import 'package:flutter/material.dart';

class TekenInPage extends StatelessWidget {
	const TekenInPage({super.key});

	@override
	Widget build(BuildContext context) {
		return Center(
			child: ConstrainedBox(
				constraints: const BoxConstraints(maxWidth: 420),
				child: Column(
					mainAxisSize: MainAxisSize.min,
					children: [
						Text('Teken In', style: Theme.of(context).textTheme.headlineSmall),
						const SizedBox(height: 16),
						TextField(decoration: const InputDecoration(labelText: 'E-pos')),
						const SizedBox(height: 12),
						TextField(decoration: const InputDecoration(labelText: 'Wagwoord'), obscureText: true),
						const SizedBox(height: 16),
						LayoutBuilder(builder: (context, constraints) {
							return Wrap(
								alignment: WrapAlignment.spaceBetween,
								children: [
									TextButton(onPressed: () {}, child: const Text('Vergeet wagwoord?')),
									FilledButton(onPressed: () {}, child: const Text('Teken in')),
								],
							);
						}),
						const SizedBox(height: 8),
						TextButton(onPressed: () {}, child: const Text('Registreer as admin')),
					],
				),
			),
		);
	}
} 