import 'package:flutter/material.dart';

class SpyskaartBestuurPage extends StatelessWidget {
	const SpyskaartBestuurPage({super.key});
	@override
	Widget build(BuildContext context) {
		return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
			Row(children: [
				Expanded(child: TextField(decoration: const InputDecoration(hintText: 'Soek'))),
				const SizedBox(width: 12),
				FilledButton(onPressed: () {}, child: const Text('Voeg nuwe item by')),
			]),
			const SizedBox(height: 12),
			Expanded(
				child: SingleChildScrollView(
					scrollDirection: Axis.horizontal,
					child: DataTable(columns: const [
						DataColumn(label: Text('Prent')),
						DataColumn(label: Text('Naam')),
						DataColumn(label: Text('Beskrywing')),
						DataColumn(label: Text('Kategorië')),
						DataColumn(label: Text('Prys')),
						DataColumn(label: Text('Beskikbaar')),
						DataColumn(label: Text('Aksies')),
					], rows: const []),
				),
			),
		]);
	}
} 