import 'package:capstone_admin/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Sidebar extends StatelessWidget {
  final bool isCollapsed;
  const Sidebar({super.key, required this.isCollapsed});

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.toString();

    final entries = <_NavEntry>[
      _NavEntry('Dashboard', Icons.dashboard_outlined, '/dashboard'),
      _NavEntry('Spyskaart', Icons.restaurant_menu, '/spyskaart'),
      _NavEntry('Week Spyskaart', Icons.calendar_today, '/week_spyskaart'),
      _NavEntry('Templates: Kositem', Icons.list_alt, '/templates/kositem'),
      _NavEntry('Templates: Week', Icons.view_week, '/templates/week'),
      _NavEntry('Bestellings', Icons.receipt_long, '/bestellings'),
      _NavEntry('Gebruikers', Icons.group_outlined, '/gebruikers'),
      _NavEntry(
        'Kennisgewings',
        Icons.notifications_outlined,
        '/kennisgewings',
      ),
      _NavEntry('Verslae', Icons.insights_outlined, '/verslae'),
      _NavEntry('Instellings', Icons.settings_outlined, '/instellings'),
      _NavEntry('Hulp', Icons.help_outline, '/hulp'),
      _NavEntry('Profiel', Icons.person_outline, '/profiel'),
    ];

    return SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Header / Brand
          Padding(
            padding: const EdgeInsets.all(16),
            child: isCollapsed
                ? const Icon(Icons.fastfood, size: 28)
                : Text(
                    'Spys Admin',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
          ),

          // Nav items
          ...entries.map((e) {
            final isSelected = currentRoute == e.path;

            final tile = MouseRegion(
              cursor: SystemMouseCursors.click,
              child: StatefulBuilder(
                builder: (context, setState) {
                  bool isHovered = false;
                  return MouseRegion(
                    onEnter: (_) => setState(() => isHovered = true),
                    onExit: (_) => setState(() => isHovered = false),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : isHovered
                            ? Colors.grey.withOpacity(0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: Tooltip(
                          message: isCollapsed ? e.label : '',
                          waitDuration: const Duration(milliseconds: 400),
                          child: Icon(
                            e.icon,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).iconTheme.color,
                          ),
                        ),
                        title: isCollapsed
                            ? null
                            : Text(
                                e.label,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Theme.of(
                                          context,
                                        ).textTheme.bodyMedium?.color,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                        dense: true,
                        onTap: () => context.go(e.path),
                        horizontalTitleGap: 12,
                        minLeadingWidth: isCollapsed ? 0 : 40,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: isCollapsed ? 16 : 12,
                        ),
                      ),
                    ),
                  );
                },
              ),
            );

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: isCollapsed ? SizedBox(height: 48, child: tile) : tile,
            );
          }),
        ],
      ),
    );
  }
}

class _NavEntry {
  final String label;
  final IconData icon;
  final String path;
  const _NavEntry(this.label, this.icon, this.path);
}
