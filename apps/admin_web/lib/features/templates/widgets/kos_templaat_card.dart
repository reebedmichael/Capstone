import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'kos_item_templaat.dart';

class KositemTemplateCard extends StatefulWidget {
  final KositemTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onView;
  final bool showEditDeleteButtons;

  const KositemTemplateCard({
    super.key,
    required this.template,
    required this.onEdit,
    required this.onDelete,
    required this.onView,
    this.showEditDeleteButtons = true,
  });

  @override
  State<KositemTemplateCard> createState() => _KositemTemplateCardState();
}

class _KositemTemplateCardState extends State<KositemTemplateCard> {
  bool _isHovered = false;

  bool get _isMobile {
    return defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android;
  }

  @override
  Widget build(BuildContext context) {
    final template = widget.template;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallOrMedium =
        screenWidth < 900; // breakpoint for showing top-right buttons

    return MouseRegion(
      onEnter: (_) {
        if (!_isMobile && !isSmallOrMedium) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (!_isMobile && !isSmallOrMedium) setState(() => _isHovered = false);
      },
      child: GestureDetector(
        onTap: widget.onView,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 6,
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Image + content
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (template.prent != null)
                    AspectRatio(
                      aspectRatio: 4 / 3,
                      child: Image.network(
                        template.prent!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.naam,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (template.beskrywing.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            template.beskrywing,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[700]),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "R${template.prys.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        if (template.bestanddele.isNotEmpty)
                          Text(
                            "${template.bestanddele.length} bestanddele",
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // Overlay action buttons (only for large screens on hover)
              if (!isSmallOrMedium)
                Positioned.fill(
                  child: AnimatedOpacity(
                    opacity: _isMobile || _isHovered ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      alignment: Alignment.center,
                      color: Colors.black.withOpacity(0.25),
                      child: Wrap(
                        spacing: 12,
                        children: [
                          _circleIconButton(
                            icon: Icons.remove_red_eye_outlined,
                            onTap: widget.onView,
                            color: Colors.blue,
                          ),
                          if (widget.showEditDeleteButtons) ...[
                            _circleIconButton(
                              icon: Icons.edit,
                              onTap: widget.onEdit,
                              color: Colors.green,
                            ),
                            _circleIconButton(
                              icon: Icons.delete_outline,
                              onTap: widget.onDelete,
                              color: Colors.red.shade400,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),

              // Always visible action buttons for small/medium screens
              if (isSmallOrMedium)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _circleIconButton(
                        icon: Icons.remove_red_eye_outlined,
                        onTap: widget.onView,
                        color: Colors.blue,
                      ),
                      if (widget.showEditDeleteButtons) ...[
                        const SizedBox(width: 8),
                        _circleIconButton(
                          icon: Icons.edit,
                          onTap: widget.onEdit,
                          color: Colors.green,
                        ),
                        const SizedBox(width: 8),
                        _circleIconButton(
                          icon: Icons.delete_outline,
                          onTap: widget.onDelete,
                          color: Colors.red.shade400,
                        ),
                      ],
                    ],
                  ),
                ),

              // Category badge
              if (template.dieetKategorie.isNotEmpty)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Wrap(
                    spacing: 4,
                    children: template.dieetKategorie.map((cat) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          cat,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 36,
        height: 36,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color ?? Colors.black, size: 20),
      ),
    );
  }
}
