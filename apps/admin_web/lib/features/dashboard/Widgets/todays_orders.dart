import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TodaysOrders extends StatelessWidget {
  final List<Map<String, dynamic>> todaysOrders;
  final String selectedLocation;
  final List<String> locations;
  final Function(String) onLocationChanged;
  final Function(String) onUpdateOrdersByStatus;
  final Function(String) onNavigateToOrders;

  const TodaysOrders({
    Key? key,
    required this.todaysOrders,
    required this.selectedLocation,
    required this.locations,
    required this.onLocationChanged,
    required this.onUpdateOrdersByStatus,
    required this.onNavigateToOrders,
  }) : super(key: key);

  Color getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.amber;
      case 'In Progress':
        return Colors.blue;
      case 'Ready':
        return Colors.purple;
      case 'Out for Delivery':
        return Colors.orange;
      case 'Delivered':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String? getNextStatus(String currentStatus) {
    switch (currentStatus) {
      case 'Pending':
        return 'In Progress';
      case 'In Progress':
        return 'Ready';
      case 'Ready':
        return 'Out for Delivery';
      case 'Out for Delivery':
        return 'Delivered';
      case 'Delivered':
        return null;
      default:
        return null;
    }
  }

  List<Map<String, dynamic>> getFilteredOrders() {
    if (selectedLocation == 'all') return todaysOrders;
    return todaysOrders
        .where((o) => o['location'] == selectedLocation)
        .toList();
  }

  List<Map<String, dynamic>> getStatusGroups() {
    final filtered = getFilteredOrders();
    final Map<String, int> summary = {};
    for (var order in filtered) {
      final s = order['status'] as String;
      summary[s] = (summary[s] ?? 0) + 1;
    }
    final groups = [
      {
        'status': 'Pending',
        'count': summary['Pending'] ?? 0,
        'color': getStatusColor('Pending'),
      },
      {
        'status': 'In Progress',
        'count': summary['In Progress'] ?? 0,
        'color': getStatusColor('In Progress'),
      },
      {
        'status': 'Ready',
        'count': summary['Ready'] ?? 0,
        'color': getStatusColor('Ready'),
      },
      {
        'status': 'Out for Delivery',
        'count': summary['Out for Delivery'] ?? 0,
        'color': getStatusColor('Out for Delivery'),
      },
      {
        'status': 'Delivered',
        'count': summary['Delivered'] ?? 0,
        'color': getStatusColor('Delivered'),
      },
    ];
    return groups.where((g) => (g['count'] as int) > 0).toList();
  }

  @override
  Widget build(BuildContext context) {
    final statusGroups = getStatusGroups();

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
                        'Vandag se Bestellings',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Bestellings gegroepeer volgens status met aflaai punt filtrering',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: selectedLocation,
                  onChanged: (v) {
                    if (v == null) return;
                    onLocationChanged(v);
                  },
                  items: [
                    DropdownMenuItem(
                      value: 'all',
                      child: Row(
                        children: const [
                          Icon(Icons.place, size: 16),
                          SizedBox(width: 6),
                          Text('Alle Liggings'),
                        ],
                      ),
                    ),
                    const DropdownMenuItem(
                      value: 'Downtown',
                      child: Text('Downtown'),
                    ),
                    const DropdownMenuItem(
                      value: 'Uptown',
                      child: Text('Uptown'),
                    ),
                    const DropdownMenuItem(value: 'Mall', child: Text('Mall')),
                  ],
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => context.go('/bestellings'),
                  child: const Text('Meer'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (statusGroups.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Geen bestellings vir heirdie ligging',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else
              Column(
                children: statusGroups.map((group) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: group['color'],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group['status'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${group['count']} order${group['count'] == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${group['count']}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (getNextStatus(group['status']) != null)
                              OutlinedButton.icon(
                                onPressed: () =>
                                    onUpdateOrdersByStatus(group['status']),
                                icon: const Icon(Icons.arrow_forward, size: 16),
                                label: Text(
                                  'Beweeg na ${getNextStatus(group['status'])}',
                                ),
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
      ),
    );
  }
}
