import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/constants/spacing.dart';

class MobileNotification {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final String type; // 'order' | 'menu' | 'allowance' | 'general'
  bool read;

  MobileNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.type,
    this.read = false,
  });
}

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _primaryTab = 'all'; // all | unread | read
  String _secondaryTab = 'all'; // all | orders | menu | allowance

  final List<MobileNotification> _notifications = <MobileNotification>[
    MobileNotification(
      id: '1',
      title: 'Bestelling Bevestig',
      message: 'Jou bestelling #1234 is bevestig.',
      date: DateTime.now().subtract(const Duration(minutes: 12)),
      type: 'order',
      read: false,
    ),
    MobileNotification(
      id: '2',
      title: 'Nuwe Spyskaart Items',
      message: 'Kyk na die nuwe week se spyskaart.',
      date: DateTime.now().subtract(const Duration(hours: 3)),
      type: 'menu',
      read: false,
    ),
    MobileNotification(
      id: '3',
      title: 'Toelaag Opgedateer',
      message: 'Jou toelaag is suksesvol aangevul.',
      date: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
      type: 'allowance',
      read: true,
    ),
    MobileNotification(
      id: '4',
      title: 'Welkom by Spys',
      message: 'Dankie dat jy aanmeld! Geniet jou ervaring.',
      date: DateTime.now().subtract(const Duration(days: 6)),
      type: 'general',
      read: true,
    ),
  ];

  int get _unreadCount => _notifications.where((n) => !n.read).length;
  int get _orderCount => _notifications.where((n) => n.type == 'order').length;
  int get _menuCount => _notifications.where((n) => n.type == 'menu').length;
  int get _allowanceCount =>
      _notifications.where((n) => n.type == 'allowance').length;

  List<MobileNotification> get _filteredNotifications {
    final List<MobileNotification> primaryFiltered = _notifications.where((
      MobileNotification n,
    ) {
      switch (_primaryTab) {
        case 'unread':
          return !n.read;
        case 'read':
          return n.read;
        default:
          return true;
      }
    }).toList();

    final List<MobileNotification> secondaryFiltered = primaryFiltered.where((
      MobileNotification n,
    ) {
      switch (_secondaryTab) {
        case 'orders':
          return n.type == 'order';
        case 'menu':
          return n.type == 'menu';
        case 'allowance':
          return n.type == 'allowance';
        default:
          return true;
      }
    }).toList();

    secondaryFiltered.sort((a, b) => b.date.compareTo(a.date));
    return secondaryFiltered;
  }

  void _markAsRead(String id) {
    setState(() {
      final MobileNotification target = _notifications.firstWhere(
        (n) => n.id == id,
        orElse: () => _notifications.first,
      );
      target.read = true;
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (final MobileNotification n in _notifications) {
        n.read = true;
      }
    });
  }

  void _markFilteredAsRead() {
    setState(() {
      for (final MobileNotification n in _filteredNotifications.where(
        (n) => !n.read,
      )) {
        n.read = true;
      }
    });
  }

  String _formatDate(DateTime date) {
    final DateTime now = DateTime.now();
    final int diffInHours = now.difference(date).inHours;
    if (diffInHours < 1) {
      final int diffInMinutes = now.difference(date).inMinutes;
      if (diffInMinutes < 1) return 'Nou net';
      return '$diffInMinutes minute gelede';
    } else if (diffInHours < 24) {
      return '$diffInHours uur gelede';
    } else {
      final int diffInDays = (diffInHours / 24).floor();
      if (diffInDays == 1) return 'Gister';
      if (diffInDays < 7) return '$diffInDays dae gelede';
      final bool showYear = date.year != now.year;
      return '${date.day.toString().padLeft(2, '0')} ${_monthShortAf(date.month)}${showYear ? ' ${date.year}' : ''}';
    }
  }

  String _monthShortAf(int month) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mrt',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return months[month - 1];
  }

  Icon _typeIcon(String type) {
    switch (type) {
      case 'order':
        return const Icon(
          Icons.shopping_cart,
          color: AppColors.primary,
          size: 20,
        );
      case 'menu':
        return const Icon(Icons.restaurant_menu, color: Colors.green, size: 20);
      case 'allowance':
        return const Icon(
          Icons.account_balance_wallet,
          color: Colors.blue,
          size: 20,
        );
      default:
        return const Icon(Icons.info_outline, color: Colors.grey, size: 20);
    }
  }

  Widget _badge(
    String text, {
    Color? backgroundColor,
    Color? textColor,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black12,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: textColor ?? Colors.black87,
        ),
      ),
    );
  }

  Widget _outlineBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black26),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: AppTypography.labelSmall),
    );
  }

  Widget _chip({
    required String value,
    required String label,
    required String groupValue,
    required void Function(String) onSelected,
    Widget? trailing,
  }) {
    final bool selected = value == groupValue;
    return InkWell(
      onTap: () => onSelected(value),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.transparent,
          border: Border.all(
            color: selected ? AppColors.primary : Colors.black12,
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: selected ? AppColors.primary : null,
              ),
            ),
            if (trailing != null) ...<Widget>[
              const SizedBox(width: 6),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<MobileNotification> filtered = _filteredNotifications;
    final bool canMarkFiltered =
        _primaryTab != 'all' && filtered.any((n) => !n.read);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              AppColors.primary.withValues(alpha: 0.05),
              AppColors.secondary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Spacing.screenHPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        if (GoRouter.of(context).canPop()) {
                          context.pop();
                        } else {
                          context.go('/home');
                        }
                      },
                    ),
                    Text(
                      'Kennisgewings',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_unreadCount > 0)
                      TextButton.icon(
                        onPressed: _markAllAsRead,
                        icon: const Icon(
                          Icons.done_all,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        label: Text(
                          'Lees Alles',
                          style: AppTypography.labelMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),

                Spacing.vGap16,

                // Primary filter chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _chip(
                      value: 'all',
                      label: 'Alles',
                      groupValue: _primaryTab,
                      onSelected: (v) => setState(() => _primaryTab = v),
                      trailing: _badge(
                        '${_notifications.length}',
                        backgroundColor: Colors.black12,
                      ),
                    ),
                    _chip(
                      value: 'unread',
                      label: 'Ongelees',
                      groupValue: _primaryTab,
                      onSelected: (v) => setState(() => _primaryTab = v),
                      trailing: _badge(
                        '$_unreadCount',
                        backgroundColor: AppColors.primary,
                        textColor: Colors.white,
                      ),
                    ),
                    _chip(
                      value: 'read',
                      label: 'Gelees',
                      groupValue: _primaryTab,
                      onSelected: (v) => setState(() => _primaryTab = v),
                      trailing: _badge(
                        '${_notifications.length - _unreadCount}',
                        backgroundColor: Colors.black12,
                      ),
                    ),
                  ],
                ),

                Spacing.vGap12,

                // Secondary filter chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    _chip(
                      value: 'orders',
                      label: 'Bestellings',
                      groupValue: _secondaryTab,
                      onSelected: (v) => setState(() => _secondaryTab = v),
                      trailing: _orderCount > 0 ? _badge('$_orderCount') : null,
                    ),
                    _chip(
                      value: 'menu',
                      label: 'Spyskaart',
                      groupValue: _secondaryTab,
                      onSelected: (v) => setState(() => _secondaryTab = v),
                      trailing: _menuCount > 0 ? _badge('$_menuCount') : null,
                    ),
                    _chip(
                      value: 'allowance',
                      label: 'Toelaag',
                      groupValue: _secondaryTab,
                      onSelected: (v) => setState(() => _secondaryTab = v),
                      trailing: _allowanceCount > 0
                          ? _badge('$_allowanceCount')
                          : null,
                    ),
                    _chip(
                      value: 'all',
                      label: 'Alle Tipes',
                      groupValue: _secondaryTab,
                      onSelected: (v) => setState(() => _secondaryTab = v),
                    ),
                  ],
                ),

                if (canMarkFiltered) ...<Widget>[
                  Spacing.vGap8,
                  Align(
                    alignment: Alignment.centerRight,
                    child: OutlinedButton.icon(
                      onPressed: _markFilteredAsRead,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Merk Sigbare As Gelees'),
                    ),
                  ),
                ],

                Spacing.vGap12,

                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: <Widget>[
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: Colors.black38,
                        ),
                        Spacing.vGap12,
                        Text(
                          'Geen kennisgewings${_primaryTab == 'unread'
                              ? ' om te lees'
                              : _primaryTab == 'read'
                              ? ' gelees'
                              : _secondaryTab == 'orders'
                              ? ' oor bestellings'
                              : _secondaryTab == 'menu'
                              ? ' oor spyskaart'
                              : _secondaryTab == 'allowance'
                              ? ' oor toelaag'
                              : ''}',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Spacing.vGap4,
                        Text(
                          _primaryTab == 'unread'
                              ? 'Jy is op hoogte met alles!'
                              : 'Probeer '
                                    "'"
                                    'n ander filter of kom later terug',
                          style: AppTypography.bodySmall.copyWith(
                            color: Colors.black54,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                else
                  Column(
                    children: filtered.map((MobileNotification n) {
                      final bool isUnread = !n.read;
                      return Card(
                        elevation: isUnread ? 2 : 0,
                        color: isUnread
                            ? AppColors.primary.withValues(alpha: 0.05)
                            : null,
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: isUnread
                                ? AppColors.primary.withValues(alpha: 0.5)
                                : Colors.black12,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: _typeIcon(n.type),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Text(
                                                n.title,
                                                style: AppTypography.labelLarge
                                                    .copyWith(
                                                      color: isUnread
                                                          ? Colors.black87
                                                          : Colors.black54,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                n.message,
                                                style: AppTypography.bodySmall
                                                    .copyWith(
                                                      color: isUnread
                                                          ? Colors.black87
                                                          : Colors.black54,
                                                    ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: <Widget>[
                                                  const Icon(
                                                    Icons.access_time,
                                                    size: 12,
                                                    color: Colors.black45,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    _formatDate(n.date),
                                                    style: AppTypography
                                                        .labelSmall
                                                        .copyWith(
                                                          color: Colors.black54,
                                                        ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  _outlineBadge(
                                                    n.type == 'order'
                                                        ? 'Bestelling'
                                                        : n.type == 'menu'
                                                        ? 'Spyskaart'
                                                        : n.type == 'allowance'
                                                        ? 'Toelaag'
                                                        : 'Algemeen',
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        if (isUnread)
                                          IconButton(
                                            onPressed: () => _markAsRead(n.id),
                                            icon: const Icon(
                                              Icons.check,
                                              color: AppColors.primary,
                                            ),
                                          )
                                        else
                                          const Row(
                                            children: <Widget>[
                                              Icon(
                                                Icons.done_all,
                                                color: Colors.green,
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                if (_notifications.isNotEmpty) ...<Widget>[
                  Spacing.vGap16,
                  Card(
                    color: Colors.black12.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Colors.black12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: <Widget>[
                          _statTile(
                            title: 'Totaal',
                            value: '${_notifications.length}',
                            color: AppColors.primary,
                          ),
                          _statTile(
                            title: 'Ongelees',
                            value: '$_unreadCount',
                            color: Colors.orange,
                          ),
                          _statTile(
                            title: 'Gelees',
                            value: '${_notifications.length - _unreadCount}',
                            color: Colors.green,
                          ),
                          _statTile(
                            title: 'Bestellings',
                            value: '$_orderCount',
                            color: Colors.blue,
                          ),
                        ],
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

  Widget _statTile({
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      children: <Widget>[
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: AppTypography.labelSmall.copyWith(color: Colors.black54),
        ),
      ],
    );
  }
}
