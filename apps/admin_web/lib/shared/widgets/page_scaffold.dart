import 'package:flutter/material.dart';
import 'sidebar.dart';

class PageScaffold extends StatelessWidget {
	final String title;
	final Widget child;
	const PageScaffold({super.key, required this.title, required this.child});

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(title: Text(title)),
			body: Row(
				children: [
					Container(width: 260, color: Theme.of(context).colorScheme.surface, child: const Sidebar()),
					Expanded(child: Padding(padding: const EdgeInsets.all(16), child: child)),
				],
			),
		);
	}
} 