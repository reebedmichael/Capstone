import 'package:flutter/material.dart';

class WagVirGoedkeuringPage extends StatelessWidget {
	const WagVirGoedkeuringPage({super.key});
	@override
	Widget build(BuildContext context) {
		return Center(
			child: Column(
				mainAxisSize: MainAxisSize.min,
				children: const [
					Icon(Icons.hourglass_empty, size: 64),
					SizedBox(height: 12),
					Text('Jou admin-aansoek wag vir goedkeuring.'),
					SizedBox(height: 8),
					TextButton(onPressed: null, child: Text('Teken uit')),
				],
			),
		);
	}
} 