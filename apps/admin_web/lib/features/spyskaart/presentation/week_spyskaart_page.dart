import 'package:flutter/material.dart';

class WeekSpyskaartPage extends StatelessWidget {
	const WeekSpyskaartPage({super.key});
	@override
	Widget build(BuildContext context) {
		return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
			Row(children: [
				FilledButton(onPressed: () {}, child: const Text('Kies week')),
				const SizedBox(width: 8),
				FilledButton(onPressed: () {}, child: const Text('Sperdatum')),
				const Spacer(),
				OutlinedButton(onPressed: () {}, child: const Text('Stoor')),
				const SizedBox(width: 8),
				FilledButton(onPressed: () {}, child: const Text('Publiseer')),
			]),
			const SizedBox(height: 12),
			Expanded(
				child: Center(child: Text('Week-kolomme en sleep-area (stub)', style: Theme.of(context).textTheme.bodyLarge)),
			),
		]);
	}
} 