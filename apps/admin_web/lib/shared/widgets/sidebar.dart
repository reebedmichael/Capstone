import 'package:capstone_admin/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Sidebar extends StatefulWidget {
  final bool isCollapsed;
  const Sidebar({super.key, required this.isCollapsed});

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  bool spyskaartExpanded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeAutoExpandForRoute();
  }

  @override
  void didUpdateWidget(covariant Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If collapse state changed, re-evaluate auto-expand
    if (oldWidget.isCollapsed != widget.isCollapsed) {
      _maybeAutoExpandForRoute();
    }
  }

  void _maybeAutoExpandForRoute() {
    // Safely get path portion of current route
    final currentUri = GoRouterState.of(context).uri;
    final path = currentUri.path;

    final shouldExpand = _isSpyskaartRoute(path);

    // Only auto-expand when sidebar is expanded (not collapsed)
    if (!widget.isCollapsed && shouldExpand && !spyskaartExpanded) {
      setState(() => spyskaartExpanded = true);
    }
    // If sidebar collapsed, keep submenu hidden
    if (widget.isCollapsed && spyskaartExpanded) {
      setState(() => spyskaartExpanded = false);
    }
  }

  bool _isSpyskaartRoute(String path) {
    // Match main route, week route, or templates subroutes
    return path == '/spyskaart' ||
        path == '/week_spyskaart' ||
        path.startsWith('/templates');
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;

    // other top-level entries (after the Spyskaart group)
    final restEntries = <_NavEntry>[
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
            child: widget.isCollapsed
                ? const Icon(Icons.fastfood, size: 28)
                : Text(
                    'Spys Admin',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
          ),

          // Dashboard (always first)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: _buildTile(
              _NavEntry('Dashboard', Icons.dashboard_outlined, '/dashboard'),
              currentRoute,
            ),
          ),

          // Spyskaart group (main + children)
          _buildSpyskaartGroup(currentRoute),

          // The rest of the entries in original order
          ...restEntries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: _buildTile(e, currentRoute),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpyskaartGroup(String currentRoute) {
    final isSelected = _isSpyskaartRoute(currentRoute);

    final children = [
      _NavEntry('Week Spyskaart', Icons.calendar_today, '/week_spyskaart'),
      _NavEntry('Templates: Kositem', Icons.list_alt, '/templates/kositem'),
      _NavEntry('Templates: Week', Icons.view_week, '/templates/week'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // parent tile
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: StatefulBuilder(
              builder: (context, setStateHover) {
                bool isHovered = false;
                return MouseRegion(
                  onEnter: (_) => setStateHover(() => isHovered = true),
                  onExit: (_) => setStateHover(() => isHovered = false),
                  child: GestureDetector(
                    onTap: () {
                      if (widget.isCollapsed) {
                        // collapsed: navigate to main spyskaart
                        context.go('/spyskaart');
                      } else {
                        // expanded: toggle submenu
                        setState(() => spyskaartExpanded = !spyskaartExpanded);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : isHovered
                            ? Colors.grey.withOpacity(0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: Tooltip(
                          message: widget.isCollapsed ? 'Spyskaart' : '',
                          waitDuration: const Duration(milliseconds: 400),
                          child: Icon(
                            Icons.restaurant_menu,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).iconTheme.color,
                          ),
                        ),
                        title: widget.isCollapsed
                            ? null
                            : Text(
                                'Spyskaart',
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
                        trailing: widget.isCollapsed
                            ? null
                            : Icon(
                                spyskaartExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context).iconTheme.color,
                              ),
                        dense: true,
                        horizontalTitleGap: 12,
                        minLeadingWidth: widget.isCollapsed ? 0 : 40,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: widget.isCollapsed ? 16 : 12,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // submenu items (only when expanded and sidebar not collapsed)
          if (!widget.isCollapsed && spyskaartExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 32, top: 6),
              child: Column(
                children: children
                    .map(
                      (e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: _buildTile(e, currentRoute),
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTile(_NavEntry e, String currentRoute) {
    final isSelected = currentRoute == e.path;

    return StatefulBuilder(
      builder: (context, setStateHover) {
        bool isHovered = false;
        return MouseRegion(
          onEnter: (_) => setStateHover(() => isHovered = true),
          onExit: (_) => setStateHover(() => isHovered = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.go(e.path),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : isHovered
                    ? Colors.grey.withOpacity(0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                leading: Tooltip(
                  message: widget.isCollapsed ? e.label : '',
                  waitDuration: const Duration(milliseconds: 400),
                  child: Icon(
                    e.icon,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).iconTheme.color,
                  ),
                ),
                title: widget.isCollapsed
                    ? null
                    : Text(
                        e.label,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).textTheme.bodyMedium?.color,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                dense: true,
                horizontalTitleGap: 12,
                minLeadingWidth: widget.isCollapsed ? 0 : 40,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: widget.isCollapsed ? 16 : 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NavEntry {
  final String label;
  final IconData icon;
  final String path;
  const _NavEntry(this.label, this.icon, this.path);
}
