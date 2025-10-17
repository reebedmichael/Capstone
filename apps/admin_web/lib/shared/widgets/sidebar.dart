import 'package:capstone_admin/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/auth_providers.dart';

class Sidebar extends ConsumerStatefulWidget {
  final bool isCollapsed;
  const Sidebar({super.key, required this.isCollapsed});

  @override
  ConsumerState<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends ConsumerState<Sidebar>
    with TickerProviderStateMixin {
  bool spyskaartExpanded = false;
  bool toelaeExpanded = false;
  bool verslaeExpanded = false;
  late AnimationController _expandController;
  late AnimationController _toelaeExpandController;
  late AnimationController _verslaeExpandController;
  late Animation<double> _expandAnimation;
  late Animation<double> _toelaeExpandAnimation;
  late Animation<double> _verslaeExpandAnimation;

  @override
  void initState() {
    super.initState();
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
    _toelaeExpandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _toelaeExpandAnimation = CurvedAnimation(
      parent: _toelaeExpandController,
      curve: Curves.easeInOut,
    );
    _verslaeExpandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _verslaeExpandAnimation = CurvedAnimation(
      parent: _verslaeExpandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    _toelaeExpandController.dispose();
    _verslaeExpandController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeAutoExpandForRoute();
  }

  @override
  void didUpdateWidget(covariant Sidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isCollapsed != widget.isCollapsed) {
      _maybeAutoExpandForRoute();
    }
  }

  void _maybeAutoExpandForRoute() {
    final currentUri = GoRouterState.of(context).uri;
    final path = currentUri.path;
    final shouldExpandSpyskaart = _isSpyskaartRoute(path);
    final shouldExpandToelae = _isToelaeRoute(path);
    final shouldExpandVerslae = _isVerslaeRoute(path);

    if (!widget.isCollapsed && shouldExpandSpyskaart && !spyskaartExpanded) {
      setState(() => spyskaartExpanded = true);
      _expandController.forward();
    }
    if (widget.isCollapsed && spyskaartExpanded) {
      setState(() => spyskaartExpanded = false);
      _expandController.reverse();
    }

    if (!widget.isCollapsed && shouldExpandToelae && !toelaeExpanded) {
      setState(() => toelaeExpanded = true);
      _toelaeExpandController.forward();
    }
    if (widget.isCollapsed && toelaeExpanded) {
      setState(() => toelaeExpanded = false);
      _toelaeExpandController.reverse();
    }

    if (!widget.isCollapsed && shouldExpandVerslae && !verslaeExpanded) {
      setState(() => verslaeExpanded = true);
      _verslaeExpandController.forward();
    }
    if (widget.isCollapsed && verslaeExpanded) {
      setState(() => verslaeExpanded = false);
      _verslaeExpandController.reverse();
    }
  }

  bool _isSpyskaartRoute(String path) {
    return path == '/spyskaart' ||
        path == '/week_spyskaart' ||
        path.startsWith('/templates');
  }

  bool _isToelaeRoute(String path) {
    return path == '/toelae' ||
        path == '/toelae/bestuur' ||
        path == '/toelae/gebruiker_tipes' ||
        path == '/toelae/transaksies';
  }

  bool _isVerslaeRoute(String path) {
    return path == '/verslae' || path.startsWith('/verslae/');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentRoute = GoRouterState.of(context).uri.path;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurfaceColor(isDark),
        border: Border(
          right: BorderSide(color: AppColors.getBorderColor(isDark), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header / Brand
            _buildHeader(theme, isDark),

            // Main navigation content
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Dashboard
                  _buildNavItem(
                    _NavEntry(
                      'Dashboard',
                      Icons.dashboard_outlined,
                      '/dashboard',
                    ),
                    currentRoute,
                    theme,
                    isDark,
                  ),

                  // Bestellings
                  _buildNavItem(
                    _NavEntry(
                      'Bestellings',
                      Icons.receipt_long,
                      '/bestellings',
                    ),
                    currentRoute,
                    theme,
                    isDark,
                  ),

                  // Spyskaart group
                  _buildSpyskaartGroup(currentRoute, theme, isDark),

                  // Other navigation items (excluding Toelae)
                  _buildNavItem(
                    _NavEntry('Gebruikers', Icons.group_outlined, '/gebruikers'),
                    currentRoute,
                    theme,
                    isDark,
                  ),

                  // Toelae group
                  _buildToelaeGroup(currentRoute, theme, isDark),

                  // Verslae group
                  _buildVerslaeGroup(currentRoute, theme, isDark),

                  // Remaining navigation items
                  ..._getRemainingNavEntries().map(
                    (e) => _buildNavItem(e, currentRoute, theme, isDark),
                  ),
                ],
              ),
            ),

            // Logout section
            _buildLogoutSection(theme, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.getBorderColor(isDark), width: 1),
        ),
      ),
      child: widget.isCollapsed
          ? Center(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.fastfood, size: 28, color: AppColors.primary),
              ),
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.fastfood,
                    size: 24,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spys Admin',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.getOnSurfaceColor(isDark),
                        ),
                      ),
                      Text(
                        'Bestuur Portaal',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.getOnSurfaceVariantColor(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildNavItem(
    _NavEntry entry,
    String currentRoute,
    ThemeData theme,
    bool isDark,
  ) {
    final isSelected = currentRoute == entry.path;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go(entry.path),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCollapsed ? 16 : 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: AppColors.primary.withOpacity(0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  width: widget.isCollapsed ? 24 : 32,
                  height: widget.isCollapsed ? 24 : 32,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.getOnSurfaceVariantColor(
                            isDark,
                          ).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    entry.icon,
                    size: widget.isCollapsed ? 16 : 18,
                    color: isSelected
                        ? Colors.white
                        : AppColors.getOnSurfaceVariantColor(isDark),
                  ),
                ),
                if (!widget.isCollapsed) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      entry.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.getOnSurfaceColor(isDark),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpyskaartGroup(
    String currentRoute,
    ThemeData theme,
    bool isDark,
  ) {
    final isSelected = _isSpyskaartRoute(currentRoute);
    final children = [
      _NavEntry('Week Spyskaart', Icons.calendar_today, '/week_spyskaart'),
      _NavEntry('Kositems', Icons.list_alt, '/templates/kositem'),
      _NavEntry('Templaaie', Icons.view_week, '/templates/week'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parent tile
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (widget.isCollapsed) {
                  context.go('/spyskaart');
                } else {
                  setState(() {
                    spyskaartExpanded = !spyskaartExpanded;
                    if (spyskaartExpanded) {
                      _expandController.forward();
                    } else {
                      _expandController.reverse();
                    }
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isCollapsed ? 16 : 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: widget.isCollapsed ? 24 : 32,
                      height: widget.isCollapsed ? 24 : 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.getOnSurfaceVariantColor(
                                isDark,
                              ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.restaurant_menu,
                        size: widget.isCollapsed ? 16 : 18,
                        color: isSelected
                            ? Colors.white
                            : AppColors.getOnSurfaceVariantColor(isDark),
                      ),
                    ),
                    if (!widget.isCollapsed) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Spyskaart',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.getOnSurfaceColor(isDark),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: spyskaartExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.getOnSurfaceVariantColor(isDark),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Submenu items
          if (!widget.isCollapsed)
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Container(
                margin: const EdgeInsets.only(left: 24, top: 4),
                child: Column(
                  children: children.map((child) {
                    final isChildSelected = currentRoute == child.path;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => context.go(child.path),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isChildSelected
                                  ? AppColors.primary.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isChildSelected
                                  ? Border.all(
                                      color: AppColors.primary.withOpacity(0.3),
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: isChildSelected
                                        ? AppColors.primary
                                        : AppColors.getOnSurfaceVariantColor(
                                            isDark,
                                          ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    child.icon,
                                    size: 12,
                                    color: isChildSelected
                                        ? Colors.white
                                        : AppColors.getOnSurfaceVariantColor(
                                            isDark,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    child.label,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isChildSelected
                                          ? AppColors.primary
                                          : AppColors.getOnSurfaceVariantColor(
                                              isDark,
                                            ),
                                      fontWeight: isChildSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToelaeGroup(
    String currentRoute,
    ThemeData theme,
    bool isDark,
  ) {
    final isSelected = _isToelaeRoute(currentRoute);
    final children = [
      _NavEntry('Gebruiker Tipes', Icons.group_work, '/toelae/gebruiker_tipes'),
      _NavEntry('Individueel', Icons.person_add_alt_1, '/toelae/bestuur'),
      _NavEntry('Transaksies', Icons.history, '/toelae/transaksies'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parent tile
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (widget.isCollapsed) {
                  context.go('/toelae');
                } else {
                  setState(() {
                    toelaeExpanded = !toelaeExpanded;
                    if (toelaeExpanded) {
                      _toelaeExpandController.forward();
                    } else {
                      _toelaeExpandController.reverse();
                    }
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isCollapsed ? 16 : 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: widget.isCollapsed ? 24 : 32,
                      height: widget.isCollapsed ? 24 : 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.getOnSurfaceVariantColor(
                                isDark,
                              ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet,
                        size: widget.isCollapsed ? 16 : 18,
                        color: isSelected
                            ? Colors.white
                            : AppColors.getOnSurfaceVariantColor(isDark),
                      ),
                    ),
                    if (!widget.isCollapsed) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Toelae',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.getOnSurfaceColor(isDark),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: toelaeExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.getOnSurfaceVariantColor(isDark),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Submenu items
          if (!widget.isCollapsed)
            SizeTransition(
              sizeFactor: _toelaeExpandAnimation,
              child: Container(
                margin: const EdgeInsets.only(left: 24, top: 4),
                child: Column(
                  children: children.map((child) {
                    final isChildSelected = currentRoute == child.path;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => context.go(child.path),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isChildSelected
                                  ? AppColors.primary.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isChildSelected
                                  ? Border.all(
                                      color: AppColors.primary.withOpacity(0.3),
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: isChildSelected
                                        ? AppColors.primary
                                        : AppColors.getOnSurfaceVariantColor(
                                            isDark,
                                          ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    child.icon,
                                    size: 12,
                                    color: isChildSelected
                                        ? Colors.white
                                        : AppColors.getOnSurfaceVariantColor(
                                            isDark,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    child.label,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isChildSelected
                                          ? AppColors.primary
                                          : AppColors.getOnSurfaceVariantColor(
                                              isDark,
                                            ),
                                      fontWeight: isChildSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerslaeGroup(
    String currentRoute,
    ThemeData theme,
    bool isDark,
  ) {
    final isSelected = _isVerslaeRoute(currentRoute);
    final children = [
      _NavEntry('Statistiek', Icons.insights_outlined, '/verslae'),
      _NavEntry('Terugvoer', Icons.feedback_outlined, '/verslae/terugvoer'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Parent tile
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                if (widget.isCollapsed) {
                  context.go('/verslae');
                } else {
                  setState(() {
                    verslaeExpanded = !verslaeExpanded;
                    if (verslaeExpanded) {
                      _verslaeExpandController.forward();
                    } else {
                      _verslaeExpandController.reverse();
                    }
                  });
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: widget.isCollapsed ? 16 : 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                          width: 1,
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: widget.isCollapsed ? 24 : 32,
                      height: widget.isCollapsed ? 24 : 32,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.getOnSurfaceVariantColor(
                                isDark,
                              ).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.query_stats,
                        size: widget.isCollapsed ? 16 : 18,
                        color: isSelected
                            ? Colors.white
                            : AppColors.getOnSurfaceVariantColor(isDark),
                      ),
                    ),
                    if (!widget.isCollapsed) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Verslae',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.getOnSurfaceColor(isDark),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      AnimatedRotation(
                        turns: verslaeExpanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: AppColors.getOnSurfaceVariantColor(isDark),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Submenu items
          if (!widget.isCollapsed)
            SizeTransition(
              sizeFactor: _verslaeExpandAnimation,
              child: Container(
                margin: const EdgeInsets.only(left: 24, top: 4),
                child: Column(
                  children: children.map((child) {
                    final isChildSelected = currentRoute == child.path;
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => context.go(child.path),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isChildSelected
                                  ? AppColors.primary.withOpacity(0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: isChildSelected
                                  ? Border.all(
                                      color: AppColors.primary.withOpacity(0.3),
                                      width: 1,
                                    )
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: isChildSelected
                                        ? AppColors.primary
                                        : AppColors.getOnSurfaceVariantColor(
                                            isDark,
                                          ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    child.icon,
                                    size: 12,
                                    color: isChildSelected
                                        ? Colors.white
                                        : AppColors.getOnSurfaceVariantColor(
                                            isDark,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    child.label,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isChildSelected
                                          ? AppColors.primary
                                          : AppColors.getOnSurfaceVariantColor(
                                              isDark,
                                            ),
                                      fontWeight: isChildSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLogoutSection(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.getBorderColor(isDark), width: 1),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _handleLogout,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCollapsed ? 16 : 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.destructive.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.destructive.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: widget.isCollapsed ? 24 : 32,
                  height: widget.isCollapsed ? 24 : 32,
                  decoration: BoxDecoration(
                    color: AppColors.destructive.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.logout,
                    size: widget.isCollapsed ? 16 : 18,
                    color: AppColors.destructive,
                  ),
                ),
                if (!widget.isCollapsed) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Teken Uit',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.destructive,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<_NavEntry> _getRemainingNavEntries() {
    return [
      _NavEntry(
        'Kennisgewings',
        Icons.notifications_outlined,
        '/kennisgewings',
      ),
      _NavEntry('Instellings', Icons.settings_outlined, '/instellings'),
      _NavEntry('Hulp', Icons.help_outline, '/hulp'),
      _NavEntry('Profiel', Icons.person_outline, '/profiel'),
    ];
  }

  void _handleLogout() async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      if (mounted) {
        context.go('/teken_in');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fout met teken uit: $e'),
            backgroundColor: AppColors.destructive,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}

class _NavEntry {
  final String label;
  final IconData icon;
  final String path;
  const _NavEntry(this.label, this.icon, this.path);
}
