import 'package:flutter/material.dart';

class RegistreerAdminPage extends StatelessWidget {
	const RegistreerAdminPage({super.key});
	@override
	Widget build(BuildContext context) {
		return SingleChildScrollView(
			child: Center(
				child: ConstrainedBox(
					constraints: const BoxConstraints(maxWidth: 640),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.stretch,
						children: const [
							TextField(decoration: InputDecoration(labelText: 'Naam')),
							SizedBox(height: 12),
							TextField(decoration: InputDecoration(labelText: 'Van')),
							SizedBox(height: 12),
							TextField(decoration: InputDecoration(labelText: 'E-pos')),
							SizedBox(height: 12),
							TextField(decoration: InputDecoration(labelText: 'Selfoon')),
							SizedBox(height: 12),
							TextField(decoration: InputDecoration(labelText: 'Wagwoord'), obscureText: true),
							SizedBox(height: 12),
							TextField(decoration: InputDecoration(labelText: 'Bevestig Wagwoord'), obscureText: true),
							SizedBox(height: 16),
							FilledButton(onPressed: null, child: Text('Doen aansoek')),
						],
					),
				),
			),
		);
	}
} 