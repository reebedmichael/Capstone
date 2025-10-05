import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ImportantNotifications extends StatelessWidget {
  final List<Map<String, dynamic>> importantNotifications;
  final Function(String) onDismissNotification;

  const ImportantNotifications({
    Key? key,
    required this.importantNotifications,
    required this.onDismissNotification,
  }) : super(key: key);

  Icon getNotificationIcon(String type) {
    switch (type) {
      case 'critical':
        return const Icon(Icons.error, color: Colors.red);
      case 'warning':
        return const Icon(Icons.warning, color: Colors.amber);
      case 'info':
        return const Icon(Icons.info, color: Colors.blue);
      case 'success':
        return const Icon(Icons.check_circle, color: Colors.green);
      default:
        return const Icon(Icons.notifications, color: Colors.grey);
    }
  }

  BoxDecoration getNotificationDecoration(String type) {
    switch (type) {
      case 'critical':
        return BoxDecoration(
          color: Colors.red.shade50,
          border: Border(left: BorderSide(color: Colors.red, width: 4)),
          borderRadius: BorderRadius.circular(8),
        );
      case 'warning':
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
      case 'success':
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
    return importantNotifications
        .where((n) => n['dismissed'] == false)
        .toList();
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
                ElevatedButton(
                  onPressed: () => context.go('/kennisgewings'),
                  child: const Text('Meer'),
                ),
              ],
            ),
            const SizedBox(height: 6),

            const SizedBox(height: 12),
            if (activeNotifications.isEmpty)
              Column(
                children: const [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8),
                  Text('No important notifications'),
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
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: getNotificationDecoration(notif['type']),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          getNotificationIcon(notif['type']),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        notif['title'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      onPressed: () =>
                                          onDismissNotification(notif['id']),
                                      splashRadius: 18,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notif['message'],
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
                                      notif['time'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    if (notif['actionRequired'] == true)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Text(
                                          'Action Required',
                                          style: TextStyle(fontSize: 12),
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
                onPressed: () {},
                child: Text(
                  'View ${activeNotifications.length - 5} more notifications',
                ),
              ),
          ],
        ),
      ),
    );
  }
}
