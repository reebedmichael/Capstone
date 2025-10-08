import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
	const DashboardPage({super.key});
	@override
	Widget build(BuildContext context) {
		return GridView.count(
			crossAxisCount: 2,
			mainAxisSpacing: 16,
			crossAxisSpacing: 16,
			childAspectRatio: 1.8,
			children: const [
				_Card(title: 'Aktiewe bestellings', value: '12'),
				_Card(title: 'Verkope (7 dae)', value: 'R 4 250'),
				_Card(title: 'Aktiewe gebruikers', value: '86'),
				_Card(title: 'Gewildste kositem', value: 'Vetkoek'),
			],
		);
	}
}

class _Card extends StatelessWidget {
	final String title;
	final String value;
	const _Card({required this.title, required this.value});
	@override
	Widget build(BuildContext context) {
		return Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
			Text(title, style: Theme.of(context).textTheme.titleMedium),
			const SizedBox(height: 8),
			Text(value, style: Theme.of(context).textTheme.headlineMedium),
		])));
	}
} 