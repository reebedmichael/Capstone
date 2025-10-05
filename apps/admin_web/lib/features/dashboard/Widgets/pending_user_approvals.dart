import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PendingUserApprovals extends StatelessWidget {
  final List<Map<String, dynamic>> pendingUsers;
  final Function(String) onApproveUser;
  final Function(String) onRejectUser;
  final Function(String) onNavigateToUsers;

  const PendingUserApprovals({
    Key? key,
    required this.pendingUsers,
    required this.onApproveUser,
    required this.onRejectUser,
    required this.onNavigateToUsers,
  }) : super(key: key);

  Widget _summaryBox(String number, String label, Color base) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: base.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: base.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              number,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: base,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: base.withOpacity(0.8)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Gebruiker Goedkeurings',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Gebruiker registrasie opsomming en goedkeuringsstatus',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => context.go('/gebruikers'),

                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: Text('Meer'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (pendingUsers.isEmpty)
              Column(
                children: const [
                  SizedBox(height: 12),
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8),
                  Text('No pending approvals'),
                ],
              )
            else
              Column(
                children: [
                  // Summary stats
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _summaryBox(
                        '${pendingUsers.length}',
                        'Total Pending',
                        Colors.amber,
                      ),
                      _summaryBox(
                        '${pendingUsers.where((u) => u['accountType'] == 'Customer').length}',
                        'Customers',
                        Colors.blue,
                      ),
                      _summaryBox(
                        '${pendingUsers.where((u) => u['accountType'] == 'Delivery Partner').length}',
                        'Partners',
                        Colors.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Most recent
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Most Recent',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: pendingUsers.take(3).map((user) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(Icons.person, size: 18),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      user['accountType'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => onRejectUser(user['id']),
                                  tooltip: 'Reject',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.check),
                                  onPressed: () => onApproveUser(user['id']),
                                  tooltip: 'Approve',
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
