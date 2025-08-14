import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Sidebar extends StatelessWidget {
	const Sidebar({super.key});

	@override
	Widget build(BuildContext context) {
		final entries = <_NavEntry>[
			_NavEntry('Dashboard', Icons.dashboard_outlined, '/dashboard'),
			_NavEntry('Spyskaart', Icons.restaurant_menu, '/spyskaart'),
			_NavEntry('Week Spyskaart', Icons.calendar_today, '/week_spyskaart'),
			_NavEntry('Templates: Kositem', Icons.list_alt, '/templates/kositem'),
			_NavEntry('Templates: Week', Icons.view_week, '/templates/week'),
			_NavEntry('Bestellings', Icons.receipt_long, '/bestellings'),
			_NavEntry('Gebruikers', Icons.group_outlined, '/gebruikers'),
			_NavEntry('Kennisgewings', Icons.notifications_outlined, '/kennisgewings'),
			_NavEntry('Verslae', Icons.insights_outlined, '/verslae'),
			_NavEntry('Instellings', Icons.settings_outlined, '/instellings'),
			_NavEntry('Hulp', Icons.help_outline, '/hulp'),
			_NavEntry('Profiel', Icons.person_outline, '/profiel'),
		];
		return LayoutBuilder(builder: (context, constraints) {
			final isCollapsed = constraints.maxWidth < 640;
			return ListView(
				children: [
					Padding(
						padding: const EdgeInsets.all(16),
						child: Text('Spys Admin', style: Theme.of(context).textTheme.titleLarge),
					),
					...entries.map((e) => ListTile(
						leading: Icon(e.icon),
						title: isCollapsed ? null : Text(e.label),
						onTap: () => context.go(e.path),
						dense: true,
					)),
				],
			);
		});
	}
}

class _NavEntry {
	final String label;
	final IconData icon;
	final String path;
	const _NavEntry(this.label, this.icon, this.path);
} 