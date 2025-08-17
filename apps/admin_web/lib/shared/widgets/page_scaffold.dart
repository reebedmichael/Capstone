import 'package:flutter/material.dart';
import 'sidebar.dart';

class PageScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  const PageScaffold({super.key, required this.title, required this.child});

  static const double _expandedWidth = 260;
  static const double _collapsedWidth = 72; // icon-only width
  static const double _breakpoint = 900; // tweak to taste

  @override
  Widget build(BuildContext context) {
    final bool showSidebar =
        (title != 'teken_in' && title != 'registreer_admin');

    // Use screen width to decide collapsed vs expanded
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isCollapsed = screenWidth < _breakpoint;
    final double sidebarWidth = isCollapsed ? _collapsedWidth : _expandedWidth;

    return Scaffold(
      body: Row(
        children: [
          if (showSidebar)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: sidebarWidth,
              color: Theme.of(context).colorScheme.surface,
              child: Sidebar(isCollapsed: isCollapsed),
            ),
          // Content
          Expanded(
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ],
      ),
    );
  }
}
