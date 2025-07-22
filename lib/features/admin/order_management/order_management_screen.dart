import 'package:flutter/material.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  List<Map<String, dynamic>> orders = [
    {'id': 1, 'gebruiker': 'Jan Smit', 'items': 'Burger x2', 'status': 'In verwerking', 'tyd': '09:30'},
    {'id': 2, 'gebruiker': 'Piet Pienaar', 'items': 'Wrap x1', 'status': 'Gereed', 'tyd': '10:00'},
    {'id': 3, 'gebruiker': 'Anna Jacobs', 'items': 'Pizza x1', 'status': 'Afgehandel', 'tyd': '08:45'},
  ];
  String statusFilter = 'Alle';
  final statusOptions = ['Alle', 'In verwerking', 'Gereed', 'Afgehandel', 'Kanselleer'];

  void _changeStatus(int index, String? newStatus) {
    if (newStatus == null) return;
    setState(() {
      orders[index]['status'] = newStatus;
    });
    // TODO: Backend integration for status change
  }

  void _cancelOrder(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kanselleer bestelling'),
        content: Text('Is jy seker jy wil bestelling #${orders[index]['id']} kanselleer?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Nee')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                orders[index]['status'] = 'Kanselleer';
              });
              Navigator.pop(context);
              // TODO: Backend integration for cancel
            },
            child: const Text('Ja, kanselleer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = statusFilter == 'Alle'
        ? orders
        : orders.where((o) => o['status'] == statusFilter).toList();
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Bestellings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              DropdownButton<String>(
                value: statusFilter,
                items: statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) => setState(() => statusFilter = val ?? 'Alle'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: filteredOrders.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, i) {
                final order = filteredOrders[i];
                return Card(
                  child: ListTile(
                    title: Text('Bestelling #${order['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Gebruiker: ${order['gebruiker']}\nItems: ${order['items']}\nTyd: ${order['tyd']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButton<String>(
                          value: order['status'],
                          items: statusOptions.where((s) => s != 'Alle').map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) => _changeStatus(orders.indexOf(order), val),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: order['status'] == 'Kanselleer' ? null : () => _cancelOrder(orders.indexOf(order)),
                          tooltip: 'Kanselleer',
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          const Text('// TODO: Backend integration for order management', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
        ],
      ),
    );
  }
} 