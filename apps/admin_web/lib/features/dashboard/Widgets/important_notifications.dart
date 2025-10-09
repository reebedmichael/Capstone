import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spys_api_client/spys_api_client.dart';

class ImportantNotifications extends StatefulWidget {
  final Function(int)? onNotificationCountChanged;

  const ImportantNotifications({Key? key, this.onNotificationCountChanged})
    : super(key: key);

  @override
  State<ImportantNotifications> createState() => _ImportantNotificationsState();
}

class _ImportantNotificationsState extends State<ImportantNotifications> {
  late final AdminDashboardRepository _repo;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final supabaseClient = Supabase.instance.client;
    _repo = AdminDashboardRepository(SupabaseDb(supabaseClient));
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      if (currentUserId == null) {
        setState(() {
          _errorMessage = 'No authenticated user found';
          _isLoading = false;
        });
        return;
      }

      final notifications = await _repo.fetchUnreadNotifications(currentUserId);
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });

      // Notify parent widget of notification count change
      widget.onNotificationCountChanged?.call(notifications.length);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _dismissNotification(String kennisId) async {
    try {
      await _repo.markNotificationAsRead(kennisId);
      // Reload notifications to reflect the change
      await _loadNotifications();
    } catch (e) {
      // Show error but don't update state to avoid UI issues
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kon nie kennisgewing afdank nie: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Icon getNotificationIcon(String type) {
    switch (type) {
      case 'fout':
        return const Icon(Icons.error, color: Colors.red);
      case 'waarskuwing':
        return const Icon(Icons.warning, color: Colors.amber);
      case 'info':
        return const Icon(Icons.info, color: Colors.blue);
      case 'sukses':
        return const Icon(Icons.check_circle, color: Colors.green);
      default:
        return const Icon(Icons.notifications, color: Colors.grey);
    }
  }

  BoxDecoration getNotificationDecoration(String type) {
    switch (type) {
      case 'fout':
        return BoxDecoration(
          color: Colors.red.shade50,
          border: Border(left: BorderSide(color: Colors.red, width: 4)),
          borderRadius: BorderRadius.circular(8),
        );
      case 'waarskuwing':
        return BoxDecoration(
          color: Colors.amber.shade50,
          border: Border(left: BorderSide(color: Colors.amber, width: 4)),
          borderRadius: BorderRadius.circular(8),
        );
      case 'info':
        return BoxDecoration(
          color: Colors.blue.shade50,
          border: Border(left: BorderSide(color: Colors.blue, width: 4)),
          borderRadius: BorderRadius.circular(8),
        );
      case 'sukses':
        return BoxDecoration(
          color: Colors.green.shade50,
          border: Border(left: BorderSide(color: Colors.green, width: 4)),
          borderRadius: BorderRadius.circular(8),
        );
      default:
        return BoxDecoration(
          color: Colors.grey.shade50,
          border: Border(left: BorderSide(color: Colors.grey, width: 4)),
          borderRadius: BorderRadius.circular(8),
        );
    }
  }

  List<Map<String, dynamic>> getActiveNotifications() {
    return _notifications;
  }

  String _formatNotificationTime(String? dateStr) {
    if (dateStr == null) return 'Onbekend';

    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Net nou';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes} min terug';
      } else if (difference.inHours < 24) {
        return '${difference.inHours} uur terug';
      } else {
        return '${difference.inDays} dag${difference.inDays > 1 ? 'e' : ''} terug';
      }
    } catch (e) {
      return 'Onbekend';
    }
  }

  String _getNotificationType(String? kennisTipeNaam) {
    // Map database notification types to UI types
    switch (kennisTipeNaam?.toLowerCase()) {
      case 'fout':
      case 'error':
        return 'fout';
      case 'waarskuwing':
      case 'warning':
        return 'waarskuwing';
      case 'info':
      case 'information':
        return 'info';
      case 'sukses':
      case 'success':
        return 'sukses';
      default:
        return 'info';
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeNotifications = getActiveNotifications();

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.notifications),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Belangrike Kennisgewings',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  ElevatedButton(
                    onPressed: () => context.go('/kennisgewings'),
                    child: const Text('Meer'),
                  ),
              ],
            ),
            const SizedBox(height: 6),

            const SizedBox(height: 12),
            if (_isLoading)
              Container(
                height: 200,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Laai kennisgewings...'),
                    ],
                  ),
                ),
              )
            else if (_errorMessage != null)
              Container(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        'Kon nie kennisgewings laai nie',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _loadNotifications,
                        icon: Icon(Icons.refresh),
                        label: Text('Probeer weer'),
                      ),
                    ],
                  ),
                ),
              )
            else if (activeNotifications.isEmpty)
              Column(
                children: const [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8),
                  Text('Geen belangrike kennisgewings'),
                ],
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: activeNotifications.length > 5
                      ? 5
                      : activeNotifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final notif = activeNotifications[index];
                    final notificationType = _getNotificationType(
                      notif['kennis_tipe_naam'] as String?,
                    );
                    final kennisId = notif['kennis_id']?.toString() ?? '';

                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: getNotificationDecoration(notificationType),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          getNotificationIcon(notificationType),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notif['kennis_titel'] as String? ??
                                            'Geen titel',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),

                                    // Expanded(
                                    //   child: Text(
                                    //     notif['kennis_beskrywing'] as String? ??
                                    //         'Geen boodskap',
                                    //     style: const TextStyle(fontSize: 14),
                                    //     maxLines: 2,
                                    //     overflow: TextOverflow.ellipsis,
                                    //   ),
                                    // ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      onPressed: () =>
                                          _dismissNotification(kennisId),
                                      splashRadius: 18,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notif['kennis_beskrywing'] as String? ??
                                      'Geen boodskap',
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatNotificationTime(
                                        notif['kennis_geskep_datum'] as String?,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            if (activeNotifications.length > 5)
              TextButton(
                onPressed: () => context.go('/kennisgewings'),
                child: Text(
                  'Bekyk ${activeNotifications.length - 5} meer kennisgewings',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
