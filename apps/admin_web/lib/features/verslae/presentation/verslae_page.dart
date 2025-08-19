import 'package:flutter/material.dart';

class VerslaePage extends StatelessWidget {
	const VerslaePage({super.key});

	@override
	Widget build(BuildContext context) {
		// Dummy report data
		final List<_KPI> kpis = <_KPI>[
			_KPI('Totale Verkope', 'R 12 540', Icons.payments_outlined, Theme.of(context).colorScheme.primary),
			_KPI('Bestellings', '236', Icons.receipt_long_outlined, Colors.blue),
			_KPI('Gem. Bestelwaarde', 'R 53.10', Icons.attach_money_outlined, Colors.green),
			_KPI('Nuwe Gebruikers', '42', Icons.group_outlined, Colors.orange),
		];

		return SingleChildScrollView(
			padding: const EdgeInsets.all(24),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: <Widget>[
					LayoutBuilder(builder: (context, constraints) {
						final int cols = constraints.maxWidth > 1100 ? 4 : constraints.maxWidth > 800 ? 2 : 1;
						return GridView.count(
							shrinkWrap: true,
							physics: const NeverScrollableScrollPhysics(),
							crossAxisCount: cols,
							mainAxisSpacing: 16,
							crossAxisSpacing: 16,
							childAspectRatio: 3.6,
							children: kpis.map((k) => _kpiCard(context, k)).toList(),
						);
					}),

					const SizedBox(height: 24),

					// Sales chart placeholder
					Card(
						child: Padding(
							padding: const EdgeInsets.all(16),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: <Widget>[
									Text('Verkope – Laaste 7 dae', style: Theme.of(context).textTheme.titleMedium),
									const SizedBox(height: 12),
									Container(
										height: 220,
										decoration: BoxDecoration(
											borderRadius: BorderRadius.circular(12),
											gradient: const LinearGradient(
												begin: Alignment.topLeft,
												end: Alignment.bottomRight,
												colors: <Color>[Color(0xFFBBDEFB), Color(0xFFE3F2FD)],
											),
										),
									),
								],
							),
						),
					),

					const SizedBox(height: 24),

					// Top items list placeholder
					Card(
						child: Padding(
							padding: const EdgeInsets.all(16),
							child: Column(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: <Widget>[
									Text('Top Verkoper Items', style: Theme.of(context).textTheme.titleMedium),
									const SizedBox(height: 12),
									ListView.separated(
										shrinkWrap: true,
										physics: const NeverScrollableScrollPhysics(),
										itemCount: 5,
										separatorBuilder: (_, __) => const Divider(height: 12),
										itemBuilder: (_, i) => Row(
											mainAxisAlignment: MainAxisAlignment.spaceBetween,
											children: <Widget>[
												Text('Item ${i + 1}', style: Theme.of(context).textTheme.bodyLarge),
												Text('R ${(20 + i * 5).toStringAsFixed(2)}'),
											],
										),
									),
								],
							),
						),
					),
				],
			),
		);
	}

	Widget _kpiCard(BuildContext context, _KPI k) {
		return Card(
			child: Padding(
				padding: const EdgeInsets.all(16),
				child: Row(children: <Widget>[
					Container(width: 40, height: 40, decoration: BoxDecoration(color: k.color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(k.icon, color: k.color)),
					const SizedBox(width: 12),
					Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
						Text(k.title, style: Theme.of(context).textTheme.titleSmall),
						const SizedBox(height: 6),
						Text(k.value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: k.color)),
					])),
				]),
			),
		);
	}
}

class _KPI {
	final String title;
	final String value;
	final IconData icon;
	final Color color;
	const _KPI(this.title, this.value, this.icon, this.color);
}