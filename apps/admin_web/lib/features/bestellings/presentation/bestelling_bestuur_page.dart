import 'package:flutter/material.dart';

class BestellingBestuurPage extends StatelessWidget {
	const BestellingBestuurPage({super.key});
	@override
	Widget build(BuildContext context) {
		return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
			Row(children: [
				DropdownButton<String>(items: const [DropdownMenuItem(value: 'alle', child: Text('Alle'))], onChanged: (_) {}),
				const SizedBox(width: 12),
				OutlinedButton(onPressed: () {}, child: const Text('Massa-aksie')),
			]),
			const SizedBox(height: 12),
			Expanded(child: Center(child: Text('Tabel met bestellings (stub)', style: Theme.of(context).textTheme.bodyLarge))),
		]);
	}
} 